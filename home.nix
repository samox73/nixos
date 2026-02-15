{ pkgs, ... }: {
  home.stateVersion = "25.11";

  programs = {
    git = {
      enable = true;
      settings = {
        user = {
	  name = "Samuel Recker";
	  email = "samuel.recker@gmail.com";
	};
        alias = {
          s = "status";
        };
      };
    };

    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };
  };

  home.packages = with pkgs; [
    alacritty
    claude-code
    firefox
    grim
    rofi
    swayidle
    swaylock
    zathura
    slurp
    wl-clipboard
    clipman
    dunst
    kanshi
    pamixer
    playerctl
    brightnessctl
    imagemagick
    mcp-nixos
    texliveFull
    pavucontrol  # for waybar pulseaudio right-click

    # Neovim dependencies
    ripgrep      # for telescope live_grep
    fd           # for telescope find_files
    gcc          # for treesitter compilation
    nodejs       # for some LSP servers
    curl         # for mason package downloads
    wget         # for mason package downloads
    unzip        # for mason package extraction
    gzip         # for mason package extraction
  ];

  wayland.windowManager.sway = {
    enable = true;
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
          border = "#dce6cc";
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
          border = "#A7C080";
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
        "${mod}+i" = "exec firefox -P work";
        "${mod}+Shift+i" = "exec firefox -P private";
        "${mod}+e" = "exec GTK_THEME=Adwaita-dark evolution";
        "${mod}+f" = "exec grimshot copy area";
        "${mod}+c" = "exec grim -g \"$(slurp -p)\" -t ppm - | convert - -format '%[pixel:p{0,0}]' txt:- | tail -n 1 | cut -d ' ' -f 4 | tr -d '\\n' | wl-copy";

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
          # bg = "~/work/repos/everforest-walls/nature/polyscape_2.png fill";
        };
      };
    };

    # extraConfig = ''
    #   exec systemctl --user set-environment XDG_CURRENT_DESKTOP=sway
    #   exec systemctl --user import-environment DISPLAY SWAYSOCK WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP

    #   exec hash dbus-update-activation-environment 2>/dev/null && \
    #     dbus-update-activation-environment --systemd DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP=sway WAYLAND_DISPLAY XDG_SESSION_DESKTOP

    #   exec_always wl-paste -t text --watch clipman store
    #   exec_always dunst
    #   exec_always pkill kanshi; kanshi
    # '';
  };

  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        height = 25;
        layer = "top";
        position = "top";
        modules-left = [ "cpu" "temperature" "memory" "battery" "disk" "pulseaudio" ];
        modules-center = [ "sway/mode" "sway/workspaces" "sway/mode" ];
        modules-right = [ "custom/weather" "network" "clock" ];

        "sway/window" = {};

        "custom/weather" = {
          tooltip = false;
          min-length = 5;
          exec = "curl 'https://wttr.in/Vienna?m&format='%l:+%t''";
          interval = 3600;
        };

        battery = {
          min-length = 5;
          states = {
            full = 90;
            warning = 30;
            critical = 15;
          };
          tooltip = false;
          full-at = 95;
          format-plugged = "{icon} {capacity}%";
          format-charging = "{icon} {capacity}%";
          format = "{icon} {capacity}%";
          format-icons = [ "" "" "" "" "" "" "" "" "" "" ];
        };

        clock = {
          format = " {:%a %b %d %H:%M:%S}";
          tooltip = false;
          max-length = 25;
          interval = 1;
        };

        network = {
          format-wifi = " {essid} {ipaddr}";
          format-ethernet = " {ipaddr}";
          format-linked = " {ifname}";
          format-disconnected = " Disconnected";
          tooltip = false;
          max-length = 30;
        };

        pulseaudio = {
          tooltip = false;
          min-length = 5;
          format = "{icon} {volume}%";
          format-bluetooth = "{icon} {volume}%";
          format-muted = "MUTE";
          format-icons = {
            headphone = "";
            headset = "";
            default = [ "" "" "" ];
          };
          on-click = "pamixer -t";
          on-click-right = "pavucontrol";
        };

        cpu = {
          interval = 4;
          min-length = 6;
          format = " {usage}%";
          tooltip = false;
          states = {
            critical = 90;
          };
        };

        temperature = {
          tooltip = false;
          min-length = 6;
          critical-threshold = 90;
          format = "{icon} {temperatureC}°C";
          format-critical = "{icon} {temperatureC}°C";
          format-icons = {
            default = [ "" "" "" "" "" ];
          };
        };

        memory = {
          tooltip = false;
          format = " {percentage}%";
          states = {
            critical = 90;
          };
          min-length = 5;
        };

        disk = {
          tooltip = false;
          path = "/";
          interval = 60;
          min-length = 5;
          format = " {percentage_used}%";
          states = {
            critical = 90;
          };
        };

        "sway/workspaces" = {
          tooltip = false;
          disable-scroll = true;
        };

        "sway/mode" = {
          format = "{}";
        };
      };
    };

    style = ''
      /* waybar style.css */
      @define-color bgcolor #2D353B; /* background color */
      @define-color bgcolor2 #B89069; /* background color */
      @define-color fgcolor #D3C6AA; /* foreground color */
      @define-color fgcolor2 #ffaec5; /* foreground color */
      @define-color charging #1F5748; /* battery charging color */
      @define-color plugged #acfcad; /* ac plugged color */
      @define-color critical #ffff00; /* critical color */
      @define-color warning #e6b493; /* warning color */
      @define-color hover #bc6981; /* mouse hover over workspace color */
      @define-color bordercolor #A7C080; /* mouse hover over workspace color */

      /* Reset all styles */
      * {
        border: none;
        border-radius: 0;
        min-height: 0;
        margin: 0;
        padding: 0;
      }

      #waybar {
        color: @fgcolor;
        background: transparent;
        font-family: JetBrainsMono;
        font-size: 12px;
        border-bottom: 1px solid @bordercolor;
        background-color: @bgcolor;
      }

      #workspaces button {
        padding-left: 10px;
        padding-right: 10px;
        color: @fgcolor;
        background: @bgcolor;
      }

      #workspaces button:hover {
        background: @hover;
        color: @fgcolor;
        transition: none;
        box-shadow: inherit;
        text-shadow: inherit;
      }

      #workspaces button.focused {
        color: @fgcolor2;
        background: @bgcolor;
      }

      #custom-cap-left, #custom-cap-right {
        color: @bgcolor;
        font-size: 24px;
      }

      #idle_inhibitor {
        background: @bgcolor;
        padding-left: 20px;
        padding-right: 10px;
      }

      #custom-offswitch {
        background: @bgcolor;
        padding-right: 20px;
        padding-left: 10px;
      }

      #custom-weather,
      #cpu,
      #temperature,
      #memory,
      #pulseaudio,
      #disk,
      #battery,
      #clock,
      #network {
        border-bottom: 1px solid @bordercolor;
        color: @fgcolor;
        background: @bgcolor;
        padding-left: 10px;
        padding-right: 10px;
      }

      #workspaces {
        border-bottom: 1px solid @bordercolor;
      }

      #disk.critical {
        color: @critical;
      }

      #temperature.critical {
        color: @critical;
      }

      #cpu.critical {
        color: @critical;
      }

      #memory.critical {
        color: @critical;
      }

      @keyframes blink1 {
        to {
          color: @plugged;
        }
      }

      #battery.plugged {
        background-color: @bgcolor;
        animation-name: blink1;
        animation-duration: 0.5s;
        animation-timing-function: linear;
        animation-iteration-count: infinite;
        animation-direction: alternate;
      }

      @keyframes blink2 {
        to {
          background-color: @charging;
        }
      }

      #battery.charging {
        animation-name: blink2;
        animation-duration: 2.0s;
        animation-timing-function: ease-in-out;
        animation-iteration-count: infinite;
        animation-direction: alternate;
      }

      @keyframes blink3 {
        to {
          background-color: @warning;
        }
      }

      #battery.warning:not(.charging) {
        /* background-color: @bgcolor; */
        animation-name: blink3;
        animation-duration: 0.7s;
        animation-timing-function: ease-in-out;
        animation-iteration-count: infinite;
        animation-direction: alternate;
      }

      @keyframes blink4 {
        to {
          background-color: @critical;
        }
      }

      #battery.critical:not(.charging) {
        /* background-color: @bgcolor; */
        animation-name: blink4;
        animation-duration: 0.8s;
        animation-timing-function: ease-in-out;
        animation-iteration-count: infinite;
        animation-direction: alternate;
      }

      #mode {
        background-color: #FF0000;
        margin: 2px;
        padding: 0px 100px;
        color: white;
        font-variant: small-caps;
        font-size: 15pt;
      }
    '';
  };
}
