# Interactively select a zoxide directory and copy its path to the clipboard.
export def copy-zoxide-path [] {
  zoxide query -i | str trim | wl-copy
}

# Open the PhD library in Neovim.
export def lib [] {
  nvim /home/samox/studies/phd/library
}

# Replace regex matches in one file or recursively across all files.
export def replace-string [
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

# Mirror the local PhD directory to Google Drive, deleting stale remote files.
export def sync-phd [] {
  rclone sync ~/studies/phd gdrive:studies/phd --filter-from ~/studies/phd/.rcloneignore --progress --transfers 8 --checkers 16 --drive-chunk-size 64M
}

# Update the Neovim flake input and activate the rebuilt NixOS configuration.
def activate-nvim [] {
  ^nix flake update nvim-config --flake ~/.config/nixos
  sudo nixos-rebuild switch --flake ~/.config/nixos
}

# Rebuild NixOS or restart configured applications.
export module reload {
  export def main [] {
    nix
    quickshell
  }

  # Rebuild and activate the current NixOS configuration.
  export def nix [] {
    sudo nixos-rebuild switch --flake ~/.config/nixos
  }

  # Update the Neovim flake input and activate the rebuilt NixOS configuration.
  export def nvim [] {
    activate-nvim
  }

  # Restart Quickshell with the samox configuration.
  export def quickshell [] {
    pkill quickshell; qs --daemonize -c samox
  }
}

# Update application-managed dependencies.
export module update {
  # Update Neovim plugins, commit and push lockfile changes, then rebuild NixOS.
  export def nvim [] {
    let repo = ($env.HOME | path join repos nvim)
    with-env { XDG_CONFIG_HOME: ($env.HOME | path join repos) } {
      ^nvim --headless '+Lazy! update' +qa
    }

    ^git -C $repo add lazy-lock.json
    let unchanged = ((^git -C $repo diff --cached --quiet -- lazy-lock.json | complete).exit_code == 0)
    if not $unchanged {
      ^git -C $repo commit -m 'Update plugins' -- lazy-lock.json
    } else {
      print 'Plugins already up to date'
    }

    ^git -C $repo push
    activate-nvim
  }
}

# Recover user services from known failure states.
export module fix {
  # Stop a wedged clipboard watcher, disabling history recording.
  export def clipboard [] {
    do -i { ^pkill -f "wl-paste --type text/plain --watch" }
    print "clipboard watcher killed (history recording is now off)"
  }

  # Restart clipboard history recording after it was disabled or wedged.
  export def clipboard-history [] {
    do -i { ^pkill -f "wl-paste --type text/plain --watch" }
    ^bash -c "nohup wl-paste --type text/plain --watch clipman store >/dev/null 2>&1 & disown"
    print "clipboard watcher restarted"
  }
}
