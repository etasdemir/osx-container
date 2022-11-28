# Welcome to OSX-Container!

Run MacOS in a docker container using QEMU. Read/Write on a shared volume, adjustable resolution to match the QEMU window (scales up to 4096x2160), mount usb, build & install apps to iphone from XCode.

## Installation
```
sudo mkdir /mnt/MacosShared
sudo chmod 777 /mnt/MacosShared
```
If you want to build yourself:  
``docker build -t imageName:tagName .``

Alternatively, get from docker hub:  
  
[![https://img.shields.io/docker/image-size/etasdemir/osx-container/ventura?label=etasdemir%2Fosx-container%3Aventura](https://img.shields.io/docker/image-size/etasdemir/osx-container/ventura?label=etasdemir%2Fosx-container%3Aventura)](https://hub.docker.com/r/etasdemir/osx-container/tags?page=1&ordering=last_updated)  
  

### Run
```
docker run -it \
	--name macos-container \
    --device /dev/kvm \
    -p 50922:10022 \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -e "DISPLAY=${DISPLAY:-:0.0}" \
	-e "RAM=18" \
	-e "CORES=2" \
	-e "THREADS=4" \
    -v /mnt/MacosShared:/mnt/MacosShared \
    etasdemir/osx-container:ventura
```


## Read/Write Shared Volume
On guest machine:
```
sudo mount_9p MacosShared
sudo chmod 777 /Volumes/MacosShared
```
Note: After writing to a file from MacOS, you can not update the same file because of file permission. Probably because of UIDs. Host Linux (uid 1000) => Ubuntu (inside docker, uid 1000) => MacOS (uid 501).
We need to change macos user id to 1000. Inside MacOS:
```
NOTE: Don't do this while logged in as user that is UID to be changed.
enable root user
login as root
dscl . -change /Users/${USER} UniqueID 501 1000
find -xP / -user 501 -print0 | xargs -0 chown -h 1000
```
Note: For some reason MacOS sees volume's capacity 0 byte.

## USB Redirect

usbredir is required. For archlinux you can use usbredirect.
```
1. lsusb to get vid:pid
2. sudo usbredirect --device {vid:pid} --as 172.17.0.1:7700 => note: --to is for client, --as for usb redirect server.
3. qemu console (press enter on interactive qemu shell)
4. chardev-add socket,id=redirectedusb,port=7700,host=172.17.0.1
5. device_add usb-redir,chardev=redirectedusb,id=redirectedusb,debug=4
6. to remove usb device = device_del redirectedusb
```

## Iphone Redirect

On host machine install (archlinux):
```
sudo pacman -S libusbmuxd usbmuxd avahi socat
```
On guest machine install (brew):
```
brew install make automake autoconf libtool pkg-config gcc libimobiledevice usbmuxd
git clone https://github.com/corellium/usbfluxd.git
cd usbfluxd
./autogen.sh
make
sudo make install
```
Host run:
```
Terminal 1:
	sudo systemctl start usbmuxd
	sudo avahi-daemon
Terminal 2:
	sudo systemctl restart usbmuxd
	sudo socat tcp-listen:5000,fork unix-connect:/var/run/usbmuxd
Terminal 3:
	sudo usbfluxd -f -n
```
or ``./host_iphone.sh``

Guest run:
```
sudo launchctl start usbmuxd
export PATH=/usr/local/sbin:${PATH}
sudo usbfluxd -f -r 172.17.0.1:5000
```
or ``./guest_iphone.sh``
restart xcode

to finish: 
```
sudo killall usbfluxd
sudo systemctl restart usbmuxd
sudo killall socat
```
or ``./kill_host_iphone.sh``

## Enable IOMMU for better GPU performance

Boot into your firmware settings, and turn on AMD-V/VT-x, as well as iommu (also called AMD-Vi, VT-d, or SR-IOV).  
The iommu kernel module is not enabled by default, but you can enable it on boot by passing the following flags to the kernel.  
AMD: iommu=pt amd_iommu=on  
Intel: iommu=pt intel_iommu=on  
To do this permanently, you can add it to your bootloader. If you're using GRUB, for example, edit /etc/default/grub and add the previous lines to the GRUB_CMDLINE_LINUX_DEFAULT section, then run sudo update-grub (or sudo grub-mkconfig on some systems) and reboot.  
Check if IOMMU enabled: dmesg | grep IOMMU => prints DMAR: IOMMU enabled  

## Special Thanks

https://github.com/sickcodes/Docker-OSX  
https://github.com/kholia/OSX-KVM/  
https://github.com/Leoyzen/KVM-Opencore  
https://github.com/thenickdude/KVM-Opencore/  
https://github.com/qemu/qemu/blob/master/docs/usb2.txt 
