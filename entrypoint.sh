#!/bin/bash

#ProgName=$(basename $0)
ProgName="podman imbearchild/podmock"


sub_echo(){
    if tty > /dev/null 2>&1 ; then
        echo "$@"
    fi
}

sub_init(){
    if tty > /dev/null 2>&1 ; then
        sub_echo "[PodMock] Pseudo-TTY detected, entering interactive shell"
    else
        :;
    fi
    if [ $(find /etc/mock -maxdepth 0 -empty | wc -l) != 0 ]; then
        sub_echo "[PodMock] /etc/mock is empty, populating it with default configs."
        cp -raT /etc/mock-default /etc/mock
    fi
    if [ $(find /root -maxdepth 0 -empty | wc -l) != 0 ]; then
        sub_echo "[PodMock] /root is empty, populating it with default files."
        cp -raT /opt/etc/root-default /root
    fi
    if [ -z "$socks_proxy" ]; then
        :;
        # sub_echo "[PodMock] socks_proxy is blank";
    else
        sub_echo "[PodMock] socks_proxy is set to '$socks_proxy'";
        sub_tun2socks
    fi
}


sub_bash(){
    sub_init
    cd /media/workdir
    exec /usr/bin/bash "$@"
}


sub_mock(){
    sub_init
    cd /media/workdir
    exec /usr/bin/mock "$@"
}

sub_binfmt(){
    /opt/bin/qemu-binfmt-conf.sh --qemu-path=/usr/bin --qemu-suffix=-static --persistent yes
}

sub_tun2socks(){
    IP_AND_PORT=${socks_proxy#*socks://}
    if [[ $IP_AND_PORT == 127.0.0.1* ]]; then
        IP_AND_PORT=${IP_AND_PORT/127.0.0.1/10.0.2.2}
    fi
    sub_echo "[PodMock] setting up badvpn-tun2socks to $IP_AND_PORT"
    # Add tun device
    ip tuntap add mode tun dev tun0
    ip addr add 10.0.114.1/24 dev tun0
    ip link set dev tun0 up
    # Add route
    ip route del default
    ip route add default via 10.0.114.1 dev tun0 metric 1
    ip route add default via 10.0.2.2 dev tap0 metric 10
    nohup badvpn-tun2socks --tundev tun0 --netif-ipaddr 10.0.114.2 --netif-netmask 255.255.255.0 \
        --socks-server-addr $IP_AND_PORT > /tmp/tun2socks.log 2>&1 &
    unset socks_proxy
    unset IP_AND_PORT
    # Fix dns issue
    echo "options use-vc" | tee /etc/resolv.conf > /dev/null
    echo "nameserver 1.1.1.1" | tee -a /etc/resolv.conf > /dev/null
}


sub_help(){
    echo "Usage: $ProgName <subcommand> [options]"
    echo ""
    echo "Subcommands:"
    echo "    bash         run bash"
    echo "    mock         run mock"
    echo "    binfmt       configure binfmt_misc to use qemu interpreter"
    echo "    tun2socks    configure badvpn-tun2socks"
    echo ""
    #echo "For help with each subcommand run:"
    #echo "$ProgName <subcommand> -h|--help"
    #echo ""
}


subcommand=$1
case $subcommand in
    "" | "-h" | "--help")
        sub_help
        ;;
    *)
        shift
        sub_${subcommand} "$@"
        if [ $? = 127 ]; then
            echo "Error: '$subcommand' is not a known subcommand." >&2
            echo "       Run '$ProgName --help' for a list of known subcommands." >&2
            exit 1
        fi
        ;;
esac
