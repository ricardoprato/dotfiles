#!/usr/bin/env bats
# Tests for dot_local/bin/executable_upstream-sync against a throwaway upstream
# repo and a throwaway chezmoi source repo. Nothing touches the real HOME,
# chezmoi state or desktop session.

SCRIPT="$BATS_TEST_DIRNAME/../dot_local/bin/executable_upstream-sync"

setup() {
  export HOME="$BATS_TEST_TMPDIR/home"
  export XDG_RUNTIME_DIR="$BATS_TEST_TMPDIR/run"
  mkdir -p "$HOME" "$XDG_RUNTIME_DIR"
  unset HYPRLAND_INSTANCE_SIGNATURE
  export UPSTREAM_SYNC_SKIP_SESSION=1
  export UPSTREAM_SYNC_FILTER=""
  export UPSTREAM_SYNC_CACHE="$BATS_TEST_TMPDIR/cache"
  export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
  export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null

  UP="$BATS_TEST_TMPDIR/up"
  export UPSTREAM_SYNC_URL="$UP"
  make_upstream
  make_source
  make_chezmoi_stub
  export PATH="$BATS_TEST_TMPDIR/stub:$PATH"
}

make_upstream() {
  git init -q -b main "$UP"
  mkdir -p "$UP"/{bin,default/hypr/bindings,default/themed,themes/t1,shell/plugins/p1,migrations,docs}
  printf '#!/bin/bash\n# omarchy:summary=Old thing\necho a\nzzold-tool\n' >"$UP/bin/omarchy-a"
  printf '#!/bin/bash\n# omarchy:summary=Overridden\necho ov\n' >"$UP/bin/omarchy-ov"
  printf '#!/bin/bash\n# omarchy:summary=Doomed\n' >"$UP/bin/omarchy-gone"
  printf 'o.bind("SUPER + A", "A", f)\n' >"$UP/default/hypr/bindings/x.lua"
  echo x >"$UP/default/themed/foo.tpl"
  echo x >"$UP/themes/t1/colors.toml"
  echo x >"$UP/shell/plugins/p1/a.qml"
  echo x >"$UP/docs/ignored.md"
  printf '# old\n' >"$UP/migrations/1.sh"
  git -C "$UP" add -A && git -C "$UP" commit -q -m c1
  C1=$(git -C "$UP" rev-parse HEAD)

  printf '#!/bin/bash\n# omarchy:summary=Old thing\necho a2\nzzold-tool\nzzfake-chg --now\n' >"$UP/bin/omarchy-a"
  printf '#!/bin/bash\n# omarchy:summary=Overridden\necho ov-new\n' >"$UP/bin/omarchy-ov"
  git -C "$UP" rm -q bin/omarchy-gone
  printf '#!/bin/bash\n# omarchy:summary=Brand new\nzzfake-tool --go\nomarchy-cmd-present zzfake-opt && zzfake-opt\nls\n' >"$UP/bin/omarchy-new"
  printf 'o.bind("SUPER + A", "A", f)\no.bind("SUPER + B", "B", g)\n' >"$UP/default/hypr/bindings/x.lua"
  echo y >"$UP/default/themed/foo.tpl"
  echo y >"$UP/default/themed/bar.tpl"
  mkdir -p "$UP/themes/t2" && echo x >"$UP/themes/t2/colors.toml"
  echo y >"$UP/shell/plugins/p1/a.qml"
  echo y >"$UP/docs/ignored.md"
  printf '#!/bin/bash\n# Rewrite the hypr config\nrm ~/.config/hypr/old.lua\n' >"$UP/migrations/2.sh"
  printf '#!/bin/bash\n# Harmless\necho hi\n' >"$UP/migrations/3.sh"
  git -C "$UP" add -A && git -C "$UP" commit -q -m c2
  C2=$(git -C "$UP" rev-parse HEAD)
}

