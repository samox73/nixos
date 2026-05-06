{ hostname, ... }: {
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      # Monitor configuration
      monitor = if hostname == "nexus" then [
        "HDMI-A-1,1920x1080@75,0x180,1"          # Acer on the left
        "DP-1,2560x1440@240,1920x0,1"            # Samsung on the right
      ] else [
        "desc:Lenovo Group Limited P40w-20,5120x2160@60,0x0,1.25"  # Lenovo P40w-20 ultrawide
        "eDP-1,1920x1200@60,4096x0,1"                            # Laptop screen to the right
      ];

      # Environment variables
      env = [
        "ELECTRON_OZONE_PLATFORM_HINT,auto"
      ];

      # Startup applications
      exec-once = [
        "waybar"
        "swaybg -i /home/samox/wallpapers/nature/mist_forest_2.png -m fill"
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
        kb_layout = "us,de";
        kb_options = "grp:caps_toggle";
        repeat_delay = 200;
        repeat_rate = 100;

        touchpad = {
          natural_scroll = true;
          scroll_factor = 1.0;
        };

        tablet = {
          output = "desc:Lenovo Group Limited P40w-20 V90F4187";
        };
      };

      # General settings
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 1;
        "col.active_border" = "rgb(dce6cc)";
        "col.inactive_border" = "rgb(556a35)";
        layout = "master";
      };

      # Decoration
      decoration = {
        rounding = 0;
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

      # Master layout
      master = {
        new_status = "slave";
        orientation = "center";
        mfact = 0.5;
      };

      # Window rules
      windowrulev2 = [
        "bordercolor rgb(dce6cc),focus:1"
        "bordercolor rgb(556a35),focus:0"
      ];

      # Keybindings - using ALT (Mod1) to match your Sway config
      "$mod" = "ALT";

      bind = [
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
        "$mod CTRL SHIFT, Right, movecurrentworkspacetomonitor, r"
        "$mod CTRL SHIFT, Left, movecurrentworkspacetomonitor, l"

        # Launchers
        "$mod, space, exec, rofi -modi combi -show combi -combi-modi drun,run -no-levenshtein-sort"

        # Layout
        "$mod, m, layoutmsg, focusmaster"
        "$mod SHIFT, m, layoutmsg, swapwithmaster"
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
        "CTRL SHIFT, F8, exec, swaylock"

        # Brightness
        ", XF86MonBrightnessUp, exec, brightnessctl s +10%"
        ", XF86MonBrightnessDown, exec, brightnessctl s 10%-"

        # Media keys
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"
        "$mod, p, exec, playerctl -p spotify play-pause"
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
  };
}
