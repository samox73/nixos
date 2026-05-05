source /nix/store/siq9pmliy3yjr1549q93913ll0jifaj9-zoxide-nushell-config.nu

def --env yy [...args] {
  let tmp = (mktemp -t "yazi-cwd.XXXXX")
  yazi ...$args --cwd-file $tmp
  let cwd = (open $tmp)
  if $cwd != "" and $cwd != $env.PWD {
    cd $cwd
  }
  rm -fp $tmp
}

alias rebuild-nix = sudo nixos-rebuild switch --flake ~/.config/nixos