make_source() {
  SRC="$BATS_TEST_TMPDIR/src"
  export UPSTREAM_SYNC_SOURCE="$SRC"
  mkdir -p "$SRC/.chezmoidata" "$SRC/dot_local/bin"
  ov_sha=$(git -C "$UP" cat-file blob "$C1:bin/omarchy-ov" | sha256sum | cut -d' ' -f1)
  cat >"$SRC/.chezmoidata/omarchy.toml" <<TOML
# comment
[omarchy]
commit = "$C1"
landing = ".local/share/omarchy-upstream"

[omarchy.overrides."bin/omarchy-ov"]
sha256 = "$ov_sha"
why = "test"

[omarchy.overrides."bin/omarchy-missing"]
sha256 = "deadbeef"
why = "removed upstream"
TOML
  cat >"$SRC/.chezmoiexternal.toml.tmpl" <<'TPL'
{{/* exclude = ["*/not-this"] inside a comment must be ignored? no: only real arrays count */ -}}
["x"]
    type = "archive"
    exclude = [
        "*/docs",
        "*/migrations",
        "*/themes/*/backgrounds/intros",
    ]
TPL
  printf '#!/bin/bash\necho fine\n' >"$SRC/dot_local/bin/executable_ok"
  git init -q -b main "$SRC"
  git -C "$SRC" add -A && git -C "$SRC" commit -q -m init
}

make_chezmoi_stub() {
  mkdir -p "$BATS_TEST_TMPDIR/stub"
  export CZ_LOG="$BATS_TEST_TMPDIR/chezmoi.log"
  : >"$CZ_LOG"
  cat >"$BATS_TEST_TMPDIR/stub/chezmoi" <<'STUB'
#!/bin/bash
echo "$*" >>"$CZ_LOG"
case $1 in
  source-path) echo "$UPSTREAM_SYNC_SOURCE" ;;
  diff) [[ -z ${CZ_DIFF:-} ]] || echo "$CZ_DIFF" ;;
  apply) : ;;
esac
STUB
  chmod +x "$BATS_TEST_TMPDIR/stub/chezmoi"
}

fn() { bash -c 'set -euo pipefail; source "$1"; shift; "$@"' _ "$SCRIPT" "$@"; }

# ------------------------------------------------------------- pin parsing --

@test "pin: reads commit and landing" {
  run fn pin_commit "$SRC/.chezmoidata/omarchy.toml"
  [ "$status" -eq 0 ]
  [ "$output" = "$C1" ]
  run fn pin_landing "$SRC/.chezmoidata/omarchy.toml"
  [ "$output" = ".local/share/omarchy-upstream" ]
}

@test "pin: rewrites only the commit line" {
  cp "$SRC/.chezmoidata/omarchy.toml" "$BATS_TEST_TMPDIR/before"
  run fn pin_set_commit "$SRC/.chezmoidata/omarchy.toml" "$C2"
  [ "$status" -eq 0 ]
  run diff "$BATS_TEST_TMPDIR/before" "$SRC/.chezmoidata/omarchy.toml"
  [[ $output == *"commit = \"$C1\""* && $output == *"commit = \"$C2\""* ]]
  [ "$(diff "$BATS_TEST_TMPDIR/before" "$SRC/.chezmoidata/omarchy.toml" | grep -c '^[<>]')" -eq 2 ]
}

@test "pin: lists overrides with recorded hashes" {
  run fn pin_overrides "$SRC/.chezmoidata/omarchy.toml"
  [ "${lines[0]}" = "$(printf 'bin/omarchy-ov\t%s' "$ov_sha")" ]
  [ "${lines[1]}" = "$(printf 'bin/omarchy-missing\tdeadbeef')" ]
}

@test "pin: rewrites one override hash" {
  run fn pin_set_override_sha "$SRC/.chezmoidata/omarchy.toml" bin/omarchy-ov abc123
  [ "$status" -eq 0 ]
  run fn pin_overrides "$SRC/.chezmoidata/omarchy.toml"
  [ "${lines[0]}" = "$(printf 'bin/omarchy-ov\tabc123')" ]
  [ "${lines[1]}" = "$(printf 'bin/omarchy-missing\tdeadbeef')" ]
}

# ---------------------------------------------------- include/exclude parse --

@test "external: extracts the exclude array only" {
  run fn ext_array "$SRC/.chezmoiexternal.toml.tmpl" exclude
  [ "${lines[0]}" = "*/docs" ]
  [ "${lines[1]}" = "*/migrations" ]
  [ "${lines[2]}" = "*/themes/*/backgrounds/intros" ]
  [ "${#lines[@]}" -eq 3 ]
}

@test "external: pathspec drops the wildcard prefix and excludes children" {
  run bash -c 'set -euo pipefail; source "$1"; build_pathspec "$2"; printf "%s\n" "${PATHSPEC[@]}"' _ "$SCRIPT" "$SRC/.chezmoiexternal.toml.tmpl"
  [ "${lines[0]}" = "." ]
  [ "${lines[1]}" = ":(exclude,glob)docs" ]
  [ "${lines[2]}" = ":(exclude,glob)docs/**" ]
}

# --------------------------------------------------------------- dry run ----

