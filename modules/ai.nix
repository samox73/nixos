{ config, pkgs-unstable, ... }:

{
  programs.codex = {
    enable = true;
    package = pkgs-unstable.codex;
    context = ../configs/codex/AGENTS.md;
  };

  programs.claude-code = {
    enable = true;
    package = pkgs-unstable.claude-code;
    context = ../configs/claude/CLAUDE.md;
    settings = {
      permissions.defaultMode = "bypassPermissions";
      model = "opus";
      hooks = {
        Stop = [{
          matcher = "";
          hooks = [{
            type = "command";
            command = "notify-send 'Claude Code' 'Awaiting your input'";
          }];
        }];
        Notification = [{
          matcher = "";
          hooks = [{
            type = "command";
            command = "notify-send 'Claude Code' 'Notification'";
          }];
        }];
        PreToolUse = [{
          matcher = "Bash";
          hooks = [{
            type = "command";
            command = "rtk hook claude";
          }];
        }];
      };
      enabledPlugins = {
        "rust-analyzer-lsp@claude-plugins-official" = true;
        "pyright-lsp@claude-plugins-official" = true;
        "ponytail@ponytail" = true;
      };
      extraKnownMarketplaces.ponytail.source = {
        source = "github";
        repo = "DietrichGebert/ponytail";
      };
      effortLevel = "xhigh";
      tui = "fullscreen";
      skipDangerousModePermissionPrompt = true;
      theme = "dark-daltonized";
      preferredNotifChannel = "notifications_disabled";
      agentPushNotifEnabled = false;
    };
  };

  home.file = {
    ".codex/AGENTS.md".force = true;
    ".codex/RTK.md" = {
      source = ../configs/codex/RTK.md;
      force = true;
    };
    "${config.home.homeDirectory}/.claude/settings.json".force = true;
    "${config.home.homeDirectory}/.claude/CLAUDE.md".force = true;
    "${config.home.homeDirectory}/.claude/RTK.md" = {
      source = ../configs/claude/RTK.md;
      force = true;
    };
  };
}
