$env.LD_LIBRARY_PATH = $"/etc/profiles/per-user/($env.USER)/lib:(($env.LD_LIBRARY_PATH? | default ''))"
$env.SSH_AUTH_SOCK = ($env.XDG_RUNTIME_DIR | path join ssh-agent)

$env.PATH = ($env.PATH | prepend $"($env.HOME)/.cargo/bin" | uniq)
