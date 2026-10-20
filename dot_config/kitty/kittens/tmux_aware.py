"""Run a kitty action, unless tmux is in the foreground: then hand the key to tmux.

Usage from kitty.conf:
  map alt+1 kitten kittens/tmux_aware.py alt+1 goto_tab 1

Args: <pass-key> <kitty action ...>
If the foreground process of the target window is tmux, write the key to the
child PTY so tmux's own binding (e.g. M-1 select-window) handles it. Otherwise
run the joined kitty action via boss.combine(). Supported pass-keys:
alt+<single char> (encoded as ESC + char).
"""

from kittens.tui.handler import result_handler

PASSTHROUGH_PROCESSES = frozenset({"tmux"})


def _key_bytes(key: str):
    if key.startswith("alt+") and len(key) == 5:
        return b"\x1b" + key[4].encode()
    return None


def _foreground_is_tmux(window) -> bool:
    for proc in (window.child.foreground_processes or []):
        cmdline = proc.get("cmdline") or []
        if not cmdline:
            continue
        exe = cmdline[0].rsplit("/", 1)[-1]
        # tmux clients may show as "tmux: client"; the first token is enough.
        if exe.split(":", 1)[0] in PASSTHROUGH_PROCESSES:
            return True
    return False


def main(args):
    # Logic lives in handle_result (runs in the kitty parent process).
    pass


@result_handler(no_ui=True)
def handle_result(args, result, target_window_id, boss):
    if len(args) < 3:
        return
    pass_key = args[1]
    action = " ".join(args[2:])
    window = boss.window_id_map.get(target_window_id)
    if window is None:
        return

    seq = _key_bytes(pass_key)
    if seq and _foreground_is_tmux(window):
        window.write_to_child(seq)
        return

    boss.combine(action, window)
