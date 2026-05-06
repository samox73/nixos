{ ... }: {
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        height = 25;
        layer = "top";
        position = "top";
        modules-left = [ "cpu" "temperature" "memory" "battery" "disk" "pulseaudio" ];
        modules-center = [ "hyprland/workspaces" ];
        modules-right = [ "custom/weather" "network" "clock" ];

        "hyprland/workspaces" = {
          format = "{id}";
          on-click = "activate";
          sort-by-number = true;
        };

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
          format-icons = [ "󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
        };

        clock = {
          format = "{:%a %b %d %H:%M:%S}";
          tooltip = false;
          max-length = 25;
          interval = 1;
        };

        network = {
          format-wifi = "󰖩 {essid} {ipaddr}";
          format-ethernet = "󰈀 {ipaddr}";
          format-linked = "󰈀 {ifname}";
          format-disconnected = "󰖪 Disconnected";
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
            headphone = "󰋋";
            headset = "󰋎";
            default = [ "󰕿" "󰖀" "󰕾" ];
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
            default = [ "󱃃" "󰔏" "󱃂" "󰸁" "󰔐" ];
          };
        };

        memory = {
          tooltip = false;
          format = "󰍛 {percentage}%";
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
          format = "󰋊 {percentage_used}%";
          states = {
            critical = 90;
          };
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
        font-family: "JetBrainsMonoNL Nerd Font Mono";
        font-size: 13px;
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

      #workspaces button.active {
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

    '';
  };
}
