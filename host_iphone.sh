#!/usr/bin/env bash

terminal1() {
	sudo systemctl start usbmuxd
	sudo avahi-daemon
}

terminal2() {
	sudo systemctl restart usbmuxd
	sudo socat tcp-listen:5000,fork unix-connect:/var/run/usbmuxd
}

terminal3() {
	sudo usbfluxd -f -n
}

terminal1 &
terminal2 &
terminal3 &
