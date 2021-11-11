# Demo for Pantheon XDG Desktop Portals

A demo application to test pantheon xdg desktop portals.

## Dependencies

You'll need the following dependencies to successfully build the demo application:

    sudo apt install elementary-sdk
    flatpak install --user --assumeyes appcenter io.elementary.Platform io.elementary.Sdk

## Install

Run `flatpak-builder` to build and install the application:

    flatpak-builder build demo/io.elementary.portals.demo.yml --user --install --force-clean

## Run

To start the demo application, execute the following:

    flatpak run io.elementary.portals.demo

**IMPORTANT:** Make sure xdg-desktop-portal running, otherwise
this demo app won't work as expected:

    /usr/libexec/xdg-desktop-portal -r

## Uninstall

Run the `flatpak` command to remove the application once your done with testing:

    flatpak uninstall --user io.elementary.portals.demo
