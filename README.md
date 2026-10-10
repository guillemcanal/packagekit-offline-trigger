# PackageKit offline trigger

This project makes the offline update flow work in desktop sessions that do not
run `gnome-shell` (for example, custom or wlroots-based sessions), while keeping
it generic and independent of any specific desktop environment.

## Problem

On GNOME, the offline update is armed by the logout/shutdown dialog in
`gnome-shell`, which calls `Offline.Trigger` on PackageKit. Without
`gnome-shell`, GNOME Software restarts via logind but does not arm the offline
update: `/system-update` is never created, and the machine simply reboots or
powers off without applying the pending packages.

## Solution

The `pk-offline-arm.service` unit runs `pk-offline-arm` during system shutdown.
If updates have already been prepared in `/var/lib/PackageKit/prepared-update`
and the offline update is not already armed, the script creates the same files as
`pkcon offline-trigger`:

- `/var/lib/PackageKit/offline-update-action` (`reboot` or `power-off`)
- `/system-update` → `/var/lib/PackageKit/prepared-update`

The files are written directly because `packagekitd` cannot be started while the
system is shutting down.

On the next boot, systemd runs `packagekit-offline-update`, which installs the
pending packages and then reboots or powers off according to the action that was
armed.

## Usage

```sh
./install.sh            # install and enable the service (sudo)
./install.sh uninstall  # disable and remove the service (sudo)
./install.sh status     # show service and offline update status
```
