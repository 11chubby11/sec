sudo apt update
#sudo apt upgrade -y
pip3 install https://dl.google.com/coral/python/tflite_runtime-2.1.0.post1-cp37-cp37m-linux_armv7l.whl
sudo bash -c 'echo hdmi_force_hotplug=1 >> /boot/config.txt'
sudo bash -c 'cat >> /etc/fstab <<EOF
/dev/sda1 /home/pi/Desktop/usb ntfs defaults,auto,users,rw,nofail 0 0
EOF'
