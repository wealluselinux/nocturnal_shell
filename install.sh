#!/bin/sh
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME="$(eval echo "~$REAL_USER")"

# 1. Detect distro and map to base family
DISTRO_ID="unknown"
DISTRO_NAME="Linux"
DISTRO_LIKE=""
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO_ID="${ID:-unknown}"
    DISTRO_NAME="${PRETTY_NAME:-$DISTRO_ID}"
    DISTRO_LIKE="${ID_LIKE:-}"
fi

BASE="unknown"
case "$DISTRO_ID $DISTRO_LIKE" in
    *arch*|*cachyos*|*endeavouros*|*manjaro*|*garuda*|*kaos*)
        BASE="arch" ;;
    *ubuntu*|*debian*|*linuxmint*|*pop*|*zorin*|*elementary*)
        BASE="debian" ;;
    *fedora*|*nobara*|*rhel*|*centos*|*rocky*)
        BASE="fedora" ;;
    *gentoo*)
        BASE="gentoo" ;;
    *suse*|*opensuse*)
        BASE="suse" ;;
esac

echo "=========================================="
echo "  Nocturnal Shell Installer"
echo "=========================================="
echo "Detected OS:   $DISTRO_NAME"
echo "Base family:   $BASE"
echo ""
echo "What this installer will do:"
echo "  1. Install dependencies (Hyprland, Quickshell, Kitty, swaybg, grim, slurp, wl-clipboard, cava, curl, python3, kdialog, notify-send)"
echo "  2. Auto-install Hyprland, Quickshell, and nixGL via Nix if missing from your distro repos"
echo "  3. Install JetBrainsMono Nerd Font if missing"
echo "  4. Reset shell settings to clean Nocturnal defaults (default wall0.png wallpaper)"
echo "  5. Install /usr/local/bin/nocturnal-session and /usr/share/wayland-sessions/nocturnal.desktop"
echo ""
printf "Are you ready for the installation? [y/N]: "
read -r ans
case "$ans" in
    y|Y|yes|YES) ;;
    *) echo "Installation cancelled."; exit 0 ;;
esac

# 2. Install base dependencies per distro family
echo ""
echo "Installing dependencies for $BASE..."
case "$BASE" in
    arch)
        sudo pacman -S --needed --noconfirm hyprland kitty swaybg grim slurp wl-clipboard cava curl python python-pillow kdialog libnotify qt6-wayland dbus
        if ! command -v quickshell >/dev/null 2>&1; then
            if command -v yay >/dev/null 2>&1; then yay -S --needed --noconfirm quickshell-git
            elif command -v paru >/dev/null 2>&1; then paru -S --needed --noconfirm quickshell-git
            fi
        fi
        ;;
    debian)
        sudo apt-get update
        sudo apt-get install -y kitty swaybg grim slurp wl-clipboard cava curl xz-utils fontconfig python3 python3-pil kdialog libnotify-bin dbus-x11
        ;;
    fedora)
        sudo dnf install -y hyprland kitty swaybg grim slurp wl-clipboard cava curl xz fontconfig python3 python3-pillow kdialog libnotify dbus-x11
        ;;
    gentoo)
        sudo emerge --ask --noreplace gui-wm/hyprland x11-terms/kitty gui-apps/swaybg gui-apps/grim gui-apps/slurp gui-apps/wl-clipboard media-sound/cava net-misc/curl dev-python/pillow kde-apps/kdialog x11-libs/libnotify
        ;;
    suse)
        sudo zypper install -y hyprland kitty swaybg grim slurp wl-clipboard cava curl xz fontconfig python3 python3-Pillow kdialog libnotify-tools dbus-1-x11
        ;;
esac

# 3. Ensure Hyprland, Quickshell, & nixGL are installed system-wide via Nix if missing
nix_add() {
    NIX_BIN="$(command -v nix || echo /nix/var/nix/profiles/default/bin/nix)"
    sudo "$NIX_BIN" --extra-experimental-features 'nix-command flakes' profile add --profile /nix/var/nix/profiles/default "$@" 2>/dev/null || \
    sudo "$NIX_BIN" --extra-experimental-features 'nix-command flakes' profile install --profile /nix/var/nix/profiles/default "$@"
}

