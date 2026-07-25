{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/profiles/workstation.nix
  ];

  config = {
    networking.hostName = "prometheus";

    # ── Realtek RTL8852BE WiFi fix ──
    # Disable PCIe ASPM L1 + clock request to prevent rtw89_hw_scan_offload -110
    # timeouts (firmware can't wake from deep PS in time for scan commands).
    boot.extraModprobeConfig = ''
      options rtw89_pci disable_aspm_l1=y disable_clkreq=y
      options rtw89_core disable_ps_mode=y
    '';
    networking.networkmanager.wifi.powersave = false;

    hardware.cpu.amd.updateMicrocode = true;
    hardware.keyboard.qmk.enable = true;

    # Local Ollama for STT cleanup (see modules/stt.nix). CPU is plenty for a 3B
    # model on short dictation. For AMD GPU accel set acceleration = "rocm"
    # (may need HSA_OVERRIDE_GFX_VERSION for this APU).
    services.ollama = {
      enable = true;
      loadModels = [ "qwen2.5:3b" ];
    };

    # AMD GPU + Vulkan support
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        vulkan-tools
        rocmPackages.clr
      ];
    };

    workstation = {
      profile.enable = true;

      stt.cleanup = false; # Disabled for speed; toggle to true if you want Wispr-style LLM cleanup via local Ollama
      stt.model = "large-v3-turbo-q5_0"; # 547MB, quantized large-v3-turbo — best accuracy/speed with Vulkan GPU

      books.enable = true;

      backup = {
        enable = true;
        # BorgBase repo — URL from borgbase.com repo page
        repo = "ssh://q93e746c@q93e746c.repo.borgbase.com/./repo";
        # Books only
        paths = [ "/home/sid/Downloads/Epubs" ];
        exclude = [ ];
        passFile = ../../../secrets/borg.borgbase.age;
        # Midday + Persistent (module default) — better for a laptop than midnight
        startAt = "*-*-* 12:00:00";
      };

      surfshark = {
        enable = false;
        privateKeyFile = config.age.secrets.surfshark-key.path;
        endpoint = "us-buf.prod.surfshark.com:51820";
        serverPublicKey = "156ry2sOmv+I9KYTy2jR4/BLTnPT+Qn+DoCNqOon1ys=";
        address = [ "10.14.0.2/16" ];
        dns = [
          "162.252.172.57"
          "149.154.159.92"
        ];
      };

      hermes = {
        model = "deepseek/deepseek-v4-flash";
        customProviders = [
          {
            name = "Grok";
            base_url = "http://127.0.0.1:8645/v1";
            api_key = "anything";
            models = [
              "grok-4.5"
              "grok-4.20"
              "grok-4.20-reasoning"
              "grok-4.3"
              "grok-build-0.1"
            ];
          }
        ];
      };
    };

    # ── Age secrets ──
    age.secrets.surfshark-key.file = ../../../secrets/surfshark-key.age;
    age.secrets.anthropic-key = {
      file = ../../../secrets/anthropic-key.age;
      owner = "sid";
      mode = "0400";
    };
    age.secrets.deepseek-key = {
      file = ../../../secrets/deepseek-key.age;
      owner = "sid";
      mode = "0400";
    };

    # ThinkPad-specific: Turn off micmute LED at boot
    systemd.services.micmute-led-off = {
      description = "Turn off micmute LED at boot";
      wantedBy = [ "multi-user.target" ];
      after = [ "sysinit.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.bash}/bin/bash -c 'echo 0 > /sys/class/leds/platform::micmute/brightness || true'";
      };
    };

    # ── Lid close: suspend (swayidle before-sleep hook locks first) ──
    services.logind = {
      settings = {
        Login = {
          HandleLidSwitch = "suspend";
          HandleLidSwitchExternalPower = "suspend";
          HandleLidSwitchDocked = "ignore";
        };
      };
    };

    # ── Extra system packages ──
    environment.systemPackages = with pkgs; [
      nix.doc
    ];
  };
}