@test "dry-run: report covers bins, bindings, themes, templates, shell, migrations" {
  run "$SCRIPT" --dry-run "$C2"
  [ "$status" -eq 0 ]
  [[ $output == *"added \`omarchy-new\`: Brand new"* ]]
  [[ $output == *"removed \`omarchy-gone\`: Doomed"* ]]
  [[ $output == *"+o.bind(\"SUPER + B\""* ]]
  [[ $output == *"- bins: +1 / -1 / ~2 changed"* ]]
  [[ $output == *"added \`t2\`"* ]]
  [[ $output == *"added \`default/themed/bar.tpl\`"* ]]
  [[ $output == *"\`p1\`: 1 files"* ]]
  [[ $output == *"migrations/2.sh\`: Rewrite the hypr config"*"touches overlay-owned: hypr"* ]]
  [[ $output == *"migrations added: 2 (1 touching"* ]]
  [[ $output != *"ignored.md"* ]]
}

@test "dry-run: override drift lists changed and removed overrides" {
  run "$SCRIPT" --dry-run "$C2"
  [[ $output == *"CHANGED upstream: \`bin/omarchy-ov\`"* ]]
  [[ $output == *"+echo ov-new"* ]]
  [[ $output == *"accept-override bin/omarchy-ov"* ]]
  [[ $output == *"REMOVED upstream: \`bin/omarchy-missing\`"* ]]
  [[ $output == *"overrides: 2 tracked, 1 drifted, 1 removed upstream"* ]]
}

@test "dry-run: makes no changes (pin, worktree, chezmoi, report dir)" {
  run "$SCRIPT" --dry-run "$C2"
  [ "$status" -eq 0 ]
  [ -z "$(git -C "$SRC" status --porcelain)" ]
  [ "$(git -C "$SRC" rev-list --count HEAD)" -eq 1 ]
  [ "$(fn pin_commit "$SRC/.chezmoidata/omarchy.toml")" = "$C1" ]
  [ ! -e "$SRC/odd" ]
  ! grep -q '^apply' "$CZ_LOG"
}

@test "dry-run: same ref as the pin reports already at pin" {
  run "$SCRIPT" --dry-run "$C1"
  [ "$status" -eq 0 ]
  [[ $output == *"already at pin"* ]]
  [[ $output != *"## Summary"* ]]
}

@test "dry-run: resolves branch and short refs to the full sha" {
  run "$SCRIPT" --dry-run main
  [[ $output == *"new pin: \`$C2\`"* ]]
  run "$SCRIPT" --dry-run "${C2:0:10}"
  [[ $output == *"new pin: \`$C2\`"* ]]
}

@test "dry-run: default ref is upstream HEAD" {
  run "$SCRIPT" --dry-run
  [[ $output == *"new pin: \`$C2\`"* ]]
}

@test "dry-run: dirty worktree only warns" {
  echo dirt >>"$SRC/dot_local/bin/executable_ok"
  run "$SCRIPT" --dry-run "$C2"
  [ "$status" -eq 0 ]
  [[ $output == *"dirty chezmoi source worktree"* ]]
}

# ------------------------------------------------------------ real run ------

@test "run: dirty worktree aborts before touching the pin" {
  echo dirt >>"$SRC/dot_local/bin/executable_ok"
  run "$SCRIPT" "$C2"
  [ "$status" -ne 0 ]
  [[ $output == *"dirty chezmoi source worktree"* ]]
  [ "$(fn pin_commit "$SRC/.chezmoidata/omarchy.toml")" = "$C1" ]
  ! grep -q '^apply' "$CZ_LOG"
}

@test "run: untracked .atl/ does not count as dirty" {
  mkdir "$SRC/.atl" && echo x >"$SRC/.atl/f"
  run "$SCRIPT" "$C2"
  [ "$status" -eq 0 ]
}

@test "run: non-empty chezmoi diff aborts" {
  CZ_DIFF="diff --git a/x b/x" run "$SCRIPT" "$C2"
  [ "$status" -ne 0 ]
  [[ $output == *"chezmoi diff is not empty"* ]]
  [ "$(fn pin_commit "$SRC/.chezmoidata/omarchy.toml")" = "$C1" ]
}

