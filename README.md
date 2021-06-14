# Pantheon XDG Desktop Portals

## Building, Testing, and Installation

You'll need the following dependencies:
* libgranite-dev >= 6.0.0
* libhandy-1
* libgtk-3.0-dev
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
