# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, pkgs-unstable, lib, ... }:

{
  imports = [
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 3;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelModules = [ "usb-storage" ];

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Vienna";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.samox = {
    isNormalUser = true;
    description = "Samuel Recker";
    extraGroups = [ "networkmanager" "wheel" "input" "kvm" ];
    packages = with pkgs; [];
    shell = pkgs.nushell;
  };

  environment.shells = [ pkgs.nushell ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.android_sdk.accept_license = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Stable Codex defaults live at system scope so ~/.codex/config.toml remains
  # writable for project trust, plugin hook approvals, and other local state.
  environment.etc."codex/config.toml".source = (pkgs.formats.toml { }).generate "codex-config.toml" {
    model = "gpt-5.6-sol";
    model_reasoning_effort = "high";
    personality = "pragmatic";
    approval_policy = "never";
    sandbox_mode = "danger-full-access";
    approvals_reviewer = "user";

    marketplaces.ponytail = {
      source_type = "git";
      source = "https://github.com/DietrichGebert/ponytail.git";
    };
    plugins."ponytail@ponytail".enabled = true;

    mcp_servers.lsp = {
      command = "npx";
      args = [ "-y" "@theupsider/lsp-mcp@1.1.2" ];
    };
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  hardware.graphics.enable = true;

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      libGL
      wayland
      libxkbcommon
      libx11
      libxcursor
      libxi
      libxrandr
      vulkan-loader
      vulkan-validation-layers
    ];
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  programs = {
    steam = {
      enable = true;
    };
    hyprland = {
      enable = true;
      withUWSM = true;
      package = pkgs.hyprland;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
    };
    hyprlock = {
      enable = true;
      package = pkgs-unstable.hyprlock;
    };
    git = {
      enable = true;
    };
    ssh.startAgent = true;
  };

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # Allow non-bonded BT HID devices (needed for Wacom Intuos Pro)
  environment.etc."bluetooth/input.conf".text = lib.mkForce ''
    [General]
    ClassicBondedOnly=false
  '';

  # Audio via PipeWire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;  # exposes PulseAudio socket so Audacity sees "PulseAudio" host
    jack.enable = true;
  };

  # List services that you want to enable:

  services.tlp = {
    enable = true;
    settings = {
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80;
      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      PLATFORM_PROFILE_ON_AC = "balanced";
      PLATFORM_PROFILE_ON_BAT = "low-power";
      WIFI_PWR_ON_BAT = "on";
      CPU_BOOST_ON_BAT = 0;
    };
  };

  services.hypridle.package = pkgs-unstable.hypridle;

  services.upower.enable = true;
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd 'uwsm start -F -e -D Hyprland -- start-hyprland'";
	user = "greeter";
      };
    };
  };

  fonts.fontDir.enable = true;

  services.udev.packages = [ pkgs.libwacom ];
  services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="input", MODE="0660"
  '';

  services.input-remapper.enable = true;

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id === "org.freedesktop.policykit.exec") {
        var program = action.lookup("program");
        if ((program === "${config.services.input-remapper.package}/bin/input-remapper-control" ||
             program === "/run/current-system/sw/bin/input-remapper-control") &&
            subject.isInGroup("input")) {
          return polkit.Result.YES;
        }
      }
    });
  '';

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
