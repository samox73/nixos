$env.config.show_banner = false
$env.config.history.sync_on_enter = false

alias ll = ls
alias l = ls
def nf [] { let file = (fzf --preview 'bat --color=always --style=numbers {}' | str trim); if $file != "" { nvim $file } }

def "nu-complete claude accounts" [] { ["uni" "private"] }

def --wrapped c [account?: string@"nu-complete claude accounts", ...args] {
  let account = if $account == null {
    ["uni" "private"] | str join (char nl) | fzf --height 5 --reverse --prompt "Claude account> " | str trim
  } else {
    $account
  }

  if $account == "" { return }
  if $account not-in ["uni" "private"] {
    error make { msg: $"unknown Claude account: ($account)" }
  }

  let config_dir = if $account == "private" { "~/.claude" } else { "~/.claude-uni" }
  with-env { CLAUDE_CONFIG_DIR: ($config_dir | path expand) } { claude ...$args }
}

$env.config.keybindings ++= [{
  name: fuzzy_file
  modifier: control
  keycode: char_f
  mode: [emacs vi_insert vi_normal]
  event: {
    send: executehostcommand
    cmd: "let file = (fzf --preview 'bat --color=always --style=numbers {}' | str trim); if $file != '' { commandline edit --insert ($file | to nuon) }"
  }
}]

$env.config.keybindings ++= [{
  name: fuzzy_history
  modifier: control
  keycode: char_r
  mode: [emacs vi_insert vi_normal]
  event: {
    send: executehostcommand
    cmd: "let command = (history | get command | reverse | uniq | str join (char nl) | fzf --height 40% --reverse --query (commandline) | str trim); if $command != '' { commandline edit --replace $command }"
  }
}]

def "nu-complete vim files" [context: string] {
  let spans = ($context | split row ' ')
  carapace vim nushell ...$spans
  | from json
  | where display !~ '(?i)\.(aux|fdb_latexmk|fls|log|out|pdf|synctex\.gz)$'
}

extern vim [...files: path@"nu-complete vim files"]

use /home/samox/.config/nixos/data/pokedex
use /home/samox/.config/nixos/configs/nushell/s.nu
use (if ("~/.config/nushell/private/vsc.nu" | path exists) {
  "~/.config/nushell/private/vsc.nu"
})

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
