FROM i.anatase.org/anatase:stable

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

# Cleanup (leave this here)
RUN rm -rf /var && \
    mkdir -p /var/tmp
