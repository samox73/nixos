{ ... }: {
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
}
