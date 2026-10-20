# Feature: Migrate Wi-Fi from iwd to NetworkManager

## Objective
Replace iwd with NetworkManager so omarchy-shell's network panel
(`Quickshell.Networking`, NetworkManager D-Bus) and upstream's nmcli helpers
(network qr/password/band/status) work on this machine.

## Current state (2026-10-19)
- iwd enabled+active, does DHCP itself (`/etc/iwd/main.conf`
  `EnableNetworkConfiguration=true`, `NameResolvingService=systemd`).
- systemd-resolved enabled; `/etc/resolv.conf` -> stub-resolv.conf.
- NetworkManager, wpa_supplicant not installed; systemd-networkd disabled.
- Interfaces: wlan0 (in use), enp2s0 (down, unmanaged), docker/br-*/veth*/virbr0.
- sudo needs a password, so the user runs the system steps.
- impala 0.9.0 is the Wi-Fi TUI (`omarchy-launch-wifi` runs it via sudo).

## Scope
- `networkmanager` in the `desktop` package set (WSL unaffected).
- Our own one-shot script `network-migrate-networkmanager` (no omarchy- prefix):
  backup iwd state, import iwd profiles (PSK and open) as NM keyfiles, keep
  container/VM bridges unmanaged, use systemd-resolved for DNS, swap services,
  wait for connectivity, roll back to iwd automatically on failure. Idempotent,
  `--dry-run` supported.
- `omarchy-launch-wifi`: stop using impala (it needs iwd); open the NM UI until
  omarchy-shell owns this.

## Constraints
- Never lose connectivity without an automatic rollback.
- Back up `/var/lib/iwd` and `/etc/iwd` before touching anything.
- 802.1X/enterprise iwd profiles are not converted (warn, keep backup).
- Userland chezmoi rule: the system change is an explicit, user-run step, like
  the gaming unit's `/etc/gamemode.ini` precedent; not run on `chezmoi apply`.

## Acceptance criteria
- `bash -n` and `shellcheck` clean; `--dry-run` prints the plan with no root.
- After the user runs it: `nmcli -t -f STATE general` = connected,
  `systemctl is-active iwd` = inactive, the saved networks show in
  `nmcli connection show`, DNS resolves.
- `chezmoi ignored --override-data '{"platform":"wsl"}'` excludes the script.

## TDD
Mode: enabled (global), no runner. Proof: bash -n, shellcheck, dry-run, then the
user-run migration checks above.

## Delivery
exception-ok (direct commits on main-omarchy).

## Tasks
- [x] T1 Package + migration script + launch-wifi + wsl gating (route: delegated writer)
- [x] T2 User runs the migration; verify (route: user-run + parent checks)

## Progress / evidence
- T1 done (delegated writer): `networkmanager` in `[packages.desktop]`;
  `dot_local/bin/executable_network-migrate-networkmanager`;
  `omarchy-launch-wifi` uses nmtui when NetworkManager is active, else impala
  (`org.omarchy.nmtui` added to the floating-window rule in
  `dot_config/hypr/apps/system.lua`); script gated for wsl in `.chezmoiignore`.
- `bash -n` both scripts: ok. `shellcheck` both: clean.
- `network-migrate-networkmanager --dry-run`: prints plan, exit 0, no sudo.
- Installer render contains `networkmanager`; `chezmoi ignored` (wsl) lists
  the script and `omarchy-launch-wifi`.
- SSID/INI helpers spot-checked (plain, hex-encoded, digit-only, `;` SSIDs).

- T2 done (user-run, three iterations). Fixes found in real runs:
  629af00/180246a iwd deletes its netdev on stop (async) -> recreate station
  iface with `iw` after a short wait and recheck once NM is up; cf584a7 old NM
  profiles from a previous install were pinned to `interface-name=wlp3s0`
  (now `wlan0`) -> unpin Wi-Fi profiles bound to a missing interface.
  Automatic rollback to iwd worked on both failed runs.
- Verified: NetworkManager active+enabled, iwd inactive+disabled,
  `nmcli general` connected:full, wlan0 connected to Blueorange
  (10.20.20.107/24), DNS via systemd-resolved (1.1.1.1 from the profile),
  `getent hosts archlinux.org` resolves, container/VM bridges unmanaged.

## Next step
Done. Continue with omarchy-shell phase.
