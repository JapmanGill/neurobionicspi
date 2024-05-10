#!/bin/bash

# Update /boot/config.txt
cat >>/boot/firmware/config.txt<< EOL
# Disable Bluetooth
dtoverlay=disable-bt

# Enable UART
dtoverlay=uart1
dtoverlay=uart3

# Enable SPI Bus
dtoverlay=spi0-1cs
dtoverlay=spi1-1cs

# Enable CAN
dtoverlay=mcp2515-can0,oscillator=16000000,interrupt=25

# Latch Switch Operation
dtoverlay=gpio-shutdown,gpio_pin=27
dtoverlay=gpio-poweroff,active_low=1,inactive_delay_ms=0
EOL

# I2C Tools
apt install i2c-tools

# Create a virtual environment
VENV_DIR="/home/pi/.venv/neurobionics"
mkdir -p "$VENV_DIR"
python -m venv "$VENV_DIR"
cat >>~/.bashrc<< EOL
source /home/pi/.venv/neurobionics/bin/activate
EOL

# CAN packages
apt install can-utils
"$VENV_DIR/bin/pip" install python-can
"$VENV_DIR/bin/pip" install canopen
"$VENV_DIR/bin/pip" install PyYAML

# Script to start CAN network
touch /usr/bin/setup-can
chmod +x /usr/bin/setup-can
cat >/usr/bin/setup-can<< EOL
#!/bin/bash
/sbin/ip link set can0 up type can bitrate 500000
ifconfig can0 txqueuelen 1000
EOL

# Script to stop CAN network
touch /usr/bin/teardown-can
chmod +x /usr/bin/teardown-can
cat >/usr/bin/teardown-can<< EOL
#!/bin/bash
/sbin/ip link set can0 down
EOL

# systemctl service for CAN
touch /usr/lib/systemd/system/can.service
cat >/usr/lib/systemd/system/can.service<< EOL
[Unit]
Description=CAN Network Socket

[Service]
Type=oneshot
ExecStart=/usr/bin/setup-can
RemainAfterExit=yes
ExecStop=/usr/bin/teardown-can

[Install]
WantedBy=multi-user.target
EOL

# Enable can.service
systemctl daemon-reload
systemctl enable can.service

# Install MSCL Library
wget https://github.com/LORD-MicroStrain/MSCL/releases/latest/download/python3-mscl_65.0.0_arm64.deb
sudo dpkg -i python3-mscl_65.0.0_arm64.deb
sudo apt install -f
sudo mv /usr/share/python3-mscl/mscl.py /usr/share/python3-mscl/_mscl.so "$VENV_DIR/lib/python3.11/site-packages"
rm -f python3-mscl_65.0.0_arm64.deb

# Reboot
reboot
