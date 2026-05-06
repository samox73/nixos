{ ... }: {
  programs.zoxide.enable = true;
  programs.carapace = {
    enable = true;
    enableNushellIntegration = true;
  };
  programs.nushell = {
    enable = true;
    configFile.source = ../configs/nushell/config.nu;
    envFile.source = ../configs/nushell/env.nu;
  };
}
