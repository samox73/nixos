{ pkgs, ... }: {
  programs.git = {
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
}
