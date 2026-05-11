{ pkgs, ags, astal, pkgs-unstable, hostname, ... }: {
  imports = [
    ags.homeManagerModules.default
    ./modules/alacritty.nix
    ./modules/git.nix
    ./modules/neovim.nix
    ./modules/yazi.nix
    ./modules/nushell.nix
    ./modules/hyprland.nix
    ./modules/rofi.nix
    ./modules/sway.nix
    ./modules/waybar.nix
  ];

  home.stateVersion = "25.11";

  home.pointerCursor = {
    name = "everforest-cursors";
    package = pkgs.everforest-cursors;
    size = 24;
    gtk.enable = true;
  };

  programs = {
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
    thunderbird
    (spotify.overrideAttrs (old: {
      postInstall = (old.postInstall or "") + ''
        wrapProgram $out/bin/spotify \
          --add-flags "--enable-features=UseOzonePlatform --ozone-platform=wayland"
      '';
    }))
    xournalpp
    whatsapp-electron
    grim
    gh
    rofi
    swaybg
    swayidle
    swaylock
    sioyek
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
    eww                  # widget system for submap hints
    jq                   # JSON processing
    sqlite               # for sioyek mark lookup script
    bat                  # syntax-highlighted cat
    fzf                  # fuzzy finder
    darktable            # RAW photo editor with Nikon NEF support
    gphoto2              # transfer photos from Nikon camera via USB
    nautilus              # GTK file manager
    rclone                # mount Google Drive as local directory

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

  xdg.configFile."eww/eww.yuck".text = ''
    (defvar submap_name "")
    (defvar submap_keys '[{"key": "", "desc": ""}]')

    (defwindow submap-hints
      :monitor 0
      :geometry (geometry :x "0%" :y "10%" :anchor "top center")
      :stacking "overlay"
      :focusable false
      :namespace "submap-hints"
      (box :class "submap-popup" :orientation "vertical" :space-evenly false :spacing 10
        (label :class "submap-title" :halign "center" :text submap_name)
        (box :class "submap-keys" :orientation "vertical" :spacing 6
          (for entry in submap_keys
            (box :orientation "horizontal" :space-evenly false :spacing 10
              (label :class "submap-key" :text "''${entry.key}")
              (label :class "submap-desc" :text "''${entry.desc}"))))
        (label :class "submap-escape" :halign "center" :text "Esc to cancel")))
  '';

  xdg.configFile."eww/eww.scss".text = ''
    .submap-popup {
      background-color: #2d353b;
      border: 2px solid #a7c080;
      border-radius: 8px;
      padding: 15px 20px;
    }

    .submap-title {
      color: #a7c080;
      font-size: 16px;
      font-weight: bold;
      margin-bottom: 4px;
    }

    .submap-key {
      color: #dbbc7f;
      font-family: "JetBrainsMono Nerd Font";
      font-size: 14px;
      font-weight: bold;
      background-color: #475258;
      padding: 2px 8px;
      border-radius: 4px;
      min-width: 20px;
    }

    .submap-desc {
      color: #d3c6aa;
      font-size: 14px;
    }

    .submap-escape {
      color: #859289;
      font-size: 12px;
      margin-top: 4px;
    }
  '';

  xdg.configFile."sioyek/open-mark.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      SHARED="''${XDG_DATA_HOME:-$HOME/.local/share}/sioyek/shared.db"
      LOCAL="''${XDG_DATA_HOME:-$HOME/.local/share}/sioyek/local.db"
      [ -f "$SHARED" ] && [ -f "$LOCAL" ] || exit 0

      MARKS=$(sqlite3 -separator $'\t' "$SHARED" "
        ATTACH '$LOCAL' AS local_db;
        SELECT m.symbol, h.path
        FROM marks m
        JOIN local_db.document_hash h ON m.document_path = h.hash
        ORDER BY m.symbol;
      ")
      [ -z "$MARKS" ] && exit 0

      DISPLAY=""
      while IFS=$'\t' read -r sym path; do
        fname=$(basename "$path" .pdf)
        DISPLAY+="$sym  →  $fname"$'\n'
      done <<< "$MARKS"

      SELECTED=$(echo -n "$DISPLAY" | rofi -dmenu -p "Marks" -i)
      [ -z "$SELECTED" ] && exit 0

      SYMBOL=$(echo "$SELECTED" | awk '{print $1}')
      DOC_PATH=$(echo "$MARKS" | grep "^''${SYMBOL}"$'\t' | cut -f2)

      SIOYEK_ARGS=()
      [[ "$1" == "--new-window" ]] && SIOYEK_ARGS+=(--new-window)
      sioyek "''${SIOYEK_ARGS[@]}" "$DOC_PATH" &
      sleep 0.5
      sioyek --execute-command goto_mark --execute-command-data "$SYMBOL"
    '';
  };

  xdg.configFile."sioyek/update-mark.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      SHARED="''${XDG_DATA_HOME:-$HOME/.local/share}/sioyek/shared.db"
      LOCAL="''${XDG_DATA_HOME:-$HOME/.local/share}/sioyek/local.db"
      [ -f "$SHARED" ] && [ -f "$LOCAL" ] || exit 0

      MARKS=$(sqlite3 -separator $'\t' "$SHARED" "
        ATTACH '$LOCAL' AS local_db;
        SELECT m.symbol, h.path
        FROM marks m
        JOIN local_db.document_hash h ON m.document_path = h.hash
        ORDER BY m.symbol;
      ")
      [ -z "$MARKS" ] && exit 0

      DISPLAY=""
      while IFS=$'\t' read -r sym path; do
        fname=$(basename "$path" .pdf)
        DISPLAY+="$sym  →  $fname"$'\n'
      done <<< "$MARKS"

      SELECTED=$(echo -n "$DISPLAY" | rofi -dmenu -p "Update mark" -i)
      [ -z "$SELECTED" ] && exit 0

      SYMBOL=$(echo "$SELECTED" | awk '{print $1}')
      sioyek --execute-command set_mark --execute-command-data "$SYMBOL"
    '';
  };

  xdg.configFile."sioyek/delete-mark.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      SHARED="''${XDG_DATA_HOME:-$HOME/.local/share}/sioyek/shared.db"
      LOCAL="''${XDG_DATA_HOME:-$HOME/.local/share}/sioyek/local.db"
      [ -f "$SHARED" ] && [ -f "$LOCAL" ] || exit 0

      MARKS=$(sqlite3 -separator $'\t' "$SHARED" "
        ATTACH '$LOCAL' AS local_db;
        SELECT m.symbol, h.path
        FROM marks m
        JOIN local_db.document_hash h ON m.document_path = h.hash
        ORDER BY m.symbol;
      ")
      [ -z "$MARKS" ] && exit 0

      DISPLAY=""
      while IFS=$'\t' read -r sym path; do
        fname=$(basename "$path" .pdf)
        DISPLAY+="$sym  →  $fname"$'\n'
      done <<< "$MARKS"

      SELECTED=$(echo -n "$DISPLAY" | rofi -dmenu -p "Delete mark" -i)
      [ -z "$SELECTED" ] && exit 0

      SYMBOL=$(echo "$SELECTED" | awk '{print $1}')
      sqlite3 "$SHARED" "DELETE FROM marks WHERE symbol='$SYMBOL';"
    '';
  };

  xdg.configFile."sioyek/prefs_user.config".text = ''
    # Everforest dark colors
    custom_background_color 0.176 0.208 0.231
    custom_text_color 0.827 0.776 0.667
    dark_mode_background_color 0.176 0.208 0.231
    dark_mode_contrast 0.827
    background_color 0.176 0.208 0.231
    startup_commands toggle_custom_color

    # Search engines
    search_url_l https://libgen.li/index.php?req=
    search_url_g https://www.google.com/search?q=
    search_url_s https://scholar.google.com/scholar?q=
  '';

  xdg.configFile."sioyek/keys_user.config".text = ''
    toggle_custom_color <C-<f8>>
  '';

  xdg.configFile."xournalpp/palette.gpl".text = ''
    GIMP Palette
    Name: Everforest
    #
    45  53  59   bg
    211 198 170  fg
    71  82  88   black
    230 126 128  red
    167 192 128  green
    219 188 127  yellow
    127 187 179  blue
    214 153 182  magenta
    131 192 146  cyan
    232 213 183  bright fg
  '';

  fonts.fontconfig = {
    enable = true;
    antialiasing = true;
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
