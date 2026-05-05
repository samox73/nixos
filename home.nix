{ pkgs, ags, astal, pkgs-unstable, hostname, ... }: {
  imports = [ ags.homeManagerModules.default ];

  home.stateVersion = "25.11";

  programs = {
    alacritty = {
      enable = true;
      settings = {
        window = {
          padding = {
            x = 10;
          };
        };
        font = {
          normal = {
            family = "JetBrainsMonoNL Nerd Font Mono";
          };
          size = 11.0;
        };
        colors = {
          primary = {
            background = "#2d353b";
            foreground = "#d3c6aa";
          };
          normal = {
            black = "#475258";
            red = "#e67e80";
            green = "#a7c080";
            yellow = "#dbbc7f";
            blue = "#7fbbb3";
            magenta = "#d699b6";
            cyan = "#83c092";
            white = "#d3c6aa";
          };
          bright = {
            black = "#475258";
            red = "#e67e80";
            green = "#a7c080";
            yellow = "#dbbc7f";
            blue = "#7fbbb3";
            magenta = "#d699b6";
            cyan = "#83c092";
            white = "#d3c6aa";
          };
        };
      };
    };

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
        credential.helper = "!${pkgs.gh}/bin/gh auth git-credential";
        init.defaultBranch = "main";
      };
    };

    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };

    yazi = {
      enable = true;
      settings = {
        preview = {
          image_filter = "lanczos3";
          image_quality = 90;
          tab_size = 1;
          max_width = 600;
          max_height = 900;
          cache_dir = "";
          ueberzug_scale = 1;
          ueberzug_offset = [
            0
            0
            0
            0
          ];
        };
      };
    };

    zoxide.enable = true;
    nushell = {
      enable = true;
      configFile.source = ./config.nu;
      envFile.source = ./env.nu;
    };

    ags = {
      enable = true;
      configDir = null;  # already exists at ~/.config/ags
      extraPackages = with astal.packages.${pkgs.system}; [
        hyprland
        battery
        wireplumber
        network
      ];
    };
  };

  home.packages = with pkgs; [
    pkgs-unstable.claude-code
    firefox
    spotify
    whatsapp-electron
    grim
    gh
    rofi
    swayidle
    swaylock
    zathura
    slurp
    hyprshot
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
    pavucontrol           # for waybar pulseaudio right-click
    ueberzugpp            # for image previews in yazi file browser
    sway-contrib.grimshot # for easier screenshots in wayland
    wl-color-picker
    hyprpicker
    obs-studio
    slack
    everforest-gtk-theme
    everforest-cursors
    nautilus              # GTK file manager

    # Screensharing dependencies
    pipewire
    wireplumber

    # Neovim dependencies
    ripgrep      # for telescope live_grep
    fd           # for telescope find_files
    gcc          # for treesitter compilation
    tree-sitter  # treesitter CLI
    nodejs       # for some LSP servers
    curl         # for mason package downloads
    wget         # for mason package downloads
    unzip        # for mason package extraction
    gzip         # for mason package extraction
    texpresso    # live rendering latex

    # Go development
    go
    gopls        # Go LSP server
    delve        # Go debugger
    gotools      # goimports, etc.

    # Python development
    python3
    python3Packages.pip
    python3Packages.virtualenv
    pyright      # Python LSP server

    # Rust development
    rustc
    cargo
    rust-analyzer  # Rust LSP server
    rustfmt        # Rust formatter
    clippy         # Rust linter

    # C++ development tools
    cmake        # build system
    gnumake      # make command
    pkg-config   # for finding libraries
    clang-tools  # clangd LSP, clang-format, clang-tidy
    gdb          # debugger

    # OpenGL/Graphics libraries
    libGL        # OpenGL library
    libGLU       # OpenGL utility library
    freeglut     # GLUT library
    glew         # GLEW library
    opencv       # OpenCV library
    xorg.libX11  # X11 library
    xorg.libXi   # X11 input extension
    xorg.libXmu  # X11 miscellaneous utilities

    font-awesome  # for waybar icons
    nerd-fonts.commit-mono
    nerd-fonts.symbols-only
    nerd-fonts.jetbrains-mono
  ];

  fonts.fontconfig = {
    enable = true;
    antialiasing = true;
  };

  xdg.configFile."rofi/config.rasi".text = ''
    configuration {
     timeout {
      action: "kb-cancel";
      delay: 15;
     }
    }
    @theme "hack"
  '';

  xdg.configFile."rofi/themes/colors.rasi".text = ''
    * {
      al: #00000000;
      bg: #2D353BFF;
      sfg: #000000ff;
      sbg: #89818326;
      fg: #d3c6aaff;
    }
  '';

  xdg.configFile."rofi/themes/hack.rasi".text = ''
    @import "colors.rasi"

    configuration {
     font: "Iosevka Nerd Font 10";
     show-icons: true;
     icon-theme: "Numix";
     display-drun: "";
     drun-display-format: "{name}";
     disable-history: false;
     fullscreen: false;
     hide-scrollbar: true;
     sidebar-mode: false;
    }

    window {
     transparency: "real";
     background-color: @bg;
     text-color: @fg;
     border: 2px;
     border-color: @fg;
     border-radius: 0px;
     width: 800px;
     height: 430px;
     location: center;
     x-offset: 0;
     y-offset: 0;
    }

    prompt {
     enabled: true;
     padding: 10px;
     background-color: @al;
     text-color: @fg;
     font: "Iosevka Nerd Font 10";
    }

    entry {
     background-color: @al;
     text-color: @fg;
     placeholder-color: @fg;
     expand: true;
     horizontal-align: 0;
     placeholder: "Search...";
     padding: 10px 10px 10px 0px;
     border-radius: 0px;
     blink: true;
    }

    inputbar {
     children: [ prompt, entry ];
     background-color: @al;
     text-color: @fg;
     expand: false;
     border: 0px 0px 1px 0px;
     border-radius: 0px;
     border-color: @fg;
     spacing: 0px;
    }

    listview {
     background-color: @al;
     padding: 0px;
     columns: 1;
     lines: 5;
     spacing: 5px;
     cycle: true;
     dynamic: true;
     layout: vertical;
    }

    mainbox {
     background-color: @al;
     border: 0px;
     border-radius: 0px;
     border-color: @fg;
     children: [ inputbar, listview ];
     spacing: 10px;
     padding: 2px 10px 10px 10px;
    }

    element {
     background-color: @al;
     text-color: @fg;
     orientation: horizontal;
     border-radius: 0px;
     padding: 8px;
    }

    element-icon {
     size: 24px;
     border: 0px;
     background-color: @al;
    }

    element-text {
     expand: true;
     horizontal-align: 0;
     vertical-align: 0.5;
     text-color: @fg;
     background-color: @al;
     margin: 0px 2.5px 0px 2.5px;
    }

    element selected {
     background-color: @sbg;
     text-color: @sfg;
     border: 1px;
     border-radius: 0px;
     border-color: @fg;
    }
  '';

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
          bg = "/home/samox/wallpapers/everforest_walls/nature/mist_forest_2.png fill";
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

      # Startup applications
      exec-once = [
        "waybar"
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
        "$mod SHIFT, m, layoutmsg, swapwithmaster, auto"
        "$mod SHIFT, f, fullscreen, 0"
        "$mod SHIFT, space, togglefloating,"

        # Groups (tabbed containers)
        "$mod, g, togglegroup,"
        "$mod, TAB, changegroupactive, f"
        "$mod SHIFT, TAB, changegroupactive, b"
        "$mod SHIFT, g, moveoutofgroup,"

        # Scratchpad (special workspace in Hyprland)
        "$mod SHIFT, p, movetoworkspace, special"
        "$mod, p, togglespecialworkspace,"

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
        "$mod, c, exec, grim -g \"$(slurp -p)\" -t ppm - | convert - -format '%[pixel:p{0,0}]' txt:- | tail -n 1 | cut -d ' ' -f 4 | tr -d '\\n' | wl-copy"

        # Lock screen
        "CTRL SHIFT, F8, exec, swaylock"

        # Brightness
        ", XF86MonBrightnessUp, exec, brightnessctl s +10%"
        ", XF86MonBrightnessDown, exec, brightnessctl s 10%-"

        # Media keys
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"
        "SUPER, p, exec, dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause"
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
          format = " {usage}%";
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

  gtk = {
    enable = true;

    iconTheme = {
      name = "everforest-cursors";
      package = pkgs.everforest-cursors;
    };

    theme = {
      name = "Everforest-Dark-Medium";
      package = pkgs.everforest-gtk-theme;
    };

    cursorTheme = {
      name = "everforest-cursors";
      package = pkgs.everforest-cursors;
    };

    gtk3.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };

    gtk4.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };
  };

  home.sessionVariables.GTK_THEME = "Everforest-Dark-Medium";
}
