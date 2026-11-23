# Power on after AC loss without BIOS: clear AFTERG3_EN (GEN_PMCON_A bit 0) each boot.
# PMC bases found like the kernel's intel_pmc_ssram_telemetry; BIOS resets the bit at POST.
{pkgs, ...}: let
  script = pkgs.writeShellScript "afterg3" ''
    set -eu
    dm() { ${pkgs.busybox}/bin/devmem "$@" || { echo "devmem $1 failed" >&2; exit 1; }; }
    read -r ssram _ < /sys/bus/pci/devices/0000:00:14.0/resource
    soc_pwrm=$(( $(dm $((ssram + 0x14)) 64) & ~7 ))
    pch_ssram=$(( $(dm $((ssram + 0x60)) 64) & ~7 ))
    devid=$(dm $((pch_ssram + 0x70)) 16)
    pch_pwrm=$(( $(dm $((pch_ssram + 0x14)) 64) & ~7 ))
    printf 'soc_pwrm=%#x pch_ssram=%#x pch_devid=%s pch_pwrm=%#x\n' \
      "$soc_pwrm" "$pch_ssram" "$devid" "$pch_pwrm"
    [ "$devid" = 0x7F27 ] || { echo "unexpected PCH PMC devid, not writing" >&2; exit 1; }
    for b in "$soc_pwrm" "$pch_pwrm"; do
      [ "$b" -ne 0 ] || continue
      v=$(dm $((b + 0x1020)) 8)
      [ "$v" != 0xFF ] || { printf 'pwrm=%#x reads 0xFF, skipping\n' "$b"; continue; }
      dm $((b + 0x1020)) 8 $((v & ~1))
      printf 'pwrm=%#x GEN_PMCON_A[7:0] %s -> %s\n' "$b" "$v" "$(dm $((b + 0x1020)) 8)"
    done
  '';
in {
  # pmc_ssram_telemetry claims the SSRAM BAR; strict devmem would refuse reading its header.
  boot.kernelParams = ["iomem=relaxed"];
  systemd.services.afterg3 = {
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = script;
    };
  };
}
