sudo apt update
#sudo apt upgrade -y
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
