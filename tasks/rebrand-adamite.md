# Rebrand Adamite without forking Anatase

Keep Adamite a bootc derivative of `i.anatase.org/anatase:stable`. The image currently changes only `NAME` and `PRETTY_NAME`; the installed boot entries can still say Anatase, and Fastfetch shows `OS: Adamite` next to Anatase art.

## Scope

- [ ] Create original Adamite artwork. Replace the About System and launcher icons, Plasma theme and login splash, wallpapers, and Fastfetch art. Check for other visible marks, including Steam's update screen and the Anatase Browser and Konsole entries. Keep upstream attribution distinct from Adamite branding.
- [ ] Replace the Plymouth watermark and fallback logo. Investigate how the boot entry title is generated and verify a new Adamite deployment shows the right title without relabeling a stock Anatase rollback entry.
- [ ] Update `LOGO` and user-facing homepage, docs, support, and issue links where Adamite has real destinations. Retain `ID=anatase`, `VARIANT_ID=anatase`, and the Steam-facing codename unless a separate compatibility review warrants changing them. Leave the updater and signing policy intact.

## Public release gate

- [ ] Ask Anatase for written permission to redistribute the inherited artwork or for an unbranded base. See the [Anatase logo license](https://github.com/anatase-org/anatase/blob/master/cards/base/identity/COPYING).
- [ ] If neither is available and staying on the current base, remove restricted artwork from the final filesystem and ensure it is absent from the published layers, including copies embedded in boot assets where applicable. CI's `--squash` keeps inherited layers; evaluate [`--squash-all`](https://docs.podman.io/en/latest/markdown/podman-build.1.html#squash-all) and its effect on update downloads. Inspect the release candidate's actual OCI layers before publishing.

## Acceptance

- [ ] Obtain approval before replacing Anatase-shipped packages or changing boot or system defaults, as required by `AGENTS.md`.
- [ ] Build a test image and verify the visible branding in a VM or on a disposable test system. Exercise `bootc` update, rollback, and switching back to stock Anatase; check Steam and the updater still work.
- [ ] Update `readme.md` to describe the verified behavior and remaining upstream identity.
