"""Push SteamVR frame timing and Steam Link stream health to VictoriaMetrics.

Two sources, both on the desktop that runs SteamVR:

- The OpenVR compositor's per-frame timing (IVRCompositor::GetFrameTimings),
  read as a background app so polling never launches SteamVR. Folded into
  histograms and counters.
- The Steam Link driver log (driver_vrlink.txt), whose [ProblemAttribution]
  lines summarise every ~15 s how many streamed frames went wrong and why
  (NetworkSlow, PingSpike, DecodeSlow, ...).

Metrics are pushed in Prometheus text format to VictoriaMetrics'
/api/v1/import/prometheus, so the NAS never has to reach the desktop.
"""

import argparse
import base64
import ctypes
import logging
import os
import re
import threading
import time
import urllib.error
import urllib.parse
import urllib.request

import openvr
from prometheus_client import CollectorRegistry, Counter, Gauge, Histogram, generate_latest

log = logging.getLogger("steamvr-exporter")

# Frame time buckets in ms: refresh budgets of 144/120/90/72/60/45/30 Hz plus tails.
BUCKETS_MS = (2, 4, 6, 6.9, 8.3, 10, 11.1, 12.5, 13.9, 16.7, 20, 22.2, 25, 33.3, 50, 100, 250)

registry = CollectorRegistry()

up = Gauge("steamvr_up", "1 while the SteamVR compositor is reachable", registry=registry)
app_info = Gauge("steamvr_app_info", "Application the compositor last served", ["app"], registry=registry)

# Per-frame timings from Compositor_FrameTiming (ms).
TIMING_FIELDS = {
    "frame_interval": ("m_flClientFrameIntervalMs", "Time between the app's WaitGetPoses calls"),
    "app_gpu": ("m_flPreSubmitGpuMs", "App GPU time before Submit"),
    "total_gpu": ("m_flTotalRenderGpuMs", "GPU time from present until compositor work ends"),
    "compositor_gpu": ("m_flCompositorRenderGpuMs", "Compositor GPU time"),
    "compositor_cpu": ("m_flCompositorRenderCpuMs", "Compositor CPU time"),
    "submit": ("m_flSubmitFrameMs", "App CPU time spent in Submit"),
    "app_cpu": (None, "App CPU time: new poses ready until new frame ready"),
    "transfer_latency": ("m_flTransferLatencyMs", "Transfer latency reported by the runtime"),
}
timing_hist = {
    name: Histogram(f"steamvr_{name}_ms", help_, buckets=BUCKETS_MS, registry=registry)
    for name, (_, help_) in TIMING_FIELDS.items()
}

frames = Counter("steamvr_frames", "Compositor frames observed", registry=registry)
presents = Counter("steamvr_frame_presents", "Times the compositor presented a frame (>1 per frame = repeated)", registry=registry)
mispresented = Counter("steamvr_frames_mispresented", "Frames presented on the wrong vsync", registry=registry)
dropped = Counter("steamvr_frames_dropped", "Frames dropped by the compositor", registry=registry)
reprojected = Counter(
    "steamvr_frames_reprojected",
    "Frames reprojected, by reason (cpu/gpu) and motion smoothing",
    ["reason"],
    registry=registry,
)

# Steam Link (vrlink) [ProblemAttribution] summaries.
link_frames = Counter("steamvr_link_frames", "Frames streamed to the headset", registry=registry)
link_outcome = Counter("steamvr_link_frame_outcome", "Streamed frames with a bad outcome", ["outcome"], registry=registry)
link_cause = Counter(
    "steamvr_link_frame_cause",
    "Streamed frames flagged with a cause (a frame can carry several)",
    ["cause"],
    registry=registry,
)
link_outcome_cause = Counter(
    "steamvr_link_frame_outcome_cause",
    "Streamed frames by bad outcome and contributing cause",
    ["outcome", "cause"],
    registry=registry,
)
link_lines = Counter("steamvr_link_log_lines_parsed", "ProblemAttribution lines parsed", registry=registry)


def pairs(text):
    """'NetworkSlow 292 PingSpike 3' -> [('NetworkSlow', 292), ('PingSpike', 3)]."""
    return [(k, int(v)) for k, v in re.findall(r"(\w+) (\d+)", text)]


# --- OpenVR compositor ---------------------------------------------------------


