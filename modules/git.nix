{ pkgs, ... }: {
  home.packages = [ pkgs.ov ];

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
      core.pager = "delta";
      delta = {
        dark = true;
        "line-numbers" = true;
        navigate = true;
        # sticky file header while scrolling: ov pins the current section
        pager = "ov -F --section-delimiter '^Δ' --section-header";
        "file-modified-label" = "Δ";
        "file-added-label" = "Δ";
        "file-removed-label" = "Δ";
        "file-renamed-label" = "Δ";
      };
      init.defaultBranch = "main";
      interactive.diffFilter = "delta --color-only";
      pull.rebase = true;
      push.autoSetupRemote = true;
    };
  };

  xdg.configFile."ov/config.yaml".source = ../configs/ov/config.yaml;

  xdg.configFile."lazygit/config.yml".text = ''
    git:
      pagers:
        - pager: delta --dark --paging=never --line-numbers --hyperlinks --hyperlinks-file-link-format="lazygit-edit://{path}:{line}"
  '';
}
