#!/usr/bin/python3

import subprocess
import json
import sys


def run(cmd):
    return subprocess.run(
        cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE
    ).stdout.decode().strip()


def main():
    is_paused = run(["dunstctl", "is-paused"]) == "true"
    waiting = int(run(["dunstctl", "count", "waiting"]) or "0")
    history_count = int(run(["dunstctl", "count", "history"]) or "0")

    if is_paused:
        count = waiting
        alt = "dnd"
    elif history_count > 0:
        count = history_count
        alt = "notification"
    else:
        count = 0
        alt = "none"

    tooltip_lines = [
        "\u200e󰎟 Notifications",
        "󰳽 scroll:        history pop",
        "󰳽 left click:    toggle DND",
        "󰳽 middle click:  clear history",
        "󰳽 right click:   dismiss all",
    ]

    if is_paused:
        tooltip_lines.append(f"\n  DND: ON  ({waiting} waiting)")

    if history_count > 0:
        try:
            history = json.loads(run(["dunstctl", "history"]))
            notifications = history.get("data", [[]])[0][:5]
            if notifications:
                tooltip_lines.append("")
                for n in notifications:
                    summary = n.get("summary", {}).get("data", "")
                    body = n.get("body", {}).get("data", "")
                    line = f"  {summary}"
                    if body:
                        line += f": {body}"
                    tooltip_lines.append(line)
        except (json.JSONDecodeError, IndexError, KeyError):
            pass

    output = {
        "text": str(count),
        "alt": alt,
        "tooltip": "\n".join(tooltip_lines),
        "class": alt,
    }

    sys.stdout.write(json.dumps(output) + "\n")
    sys.stdout.flush()


if __name__ == "__main__":
    main()
