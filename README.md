# ob-dotfiles — quick setup

This repository contains a small setup script (`setup.sh`) that installs and configures an Openbox-based desktop environment with Polybar, Rofi, Kitty, Gruvbox theming, Font Awesome, and the Bibata cursor (user-local) on Debian-based systems.

## What `setup.sh` does
- Installs packages commonly used in this Openbox setup (Debian/Ubuntu packages), including `openbox`, `polybar`, `dunst`, `rofi`, `kitty`, `picom`, `polybar`, and theming tools.
- Unpacks the bundled Gruvbox GTK/Openbox theme into `~/.local/share/themes`.
- Installs Font Awesome to `~/.fonts` and refreshes the font cache (`fc-cache`).
- Downloads and installs the Bibata cursor into `~/.icons` and writes `~/.icons/default/index.theme` so user sessions use the cursor theme.
- Writes GTK2/GTK3/GTK4 settings files so GTK apps pick up the Gruvbox theme and `Papirus-Dark` icon theme.
- Creates user config directories and copies or writes configuration files into `~/.config` for: `dunst`, `kitty`, `picom`, `polybar`, `rofi`, `openbox`, and wallpapers.
- Writes a simple `~/.config/polybar/config.ini` and a helper network script `~/.config/polybar/network.sh`.
- Creates Rofi helper scripts: `~/.config/rofi/powermenu.sh` and `~/.config/rofi/launcher.sh` (use the `gruvbox-dark` theme).
- Writes an Openbox `autostart` that launches `dunst`, `picom`, `polybar`, `nm-applet` and other helpers.

Note: the script is intended for Debian-based systems and uses `apt` and `sudo` for package installation.

## Run the script
Make the script executable (optional) and run it as your user:

```bash
chmod +x setup.sh
./setup.sh
# or
bash setup.sh
```

The script will prompt for `sudo` when installing packages.

## Apply changes (logout/login)
Some settings (especially cursor theme and GTK2 apps) require logging out and back in to take effect. You can also restart your display manager.

If you want to apply the cursor setting for the current shell session without logging out, source your profile:

```bash
source ~/.profile
```

## Quick tests / useful commands
- Refresh font cache (after install):

```bash
fc-cache -f -v
```

- Reload Polybar (preferred):

```bash
polybar-msg cmd restart
```

- Restart Polybar manually if above fails:

```bash
killall -q polybar
polybar -r & disown
```

- Reload Dunst:

```bash
dunstctl reload
# or
pkill dunst && dunst & disown
```

- Test Rofi scripts manually:

```bash
~/.config/rofi/launcher.sh    # should open application launcher (drun)
~/.config/rofi/powermenu.sh   # should show power menu
```

- Inspect GTK settings or cursor variables:

```bash
echo $XCURSOR_THEME
cat ~/.config/gtk-3.0/settings.ini
cat ~/.config/gtk-4.0/settings.ini
cat ~/.gtkrc-2.0
```

## Notes & troubleshooting
- If Font Awesome icons appear as boxes, ensure fonts were copied to `~/.fonts` and run `fc-cache -f -v`. You can verify font names with `fc-list | grep -i "font awesome"` and adjust config entries if needed.
- If icons/glyphs do not render in dunst or Polybar, use the exact Pango font name reported by `fc-list` (for example `Font Awesome 6 Free:style=Solid`) in your config.
- If a cursor or theme change doesn't appear, log out/in — some compositors or desktop sessions require a full session restart.
- The script installs the Bibata cursors into `~/.icons` (user-local). For system-wide installation copy to `/usr/share/icons` (requires `sudo`).

## Want changes?
If you want system-wide cursor/install, a different icon theme, different Gruvbox variant, or to remove a package from the installer list, tell me and I can update `setup.sh`.

---
Generated to reflect the current `setup.sh` behavior.
