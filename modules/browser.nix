{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.workstation.browser;

  # WebGPU blocklist workaround: AMD Radeon Renoir/RDNA-2 GPUs are
  # blacklisted by Chromium for WebGPU. Pass --ignore-gpu-blocklist so
  # Dawn can enumerate the Vulkan adapter. See also:
  #   chromium --ignore-gpu-blocklist http://localhost:5173
  chromium-wrapped = pkgs.symlinkJoin {
    name = "chromium-wrapped-${pkgs.chromium.version}";
    paths = [ pkgs.chromium ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      # Replace the unwrapped binaries with wrapped versions that pass
      # --ignore-gpu-blocklist. symlinkJoin keeps desktop files, icons,
      # and other resources from the original package.
      rm $out/bin/chromium $out/bin/chromium-browser
      makeWrapper ${pkgs.chromium}/bin/chromium $out/bin/chromium \
        --add-flags "--ignore-gpu-blocklist"
      makeWrapper ${pkgs.chromium}/bin/chromium-browser $out/bin/chromium-browser \
        --add-flags "--ignore-gpu-blocklist"
    '';
    meta.priority = 10;
  };
in
{
  options.workstation.browser = {
    enable = lib.mkEnableOption "Web browsers";

    firefox = lib.mkEnableOption "Firefox" // {
      default = true;
    };
    chromium = lib.mkEnableOption "Chromium" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      lib.optionals cfg.firefox [ pkgs.firefox ]
      ++ lib.optionals cfg.chromium [ chromium-wrapped ];
  };
}
