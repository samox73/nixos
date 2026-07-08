$env.LD_LIBRARY_PATH = $"/etc/profiles/per-user/($env.USER)/lib:(($env.LD_LIBRARY_PATH? | default ''))"

# User-installed tools (uv, uvx, pipx, ...) live in ~/.local/bin.
$env.PATH = ($env.PATH | prepend $"($env.HOME)/.local/bin" | uniq)
$env.PATH = ($env.PATH | prepend $"($env.HOME)/go/bin" | uniq)
$env.PATH = ($env.PATH | prepend $"($env.HOME)/.cargo/bin" | uniq)
