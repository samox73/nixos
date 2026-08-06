{ config, pkgs, pkgs-unstable, nvim-config, ... }:
let
  androidBuildToolsVersion = "34.0.0";
  androidPlatformVersion = "34";
  androidNdkVersion = "26.1.10909125";
  androidComposition = pkgs.androidenv.composeAndroidPackages {
    platformVersions = [ androidPlatformVersion ];
    buildToolsVersions = [ androidBuildToolsVersion ];
    includeNDK = true;
    ndkVersions = [ androidNdkVersion ];
    includeEmulator = true;
    includeSystemImages = true;
    systemImageTypes = [ "google_apis" ];
    abiVersions = [ "x86_64" ];
  };
  rustToolchain = pkgs.rust-bin.stable.latest.default.override {
    extensions = [ "rust-src" "rustfmt" "clippy" ];
    targets = [ "aarch64-linux-android" "x86_64-linux-android" ];
  };
  # `phy`: a physics scratchpad — euporie-notebook (a rich terminal Jupyter
  # notebook editor) preloaded with numpy/scipy/matplotlib + physical
  # constants. Real notebook semantics (independent cells, Shift+Enter runs
  # and advances natively — unlike euporie-console, which shares one input
  # history across cells, so up-arrow in a fresh cell recalls the previous
  # one). Opens a throwaway .ipynb path that's never written unless you
  # explicitly save, so it stays a no-clutter scratchpad. Self-contained: own
  # python, kernel, kernelspec.
  phyPython = pkgs.python3.withPackages (ps: with ps; [
    euporie
    ipykernel     # the python kernel euporie drives
    numpy
    scipy
    (matplotlib.override { enableTk = true; })  # inline by default; `%matplotlib tk` = popup fallback
  ]);
  # A dedicated kernelspec whose kernel preloads phy_startup.py at boot. euporie
  # can't print at kernel start, so the constants table is exposed as `consts`.
  phyKernel = pkgs.writeTextDir "share/jupyter/kernels/phy/kernel.json" (builtins.toJSON {
    argv = [
      "${phyPython}/bin/python" "-m" "ipykernel_launcher" "-f" "{connection_file}"
      "--IPKernelApp.exec_files=[\"${./configs/python/phy_startup.py}\"]"
    ];
    display_name = "phy";
    language = "python";
  });
  phy = pkgs.writeShellScriptBin "phy" ''
    export JUPYTER_PATH="${phyKernel}/share/jupyter''${JUPYTER_PATH:+:$JUPYTER_PATH}"
    exec ${phyPython}/bin/euporie-notebook --kernel-name phy \
      --edit-mode vi \
      --color-scheme custom \
      --custom-background-color "#2d353b" \
      --custom-foreground-color "#d3c6aa" \
      --accent-color "#a7c080" \
      --syntax-theme zenburn \
      --custom-styles '{"cell input prompt":"fg:#7fbbb3 bold","cell output prompt":"fg:#e69875 bold"}' \
      "$(mktemp -u --suffix=.ipynb)" "$@"
  '';
