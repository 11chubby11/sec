# https://raspberrypi.stackexchange.com/questions/108592/use-systemd-networkd-for-general-networking/108593#108593
# deinstall classic networking
sudo -Es
apt -y --autoremove purge ifupdown dhcpcd5 isc-dhcp-client isc-dhcp-common rsyslog
apt-mark hold ifupdown dhcpcd5 isc-dhcp-client isc-dhcp-common rsyslog raspberrypi-net-mods openresolv
rm -r /etc/network /etc/dhcp
# setup/enable systemd-resolved and systemd-networkd
apt -y --autoremove purge avahi-daemon
apt-mark hold avahi-daemon libnss-mdns
apt install libnss-resolve
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
systemctl enable systemd-networkd.service systemd-resolved.service

# https://raspberrypi.stackexchange.com/questions/88214/setting-up-a-raspberry-pi-as-an-access-point-the-easy-way
cat > /etc/wpa_supplicant/wpa_supplicant-wlan0.conf <<EOF
country=NZ
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="Camera"
    mode=2
    #frequency=2437
    #key_mgmt=WPA-PSK
    #proto=RSN WPA
    psk="password"
}
EOF
chmod 600 /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
systemctl disable wpa_supplicant.service
systemctl enable wpa_supplicant@wlan0.service
rfkill unblock 0
cat > /etc/systemd/network/02-br0.netdev <<EOF
[NetDev]
Name=br0
Kind=bridge
EOF

cat > /etc/systemd/network/04-br0_add-eth0.network <<EOF
[Match]
Name=eth0
[Network]
Bridge=br0
EOF

cat > /etc/systemd/network/12-br0_up.network <<EOF
[Match]
Name=br0
[Network]
MulticastDNS=yes
DHCP=yes
# to use static IP uncomment these and comment DHCP=yes
#Address=192.168.50.60/24
#Gateway=192.168.50.1
#DNS=84.200.69.80 1.1.1.1
EOF
systemctl edit wpa_supplicant@wlan0.service
[Service]
ExecStartPre=/sbin/iw dev %i set type __ap
ExecStartPre=/bin/ip link set %i master br0

ExecStart=
ExecStart=/sbin/wpa_supplicant -c/etc/wpa_supplicant/wpa_supplicant-%I.conf -Dnl80211,wext -i%I -bbr0

ExecStopPost=-/bin/ip link set %i nomaster
ExecStopPost=-/sbin/iw dev %i set type managed
