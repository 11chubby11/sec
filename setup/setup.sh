#https://www.raspberrypi.org/documentation/configuration/wireless/access-point-bridged.md
sudo apt update
#sudo apt upgrade -y
sudo apt install nginx
sudo rm /etc/nginx/sites-enabled/default
pip3 install https://dl.google.com/coral/python/tflite_runtime-2.1.0.post1-cp37-cp37m-linux_armv7l.whl
sudo systemctl enable --now vncserver-x11-serviced.service
sudo bash -c 'cat  >> /boot/config.txt <<EOF
hdmi_force_hotplug=1
start_x=1
gpu_mem=512
EOF'
sudo bash -c 'cat >> /etc/fstab <<EOF
/dev/sda1 /home/pi/Desktop/usb ntfs defaults,auto,users,rw,nofail 0 0
EOF'
read -p "Bridge ethernet to a wifi AP? Yes or No" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
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
    #https://w1.fi/cgit/hostap/plain/hostapd/hostapd.conf
    sudo bash -c 'cat > /etc/hostapd/hostapd.conf <<EOF
    country_code=NZ
    interface=wlan0
    bridge=br0
    ssid=SecurityCameraNetwork
    hw_mode=g
    channel=11
    macaddr_acl=0
    auth_algs=1
    wpa=2
    wpa_passphrase=password
    wpa_key_mgmt=WPA-PSK
    wpa_pairwise=TKIP
    rsn_pairwise=CCMP
    EOF'
    sudo nano /etc/hostapd/hostapd.conf
fi
