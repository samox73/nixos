# Search CopyQ history with Rofi.
export module clipboard {
  export def pick [] {
    let selection = (
      ^copyq eval 'for (i = 0; i < size(); ++i) { var text = str(read(i)).split(String.fromCharCode(10)).join(" ").trim(); if (text) print(i + String.fromCharCode(9) + text + String.fromCharCode(10)); }'
      | ^rofi -dmenu -i -p Clipboard -display-columns 2 -display-column-separator (char tab)
      | str trim
    )
    if $selection != "" {
      ^copyq select ($selection | split row (char tab) | first)
    }
  }
}

# Manage the editable Neovim configuration.
export module nvim {
  # Clone the repository used by `s nvim update`.
  export def init [] {
    let repo = ($env.HOME | path join repos nvim)
    mkdir ($repo | path dirname)
    ^git clone https://github.com/samox73/nvim $repo
  }

  # Commit and push changes, then update Neovim in NixOS.
  export def update [
    --update-plugins # Update all Neovim plugins first.
  ] {
    let repo = ($env.HOME | path join repos nvim)
    if $update_plugins {
      with-env { XDG_CONFIG_HOME: ($env.HOME | path join repos) } {
        ^nvim --headless '+Lazy! update' +qa
      }
    }

    ^git -C $repo add .
    let unchanged = ((^git -C $repo diff --cached --quiet | complete).exit_code == 0)
    if not $unchanged {
      ^git -C $repo commit -m 'Update'
    } else {
      print 'Nvim already up to date'
    }

    ^git -C $repo push
    ^nix flake update nvim-config --flake ~/.config/nixos
    sudo nixos-rebuild switch --flake ~/.config/nixos
  }
}

# Manage the current NixOS configuration.
export module nix {
  # Rebuild and activate the current NixOS configuration.
  export def rebuild [] {
    sudo nixos-rebuild switch --flake ~/.config/nixos
  }

  # Update every flake input, then rebuild and activate NixOS.
  export def update [] {
    ^nix flake update --flake ~/.config/nixos
    sudo nixos-rebuild switch --flake ~/.config/nixos
  }
}

# Manage PhD files.
export module phd {
  # Mirror the local directory to Google Drive, deleting stale remote files.
  export def sync [] {
    rclone sync ~/studies/phd gdrive:studies/phd --filter-from ~/studies/phd/.rcloneignore --progress --transfers 8 --checkers 16 --drive-chunk-size 64M
  }
}

# Manage Quickshell.
export module quickshell {
  # Restart Quickshell with the samox configuration.
  export def reload [] {
    pkill quickshell; qs --daemonize -c samox
  }
}

# Transform strings in files.
export module string {
  # Replace regex matches in one file or recursively across all files.
  export def replace [
    --all (-a)
    --exclude (-e): string
    src: string
    dst: string
    file?: path
  ] {
    let src = $src | default ""
    let dst = $dst | default ""
    let files = if $all { ls **/* | where type == file | get name } else { [$file] }
    let files = if ($exclude | is-not-empty) { $files | where { |f| not ($f =~ $exclude) } } else { $files }
    for f in $files {
      open --raw $f | str replace -a -r $src $dst | save -f $f
    }
  }
}

# Query zoxide paths.
export module zoxide {
  # Interactively select a directory and copy its path to the clipboard.
  export def copy-path [] {
    ^zoxide query -i | str trim | wl-copy
  }
}

# Reload the NixOS configuration and Quickshell together.
export module system {
  # Rebuild NixOS, then restart Quickshell.
  export def reload [] {
    sudo nixos-rebuild switch --flake ~/.config/nixos
    pkill quickshell; qs --daemonize -c samox
  }
}
