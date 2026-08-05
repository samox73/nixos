@RTK.md

# Shell: Nushell, not Bash

My default shell is **nushell** (`nu`), not bash. Give me nushell-compatible
commands in every project. Common gotchas:

- Flags: `ls -la` → `ls -la` is invalid; use `ls -a` (nu has no `-l`, output is already a table). `ls **/*.rs` for recursive globs.
- No `&&`/`||` chaining → use `;` for sequencing, or `and`/`or` for booleans. Conditional: `if (cmd | complete).exit_code == 0 { ... }`.
- No `$(...)` or backticks → use `(command)` for command substitution.
- Env vars: `$env.VAR`, set with `$env.VAR = "x"` or `VAR=x cmd`. Export in scripts via `$env`.
- Pipes carry structured data, not just text: prefer `open file.json | get key`, `ps | where cpu > 10`, `ls | sort-by size`.
- `echo` exists but prefer `print`. String interpolation: `$"value is ($x)"`.
- Redirects: `cmd out> file.txt`, `cmd err> file.txt`, `cmd out+err> file.txt`. No `2>&1` → use `out+err>`.
- Text tools still work as external cmds (`grep`, `sed`, `rg`), but prefer nu builtins: `where`, `find`, `str replace`, `lines`, `split row`.
- Reading/editing files: `open`, `save`, `save -f` to overwrite.

When a bash-only construct is genuinely needed, wrap it: `bash -c "..."`.
