FROM i.anatase.org/anatase:stable

# Show "Ruizite" as the OS name (boot menu, System Settings, fastfetch). Only the
# display names change: ID, VARIANT_ID and the rest stay Anatase's, so tools and the
# updater that check for Anatase keep working and rebasing back stays clean.
RUN sed -i -e 's/^NAME=.*/NAME="Ruizite"/' -e 's/^PRETTY_NAME=.*/PRETTY_NAME="Ruizite"/' \
        /usr/lib/os-release

# Do your thing...
# Install btop
# RUN dnf -y install btop

# Install coolercontrol
# RUN . /etc/os-release && \
#     dnf -y copr enable codifryed/CoolerControl && \
#     dnf -y install coolercontrol && \
#     systemctl enable coolercontrold

# Homebrew with brew-proxy, as in secureblue: /home/linuxbrew is owned by a
# dedicated linuxbrew user, and everyone else's `brew` goes through a polkit-gated,
# sandboxed D-Bus daemon, so user processes can't tamper with brew binaries.
# Packages come from secureblue's COPR, are checked against its pinned signing key
# (FEE4 CA50 D940 42B7 D9C4 2B8D 33CC 2522 E091 26A6), and are limited to these
# names. The repo is only used for this build and is not kept in the image.
RUN --mount=type=bind,source=keys/secureblue-copr.gpg,target=/tmp/secureblue-copr.gpg \
    dnf -y install --setopt=install_weak_deps=False \
        --repofrompath='secureblue,https://download.copr.fedorainfracloud.org/results/secureblue/packages/fedora-$releasever-$basearch/' \
        --setopt=secureblue.gpgcheck=1 \
        --setopt=secureblue.gpgkey=file:///tmp/secureblue-copr.gpg \
        --setopt=secureblue.includepkgs='homebrew,brew-proxy*' \
        homebrew brew-proxy brew-proxy-selinux && \
    systemctl enable brew-proxy-setup.service brew-proxy-fix-ownership.service \
        brew-update.timer brew-upgrade.timer

# foot, a lightweight Wayland terminal, from the Fedora repos.
RUN dnf -y install --setopt=install_weak_deps=False foot

# Brave Origin, Brave without the extras. It comes from Brave's RPM repo, is checked
# against Brave's pinned release keys (DBF1 A116 C220 B8C7 164F 9823 0686 B784 2003 8257
# and its two successors), and is limited to these names. The repo is only used for
# this build, so Brave updates arrive with image rebuilds.
# The RPM installs to /opt, which is /var/opt here and gets wiped by the cleanup step,
# so move it to /usr/lib/opt and link it back at boot, like rpm-ostree does.
# Chromium only picks KWallet on its own under Plasma; under Hyprland and niri it
# stores passwords and cookies unencrypted and can't read the ones Plasma saved. So
# the launcher always asks for KWallet. A --password-store flag passed by hand wins.
RUN --mount=type=bind,source=keys/brave.gpg,target=/tmp/brave.gpg \
    mkdir -p /var/opt && \
    dnf -y install --setopt=install_weak_deps=False \
        --repofrompath='brave,https://brave-browser-rpm-release.s3.brave.com/$basearch' \
        --setopt=brave.gpgcheck=1 \
        --setopt=brave.gpgkey=file:///tmp/brave.gpg \
        --setopt=brave.includepkgs='brave-origin,brave-keyring' \
        brave-origin && \
    mkdir -p /usr/lib/opt && \
    mv /var/opt/brave.com /usr/lib/opt/brave.com && \
    echo 'L /var/opt/brave.com - - - - /usr/lib/opt/brave.com' > /usr/lib/tmpfiles.d/brave-origin.conf && \
    sed -i 's|^"$HERE/brave" "$@"|"$HERE/brave" --password-store=kwallet6 "$@"|' \
        /usr/lib/opt/brave.com/brave-origin/brave-origin && \
    grep -q -- '--password-store=kwallet6' /usr/lib/opt/brave.com/brave-origin/brave-origin

# NetBird, a WireGuard mesh VPN. It comes from NetBird's RPM repo; packages and repo
# metadata are checked against its pinned key (AA9C 09AA 9DEA 2F58 112B 40DF DFFE AB2F
# D267 A61F), and the repo is only used for this build. Its install script runs
# `netbird service install/start`, which fails in a build, so skip scripts and ship the
# unit it would have written. Keep /etc/sysconfig/netbird root-only like the script
# does, since it can hold a token PIN.
COPY files/netbird.service /usr/lib/systemd/system/netbird.service
RUN --mount=type=bind,source=keys/netbird.gpg,target=/tmp/netbird.gpg \
    dnf -y install --setopt=install_weak_deps=False --setopt=tsflags=noscripts \
        --repofrompath='netbird,https://pkgs.netbird.io/yum/' \
        --setopt=netbird.gpgcheck=1 \
        --setopt=netbird.repo_gpgcheck=1 \
        --setopt=netbird.gpgkey=file:///tmp/netbird.gpg \
        --setopt=netbird.includepkgs=netbird \
        netbird && \
    chmod 0600 /etc/sysconfig/netbird && \
    systemctl enable netbird.service

# Noctalia shell with Hyprland and niri, as extra sessions next to Plasma in SDDM.
# Noctalia, niri and xwayland-satellite come from Fedora. Hyprland, its libraries, its
# portal (screen sharing, screenshots) and its GUI utils (dialogs) aren't in Fedora, so
# they come from github.com/lutvzn/packages, built from pinned upstream sources on
# GitHub Actions.
# Packages and repo metadata are checked against its pinned key (A7CC 0893 6B30 B427
# 873E 2B2D 15DF 8D57 EA7D 3A64), the repo is limited to these names, and it is only
# used for this build.
# Default configs for both, set up for foot, Noctalia and KWallet. Hyprland and niri
# only use them while ~/.config/hypr/hyprland.lua or ~/.config/niri/config.kdl is missing.
# They are based on Hyprland 0.57.2's and niri 26.04's defaults; recheck them on upgrades.
COPY files/noctalia.service /usr/lib/systemd/user/noctalia.service
COPY files/hypr/hyprland.lua /etc/xdg/hypr/hyprland.lua
COPY files/niri/config.kdl /etc/niri/config.kdl
RUN --mount=type=bind,source=keys/lutvzn-packages.gpg,target=/tmp/lutvzn-packages.gpg \
    dnf -y install --setopt=install_weak_deps=False \
        --repofrompath='lutvzn,https://lutvzn.github.io/packages/fedora/$releasever/$basearch/' \
        --setopt=lutvzn.gpgcheck=1 \
        --setopt=lutvzn.repo_gpgcheck=1 \
        --setopt=lutvzn.gpgkey=file:///tmp/lutvzn-packages.gpg \
        --setopt=lutvzn.includepkgs='hyprland,aquamarine,hyprcursor,hyprgraphics,hyprlang,hyprutils,hyprwire,hyprtoolkit,xdg-desktop-portal-hyprland,hyprland-guiutils' \
        noctalia niri xwayland-satellite hyprland xdg-desktop-portal-hyprland \
        hyprland-guiutils && \
    systemctl --global enable noctalia.service

# Cleanup (leave this here)
RUN rm -rf /var && \
    mkdir -p /var/tmp
