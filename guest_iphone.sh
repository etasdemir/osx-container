#!/usr/bin/env bash

sudo launchctl start usbmuxd
export PATH=/usr/local/sbin:${PATH}
sudo usbfluxd -f -r 172.17.0.1:5000