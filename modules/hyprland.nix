{ hostname, pkgs, lib, config, ... }:
let
  splitIndicator = pkgs.writeShellScript "hy3-split-indicator" ''
    window=$(${pkgs.hyprland}/bin/hyprctl activewindow -j | ${pkgs.jq}/bin/jq -r .address)
    ${pkgs.hyprland}/bin/hyprctl dispatch setprop "address:$window" active_border_color "rgb(dce6cc) rgb(dce6cc) rgb(dce6cc) rgb(dce6cc) rgb(dce6cc) rgb(dce6cc) rgb(dce6cc) rgb(dce6cc) rgb(dce6cc) rgb(e67e80) $1"
    ${pkgs.coreutils}/bin/sleep 1
    ${pkgs.hyprland}/bin/hyprctl dispatch setprop "address:$window" active_border_color "rgb(dce6cc)"
  '';
in {
  programs.hyprlock = {
    enable = true;
    package = null; # Installed system-wide so PAM authentication is configured too.
    settings = {
      background = [{
        monitor = "";
        path = "${../assets/wallpapers/stary-night-galaxy-car-everforest-dark-medium-cropped.jpg}";
        blur_passes = 0;
        contrast = 0.8916;
        brightness = 0.8916;
        vibrancy = 0.8916;
        vibrancy_darkness = 0.0;
      }];

      shape = [
        # Main translucent panel behind the lock-screen controls.
        {
          monitor = "";
          size = "550, 630";
          color = "rgba(45, 53, 59, 0.72)";
          rounding = 30;
          halign = "center";
          valign = "center";
          zindex = 0;
        }
        # Circular backdrop for the user icon.
        {
          monitor = "";
          size = "120, 120";
          color = "rgba(255, 255, 255, 0.1)";
          rounding = -1;
          border_size = 2;
          border_color = "rgba(127, 187, 179, 0.9)";
          position = "0, 190";
          halign = "center";
          valign = "center";
          zindex = 1;
        }
        # Pill-shaped backdrop behind the username row.
        {
          monitor = "";
          size = "320, 55";
          color = "rgba(255, 255, 255, 0.1)";
          rounding = -1;
          position = "0, -130";
          halign = "center";
          valign = "center";
          zindex = 1;
        }
      ];

      label = [
        # Large user icon; padding keeps its overhanging glyph from being clipped.
        {
          monitor = "";
          text = "<span>  </span>";
          color = "rgba(216, 222, 233, 0.80)";
          font_size = 48;
          font_family = "JetBrainsMono Nerd Font";
          position = "-10, 190";
          halign = "center";
          valign = "center";
          zindex = 2;
        }
        # Current time, refreshed every second.
        {
          monitor = "";
          text = ''cmd[update:1000] date +"%I:%M"'';
          color = "rgba(216, 222, 233, 0.80)";
          font_size = 60;
          font_family = "JetBrainsMono Nerd Font";
          position = "0, 40";
          halign = "center";
          valign = "center";
          zindex = 2;
        }
        # Current weekday and date, refreshed every minute.
        {
          monitor = "";
          text = ''cmd[update:60000] date +"%A, %B %d"'';
          color = "rgba(216, 222, 233, 0.80)";
          font_size = 19;
          font_family = "JetBrainsMono Nerd Font";
          position = "0, -30";
          halign = "center";
          valign = "center";
          zindex = 2;
        }
        # User icon and username inside the identity pill.
        {
          monitor = "";
          text = "$USER";
          color = "rgba(216, 222, 233, 0.80)";
          font_size = 16;
          font_family = "JetBrainsMono Nerd Font";
          position = "0, -130";
          halign = "center";
          valign = "center";
          zindex = 2;
        }
      ];

      input-field = [
        # Password entry field used to unlock the session.
        {
          monitor = "";
          size = "320, 55";
          outline_thickness = 0;
          dots_size = 0.2;
          dots_spacing = 0.2;
          dots_center = true;
          outer_color = "rgba(255, 255, 255, 0)";
          inner_color = "rgba(255, 255, 255, 0.1)";
          font_color = "rgb(200, 200, 200)";
          fade_on_empty = false;
          font_family = "JetBrainsMono Nerd Font";
          placeholder_text = ''<i><span foreground="##ffffff99">   Enter Pass</span></i>'';
          hide_input = false;
          position = "0, -208";
          halign = "center";
          valign = "center";
          zindex = 2;
        }
      ];
    };
  };

  services.hyprpaper = {
    enable = true;
    settings = {
      splash = false;
      wallpaper = [{
        monitor = "";
        path = "${../assets/wallpapers/stary-night-galaxy-car-everforest-dark-medium-cropped.jpg}";
        fit_mode = "cover";
      }];
    };
  };

  services.hypridle = {
    enable = true;
    package = null; # The NixOS Hyprlock module owns the user service.
    settings.general = {
      lock_cmd = "pidof hyprlock || hyprlock";
      before_sleep_cmd = "loginctl lock-session";
      after_sleep_cmd = "hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })'";
      inhibit_sleep = 2;
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "hyprlang";
    package = pkgs.hyprland;
    plugins = [ pkgs.hyprlandPlugins.hy3 ];
    systemd.enable = false;
    settings = {
      # Monitor configuration
      monitor = if hostname == "alakazam" then [
        "HDMI-A-1,1920x1080@75,0x180,1"          # Acer on the left
        "DP-1,2560x1440@240,1920x0,1"            # Samsung on the right
      ] else [
        "eDP-1,1920x1200@60,0x0,1"                                  # Laptop screen on the left
        "desc:Lenovo Group Limited P40w-20,5120x2160@60,1920x0,1.33"  # Lenovo P40w-20 ultrawide on the right
      ];

      # Environment variables
      env = [
        "ELECTRON_OZONE_PLATFORM_HINT,auto"
        # Allow XWayland apps (e.g. Android emulator) to receive keyboard input
        "XMODIFIERS,"
      ];

      # Startup applications
      exec-once = [
        "qs -c samox"
        "mako"
        "mkdir -p /home/samox/gdrive && rclone mount gdrive: /home/samox/gdrive --vfs-cache-mode full"
      ];

      # Odd workspaces on the primary external display, even workspaces on the
      # secondary/internal display. Disconnected workspaces fall back to the
      # remaining monitor.
      workspace = if hostname == "alakazam" then [
        "1, monitor:DP-1"
        "2, monitor:HDMI-A-1"
        "3, monitor:DP-1"
        "4, monitor:HDMI-A-1"
        "5, monitor:DP-1"
        "6, monitor:HDMI-A-1"
        "7, monitor:DP-1"
        "8, monitor:HDMI-A-1"
        "9, monitor:DP-1"
        "10, monitor:HDMI-A-1"
      ] else [
        "1, monitor:DP-3"
        "2, monitor:eDP-1"
        "3, monitor:DP-3"
        "4, monitor:eDP-1"
        "5, monitor:DP-3"
        "6, monitor:eDP-1"
        "7, monitor:DP-3"
        "8, monitor:eDP-1"
        "9, monitor:DP-3"
        "10, monitor:eDP-1"
      ];

      # Input configuration
      input = {
        kb_layout = "us";
        kb_options = "compose:caps";
        repeat_delay = 200;
        repeat_rate = 100;

        touchpad = {
          natural_scroll = true;
          scroll_factor = 1.0;
        };

        tablet = {
          output = if hostname == "alakazam" then "desc:Samsung Electric Company LC27G7xT H4ZR701769" else "desc:Lenovo Group Limited P40w-20 V90F4187";
        } // lib.optionalAttrs (hostname != "alakazam") {
          active_area_size = "224 94.5";
          active_area_position = "0 26.75";
        };
      };

      # General settings
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 1;
        "col.active_border" = "rgb(dce6cc)";
        "col.inactive_border" = "rgb(556a35)";
        layout = "hy3";
      };

      plugin.hy3.group_inset = 0;
      plugin.hy3.tabs.colors = {
        active = "rgba(a7c08040)";
        active_border = "rgba(a7c080ee)";
        active_text = "rgb(d3c6aa)";
      };

      # Stop Hyprland from upscaling XWayland apps (e.g. Android emulator);
      # they manage their own DPI.
      xwayland = {
        force_zero_scaling = true;
      };

      # Decoration
      decoration = {
        rounding = 10;
      };

      # Group bar
      group = {
        groupbar = {
          "col.active" = "rgba(556a357f)";
          "col.inactive" = "rgba(2a35187f)";
          text_color = "rgb(dce6cc)";
          gradients = true;
          keep_upper_gap = false;
          gaps_in = 0;
          gaps_out = 0;
          font_size = 11;
          height = 18;
          blur = true;
        };
      };

      # Animations (Hyprland's main feature)
      animations = {
        enabled = true;
        bezier = "myBezier, 0.37, 0, 0.63, 1.00";
        animation = [
          "windows, 1, 1, default"
          "border, 1, 2, default"
          "fade, 1, 1, default"
          "workspaces, 1, 2, default, slidefade 10%"
        ];
      };

      # Keybindings
      "$mod" = "ALT";

      bindd = [
        # Terminal
        "$mod, Return, Open terminal, exec, kitty"

        # Window management
        "$mod, Q, Close active window, hy3:killactive,"

        # Focus
        "$mod, h, Focus left, hy3:movefocus, l, visible"
        "$mod, j, Focus down, hy3:movefocus, d, visible"
        "$mod, k, Focus up, hy3:movefocus, u, visible"
        "$mod, l, Focus right, hy3:movefocus, r, visible"
        "$mod, period, Focus next monitor, focusmonitor, +1"
        "$mod, comma, Focus previous monitor, focusmonitor, -1"
        "$mod SHIFT, period, Move window to next monitor, movewindow, mon:+1"
        "$mod SHIFT, comma, Move window to previous monitor, movewindow, mon:-1"

        # Move windows
        "$mod SHIFT, h, Move window left, hy3:movewindow, l"
        "$mod SHIFT, j, Move window down, hy3:movewindow, d"
        "$mod SHIFT, k, Move window up, hy3:movewindow, u"
        "$mod SHIFT, l, Move window right, hy3:movewindow, r"
        "$mod SHIFT, Left, Move window left, hy3:movewindow, l"
        "$mod SHIFT, Down, Move window down, hy3:movewindow, d"
        "$mod SHIFT, Up, Move window up, hy3:movewindow, u"
        "$mod SHIFT, Right, Move window right, hy3:movewindow, r"

        # Move workspace between monitors
        "$mod CTRL SHIFT, l, Move workspace to right monitor, movecurrentworkspacetomonitor, r"
        "$mod CTRL SHIFT, h, Move workspace to left monitor, movecurrentworkspacetomonitor, l"

        # Launchers
        "$mod, space, Open application launcher, exec, rofi -modi combi -show combi -combi-modi drun,run -no-levenshtein-sort"

        # Shortcut help
        "$mod, slash, Show shortcut help, exec, qs -c samox ipc call shortcuts toggle"

        # Layout
        "$mod, b, Create horizontal split, hy3:makegroup, h"
        "$mod, v, Create vertical split, hy3:makegroup, v"
        "$mod, a, Focus parent container, hy3:changefocus, raise"
        "$mod, d, Focus child container, hy3:changefocus, lower"
        "$mod, r, Enter resize mode, submap, resize"
        "$mod SHIFT, f, Toggle fullscreen, fullscreen, 0"
        "$mod SHIFT, space, Toggle floating, togglefloating,"

        # Groups (tabbed containers)
        "$mod, g, Toggle tabbed group, hy3:makegroup, tab, toggle"
        "$mod, TAB, Focus next tab, hy3:focustab, r, wrap"
        "$mod SHIFT, TAB, Focus previous tab, hy3:focustab, l, wrap"
        "$mod SHIFT, g, Remove window from group, hy3:changegroup, untab"

        # Workspaces
        "$mod, 1, Switch to workspace 1, workspace, 1"
        "$mod, 2, Switch to workspace 2, workspace, 2"
        "$mod, 3, Switch to workspace 3, workspace, 3"
        "$mod, 4, Switch to workspace 4, workspace, 4"
        "$mod, 5, Switch to workspace 5, workspace, 5"
        "$mod, 6, Switch to workspace 6, workspace, 6"
        "$mod, 7, Switch to workspace 7, workspace, 7"
        "$mod, 8, Switch to workspace 8, workspace, 8"
        "$mod, 9, Switch to workspace 9, workspace, 9"
        "$mod, 0, Switch to workspace 10, workspace, 10"

        # Move to workspace
        "$mod SHIFT, 1, Move window to workspace 1, hy3:movetoworkspace, 1"
        "$mod SHIFT, 2, Move window to workspace 2, hy3:movetoworkspace, 2"
        "$mod SHIFT, 3, Move window to workspace 3, hy3:movetoworkspace, 3"
        "$mod SHIFT, 4, Move window to workspace 4, hy3:movetoworkspace, 4"
        "$mod SHIFT, 5, Move window to workspace 5, hy3:movetoworkspace, 5"
        "$mod SHIFT, 6, Move window to workspace 6, hy3:movetoworkspace, 6"
        "$mod SHIFT, 7, Move window to workspace 7, hy3:movetoworkspace, 7"
        "$mod SHIFT, 8, Move window to workspace 8, hy3:movetoworkspace, 8"
        "$mod SHIFT, 9, Move window to workspace 9, hy3:movetoworkspace, 9"
        "$mod SHIFT, 0, Move window to workspace 10, hy3:movetoworkspace, 10"

        # Config reload
        "$mod SHIFT CTRL, r, Reload Hyprland configuration, exec, hyprctl reload"

        # Applications
        "$mod, i, Open university Firefox, exec, firefox -P uni"
        "$mod SHIFT, i, Open private Firefox, exec, firefox -P private"
        "$mod, f, Pick screen color, exec, hyprpicker -a"
        "$mod, c, Copy region screenshot, exec, hyprshot -z -m region --clipboard-only"

        # Clipboard manager
        "CTRL SHIFT ALT, c, Search clipboard history, exec, nu --config /home/samox/.config/nixos/configs/nushell/config.nu -c 's clipboard pick'"

        # Lock screen
        "CTRL SHIFT, F8, Lock screen, exec, hyprlock"

        # Brightness
        ", XF86MonBrightnessUp, Increase brightness, exec, brightnessctl s +10%"
        ", XF86MonBrightnessDown, Decrease brightness, exec, brightnessctl s 10%-"

        # Media keys
        ", XF86AudioNext, Next track, exec, playerctl next"
        ", XF86AudioPrev, Previous track, exec, playerctl previous"
        "$mod, p, Toggle Spotify playback, exec, playerctl -p spotify play-pause"

        # Move all windows from current workspace to another
        "$mod SHIFT, w, Move all windows to another workspace, exec, ~/.config/hypr/move-windows.nu"
      ];

      # Secondary actions for the documented layout bindings above.
      bind = [
        "$mod, b, exec, ${splitIndicator} 0deg"
        "$mod, v, exec, ${splitIndicator} 90deg"
      ];

      # Volume control (bindl for locked screen support)
      bindld = [
        ", XF86AudioRaiseVolume, Increase volume, exec, pamixer -i 1"
        ", XF86AudioLowerVolume, Decrease volume, exec, pamixer -d 1"
      ];

      # Mouse bindings
      bindmd = [
        "$mod, mouse:272, Move window with mouse, movewindow"
        "$mod, mouse:273, Resize window with mouse, resizewindow"
      ];

    };

    extraConfig = ''
      source = ${config.home.homeDirectory}/.config/hypr/rules.conf

      submap = resize
      binded = , h, Resize left, resizeactive, -50 0
      binded = , j, Resize down, resizeactive, 0 50
      binded = , k, Resize up, resizeactive, 0 -50
      binded = , l, Resize right, resizeactive, 50 0
      binded = , left, Resize left, resizeactive, -50 0
      binded = , down, Resize down, resizeactive, 0 50
      binded = , up, Resize up, resizeactive, 0 -50
      binded = , right, Resize right, resizeactive, 50 0
      bindd = $mod, r, Exit resize mode, submap, reset
      bindd = , Return, Exit resize mode, submap, reset
      bindd = , Escape, Exit resize mode, submap, reset
      submap = reset

    '';
  };
}
