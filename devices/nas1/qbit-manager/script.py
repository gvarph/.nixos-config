import time
from datetime import datetime
import os
from qbittorrentapi import Client, APIConnectionError

# Pulling config from environment variables
QBIT_URL = os.getenv("QBIT_URL", "http://qbittorrent:8080")
QBIT_USER = os.getenv("QBIT_USER", None)
QBIT_PASS = os.getenv("QBIT_PASS", None)
CHECK_INTERVAL = int(os.getenv("CHECK_INTERVAL", "600"))
SEED_THRESHOLD = int(os.getenv("SEED_THRESHOLD", "10"))
AGE_THRESHOLD_HOURS = int(os.getenv("AGE_THRESHOLD_HOURS", "24"))
ratio_threshold = float(os.getenv("RATIO_THRESHOLD", "1"))


def should_be_running(torrent) -> tuple[bool, dict[str, object]]:
    if torrent.progress < 1.0:
        return True, {"Reason": "Torrent is downloading"}

    age_in_hours = (datetime.now().timestamp() - torrent.added_on) / 3600
    if age_in_hours < AGE_THRESHOLD_HOURS:
        return True, {
            "Reason": "Torrent is still fresh",
            "Age": f"{age_in_hours:.2f}h",
            "Threshold": AGE_THRESHOLD_HOURS,
            "Added on": datetime.fromtimestamp(torrent.added_on),
        }

    if torrent.ratio < ratio_threshold:
        return True, {
            "Reason": "Torrent is under ratio threshold",
            "Ratio": f"{torrent.ratio:.2f}",
            "Threshold": ratio_threshold,
        }

    if torrent.num_complete < SEED_THRESHOLD:
        return True, {
            "Reason": "Torrent has not reached swarm seed threshold",
            "Seeds": f"{torrent.num_complete}",
            "Threshold": SEED_THRESHOLD,
        }

    return False, {
        "Reason": "Torrent is complete and has healthy seeds",
        "Seeds": torrent.num_complete,
        "Threshold": SEED_THRESHOLD,
        "Age": f"{age_in_hours:.2f}h",
    }


def manage_torrents():
    try:
        # Connect without needing credentials
        qbt_client = Client(host=QBIT_URL)

        torrents = qbt_client.torrents_info()
        for torrent in torrents:
            h = torrent.hash
            name = torrent.name

            should_run, reason = should_be_running(torrent)
            data = {"Name": name, **reason}

            now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            if torrent.state_enum.is_paused and should_run:
                qbt_client.torrents_resume(torrent_hashes=h)
                print(f"{now} + Resuming torrent")
                for k, v in data.items():
                    print(f"\t{k}:\t{v}")

            elif not torrent.state_enum.is_paused and not should_run:
                qbt_client.torrents_pause(torrent_hashes=h)
                print(f"{now} - Pausing torrent")
                for k, v in data.items():
                    print(f"\t{k}:\t{v}")

    except APIConnectionError:
        print("[WARNING] Could not connect to qBittorrent. Retrying next cycle.")
    except Exception as e:
        print(f"[ERROR] {e}")


if __name__ == "__main__":
    print(f"qBittorrent manager started. Checking every {CHECK_INTERVAL} seconds...")
    print(f"Target swarm seed threshold set to: {SEED_THRESHOLD}")
    while True:
        manage_torrents()
        time.sleep(CHECK_INTERVAL)
