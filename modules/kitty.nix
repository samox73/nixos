{ ... }: {
  # Graphics-capable terminal — used by `phy` so euporie can render matplotlib
  # plots crisply inline (kitty graphics protocol).
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMonoNL Nerd Font Mono";
      size = 11;
    };
    settings = {
      window_padding_width = 10;
      confirm_os_window_close = 0;
      scrollback_lines = 20000;
      scrollback_pager = "nvim --cmd 'set eventignore=FileType' +'silent autocmd! TrimNvim' +'silent autocmd! TrimHighlight' +'call clearmatches()' +'nnoremap q ZQ' +'call nvim_open_term(0, {})' +'set nomodified nolist' +'$' -";

      # Everforest Dark
      background = "#2d353b";
      foreground = "#d3c6aa";
      cursor = "#d3c6aa";
      selection_background = "#475258";
      selection_foreground = "#d3c6aa";

      color0 = "#475258"; color8 = "#475258";   # black
      color1 = "#e67e80"; color9 = "#e67e80";    # red
      color2 = "#a7c080"; color10 = "#a7c080";   # green
      color3 = "#dbbc7f"; color11 = "#dbbc7f";   # yellow
      color4 = "#7fbbb3"; color12 = "#7fbbb3";   # blue
      color5 = "#d699b6"; color13 = "#d699b6";   # magenta
      color6 = "#83c092"; color14 = "#83c092";   # cyan
      color7 = "#d3c6aa"; color15 = "#d3c6aa";   # white
    };
  };
}