in {
  imports = [
    ./modules/git.nix
    ./modules/neovim.nix
    ./modules/yazi.nix
    ./modules/nushell.nix
    ./modules/kitty.nix
    ./modules/hyprland.nix
    ./modules/rofi.nix
    ./modules/mako.nix
    ./modules/ai.nix
  ];

  home.stateVersion = "25.11";

  home.pointerCursor = {
    name = "everforest-cursors";
    package = pkgs.everforest-cursors;
    size = 24;
    gtk.enable = true;
  };

  home.packages = with pkgs; [
    pkgs-unstable.quickshell
    translate-shell
    chromium
    thunderbird
    (spotify.overrideAttrs (old: {
      postInstall = (old.postInstall or "") + ''
        wrapProgram $out/bin/spotify \
          --add-flags "--enable-features=UseOzonePlatform --ozone-platform=wayland"
      '';
    }))
    xournalpp
    krita
    gimp
    rnote
    libwacom
    libinput
    glib
    whatsapp-electron
    signal-desktop
    discord
    grim
    gh
    rofi
    sioyek
    zotero
    kdePackages.okular
    slurp
    hyprshot
    wl-clipboard
    clipman
    mako   # notification daemon; dunst 1.13 didn't repaint its Wayland surface while Hyprland was idle
    libnotify
    kanshi
    pamixer
    playerctl
    brightnessctl
    imagemagick
    loupe
    mcp-nixos
    texliveFull
    networkmanagerapplet  # nm-connection-editor GUI for WPA-Enterprise (eduroam)
    pavucontrol
    ueberzugpp            # for image previews in yazi file browser
    wl-color-picker
    hyprpicker
    obs-studio
    audacity             # audio recording from mic and system audio
    slack
    pkgs-unstable.everforest-gtk-theme
    everforest-cursors
    jq                   # JSON processing
    litecli
    bat                  # syntax-highlighted cat
    fzf                  # fuzzy finder
    darktable            # RAW photo editor with Nikon NEF support
    gphoto2              # transfer photos from Nikon camera via USB
    nautilus              # GTK file manager
    rclone                # mount Google Drive as local directory
    vscode               # code editor
    obsidian             # markdown editor
    pandoc               # conversion between document formats
    doxygen              # source code documentation generator
    openmpi              # MPI implementation for parallel computing
    openmpi.dev          # MPI headers, mpicc, and pkg-config files for building
    poppler-utils        # PDF command-line tools (pdftotext, pdfinfo, pdftoppm)
    ntfsprogs            # mkfs.ntfs and other NTFS tools
    gitui
    lazygit
    delta
    git-extras
    dyff
    glow
    nix-search-cli
    pkgs-unstable.rtk

    # Android development
    androidComposition.androidsdk  # sdkmanager, adb, platform-tools, cmdline-tools
    gradle
    cargo-ndk
    jdk17                          # Android Gradle Plugin 8.x requires JDK 17

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
    zip          # for mason package extraction
    unzip        # for mason package extraction
    gzip         # for mason package extraction
    texpresso    # live rendering latex

    # Go development
    go
    gopls        # Go LSP server
    delve        # Go debugger
    gotools      # goimports, etc.

    # Python development
    (python3.withPackages (ps: with ps; [ jupyterlab numpy matplotlib scipy tensorly ]))
    python3Packages.pip
    python3Packages.virtualenv
    pyright      # Python LSP server
    jetbrains.pycharm
    pkgs-unstable.uv

    # Rust development
    rustToolchain
    rust-analyzer  # Rust LSP server

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
    libx11       # X11 library
    libxi        # X11 input extension
    libxmu       # X11 miscellaneous utilities
    wayland
    libxkbcommon
    libxcursor
    libxrandr

    # Vulkan development
    vulkan-tools             # vulkaninfo, vkcube
    vulkan-validation-layers # validation layers for debugging
    vulkan-loader            # Vulkan ICD loader
    vulkan-headers           # Vulkan headers for compilation
    #glslang                  # glslangValidator: GLSL/HLSL → SPIR-V
    shaderc                  # glslc: GLSL/HLSL → SPIR-V
    #spirv-tools              # SPIR-V assembler, disassembler, validator
    renderdoc                # GPU frame debugger

    #protobuf
    grpc-tools

    kotlin

    font-awesome
    nerd-fonts.commit-mono
    nerd-fonts.symbols-only
    nerd-fonts.jetbrains-mono

    # vhs (terminal-recorder) dependencies
    vhs
    ffmpeg
    ttyd

    # obs keypress display
    showmethekey

    # physics stuff
    quantum-espresso # alternative to VASP, ab-initio simulations
    phy          # euporie-notebook physics scratchpad in kitty (np/scipy/plt + constants)
  ];

  programs.firefox = {
    enable = true;
    configPath = ".config/mozilla/firefox";
    profiles = {
      uni = {
        id = 0;
        path = "7irvrn36.uni";
        isDefault = true;
      };
      private = {
        id = 1;
        settings."browser.privatebrowsing.autostart" = true;
      };
    };
  };

  home.file.".config/mozilla/firefox/profiles.ini".force = true;

  xdg.configFile."nvim" = {
    source = nvim-config;
    force = true;
  };

  xdg.configFile."input-remapper-2/config.json" = {
    source = ./configs/input-remapper/config.json;
    force = true;
  };

  xdg.configFile."input-remapper-2/presets/Wacom Intuos Pro M Pad/custom.json" = {
    source = ./configs/input-remapper/wacom-intuos-pro-m-pad.json;
    force = true;
  };

  xdg.configFile."quickshell/samox" = {
    source = ./configs/quickshell;
    recursive = true;
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/about" = "firefox.desktop";
      "x-scheme-handler/unknown" = "firefox.desktop";
    } // builtins.listToAttrs (map (name: {
      inherit name;
      value = "org.gnome.Loupe.desktop";
    }) [
      "image/jpeg" "image/png" "image/gif" "image/webp" "image/tiff" "image/x-tga"
      "image/vnd-ms.dds" "image/x-dds" "image/bmp" "image/vnd.microsoft.icon"
      "image/vnd.radiance" "image/x-exr" "image/x-portable-bitmap" "image/x-portable-graymap"
      "image/x-portable-pixmap" "image/x-portable-anymap" "image/x-qoi" "image/qoi"
      "image/svg+xml" "image/svg+xml-compressed" "image/avif" "image/heic" "image/jxl"
    ]);
  };

  xdg.configFile."hypr/move-windows.nu" = {
    executable = true;
    text = ''
      #!/usr/bin/env nu

      def main [] {
        let current_ws = (hyprctl activeworkspace -j | from json | get id)
        let options = (1..10 | where { $in != $current_ws } | each { $in | into string } | str join "\n")
        let target = (try { $options | rofi -dmenu -p $"Move WS ($current_ws) →" -i | str trim } catch { "" })
        if $target == "" { return }

        let windows = (hyprctl clients -j | from json | where { $in.workspace.id == $current_ws })
        for win in $windows {
          hyprctl dispatch movetoworkspacesilent $"($target),address:($win.address)"
        }
      }
    '';
  };

  xdg.configFile."hypr/rules.conf".text = ''
    windowrule {
      name = android-emulator-class
      match:class = .*[Ee]mulator.*

      float = true
      allows_input = true
    }

    windowrule {
      name = android-emulator-title
      match:title = .*[Ee]mulator.*

      float = true
      allows_input = true
    }

    # Float matplotlib (phy) plot windows from `%matplotlib tk`.
    # The Tk backend sets WM_CLASS to "matplotlib".
    windowrule {
      name = matplotlib-float
      match:class = [Mm]atplotlib

      float = true
    }
  '';

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

    theme = {
      name = "Everforest-Dark";
      package = pkgs-unstable.everforest-gtk-theme;
    };

    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4 = {
      extraConfig.gtk-application-prefer-dark-theme = 1;
      theme = config.gtk.theme;
    };
    # gtk4.extraCss = builtins.readFile "${pkgs-unstable.everforest-gtk-theme}/share/themes/Everforest-Dark/gtk-4.0/gtk.css";
  };

  home.sessionVariables = {
    GTK_THEME = "Everforest-Dark";
    _ZO_FZF_OPTS = "--exact --no-sort --bind=ctrl-z:ignore,btab:up,tab:down --cycle --keep-right --border=sharp --height=20% --info=inline --layout=reverse --tabstop=1 --exit-0 --color=fg:#d3c6aa,bg:#2d353b,hl:#dbbc7f,fg+:#d3c6aa,bg+:#475258,hl+:#dbbc7f,info:#859289,prompt:#a7c080,pointer:#a7c080,marker:#d699b6,spinner:#83c092,header:#7fbbb3,border:#475258";
    ANDROID_HOME = "${androidComposition.androidsdk}/libexec/android-sdk";
    ANDROID_SDK_ROOT = "${androidComposition.androidsdk}/libexec/android-sdk";
    ANDROID_NDK_ROOT = "${androidComposition.androidsdk}/libexec/android-sdk/ndk/${androidNdkVersion}";
    ANDROID_NDK_HOME = "${androidComposition.androidsdk}/libexec/android-sdk/ndk/${androidNdkVersion}";
    # avdmanager writes AVDs under $XDG_CONFIG_HOME/.android while the emulator
    # only searches $HOME/.android by default. Pin both to one explicit path.
    # Absolute (not $HOME) so it's also valid as a literal in nushell's load-env.
    ANDROID_AVD_HOME = "${config.home.homeDirectory}/.android/avd";
    JAVA_HOME = "${pkgs.jdk17}/lib/openjdk";
    GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidComposition.androidsdk}/libexec/android-sdk/build-tools/${androidBuildToolsVersion}/aapt2";
  };
}
