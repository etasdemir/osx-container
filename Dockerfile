#!/usr/bin/docker

FROM ubuntu:latest
SHELL ["/bin/bash", "-c"]

ARG SHORTNAME=ventura
ARG SIZE=225G
ENV DISPLAY=:0.0
ENV RAM=16
ENV CORES=2
ENV THREADS=4
ENV EXTRA=

RUN apt-get update
RUN apt-get install -y qemu alsa-utils uml-utilities virt-manager git wget libguestfs-tools p7zip-full make dmg2img sudo
RUN useradd user -p user \
    && tee -a /etc/sudoers <<< "user ALL=(ALL) NOPASSWD:ALL" \
    && mkdir /home/user \
    && chown user:user /home/user
RUN usermod -aG kvm user \
    && usermod -aG libvirt user \
    && usermod -aG input user
USER user
WORKDIR /home/user
RUN id user 
RUN git clone --depth 1 --recursive https://github.com/kholia/OSX-KVM.git
WORKDIR /home/user/OSX-KVM
RUN sudo cp kvm.conf /etc/modprobe.d/kvm.conf
RUN ./fetch-macOS-v2.py -s "${SHORTNAME}"
RUN dmg2img -i BaseSystem.dmg BaseSystem.img && rm BaseSystem.dmg
RUN qemu-img create -f qcow2 mac_hdd_ng.img "${SIZE}"

COPY Launch.sh /home/user/OSX-KVM/Launch.sh
RUN sudo chmod +x /home/user/OSX-KVM/Launch.sh
CMD /home/user/OSX-KVM/Launch.sh "${RAM}" "${CORES}" "${THREADS}" "${EXTRA}"
