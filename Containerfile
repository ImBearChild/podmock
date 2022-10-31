FROM registry.fedoraproject.org/fedora:36

LABEL   name="podmock" \
        version="1.0" \
        architecture="x86_64" \
        vcs-type="git" \
        vcs-url="https://github.com/imbearchild/podmock" \
        summary="mock provides an environment for building rpms." \
        maintainer="Nianqing Yao <imbearchild@outlook.com>"

RUN dnf -y --setopt=tsflags='' --setopt install_weak_deps=False update && \
    dnf -y --setopt=tsflags='' --setopt install_weak_deps=False install man qemu-user-static iproute badvpn python3-pip fedpkg rpmdevtools mock mock-core-configs && \
    dnf -y clean all

RUN mv /etc/mock /etc/mock-default && \
    mkdir /etc/mock && \
    useradd -c 'Mock Build' -G mock,wheel mockbuild && \
    echo "mockbuild ALL=(ALL)NOPASSWD:ALL" | tee -a /etc/sudoers && \
    mkdir /opt/etc && \
    cp -raT /root /opt/etc/root-default && \
    mkdir /media/workdir && \
    mkdir /media/root

COPY macros.netshared /etc/rpm/
COPY entrypoint.sh /opt/bin/entrypoint.sh
COPY qemu-binfmt-conf.sh /opt/bin/qemu-binfmt-conf.sh

VOLUME ["/var/lib/mock", "/var/cache/mock", "/etc/mock", "/root", "/media/workdir", "/media/root"]
# USER mockbuild
ENTRYPOINT ["/opt/bin/entrypoint.sh"]
