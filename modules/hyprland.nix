{ hostname, pkgs-unstable, lib, ... }: {
  wayland.windowManager.hyprland = {
    enable = true;
    package = pkgs-unstable.hyprland;
    systemd.enable = false;
    settings = {
      # Monitor configuration
      monitor = if hostname == "alakazam" then [
        "HDMI-A-1,1920x1080@75,0x180,1"          # Acer on the left
        "DP-1,2560x1440@240,1920x0,1"            # Samsung on the right
      ] else [
        "eDP-1,1920x1200@60,0x0,1"                                  # Laptop screen on the left
        "desc:Lenovo Group Limited P40w-20,5120x2160@60,1920x0,1.25"  # Lenovo P40w-20 ultrawide on the right
      ];

      # Environment variables
      env = [
        "ELECTRON_OZONE_PLATFORM_HINT,auto"
      ];

      # Startup applications
      exec-once = [
        "eww daemon"
        "waybar"
        "swaybg -i /home/samox/wallpapers/nature/mist_forest_2.png -m fill"
        "mkdir -p /home/samox/gdrive && rclone mount gdrive: /home/samox/gdrive --vfs-cache-mode full"
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
          output = "desc:Lenovo Group Limited P40w-20 V90F4187";
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
        layout = if hostname == "umbreon" then "master" else "dwindle";
      };

      # Decoration
      decoration = {
        rounding = 0;
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

      # Master layout (umbreon)
      master = {
        new_status = "slave";
        orientation = "center";
        mfact = 0.5;
      };

      # Dwindle layout (alakazam)
      dwindle = {
        preserve_split = true;
      };

      # Keybindings - using ALT (Mod1) to match your Sway config
      "$mod" = "ALT";

      bind = let
        layoutBinds = if hostname == "umbreon" then [
          "$mod, m, layoutmsg, swapwithmaster"
          "$mod, n, exec, hyprctl --batch 'dispatch layoutmsg swapwithmaster child ; dispatch layoutmsg cyclenext'"
        ] else [
          "$mod, m, layoutmsg, togglesplit"
        ];
      in [
        # Terminal
        "$mod, Return, exec, alacritty"

        # Window management
        "$mod, Q, killactive,"

        # Focus
        "$mod, h, movefocus, l"
        "$mod, j, movefocus, d"
        "$mod, k, movefocus, u"
        "$mod, l, movefocus, r"
        "$mod, period, focusmonitor, +1"
        "$mod, comma, focusmonitor, -1"
        "$mod SHIFT, period, movewindow, mon:+1"
        "$mod SHIFT, comma, movewindow, mon:-1"

        # Move windows
        "$mod SHIFT, h, movewindow, l"
        "$mod SHIFT, j, movewindow, d"
        "$mod SHIFT, k, movewindow, u"
        "$mod SHIFT, l, movewindow, r"
        "$mod SHIFT, Left, movewindow, l"
        "$mod SHIFT, Down, movewindow, d"
        "$mod SHIFT, Up, movewindow, u"
        "$mod SHIFT, Right, movewindow, r"

        # Move workspace between monitors
        "$mod CTRL SHIFT, l, movecurrentworkspacetomonitor, r"
        "$mod CTRL SHIFT, h, movecurrentworkspacetomonitor, l"

        # Launchers
        "$mod, space, exec, rofi -modi combi -show combi -combi-modi drun,run -no-levenshtein-sort"
        # Layout
        "$mod SHIFT, f, fullscreen, 0"
        "$mod SHIFT, space, togglefloating,"

        # Groups (tabbed containers)
        "$mod, g, togglegroup,"
        "$mod, TAB, changegroupactive, f"
        "$mod SHIFT, TAB, changegroupactive, b"
        "$mod SHIFT, g, moveoutofgroup,"

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
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"

        # Config reload
        "$mod SHIFT CTRL, r, exec, hyprctl reload"

        # Applications
        "$mod, i, exec, firefox -P uni"
        "$mod SHIFT, i, exec, firefox -P private"
        "$mod, e, exec, GTK_THEME=Adwaita-dark evolution"
        "$mod, f, exec, hyprpicker -a"
        "$mod, c, exec, hyprshot -m region --clipboard-only"

        # Lock screen
        "CTRL SHIFT, F8, exec, swaylock -f && systemctl suspend"

        # Brightness
        ", XF86MonBrightnessUp, exec, brightnessctl s +10%"
        ", XF86MonBrightnessDown, exec, brightnessctl s 10%-"

        # Media keys
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"
        "$mod, p, exec, playerctl -p spotify play-pause"

        # Move all windows from current workspace to another
        "$mod SHIFT, w, exec, ~/.config/hypr/move-windows.nu"
      ] ++ layoutBinds;

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
