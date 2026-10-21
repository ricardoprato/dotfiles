# Galaxy Buds for the Omarchy bar

Battery and controls for Samsung Galaxy Buds (written against the Buds3 Pro).

## Features

- Bar button with the lowest bud battery; tooltip with left, right and case.
- Right click cycles noise control: Off, ANC, Ambient.
- Popup: noise mode (Off / ANC / Ambient / Adaptive, adaptive is experimental),
  strong ANC, ambient level, detect conversations, seamless connection,
  touch lock and find my buds.

## Requirements

- BlueZ, `python3` with `gi` (PyGObject) at `/usr/bin/python3`. No pip packages.
- The buds paired and connected in Bluetooth settings.

## Settings

- `address`: MAC of the buds. Empty means the first connected device whose
  name contains "Buds".
- `hideWhenDisconnected`: hide the bar button while the buds are away.

## Limits

- Samsung Auto Switch with your account cannot run on Linux. The widget only
  toggles the buds' "Seamless connection" setting.
- The buds accept one SPP client. If Galaxy Wearable on your phone, or
  GalaxyBudsClient on this machine, holds the link, the widget shows
  "Another app is using the Buds link" or "The buds refused the control link".
  Quit the other app and press Connect.
- Several monitors share one link: the first `buds watch` owns it through the
  abstract socket `omarchy-buds`, the others mirror it.

## Development

    python3 -m unittest discover -s dot_config/omarchy/plugins/redfoxd.buds/tests -v

`bin/buds status` prints one full state and exits; `bin/buds watch` streams JSON
lines and reads `key value` commands on stdin (`mode anc`, `anc_level high`,
`ambient_level 1`, `conversation on`, `seamless off`, `touch_lock on`,
`find start`).
