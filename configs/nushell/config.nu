$env.config.show_banner = false

alias ll = ls
alias l = ls
def nf [] { let file = (fzf --preview 'bat --color=always --style=numbers {}' | str trim); if $file != "" { nvim $file } }

use /home/samox/.config/nixos/data/pokedex
use /home/samox/.config/nixos/configs/nushell/s.nu

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

export def cdr --env [] { cd (git rev-parse --show-toplevel) }

export def "path cp" [p: path] {
  $p | path expand | wl-copy
}
