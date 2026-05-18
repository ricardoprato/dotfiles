"""Smart split navigation between kitty windows and nvim splits.

Invoked two ways:

  1. From a kitty keybind:  kitten navigate_kitty.py <direction> <pass-key>
     e.g. `kitten navigate_kitty.py left ctrl+h`
     Smart mode: if the foreground process is nvim/vim, write the raw control
     byte to the child PTY so the editor handles its own split navigation.
     Otherwise, move kitty focus to the neighboring window.

  2. From nvim (utils/kitty-nav.lua):  kitten navigate_kitty.py <direction>
     No pass-key, no smart check — nvim already decided that no nvim split
     exists in that direction and wants to escape to a kitty pane.

Directions accepted: left | right | top | bottom
"""

from kittens.tui.handler import result_handler

EDITOR_PROCESSES = frozenset({"nvim", "vim", "vi"})

# ASCII control chars sent when passing keys through to the editor.
PASS_BYTES = {
    "ctrl+h": b"\x08",  # BS
    "ctrl+j": b"\x0a",  # LF
    "ctrl+k": b"\x0b",  # VT
    "ctrl+l": b"\x0c",  # FF
}

VALID_DIRECTIONS = frozenset({"left", "right", "top", "bottom"})


def _foreground_is_editor(window) -> bool:
    for proc in (window.child.foreground_processes or []):
        cmdline = proc.get("cmdline") or []
        if not cmdline:
            continue
        exe = cmdline[0].rsplit("/", 1)[-1]
        if exe in EDITOR_PROCESSES:
            return True
    return False


def main(args):
    # `main` runs in a kitten subprocess; we want all logic in the parent
    # via `handle_result`, so this is a no-op stub.
    pass


@result_handler(no_ui=True)
def handle_result(args, result, target_window_id, boss):
    if len(args) < 2:
        return
    direction = args[1]
    if direction not in VALID_DIRECTIONS:
        return

    pass_key = args[2] if len(args) >= 3 else None
    window = boss.window_id_map.get(target_window_id)
    if window is None:
        return

    if pass_key and _foreground_is_editor(window):
        seq = PASS_BYTES.get(pass_key)
        if seq:
            window.write_to_child(seq)
        return

    tab = boss.active_tab
    if tab is not None:
        tab.neighboring_window(direction)