if ! command -v Hyprland >/dev/null 2>&1 || ! command -v quickshell >/dev/null 2>&1; then
    echo ""
    echo "Hyprland or Quickshell not found in native repos — installing system-wide via Nix..."
    if ! command -v nix >/dev/null 2>&1 && [ ! -x /nix/var/nix/profiles/default/bin/nix ]; then
        curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
    fi
    [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ] && . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    export PATH="/nix/var/nix/profiles/default/bin:$PATH"

    if ! command -v Hyprland >/dev/null 2>&1; then
        nix_add nixpkgs#hyprland
        nix_add --impure github:nix-community/nixGL
    fi
    if ! command -v quickshell >/dev/null 2>&1; then
        nix_add nixpkgs#quickshell
    fi

    for b in Hyprland start-hyprland hyprctl quickshell qs nixGL; do
        if [ -x "/nix/var/nix/profiles/default/bin/$b" ]; then
            sudo ln -sf "/nix/var/nix/profiles/default/bin/$b" "/usr/local/bin/$b"
        fi
    done
fi

# 4. Install JetBrainsMono Nerd Font if missing
if ! fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd Font"; then
    echo "Installing JetBrainsMono Nerd Font..."
    mkdir -p "$REAL_HOME/.local/share/fonts"
    curl -fLo /tmp/JetBrainsMono.tar.xz https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz
    tar -xf /tmp/JetBrainsMono.tar.xz -C "$REAL_HOME/.local/share/fonts"
    rm -f /tmp/JetBrainsMono.tar.xz
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.local/share/fonts" 2>/dev/null || true
    fc-cache -f
fi

# 5. Reset settings to clean Nocturnal defaults
rm -f "$DIR/quickshell/settings.json" "$DIR/quickshell/pinned.json" "$REAL_HOME/.cache/nocturnal/clipboard.txt"
cat > "$DIR/quickshell/settings.json" << 'JSON'
{"lightMode":false,"accent":"#c9b8ff","themePreset":"Nocturnal","wallpaper":"wall0.png","panelOpacity":0.85,"shapeRadius":12,"blurEnabled":true,"rounding":14,"dockEnabled":true,"widgetsEnabled":true,"widgetClock":true,"widgetAnalog":true,"widgetMusic":true,"widgetSound":true,"dockAutoHide":false,"cavaEnabled":false,"use24h":false,"volumeLimit":100,"barPosition":"top","dockPosition":"middle","launcherPosition":"middle"}
JSON
echo "[]" > "$DIR/quickshell/pinned.json"

# 6. Permissions, folders, symlink ~/nocturnal if cloned to ~/nocturnal_shell, & Session entry
chmod +x "$DIR/bin/"* 2>/dev/null || true
mkdir -p "$REAL_HOME/Pictures/Wallpapers" "$REAL_HOME/Pictures/Screenshots"
[ "$DIR" != "$REAL_HOME/nocturnal" ] && [ ! -e "$REAL_HOME/nocturnal" ] && ln -s "$DIR" "$REAL_HOME/nocturnal"
sudo install -m 755 "$DIR/bin/nocturnal-session" /usr/local/bin/nocturnal-session
sed "s|Exec=.*|Exec=/usr/local/bin/nocturnal-session|" "$DIR/session/nocturnal.desktop" > /tmp/nocturnal.desktop
sudo install -m 644 /tmp/nocturnal.desktop /usr/share/wayland-sessions/nocturnal.desktop
rm -f /tmp/nocturnal.desktop

echo ""
echo "=========================================="
echo "  Nocturnal Shell is installed!"
echo "=========================================="
echo "How to start Nocturnal:"
echo "  1. Log out of your current session."
echo "  2. On your login screen (SDDM/GDM), select 'Nocturnal' in the session menu."
echo "  3. Log in — press Super (Windows key) for apps, Super+I for Settings, Super+T for Kitty."
