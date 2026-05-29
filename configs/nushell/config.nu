$env.config.show_banner = false

alias rebuild-nix = sudo nixos-rebuild switch --flake ~/.config/nixos
alias lib = nvim /home/samox/studies/phd/library
alias ll = ls
alias l = ls
def nf [] { let file = (fzf --preview 'bat --color=always --style=numbers {}' | str trim); if $file != "" { nvim $file } }

use /home/samox/.config/nixos/data/pokedex
use /home/samox/.config/nixos/data/ikariam
