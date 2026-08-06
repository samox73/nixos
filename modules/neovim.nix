{ ... }: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    sideloadInitLua = true;
    viAlias = true;
    vimAlias = true;
    withPython3 = true;
    withRuby = true;
  };
}