@test "run: bumps the pin, applies the landing dir, commits only pin + report" {
  run "$SCRIPT" "$C2"
  [ "$status" -eq 0 ]
  [ "$(fn pin_commit "$SRC/.chezmoidata/omarchy.toml")" = "$C2" ]
  grep -q "^apply --force --no-tty --exclude=scripts $HOME/.local/share/omarchy-upstream" "$CZ_LOG"
  [ -z "$(git -C "$SRC" status --porcelain)" ]
  [ "$(git -C "$SRC" log -1 --format=%s)" = "chore(omarchy): sync upstream to ${C2:0:8}" ]
  [ "$(git -C "$SRC" show --name-only --format= HEAD | sort | tr '\n' ' ')" = \
    "$(printf '.chezmoidata/omarchy.toml\nodd/upstream-sync/%s-%s.md\n' "$(date +%F)" "${C2:0:8}" | sort | tr '\n' ' ')" ]
  grep -q "## Checks" "$SRC/odd/upstream-sync/$(date +%F)-${C2:0:8}.md"
  grep -q "PASS bash -n dot_local/bin" "$SRC/odd/upstream-sync/$(date +%F)-${C2:0:8}.md"
}

@test "run: deletes files upstream removed from the landing dir" {
  mkdir -p "$HOME/.local/share/omarchy-upstream/bin"
  touch "$HOME/.local/share/omarchy-upstream/bin/omarchy-gone" "$HOME/.local/share/omarchy-upstream/bin/omarchy-a"
  run "$SCRIPT" "$C2"
  [ "$status" -eq 0 ]
  [ ! -e "$HOME/.local/share/omarchy-upstream/bin/omarchy-gone" ]
  [ -e "$HOME/.local/share/omarchy-upstream/bin/omarchy-a" ]
}

@test "run: a failing check restores the old pin, re-applies and exits non-zero" {
  git -C "$SRC" rm -q --cached dot_local/bin/executable_ok
  printf '#!/bin/bash\nif then\n' >"$SRC/dot_local/bin/executable_ok"
  git -C "$SRC" add -A && git -C "$SRC" commit -q -m broken
  run "$SCRIPT" "$C2"
  [ "$status" -ne 0 ]
  [[ $output == *"bash -n"* ]]
  [ "$(fn pin_commit "$SRC/.chezmoidata/omarchy.toml")" = "$C1" ]
  [ "$(grep -c '^apply' "$CZ_LOG")" -eq 2 ]
  [ -z "$(git -C "$SRC" status --porcelain)" ]
  [ ! -e "$SRC/odd" ]
}

# ----------------------------------------------------- accept-override ------

@test "accept-override: rejects a path not in the overrides table" {
  run "$SCRIPT" --accept-override bin/omarchy-nope
  [ "$status" -ne 0 ]
  [[ $output == *"not in the overrides table"* ]]
}

@test "accept-override: errors when the landing file is missing" {
  run "$SCRIPT" --accept-override bin/omarchy-ov
  [ "$status" -ne 0 ]
  [[ $output == *"does not exist"* ]]
}

@test "accept-override: records the hash of the applied file (full key or bare name)" {
  mkdir -p "$HOME/.local/share/omarchy-upstream/bin"
  git -C "$UP" cat-file blob "$C2:bin/omarchy-ov" >"$HOME/.local/share/omarchy-upstream/bin/omarchy-ov"
  want=$(sha256sum "$HOME/.local/share/omarchy-upstream/bin/omarchy-ov" | cut -d' ' -f1)
  run "$SCRIPT" --accept-override omarchy-ov
  [ "$status" -eq 0 ]
  run fn pin_overrides "$SRC/.chezmoidata/omarchy.toml"
  [ "${lines[0]}" = "$(printf 'bin/omarchy-ov\t%s' "$want")" ]
  [ "${lines[1]}" = "$(printf 'bin/omarchy-missing\tdeadbeef')" ]
}

@test "usage: unknown flag exits 2" {
  run "$SCRIPT" --bogus
  [ "$status" -eq 2 ]
}

# ------------------------------------------------- external command audit ---

@test "ext_cmds: first words of pipes and lists; builtins, omarchy-*, vars, quotes, comments excluded" {
  run fn ext_cmds bin/x <<'EOF'
#!/bin/bash
# zzcomment-tool is only mentioned here
set -euo pipefail
echo "zzquoted-tool in a string"
cd /tmp && zzone-tool --flag | zztwo-tool; zzthree-tool
omarchy-whatever arg
"$VAR" arg
if zzcond-tool; then zzthen-tool; fi
x=$(zzsub-tool arg)
printf '%s' "$(zzdq-tool)"
EOF
  [ "$status" -eq 0 ]
  [ "$output" = "$(printf 'zzcond-tool\t0\nzzdq-tool\t0\nzzone-tool\t0\nzzsub-tool\t0\nzzthen-tool\t0\nzzthree-tool\t0\nzztwo-tool\t0')" ]
}

