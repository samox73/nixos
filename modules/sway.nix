{ ... }: {
  wayland.windowManager.sway = {
    enable = true;
    checkConfig = false;
    config = let
      mod = "Mod1";
      left = "h";
      down = "j";
      up = "k";
      right = "l";
    in {
      modifier = mod;
      terminal = "alacritty";
      bars = []; # we exec waybar manually
      floating.modifier = mod;
      defaultWorkspace = "workspace 1";

      window = {
        border = 1;
        commands = [
          {
            criteria = { class = ".*"; };
            command = "border pixel 1";
          }
        ];
      };

      gaps = {
        inner = 10;
      };

      colors = {
        focused = {
          border = "#A7C080";
          background = "#dce6cc";
          text = "#fdf6e3";
          indicator = "#dce6cc";
          childBorder = "#dce6cc";
        };
        focusedInactive = {
          border = "#A7C080";
          background = "#A7C080";
          text = "#eee8d5";
          indicator = "#A7C080";
          childBorder = "#A7C080";
        };
        unfocused = {
          border = "#556a35";
          background = "#073642";
          text = "#93a1a1";
          indicator = "#A7C080";
          childBorder = "#A7C080";
        };
        urgent = {
          border = "#d33682";
          background = "#d33682";
          text = "#fdf6e3";
          indicator = "#dc322f";
          childBorder = "#dc322f";
        };
      };

      startup = [
        { command = "waybar"; }
        { command = "swayidle"; }
      ];

      modes = {
        resize = {
          "${left}" = "resize shrink width 5 ppt";
          "${down}" = "resize grow height 5 ppt";
          "${up}" = "resize shrink height 5 ppt";
          "${right}" = "resize grow width 5 ppt";
          "Left" = "resize shrink width 5 ppt";
          "Down" = "resize grow height 5 ppt";
          "Up" = "resize shrink height 5 ppt";
          "Right" = "resize grow width 5 ppt";
          "${mod}+r" = "mode default";
          "Return" = "mode default";
          "Escape" = "mode default";
        };
      };

      keybindings = {
        # Terminal
        "${mod}+Return" = "exec alacritty";

        # Window management
        "${mod}+q" = "kill";

        # Focus
        "${mod}+${left}" = "focus left";
        "${mod}+${down}" = "focus down";
        "${mod}+${up}" = "focus up";
        "${mod}+${right}" = "focus right";

        # Move
        "${mod}+Shift+${left}" = "move left";
        "${mod}+Shift+${down}" = "move down";
        "${mod}+Shift+${up}" = "move up";
        "${mod}+Shift+${right}" = "move right";
        "${mod}+Shift+Left" = "move left";
        "${mod}+Shift+Down" = "move down";
        "${mod}+Shift+Up" = "move up";
        "${mod}+Shift+Right" = "move right";

        # Move workspace between monitors
        "${mod}+Control+Shift+Right" = "move workspace to output right";
        "${mod}+Control+Shift+Left" = "move workspace to output left";

        # Launchers
        "${mod}+space" = "exec --no-startup-id rofi -modi combi -show combi -combi-modi drun,run -no-levenshtein-sort";
        "ctrl+shift+x" = "exec sway-switch-workspace";
        "${mod}+ctrl+shift+x" = "exec sway-move-to-workspace";
        "${mod}+Ctrl+Shift+C" = "exec clipman pick -t rofi";

        # Layout
        "${mod}+b" = "split h";
        "${mod}+v" = "split v";
        "${mod}+Shift+f" = "fullscreen toggle";
        "${mod}+Shift+space" = "floating toggle";

        # Focus control
        "${mod}+a" = "focus parent";
        "${mod}+d" = "focus child";

        # Scratchpad
        "${mod}+Shift+p" = "move scratchpad";
        "${mod}+p" = "scratchpad show";

        # Workspaces
        "${mod}+1" = "workspace 1";
        "${mod}+2" = "workspace 2";
        "${mod}+3" = "workspace 3";
        "${mod}+4" = "workspace 4";
        "${mod}+5" = "workspace 5";
        "${mod}+6" = "workspace 6";
        "${mod}+7" = "workspace 7";
        "${mod}+8" = "workspace 8";
        "${mod}+9" = "workspace 9";
        "${mod}+0" = "workspace 10";

        # Move to workspace
        "${mod}+Shift+1" = "move container to workspace 1";
        "${mod}+Shift+2" = "move container to workspace 2";
        "${mod}+Shift+3" = "move container to workspace 3";
        "${mod}+Shift+4" = "move container to workspace 4";
        "${mod}+Shift+5" = "move container to workspace 5";
        "${mod}+Shift+6" = "move container to workspace 6";
        "${mod}+Shift+7" = "move container to workspace 7";
        "${mod}+Shift+8" = "move container to workspace 8";
        "${mod}+Shift+9" = "move container to workspace 9";
        "${mod}+Shift+0" = "move container to workspace 10";

        # Config
        "${mod}+Shift+Ctrl+r" = "reload";
        "${mod}+r" = "mode resize";

        # Applications
        "${mod}+i" = "exec firefox -P private";
        "${mod}+Shift+i" = "exec firefox -P private";
        "${mod}+e" = "exec GTK_THEME=Adwaita-dark evolution";
        "${mod}+f" = "exec grimshot copy area";
        "${mod}+c" = "exec hyprshot -m region --clipboard-only";

        # Media keys
        "XF86AudioRaiseVolume" = "exec pamixer -i 1";
        "XF86AudioLowerVolume" = "exec pamixer -d 1";
        "Mod4+p" = "exec dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause";
        "XF86AudioNext" = "exec playerctl next";
        "XF86AudioPrev" = "exec playerctl previous";

        # Brightness
        "XF86MonBrightnessUp" = "exec brightnessctl s +10%";
        "XF86MonBrightnessDown" = "exec brightnessctl s 10%-";

        # Lock screen
        "Ctrl+Shift+F8" = "exec swaylock";
      };

      input = {
        "type:keyboard" = {
          repeat_delay = "200";
          repeat_rate = "100";
          xkb_layout = "us,de";
          xkb_options = "grp:caps_toggle";
        };
        "type:touchpad" = {
          tap = "enabled";
          natural_scroll = "enabled";
          pointer_accel = "0.5";
          scroll_factor = "1";
        };
        "type:pointer" = {
          scroll_factor = "1";
        };
      };

      output = {
        "*" = {
          bg = "/home/samox/wallpapers/nature/mist_forest_2.png fill";
        };
      };
    };
  };
}
