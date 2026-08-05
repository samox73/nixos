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
        path = "/home/samox/wallpapers/stary-night-galaxy-car-everforest-dark-medium-cropped.jpg";
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
        path = "/home/samox/wallpapers/stary-night-galaxy-car-everforest-dark-medium-cropped.jpg";
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
        "eww daemon"
        "qs -c samox"
        "mako"
        "mkdir -p /home/samox/gdrive && rclone mount gdrive: /home/samox/gdrive --vfs-cache-mode full"
        "wl-paste --type text/plain --watch clipman store"
      ];

      # Workspace to monitor bindings
      # Odd workspaces on Samsung (DP-1), even on Acer (HDMI-A-1)
      workspace = [
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

      # Keybindings - using ALT (Mod1) to match your Sway config
      "$mod" = "ALT";

      bind = [
        # Terminal
        "$mod, Return, exec, kitty"

        # Window management
        "$mod, Q, hy3:killactive,"

        # Focus
        "$mod, h, hy3:movefocus, l"
        "$mod, j, hy3:movefocus, d"
        "$mod, k, hy3:movefocus, u"
        "$mod, l, hy3:movefocus, r"
        "$mod, period, focusmonitor, +1"
        "$mod, comma, focusmonitor, -1"
        "$mod SHIFT, period, movewindow, mon:+1"
        "$mod SHIFT, comma, movewindow, mon:-1"

        # Move windows
        "$mod SHIFT, h, hy3:movewindow, l"
        "$mod SHIFT, j, hy3:movewindow, d"
        "$mod SHIFT, k, hy3:movewindow, u"
        "$mod SHIFT, l, hy3:movewindow, r"
        "$mod SHIFT, Left, hy3:movewindow, l"
        "$mod SHIFT, Down, hy3:movewindow, d"
        "$mod SHIFT, Up, hy3:movewindow, u"
        "$mod SHIFT, Right, hy3:movewindow, r"

        # Move workspace between monitors
        "$mod CTRL SHIFT, l, movecurrentworkspacetomonitor, r"
        "$mod CTRL SHIFT, h, movecurrentworkspacetomonitor, l"

        # Launchers
        "$mod, space, exec, rofi -modi combi -show combi -combi-modi drun,run -no-levenshtein-sort"
        # Layout
        "$mod, b, hy3:makegroup, h"
        "$mod, b, exec, ${splitIndicator} 0deg"
        "$mod, v, hy3:makegroup, v"
        "$mod, v, exec, ${splitIndicator} 90deg"
        "$mod, a, hy3:changefocus, raise"
        "$mod, d, hy3:changefocus, lower"
        "$mod, r, submap, resize"
        "$mod SHIFT, f, fullscreen, 0"
        "$mod SHIFT, space, togglefloating,"

        # Groups (tabbed containers)
        "$mod, g, hy3:makegroup, tab, toggle"
        "$mod, TAB, hy3:focustab, r, wrap"
        "$mod SHIFT, TAB, hy3:focustab, l, wrap"
        "$mod SHIFT, g, hy3:changegroup, untab"

        # Workspaces
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"

        # Move to workspace
        "$mod SHIFT, 1, hy3:movetoworkspace, 1"
        "$mod SHIFT, 2, hy3:movetoworkspace, 2"
        "$mod SHIFT, 3, hy3:movetoworkspace, 3"
        "$mod SHIFT, 4, hy3:movetoworkspace, 4"
        "$mod SHIFT, 5, hy3:movetoworkspace, 5"
        "$mod SHIFT, 6, hy3:movetoworkspace, 6"
        "$mod SHIFT, 7, hy3:movetoworkspace, 7"
        "$mod SHIFT, 8, hy3:movetoworkspace, 8"
        "$mod SHIFT, 9, hy3:movetoworkspace, 9"
        "$mod SHIFT, 0, hy3:movetoworkspace, 10"

        # Clipboard history
        "$mod CTRL SHIFT, c, exec, clipman pick -t rofi"

        # Config reload
        "$mod SHIFT CTRL, r, exec, hyprctl reload"

        # Applications
        "$mod, i, exec, firefox -P uni"
        "$mod SHIFT, i, exec, firefox -P private"
        "$mod, e, exec, GTK_THEME=Adwaita-dark evolution"
        "$mod, f, exec, hyprpicker -a"
        "$mod, c, exec, hyprshot -m region --clipboard-only"

        # Clipboard manager
        "CTRL SHIFT ALT, c, exec, clipman pick -t rofi --tool-args='-i'"

        # Lock screen
        "CTRL SHIFT, F8, exec, hyprlock"

        # Brightness
        ", XF86MonBrightnessUp, exec, brightnessctl s +10%"
        ", XF86MonBrightnessDown, exec, brightnessctl s 10%-"

        # Media keys
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"
        "$mod, p, exec, playerctl -p spotify play-pause"

        # Move all windows from current workspace to another
        "$mod SHIFT, w, exec, ~/.config/hypr/move-windows.nu"
      ];

      # Volume control (bindl for locked screen support)
      bindl = [
        ", XF86AudioRaiseVolume, exec, pamixer -i 1"
        ", XF86AudioLowerVolume, exec, pamixer -d 1"
      ];

      # Mouse bindings
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

    };

    extraConfig = ''
      source = ${config.home.homeDirectory}/.config/hypr/rules.conf

      submap = resize
      binde = , h, resizeactive, -50 0
      binde = , j, resizeactive, 0 50
      binde = , k, resizeactive, 0 -50
      binde = , l, resizeactive, 50 0
      binde = , left, resizeactive, -50 0
      binde = , down, resizeactive, 0 50
      binde = , up, resizeactive, 0 -50
      binde = , right, resizeactive, 50 0
      bind = $mod, r, submap, reset
      bind = , Return, submap, reset
      bind = , Escape, submap, reset
      submap = reset

      $close_hints = eww close submap-hints

      bind = ALT, s, exec, eww update submap_name='Sioyek' submap_keys='[{"key":"b","desc":"Open bookmark"},{"key":"B","desc":"Open bookmark (new window)"},{"key":"u","desc":"Update bookmark position"},{"key":"d","desc":"Delete bookmark"}]' && eww open submap-hints --screen "$(hyprctl monitors -j | jq '.[] | select(.focused==true) | .id')"
      bind = ALT, s, submap, sioyek

      submap = sioyek
      bind = , b, exec, $close_hints; ~/.config/sioyek/open-bookmark.nu
      bind = , b, submap, reset
      bind = SHIFT, b, exec, $close_hints; ~/.config/sioyek/open-bookmark.nu --new-window
      bind = SHIFT, b, submap, reset
      bind = , u, exec, $close_hints; ~/.config/sioyek/update-bookmark.nu
      bind = , u, submap, reset
      bind = , d, exec, $close_hints; ~/.config/sioyek/delete-bookmark.nu
      bind = , d, submap, reset
      bind = , Escape, exec, $close_hints
      bind = , Escape, submap, reset
      submap = reset
    '';
  };
}
