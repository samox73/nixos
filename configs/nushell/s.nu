export def copy-zoxide-path [] {
  zoxide query -i | str trim | wl-copy
}

export def lib [] {
  nvim /home/samox/studies/phd/library
}

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

export def sync-phd [] {
  rclone sync ~/studies/phd gdrive:studies/phd --filter-from ~/studies/phd/.rcloneignore --progress --transfers 8 --checkers 16 --drive-chunk-size 64M
}

def activate-nvim [] {
  ^nix flake update nvim-config --flake ~/.config/nixos
  sudo nixos-rebuild switch --flake ~/.config/nixos
}

export module reload {
  export def nix [] {
    sudo nixos-rebuild switch --flake ~/.config/nixos
  }

  export def nvim [] {
    activate-nvim
  }

  export def quickshell [] {
    pkill quickshell; qs --daemonize -c samox
  }
}

export module update {
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

export module fix {
  # wl-paste --watch clipman store can wedge (likely Thunderbird's Wayland
  # clipboard never closing its end of the transfer), blocking copy/paste
  # system-wide. Restarting it just re-arms the same trap for the next
  # Thunderbird copy, so this only kills it. Run `s fix clipboard-history`
  # to turn history recording back on once you actually need it.
  export def clipboard [] {
    do -i { ^pkill -f "wl-paste --type text/plain --watch" }
    print "clipboard watcher killed (history recording is now off)"
  }

  # Turn clipboard history recording back on (until it wedges again).
  export def clipboard-history [] {
    do -i { ^pkill -f "wl-paste --type text/plain --watch" }
    ^bash -c "nohup wl-paste --type text/plain --watch clipman store >/dev/null 2>&1 & disown"
    print "clipboard watcher restarted"
  }
}
