#!/bin/sh

# Steam Big Picture First time setup needs a couple of services

mkdir -p /run/dbus
dbus-daemon --system --fork --nosyslog
echo "*** DBus started ***"
bluetoothd --nodetach &
echo "*** Bluez started ***"
NetworkManager
echo "*** NetworkManager started ***"
# Watchdog will stop steam when selecting Turn off, Suspend or Restart from the Steam power menu
steamos-dbus-watchdog.sh &
echo "*** D-Bus Watchdog started ***"

# Run Decky Loader's Plugin Loader, if exists
if [ -f /home/retro/homebrew/services/PluginLoader ]; then
    /home/retro/homebrew/services/PluginLoader &
    echo "*** Decky Loader Plugin Loader started ***"
fi

disown
