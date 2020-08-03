#https://www.raspberrypi.org/documentation/configuration/wireless/access-point-bridged.md

sudo apt install hostapd
sudo systemctl unmask hostapd
sudo systemctl enable hostapd

sudo bash -c 'cat > /etc/systemd/network/bridge-br0.netdev <<EOF
[NetDev]
Name=br0
Kind=bridge
EOF'

sudo bash -c 'cat > /etc/systemd/network/br0-member-eth0.network <<EOF
[Match]
Name=eth0
[Network]
Bridge=br0
EOF'

sudo systemctl enable systemd-networkd

sudo sed -i '1s/^/denyinterfaces wlan0 eth0\n/' /etc/dhcpcd.conf

sudo echo interface br0 >> /etc/dhcpcd.conf

sudo rfkill unblock wlan

sudo bash -c 'cat > /etc/hostapd/hostapd.conf <<EOF
country_code=NZ
interface=wlan0
bridge=br0
ssid=SecurityCameraNetwork
hw_mode=g
channel=7
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=password
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOF'

sudo systemctl reboot