class CompositorPoller:
    BATCH = 256  # frames per GetFrameTimings call; > 1 s at 144 Hz

    def __init__(self, interval):
        self.interval = interval
        self.compositor = None
        self.last_index = None
        self.last_pid = None
        self.timings = (openvr.Compositor_FrameTiming * self.BATCH)()
        self.timings[0].m_nSize = ctypes.sizeof(openvr.Compositor_FrameTiming)

    def connect(self):
        try:
            openvr.init(openvr.VRApplication_Background)
        except openvr.error_code.OpenVRError as e:
            log.debug("SteamVR not available: %s", e)
            return False
        self.compositor = openvr.VRCompositor()
        self.last_index = None
        log.info("connected to SteamVR")
        return True

    def disconnect(self):
        if self.compositor is not None:
            log.info("SteamVR went away")
        self.compositor = None
        self.last_pid = None
        app_info.clear()
        try:
            openvr.shutdown()
        except Exception:
            pass

    def poll(self):
        n, timings = self.compositor.getFrameTimings(self.timings)
        new = [t for t in timings[:n] if self.last_index is None or t.m_nFrameIndex > self.last_index]
        if n and self.last_index is None:
            # First read after connecting: start from now, not the stored history.
            new = []
        if n:
            self.last_index = max(t.m_nFrameIndex for t in timings[:n])
        for t in new:
            frames.inc()
            presents.inc(t.m_nNumFramePresents)
            mispresented.inc(t.m_nNumMisPresented)
            dropped.inc(t.m_nNumDroppedFrames)
            flags = t.m_nReprojectionFlags
            if flags & openvr.VRCompositor_ReprojectionReason_Cpu:
                reprojected.labels("cpu").inc()
            if flags & openvr.VRCompositor_ReprojectionReason_Gpu:
                reprojected.labels("gpu").inc()
            if flags & openvr.VRCompositor_ReprojectionMotion:
                reprojected.labels("motion_smoothing").inc()
            for name, (field, _) in TIMING_FIELDS.items():
                if field is None:
                    value = t.m_flNewFrameReadyMs - t.m_flNewPosesReadyMs
                else:
                    value = getattr(t, field)
                if value > 0:
                    timing_hist[name].observe(value)

        pid = self.compositor.getCumulativeStats(ctypes.sizeof(openvr.Compositor_CumulativeStats)).m_nPid
        if pid != self.last_pid:
            self.last_pid = pid
            app_info.clear()
            if pid:
                try:
                    app_info.labels(openvr.VRApplications().getApplicationKeyByProcessId(pid)).set(1)
                except openvr.error_code.OpenVRError:
                    app_info.labels(f"pid:{pid}").set(1)

    def run(self):
        while True:
            if self.compositor is None and not self.connect():
                up.set(0)
                time.sleep(5)
                continue
            try:
                self.poll()
                up.set(1)
            except Exception as e:  # vrserver exited or the IPC broke
                log.debug("poll failed: %s", e)
                up.set(0)
                self.disconnect()
            time.sleep(self.interval)



# --- Steam Link driver log -------------------------------------------------------

RE_SUMMARY = re.compile(r"\[ProblemAttribution\] (\d+) frames, (?:no problems|outcomes: (.*))$")
RE_CAUSES = re.compile(r"\[ProblemAttribution\] causes: (.*)$")
RE_OUTCOME = re.compile(r"\[ProblemAttribution\]\s+(\w+) \((\d+)\) with: (.*)$")


def handle_log_line(line):
    if "[ProblemAttribution" not in line or "session total" in line:
        return
    if m := RE_SUMMARY.search(line):
        link_frames.inc(int(m.group(1)))
        for outcome, n in pairs(m.group(2) or ""):
            link_outcome.labels(outcome).inc(n)
    elif m := RE_CAUSES.search(line):
        for cause, n in pairs(m.group(1)):
            link_cause.labels(cause).inc(n)
    elif m := RE_OUTCOME.search(line):
        for cause, n in pairs(m.group(3)):
            link_outcome_cause.labels(m.group(1), cause).inc(n)
    else:
        return
    link_lines.inc()


def follow_log(path):
    """Tail the driver log, following SteamVR's truncate/recreate on restart."""
    f = None
    from_start = False  # the file present at startup predates us: skip it
    buf = ""
    while True:
        if f is None:
            try:
                f = open(path, encoding="utf-8", errors="replace")
            except FileNotFoundError:
                from_start = True
                time.sleep(5)
                continue
            if not from_start:
                f.seek(0, os.SEEK_END)
            buf = ""
        chunk = f.read()
        if chunk:
            buf += chunk
            *lines, buf = buf.split("\n")
            for line in lines:
                handle_log_line(line.rstrip("\r"))
            continue
        time.sleep(1)
        try:
            st = os.stat(path)
            replaced = st.st_ino != os.fstat(f.fileno()).st_ino or st.st_size < f.tell()
        except FileNotFoundError:
            replaced = False
        if replaced:
            f.close()
            f = None
            from_start = True


# --- push ------------------------------------------------------------------------


def push_loop(url, labels, auth_file, interval):
    query = urllib.parse.urlencode([("extra_label", f"{k}={v}") for k, v in labels.items()])
    target = f"{url}?{query}"
    failing = False
    while True:
        time.sleep(interval)
        headers = {"Content-Type": "text/plain"}
        if auth_file:
            # Re-read every push so a rotated agenix secret takes effect
            # without restarting the service.
            with open(auth_file) as f:
                auth = f.read().strip()
            headers["Authorization"] = "Basic " + base64.b64encode(auth.encode()).decode()
        req = urllib.request.Request(target, data=generate_latest(registry), headers=headers, method="POST")
        try:
            with urllib.request.urlopen(req, timeout=10) as resp:
                resp.read()
            if failing:
                log.info("push recovered")
            failing = False
        except (urllib.error.URLError, TimeoutError, OSError) as e:
            if not failing:
                log.warning("push to %s failed: %s", url, e)
            failing = True


def main():
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--url", required=True, help="VictoriaMetrics /api/v1/import/prometheus URL")
    p.add_argument("--auth-file", help="file holding user:password for basic auth")
    p.add_argument("--instance", default=os.uname().nodename)
    p.add_argument(
        "--log",
        default=os.path.expanduser("~/.local/share/Steam/logs/driver_vrlink.txt"),
        help="Steam Link driver log",
    )
    p.add_argument("--push-interval", type=float, default=15)
    p.add_argument("--poll-interval", type=float, default=0.5)
    p.add_argument("-v", "--verbose", action="store_true")
    args = p.parse_args()
    logging.basicConfig(level=logging.DEBUG if args.verbose else logging.INFO, format="%(levelname)s %(message)s")

    up.set(0)
    threading.Thread(target=CompositorPoller(args.poll_interval).run, daemon=True).start()
    threading.Thread(target=follow_log, args=(args.log,), daemon=True).start()
    push_loop(args.url, {"job": "steamvr", "instance": args.instance}, args.auth_file, args.push_interval)


if __name__ == "__main__":
    main()
