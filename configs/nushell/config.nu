$env.config.show_banner = false

alias rebuild-nix = sudo nixos-rebuild switch --flake ~/.config/nixos
alias lib = nvim /home/samox/studies/phd/library
alias ll = ls
alias l = ls
def nf [] { let file = (fzf --preview 'bat --color=always --style=numbers {}' | str trim); if $file != "" { nvim $file } }

use /home/samox/.config/nixos/data/pokedex

# Append a column with the row-wise difference of `column` (first row is 0).
export def add-diff [
  column: cell-path             # column to compute successive differences of
  --name (-n): string = "diff"  # name of the appended column
] {
  let input = $in
  let vals = $input | get $column
  let diffs = $vals | enumerate | each { |it|
    if $it.index == 0 { 0 } else { $it.item - ($vals | get ($it.index - 1)) }
  }
  $input | merge ($diffs | wrap $name)
}

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

export def zic [] { zoxide query -i | str trim | wl-copy }

module fix {
    # wl-paste --watch clipman store can wedge (likely Thunderbird's Wayland
    # clipboard never closing its end of the transfer), blocking copy/paste
    # system-wide. Restarting it just re-arms the same trap for the next
    # Thunderbird copy, so this only kills it. Run `fix clipboard-history`
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
use fix

export def cdr --env [] { cd (git rev-parse --show-toplevel) }
