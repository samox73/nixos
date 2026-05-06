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
