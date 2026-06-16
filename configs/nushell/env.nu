$env.LD_LIBRARY_PATH = $"/etc/profiles/per-user/($env.USER)/lib:(($env.LD_LIBRARY_PATH? | default ''))"
