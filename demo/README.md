# Demo for Pantheon XDG Desktop Portals

A demo application to test pantheon xdg desktop portals.

## Dependencies

You'll need the following dependencies to successfully build the demo application:

    sudo apt install elementary-sdk
    flatpak install --user --assumeyes appcenter io.elementary.Platform io.elementary.Sdk

## Install

Run `flatpak-builder` to build and install the application:

    flatpak-builder build io.elementary.portals.demo.yml --user --install --force-clean

## Run

To start the demo application, execute the following:

    flatpak run io.elementary.portals.demo

## Uninstall

Run the `flatpak` command to remove the application once your done with testing:

    flatpak uninstall --user io.elementary.portals.demo