@test "ext_cmds: functions defined in the file, assigned names and heredoc bodies are excluded" {
  run fn ext_cmds bin/x <<'EOF'
#!/bin/bash
zzhelper() { zzreal-tool; }
function zzother { :; }
zzhelper
zzother
zzvar=1
zzvar
: <<TXT
zzprose-tool says hi
TXT
: <<-'TXT'
	zzprose2-tool
	TXT
EOF
  [ "$output" = "$(printf 'zzreal-tool\t0')" ]
}

@test "ext_cmds: exec, sudo, systemd-run and uwsm-app wrappers resolve to the wrapped command" {
  run fn ext_cmds bin/x <<'EOF'
#!/bin/bash
exec zzexec-tool "$1"
sudo -n zzsudo-tool
systemd-run --user --quiet --collect zzrun-tool --headless
uwsm-app -- zzuwsm-tool
timeout 5 zztimeout-tool
EOF
  [ "$output" = "$(printf 'zzexec-tool\t0\nzzrun-tool\t0\nzzsudo-tool\t0\nzztimeout-tool\t0\nzzuwsm-tool\t0')" ]
}

@test "ext_cmds: command -v and omarchy-cmd-present/missing mark commands as guarded" {
  run fn ext_cmds bin/x <<'EOF'
#!/bin/bash
command -v zzopt-one >/dev/null || exit 0
omarchy-cmd-present zzopt-two zzopt-three && true
if omarchy-cmd-missing zzopt-four; then :; fi
zzopt-one --go
zzhard-tool
EOF
  [ "$output" = "$(printf 'zzhard-tool\t0\nzzopt-four\t1\nzzopt-one\t1\nzzopt-three\t1\nzzopt-two\t1')" ]
}

@test "ext_cmds: non-shell shebangs yield the interpreter only; qml yields spawned commands" {
  run fn ext_cmds bin/x <<'EOF'
#!/usr/bin/env zzruby
puts `zzinner-tool`
EOF
  [ "$output" = "$(printf 'zzruby\t0')" ]
  run fn ext_cmds shell/Svc.qml <<'EOF'
Process { command: ["zzqml-tool", "--x"] }
Quickshell.execDetached(["zzdetached-tool"])
Process { command: ["omarchy-shell", "ping"] }
EOF
  [ "$output" = "$(printf 'zzdetached-tool\t0\nzzqml-tool\t0')" ]
}

@test "missing_deps: keeps only absent commands, merges files, guarded only when every use is" {
  run bash -c 'source "$1"; printf "%s\n" "ls\t0\tbin/a" "zzm-tool\t1\tbin/b" "zzm-tool\t0\tbin/c" "zzn-tool\t1\tbin/d" | sed "s/\\\\t/\t/g" | missing_deps' _ "$SCRIPT"
  [ "$output" = "$(printf 'zzm-tool\t0\tbin/b, bin/c\nzzn-tool\t1\tbin/d')" ]
}

@test "dry-run: lists new external commands missing here, near the top, without failing" {
  run "$SCRIPT" --dry-run "$C2"
  [ "$status" -eq 0 ]
  [[ $output == *"## New external commands missing on this machine"* ]]
  [[ $output == *'`zzfake-tool` (UNGUARDED): bin/omarchy-new'* ]]
  [[ $output == *'`zzfake-chg` (UNGUARDED): bin/omarchy-a'* ]]
  [[ $output == *'`zzfake-opt` (guarded): bin/omarchy-new'* ]]
  [[ $output != *"zzold-tool"* ]]
  [[ $output != *'`ls`'* ]]
  [[ $output == *"new external commands missing here: 3 (2 unguarded)"* ]]
  [[ ${output%%"## Summary"*} == *"zzfake-tool"* ]]
  [[ ${output%%"## Bins"*} == *"zzfake-tool"* ]]
}

@test "audit-deps: scans the applied tree offline and lists missing commands" {
  mkdir -p "$HOME/.local/share/omarchy-upstream/bin" "$HOME/.local/share/omarchy-upstream/shell"
  printf '#!/bin/bash\nzzaudit-tool\nls\n' >"$HOME/.local/share/omarchy-upstream/bin/omarchy-x"
  printf 'Process { command: ["zzaudit-qml"] }\n' >"$HOME/.local/share/omarchy-upstream/shell/S.qml"
  run "$SCRIPT" --audit-deps
  [ "$status" -eq 0 ]
  [ "$output" = "$(printf '%s\n' '- `zzaudit-qml` (UNGUARDED): shell/S.qml' '- `zzaudit-tool` (UNGUARDED): bin/omarchy-x')" ]
}

@test "audit-deps: refuses extra arguments" {
  run "$SCRIPT" --audit-deps --dry-run
  [ "$status" -ne 0 ]
}
