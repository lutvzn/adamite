![Tux beside a yellow oven baking cookies](./res/oven.png)

# Adamite

Adamite is a custom bootable image based on Anatase. You can use the same template to make your own image with different tools or desktop environments.

Anatase is a normal container image you can download from `i.anatase.org/anatase:stable` and then add your own packages. It is based on the latest version of Fedora, so anything you would install or modify on a fedora container you can do here. In this repository, you can find a template containerfile for building your own image.

Anatase also provides a base image (`i.anatase.org/base:stable`) which is the same Anatase you know with gamemode, Nvidia drivers, and everything included, but without KDE. This way, you can add your own Desktop Environment and experiment with tiling managers, Gnome, Cosmic, or anything else. The base image is built with the same tested packages as the main image so it is a perfect environment to become your own distribution builder and learn about containers.

## Using the template
To customize Adamite, clone this repository:
```bash
git clone https://github.com/lutvzn/adamite.git
cd adamite
```

To start from stock Anatase instead, use the [upstream template](https://github.com/anatase-org/template).

Then, customize `Containerfile` to your liking. When done, if on an Anatase system, you can run `./update.sh` from the terminal to update to that image and run it again periodically to access the latest versions. Do not run `./update.sh` in Spaces. If your IDE is in a Space, open the folder using a host terminal and run it there.

### On Github actions
A [build.yml](./.github/workflows/build.yml) Github workflow is provided that allows you to go to your fork, select `Actions > Build Custom Image > Run Workflow`. This will build the image and upload it under `ghcr.io/<your-username>/adamite`.

Then, you can switch to it with:
```bash
sudo bootc switch ghcr.io/<your-username>/adamite
```

If you already track the previous image name, switch to this reference once the new image is published. `bootc update` does not change the image reference.

Afterwards, the automatic updater will pick it up and handle updates for you, or you can manually do `sudo bootc update`.

You can edit [build.yml](./.github/workflows/build.yml) to switch `adamite` to something else, enable build on pushes, and run the workflow on a schedule.

> [!NOTE]
> **Remember:** use `FROM i.anatase.org/base:stable` when you want to use a different Desktop Environment. To extend Anatase, use `FROM i.anatase.org/anatase:stable` 

## Examples

In the [`./examples`](./examples/) folder, you will find Containerfiles for inspiration, such as ones for Gnome and Cosmic. Feel free to experiment and then PR new examples as well!

## OS name

Adamite shows up as "Adamite" in System Settings and tools like `fastfetch`. Existing boot entries can still say Anatase. Only `NAME` and `PRETTY_NAME` in `/usr/lib/os-release` change. `ID=anatase` and the other fields stay as they are, so anything that checks for Anatase, including Steam and the updater, still works.

## Homebrew (brew-proxy)

Adamite ships [Homebrew](https://brew.sh/) with [brew-proxy](https://codeberg.org/HastD/brew-proxy), set up the same way as [secureblue](https://secureblue.dev). The packages come from secureblue's COPR and are checked against its pinned signing key in [`keys/`](./keys/).

`/home/linuxbrew` belongs to a dedicated `linuxbrew` user. When you run `brew`, the command is passed to a sandboxed daemon that runs as that user, so your own processes can't change brew's binaries:

- Read-only commands (`brew list`, `brew info`, `brew search`) work for everyone.
- `brew update`, `brew upgrade` and `brew cleanup` ask for admin authentication. They don't ask if you're in the `brewadmin` group (`sudo usermod -aG brewadmin $USER`).
- `brew install` and `brew uninstall` always ask for admin authentication. For several changes in a row, use `run0 -u linuxbrew`.

Brew is set up on first boot. `brew-update.timer` and `brew-upgrade.timer` keep it updated automatically.

## Extra apps

Adamite also ships:

- [foot](https://codeberg.org/dnkl/foot), a lightweight Wayland terminal, from the Fedora repos.
- [Brave Origin](https://brave.com/origin/linux/), from Brave's RPM repo, checked against Brave's release keys in [`keys/`](./keys/). It updates with the image, not through `dnf`. It always uses KWallet, so saved passwords and logins carry over between Plasma and the Noctalia sessions.
- `ffmpeg` and `ffprobe` with H.264 and H.265 encoding (x264, x265), AV1, VP9 and Opus, and VA-API, NVENC and Vulkan hardware acceleration. Fedora's own build leaves out H.264 and H.265, so this one comes from [lutvzn/packages](https://github.com/lutvzn/packages), checked against its key in [`keys/`](./keys/). Its libraries are a private copy that only those two programs use, so Anatase's own ffmpeg libraries are unchanged.
- [NetBird](https://netbird.io/), a WireGuard mesh VPN client, from NetBird's RPM repo, checked against its key in [`keys/`](./keys/). `netbird.service` is enabled, so you only need to run `netbird up` to join your network. Settings such as a self-hosted management URL go in `/etc/sysconfig/netbird`. The GTK tray app (`netbird-ui`) is not included.

## Noctalia, Hyprland, niri, Sway and labwc

Adamite adds four sessions next to Plasma in the login screen: Hyprland, niri, Sway and labwc, all running the [Noctalia](https://noctalia.dev) shell. Plasma stays the default and is unchanged.

- Noctalia, niri, xwayland-satellite, Sway, labwc and xdg-desktop-portal-wlr (screen sharing and screenshots under Sway and labwc) come from the Fedora repos. Sway and labwc reuse the wlroots library that's already in the image, so together they add about 2 MB.
- Hyprland, its libraries, xdg-desktop-portal-hyprland (screen sharing and screenshots under Hyprland) and hyprland-guiutils (its dialogs and run prompt) aren't in Fedora. They come from [lutvzn/packages](https://github.com/lutvzn/packages), which builds them from pinned upstream sources on GitHub Actions. The image checks them against that repo's key in [`keys/`](./keys/) instead of using someone else's COPR. That build leaves out hyprpm (plugins) and Hyprland's 48 MB of default wallpapers.
- `noctalia.service` starts Noctalia with Hyprland and niri, so you can keep using their own default configs. It never starts in Plasma. If your own config also starts `noctalia`, the service skips itself.
- Sway and labwc don't start a systemd session, so Adamite's default configs for them start Noctalia themselves. Keep that line if you write your own config.

Each session starts with Adamite's default config: [`/etc/xdg/hypr/hyprland.lua`](./files/hypr/hyprland.lua), [`/etc/niri/config.kdl`](./files/niri/config.kdl), [`/etc/sway/config`](./files/sway/config), and [`/etc/xdg/labwc/rc.xml`](./files/labwc/rc.xml) with [`autostart`](./files/labwc/autostart). They are the upstream defaults with these changes:

- foot as the terminal (Super+Q in Hyprland, Super+T in niri, Super+Enter in Sway and labwc) and Noctalia's launcher (Super+R in Hyprland, Super+D in niri and Sway, tapping Super in labwc).
- KWallet unlocks with your login password, as in Plasma, so Brave and other apps find their saved passwords.
- Volume, brightness and media keys, screenshots and locking go through Noctalia.
- Sway has no swaybar and no default wallpaper, since Noctalia provides both. Super+Shift+E opens Noctalia's session menu instead of Sway's exit prompt.
- In Hyprland, Sway and labwc, Noctalia's colours apply once you enable that compositor's template in Noctalia's settings. Sway picks them up on reload (Super+Shift+C) and labwc after `labwc -r`.

To customize them, copy them to `~/.config/hypr/hyprland.lua`, `~/.config/niri/config.kdl`, `~/.config/sway/config` or `~/.config/labwc/` and edit the copy. From then on, image updates no longer change your config. labwc looks up `rc.xml` and `autostart` separately, so copying only `rc.xml` keeps Adamite's autostart. When a compositor is updated, compare your copy with the new default, since config formats change between releases.

## Frequently Asked Questions
The base image does not include a "Return to Gamemode" shortcut or autologin
settings in Handheld Daemon as they are KDE specific. You can configure your Desktop Environment to autologin to "Gamemode" instead.

Gnome supports selecting a session only if you have a password set (gear on the bottom right), otherwise it automatically logs in and blocks you from accessing the button. This is a Gnome issue.

Anatase uses kwallet for secret management. When you switch desktop environments you will lose your secrets, such as various logins in browsers and your IDE credentials (VS Code uses it for your Github login). The examples use the new secret manager oo7, but it is not ready for KDE at this time. This means you can switch through them without losing your secrets.

Lightdm (the Greeter used by Cinnamon and XFCE) does not respect the panel rotation reported by the kernel, so the Steam Deck has the login screen rotated 90 degrees (other portrait panels as well). They also do not associate the touchscreen correctly, so rotating the screen breaks the touchscreen. It does not re-initialize properly when exiting gamemode so you will get a black screen (PRs welcome if you fix it). Without a virtual keyboard, you cannot log in on handhelds.

Cosmic's first boot dialog does not scale properly on handhelds, so you will not be able to complete it without an external display.

**You can rebase between desktop environments arbitrarily, without reinstalling, and face minimal issues (other than losing your secrets).** If you face any issues when rebasing back to KDE, you can open an issue in this repository.