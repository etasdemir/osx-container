#!/usr/bin/env bash

sudo killall usbfluxd
sudo systemctl restart usbmuxd
sudo killall socat