# AGENTS.md

Guidance for AI coding agents (and humans) working on **Adamite**.

## What Adamite is

Adamite is a custom Linux image built on top of [Anatase](https://anatase.org).
It is a fork of the upstream Anatase image template
(`github.com/anatase-org/template`): a bootable container image (bootc) built
from a `Containerfile`, starting `FROM` an Anatase image:

- `i.anatase.org/anatase:stable`: full Anatase (KDE). Use this to extend Anatase.
- `i.anatase.org/base:stable`: Anatase without a desktop. Use this to bring a different DE/WM.

Anatase itself tracks the latest Fedora, so anything that works in a Fedora
container generally works here.

## Repository layout

| Path | Purpose |
|------|---------|
| `Containerfile` | The Adamite image definition. |
| `examples/` | Alternative desktop Containerfiles (GNOME, Cosmic, Cinnamon, XFCE, Niri). |
| `update.sh` | Local build + `bootc switch` to the built image. Runs as root and changes the running system. |
| `.github/workflows/build.yml` | CI build and push to GHCR. Only rebuilds when the Anatase version or the commit changes. |
| `readme.md` | User-facing docs. |

## Core goals

Every change should serve these three goals, in this order of priority when they conflict:

### 1. Security
- Only install packages from Fedora repos or the repos Anatase already ships. Treat every new COPR, third-party repo, or `curl | sh` as a risk: justify it, pin it where possible, and point it out to the user.
- Never weaken system defaults: SELinux stays enforcing, the firewall stays on, and no broad `chmod`/`chown` on system paths. Don't disable signature checks (`gpgcheck=0`, `--nogpgcheck`, `--no-verify`).
- Don't bake secrets, tokens, keys, or user-specific data into the image. Everything in the image is public once it's pushed to GHCR.
- CI: keep `permissions:` minimal, pass secrets through `env:` rather than inlining them in commands, and prefer pinned actions.
- Prefer services that are off by default. Only `systemctl enable` what the image actually needs.

### 2. Performance
- Keep the image small: use `--setopt=install_weak_deps=False`, avoid pulling in whole groups when a few packages will do, and don't add packages that duplicate something Anatase already provides.
- Keep layers few and the cache useful. Group related `dnf install` calls, and put things that change often late in the file.
- Don't add background daemons, timers, or polling services unless they're necessary.
- Keep the CI "skip if unchanged" logic (version/commit labels) working so builds don't run when nothing changed.

### 3. Simplicity
- Prefer a short, readable `Containerfile` over clever scripting. One clear purpose per `RUN` block, with a comment explaining *why*.
- Don't add build systems, frameworks, or extra tooling when a plain shell line will do.
- Keep the template's structure, so anyone familiar with Anatase can read Adamite at a glance.
- Remove dead code and stale comments rather than piling on more.

## Upstream compatibility (important)

Adamite must stay a **drop-in compatible** Anatase derivative. Users should be
able to `bootc switch` between Anatase and Adamite (and between the examples) without reinstalling,
and it should stay easy to merge upstream template changes.

**Do not change these without explicitly warning the user first:**

- The `FROM` image or tag (e.g. switching `stable` to `rolling`, or moving off `i.anatase.org`).
- The final cleanup step (`rm -rf /var && mkdir -p /var/tmp`). It must stay the last step, because bootc relies on it.
- Removing or replacing packages, services, or config that Anatase ships (KDE, kwallet, Handheld Daemon, gamemode, Nvidia drivers, the updater, etc.).
- Changes to `/etc` defaults, `/usr/lib` systemd units, PAM, the bootloader, kernel args, or the kernel, because they can break rebasing back to upstream.
- Changing the secret manager (kwallet vs. oo7), since users lose stored secrets when switching.
- Changes to the CI image labels (`org.anatase.version`, `org.opencontainers.image.*`) or the version/commit skip logic.
- Restructuring files that upstream also has (`Containerfile`, `update.sh`, `build.yml`, `readme.md`) in ways that make future upstream merges painful.

**How to warn:** before making the change, state clearly:

> ⚠️ **Upstream compatibility:** _what_ changes, _why_ it may break compatibility
> with Anatase (rebasing, updates, or upstream merges), and a safer alternative if one exists.

Then wait for the user to confirm. If unsure whether something affects compatibility, assume it does and warn.

## Working rules for agents

- **Never run `update.sh`** or `bootc switch`/`bootc update` on your own. They modify the host system and need root. Tell the user the command instead. Never run it inside a Space/container either.
- To check a change without deploying it, a plain build is enough:
  `podman build --pull=always -f Containerfile -t localhost/adamite-test .`
- Keep examples self-contained and consistent with each other (same cleanup step, same `install_weak_deps=False` style).
- Keep docs in sync. If behavior changes, update `readme.md` in the same change.
- Keep commits small and focused, with messages in the imperative mood (matching the existing history).
