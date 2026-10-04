{
  # Compressed swap in RAM: absorbs memory spikes (e.g. Hermes bursts) before the
  # OOM killer. Caps uncompressed data at 25% of RAM; costs ~1/3 of that at zstd's ~3:1.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
  };
  boot.kernel.sysctl = {
    # Swapping to zram is cheaper than evicting file cache; >100 prefers it.
    "vm.swappiness" = 180;
    # No readahead: it only helps on disk-backed swap.
    "vm.page-cluster" = 0;
  };
}
