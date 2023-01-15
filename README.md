# Pantheon XDG Desktop Portals
[![Translation status](https://l10n.elementary.io/widgets/desktop/-/portals/svg-badge.svg)](https://l10n.elementary.io/engage/desktop/)

## Building, Testing, and Installation

You'll need the following dependencies:
* libgranite-7-dev
* gtk4
* libvte-2.91-dev
* meson
* valac

Run `meson` to configure the build environment and then `ninja test` to build and run tests

    meson build --prefix=/usr
    cd build
    ninja test

To install, use `ninja install`, then execute with `/usr/libexec/xdg-desktop-portal-pantheon -r`

    sudo ninja install
    /usr/libexec/xdg-desktop-portal-pantheon -r
