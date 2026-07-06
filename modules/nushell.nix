{ config, ... }: {
  programs.zoxide.enable = true;
  programs.carapace = {
    enable = true;
    enableNushellIntegration = true;
  };
  programs.nushell = {
    enable = true;
    configFile.source = ../configs/nushell/config.nu;
    envFile.source = ../configs/nushell/env.nu;
    # Reuse the single source of truth in home.sessionVariables (which only
    # reaches bash/zsh otherwise) so nushell gets the same env without
    # duplicating ANDROID_HOME/SDK_ROOT/NDK/AVD_HOME etc.
    environmentVariables = config.home.sessionVariables;
  };
}
