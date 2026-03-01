{ config, pkgs, inputs, ... }:

let
  # Call package with kernelPackages to ensure kernel is injected
  linuwu-sense =
    config.boot.kernelPackages.callPackage ../../pkgs/linuwu-sense.nix { };

  setPlatformProfileScript = pkgs.writeShellScript "set-platform-profile" ''
    set -euo pipefail

    PROFILE_FILE="/sys/firmware/acpi/platform_profile"
    CHOICES_FILE="/sys/firmware/acpi/platform_profile_choices"

    # Wait for sysfs to appear (kernel modules / ACPI)
    for i in $(seq 1 50); do
      if [ -w "$PROFILE_FILE" ]; then
        break
      fi
      sleep 0.1
    done

    if [ ! -w "$PROFILE_FILE" ]; then
      echo "platform_profile: file not available/writable: $PROFILE_FILE" >&2
      exit 0
    fi

    choices=""
    if [ -r "$CHOICES_FILE" ]; then
      choices="$(cat "$CHOICES_FILE" || true)"
    fi

    pick_and_set() {
      local target="$1"
      if [ -n "$choices" ]; then
        echo "$choices" | tr ' ' '\n' | grep -qx "$target" || return 1
      fi
      echo "$target" > "$PROFILE_FILE"
      echo "platform_profile set to: $target"
      return 0
    }

    # Preferred: balanced-performance
    pick_and_set "balanced-performance" || \
    pick_and_set "performance" || \
    pick_and_set "balanced" || \
    (echo "platform_profile: no expected profile found. choices='$choices'" >&2; exit 0)
  '';
