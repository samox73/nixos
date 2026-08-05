{ config, pkgs, pkgs-unstable, pkgs-rnote, hostname, ... }:
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
    ./modules/alacritty.nix
    ./modules/git.nix
    ./modules/neovim.nix
    ./modules/yazi.nix
    ./modules/nushell.nix
    ./modules/kitty.nix
    ./modules/hyprland.nix
    ./modules/rofi.nix
    ./modules/mako.nix
    ./modules/sway.nix
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
    pkgs-unstable.claude-code
    pkgs-unstable.codex
    translate-shell
    firefox
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
    pkgs-rnote.rnote
    libwacom
    libinput
    glib
    whatsapp-electron
    signal-desktop
    discord
    grim
    gh
    rofi
    swaybg
    swayidle
    swaylock
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
    sway-contrib.grimshot # for easier screenshots in wayland
    wl-color-picker
    hyprpicker
    obs-studio
    audacity             # audio recording from mic and system audio
    slack
    pkgs-unstable.everforest-gtk-theme
    everforest-cursors
    eww                  # widget system for submap hints
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
    xorg.libX11  # X11 library
    xorg.libXi   # X11 input extension
    xorg.libXmu  # X11 miscellaneous utilities
    wayland
    libxkbcommon
    xorg.libXcursor
    xorg.libXrandr

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
    ffmpeg
    ttyd

    # obs keypress display
    showmethekey

    # physics stuff
    quantum-espresso # alternative to VASP, ab-initio simulations
    phy          # euporie-notebook physics scratchpad in kitty (np/scipy/plt + constants)
  ];

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

  xdg.configFile."sioyek/open-bookmark.nu" = {
    executable = true;
    text = ''
      #!/usr/bin/env nu

      def main [--new-window] {
        let data_home = ($env.XDG_DATA_HOME? | default $"($env.HOME)/.local/share")
        let shared = $"($data_home)/sioyek/shared.db"
        let local_db = $"($data_home)/sioyek/local.db"
        if not ($shared | path exists) or not ($local_db | path exists) { return }

        let sql = ("ATTACH '" + $local_db + "' AS local_db;
          SELECT b.desc, b.document_path, b.offset_y, h.path,
                 COALESCE(ob.zoom_level, 2.5) as zoom_level
          FROM bookmarks b
          JOIN local_db.document_hash h ON b.document_path = h.hash
          LEFT JOIN opened_books ob ON ob.path = h.path
          ORDER BY b.desc;")

        let bookmarks = (sqlite3 -separator "\t" $shared $sql
          | lines | where { $in != "" }
          | split column "\t" desc doc_hash offset_y path zoom_level
          | where {|b| $b.path | str trim | path exists })

        if ($bookmarks | is-empty) { return }

        let display = ($bookmarks
          | each {|b| $"($b.desc)  →  ($b.path | path basename | str replace '.pdf' "")"}
          | str join "\n")

        let idx = (try { $display | rofi -dmenu -p "Bookmarks" -i -format i | str trim } catch { "" })
        if $idx == "" or $idx == "-1" { return }

        let selected = ($bookmarks | get ($idx | into int))
        let doc_path = ($selected.path | str trim)
        let doc_hash = ($selected.doc_hash | str trim)
        let offset_y = ($selected.offset_y | str trim)
        let zoom = ($selected.zoom_level | str trim)

        # Write a temporary mark at the bookmark's position
        let sql_mark = ("INSERT OR REPLACE INTO marks (document_path, symbol, offset_x, offset_y, zoom_level) VALUES ('" + $doc_hash + "', '~', 0, " + $offset_y + ", " + $zoom + ");")
        sqlite3 $shared $sql_mark

        if $new_window {
          bash -c 'sioyek --new-window "$1" --execute-command goto_mark --execute-command-data "~" &' _ $doc_path
        } else {
          bash -c 'sioyek "$1" --execute-command goto_mark --execute-command-data "~" &' _ $doc_path
        }
      }
    '';
  };

  xdg.configFile."sioyek/update-bookmark.nu" = {
    executable = true;
    text = ''
      #!/usr/bin/env nu

      def main [] {
        let data_home = ($env.XDG_DATA_HOME? | default $"($env.HOME)/.local/share")
        let shared = $"($data_home)/sioyek/shared.db"
        let local_db = $"($data_home)/sioyek/local.db"
        if not ($shared | path exists) or not ($local_db | path exists) { return }

        let bookmarks = (sqlite3 -separator "\t" $shared $"ATTACH '($local_db)' AS local_db;
          SELECT b.desc, b.document_path, h.path FROM bookmarks b
          JOIN local_db.document_hash h ON b.document_path = h.hash
          ORDER BY b.desc;"
          | lines | where { $in != "" } | split column "\t" desc doc_hash path)

        if ($bookmarks | is-empty) { return }

        let display = ($bookmarks
          | each {|b| $"($b.desc)  →  ($b.path | path basename | str replace '.pdf' "")"}
          | str join "\n")

        let idx = (try { $display | rofi -dmenu -p "Update bookmark" -i -format i | str trim } catch { "" })
        if $idx == "" or $idx == "-1" { return }

        let selected = ($bookmarks | get ($idx | into int))
        let desc_escaped = ($selected.desc | str replace -a "'" "''''")

        sqlite3 $shared $"DELETE FROM bookmarks WHERE desc='($desc_escaped)' AND document_path='($selected.doc_hash)';"
        sioyek --execute-command add_bookmark --execute-command-data $selected.desc
      }
    '';
  };

  xdg.configFile."sioyek/delete-bookmark.nu" = {
    executable = true;
    text = ''
      #!/usr/bin/env nu

      def main [] {
        let data_home = ($env.XDG_DATA_HOME? | default $"($env.HOME)/.local/share")
        let shared = $"($data_home)/sioyek/shared.db"
        let local_db = $"($data_home)/sioyek/local.db"
        if not ($shared | path exists) or not ($local_db | path exists) { return }

        let bookmarks = (sqlite3 -separator "\t" $shared $"ATTACH '($local_db)' AS local_db;
          SELECT b.desc, b.document_path, h.path FROM bookmarks b
          JOIN local_db.document_hash h ON b.document_path = h.hash
          ORDER BY b.desc;"
          | lines | where { $in != "" } | split column "\t" desc doc_hash path)

        if ($bookmarks | is-empty) { return }

        let display = ($bookmarks
          | each {|b| $"($b.desc)  →  ($b.path | path basename | str replace '.pdf' "")"}
          | str join "\n")

        let idx = (try { $display | rofi -dmenu -p "Delete bookmark" -i -format i | str trim } catch { "" })
        if $idx == "" or $idx == "-1" { return }

        let selected = ($bookmarks | get ($idx | into int))
        let desc_escaped = ($selected.desc | str replace -a "'" "''''")

        sqlite3 $shared $"DELETE FROM bookmarks WHERE desc='($desc_escaped)' AND document_path='($selected.doc_hash)';"
      }
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
      name = "Everforest-Dark";
      package = pkgs-unstable.everforest-gtk-theme;
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