in
{
  # ══════════════════════════════════════════════
  # Acer Predator specific hardware configuration
  # ══════════════════════════════════════════════

  # Note: acer-wmi is blacklisted - replaced by linuwu-sense
  boot.extraModulePackages = [ linuwu-sense ];

  systemd.tmpfiles.rules = [
    "f /sys/firmware/acpi/platform_profile 0664 root wheel - -"
    "z /sys/devices/platform/acer-wmi 0775 root wheel - -"
    "Z /sys/devices/platform/acer-wmi - root wheel - -"
  ];

  systemd.services.set-platform-profile = {
    description = "Set ACPI platform_profile (balanced-performance)";
    wantedBy = [ "multi-user.target" ];

    after = [ "systemd-modules-load.service" "sysinit.target" ];
    wants = [ "systemd-modules-load.service" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = setPlatformProfileScript;
    };
  };

  # Run the same script immediately on every wake (suspend/hibernate/hybrid).
  environment.etc."systemd/system-sleep/set-platform-profile" = {
    mode = "0755";
    source = pkgs.writeShellScript "set-platform-profile-sleep-hook" ''
      [ "$1" = "post" ] || exit 0
      exec ${setPlatformProfileScript}
    '';
  };

  # ══════════════════════════════════════════════
  # LogiOps mouse configuration
  # ══════════════════════════════════════════════

  environment.etc."logid.cfg".text = builtins.readFile ../../config/apps/logid/logid.cfg;
  services.dbus.packages = [ pkgs.logiops ];

  systemd.services.logid = {
    description = "LogiOps (logid) for Logitech HID++ devices";
    wantedBy = [ "multi-user.target" ];

    after = [ "dbus.service" "bluetooth.service" ];
    wants = [ "dbus.service" "bluetooth.service" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.logiops}/bin/logid -c /etc/logid.cfg";
      Restart = "on-failure";
      RestartSec = 1;
    };
  };

  systemd.services."logid-restart@" = {
    description = "Restart logid when Logitech device appears (%I)";
    serviceConfig = {
      Type = "oneshot";
      ExecStart =
        "${pkgs.systemd}/bin/systemctl --no-block restart logid.service";
    };
  };

  # ══════════════════════════════════════════════
  # NVIDIA GPU — RTX 4060 Max-Q (AD107M, Ada Lovelace)
  # ══════════════════════════════════════════════
  # CachyOS runs: nvidia-open 590.48.01 with "Dual MIT/GPL" license
  # This laptop has NO Intel iGPU (dGPU-only), so no PRIME offload needed.

  nixpkgs.config.allowUnfree = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true; # enables nvidia-sleep/hibernate/resume services for GPU state save/restore
    powerManagement.finegrained = false; # no iGPU for offload, dGPU always on
    # IMPORTANT: CachyOS uses nvidia-open (license: "Dual MIT/GPL").
    # AD107 (Ada Lovelace) fully supports open kernel modules.
    # open=true matches CachyOS behavior and is recommended for RTX 40-series.
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
    dynamicBoost.enable = false; # requires nvidia-powerd which fails with open kernel modules
  };

  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true; # 32-bit support (Steam, Wine, etc.)

  # VA-API: CachyOS uses libva-nvidia-driver for NVDEC hardware decoding.
  # No Intel iGPU on this machine, so intel-media-driver is not needed.
  hardware.graphics.extraPackages = with pkgs; [
    nvidia-vaapi-driver # VA-API via NVDEC (matches CachyOS libva-nvidia-driver)
  ];

  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    "resume_offset=3738313"
  ];

  environment.sessionVariables = {
    # Wayland essentials
    QT_QPA_PLATFORM = "wayland";
    QT_QPA_PLATFORMTHEME = "gtk3";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
    # NVIDIA-specific: match CachyOS env for direct NVIDIA rendering
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    # VA-API via NVIDIA (use NVDEC backend, not nonexistent Intel)
    NVD_BACKEND = "direct";
    LIBVA_DRIVER_NAME = "nvidia";
  };

  environment.etc."nvidia/nvidia-application-profiles-rc.d/50-wayland-vram-fix.json".text =
    builtins.toJSON
      {
        rules = [
          {
            pattern = {
              feature = "procname";
              matches = "niri";
            };
            profile = "Limit Free Buffer Pool On Wayland Compositors";
          }
          {
            pattern = {
              feature = "procname";
              matches = ".quickshell-wra";
            };
            profile = "Limit Free Buffer Pool On Wayland Compositors";
          }
          {
            pattern = {
              feature = "procname";
              matches = "code";
            };
            profile = "Limit Free Buffer Pool On Wayland Compositors";
          }
        ];

        profiles = [
          {
            name = "Limit Free Buffer Pool On Wayland Compositors";
            settings = [
              {
                key = "GLVidHeapReuseRatio";
                value = 0;
              }
            ];
          }
        ];
      };

  # ══════════════════════════════════════════════
  # Udev rules for Acer WMI and LogiOps
  # ══════════════════════════════════════════════

  services.udev.extraRules = ''
    # Acer WMI - permissions for linuwu-sense
    ACTION=="add", SUBSYSTEM=="platform", DRIVER=="acer-wmi", RUN+="${pkgs.coreutils}/bin/chmod -R g+w /sys/devices/platform/acer-wmi/"
    ACTION=="add", SUBSYSTEM=="platform", DRIVER=="acer-wmi", RUN+="${pkgs.coreutils}/bin/chgrp -R wheel /sys/devices/platform/acer-wmi/"

    # LogiOps - uaccess for Logitech devices
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="046d", TAG+="uaccess"

    # LogiOps - restart logid when Logitech device appears
    ACTION=="add|change", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="046d", TAG+="systemd", ENV{SYSTEMD_WANTS}+="logid-restart@%k.service"
  '';

  # ══════════════════════════════════════════════
  # Predator-specific items from system.nix
  # ══════════════════════════════════════════════

  # Kernel packages
  boot.kernelPackages = pkgs.linuxPackages_6_18;

  # Critical blacklists for Acer Predator + linuwu_sense
  boot.blacklistedKernelModules = [
    "acer_wmi" # Replaced by linuwu_sense
    "processor_thermal_device_pci" # Conflicts with Acer thermal management
  ];

  # Hibernation via btrfs swapfile on @swap subvolume inside cryptroot
  swapDevices = [{ device = "/swap/swapfile"; }];
  boot.resumeDevice = "/dev/mapper/cryptroot";
  # resume_offset: included in boot.kernelParams above

  # IMPORTANT: thermald is DISABLED for Acer Predator
  # Intel thermal device is blacklisted; thermal management is via linuwu_sense
  services.thermald.enable = false;

  # Disable power-profiles-daemon (conflicts with platform_profile)
  services.power-profiles-daemon.enable = false;

  # Firmware update service (desktop-only)
  services.fwupd.enable = true;

  # ══════════════════════════════════════════════
  # HDMI audio fixes (NVIDIA-specific)
  # ══════════════════════════════════════════════
  # Fix: HDMI "Device or resource busy" — multi-part mitigation:
  # 51-hdmi-audio: enhanced HDMI audio handling with pause-on-idle
  # 52-reserve-dsp: explicit device reservation for NVIDIA HDMI audio

  services.pipewire.wireplumber.extraConfig."51-hdmi-audio" = {
    "monitor.alsa.rules" = [
      {
        matches = [
          { "device.name" = "~^(hdmi|HDMI).*"; }
          { "node.name" = "~alsa_output.*hdmi.*"; }
        ];
        actions.update-props = {
          "node.pause-on-idle" = true;
          "session.suspend-timeout-seconds" = 5;
          "api.alsa.period-size" = 1024;
          "api.alsa.headroom" = 128;
        };
      }
    ];
  };

  services.pipewire.wireplumber.extraConfig."52-reserve-dsp" = {
    "reserve.device" = [
      {
        matches = [{ "device.name" = "alsa_card.pci-0000_01_00.1"; }];
        "reserve.device" = "Audio";
        "reserve.priority" = 0;
      }
    ];
  };

  # ══════════════════════════════════════════════
  # LUKS encryption with TPM2 auto-unlock
  # ══════════════════════════════════════════════
  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.tpm2.enable = true;

  security.tpm2 = {
    enable = true;
    pkcs11.enable = true;
    tctiEnvironment.enable = true;
  };

  boot.initrd.luks.devices = {
    "cryptroot".crypttabExtraOpts = [ "tpm2-device=auto" ];
    "crypthome".crypttabExtraOpts = [ "tpm2-device=auto" ];
  };
}
