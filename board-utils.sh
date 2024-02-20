#!/bin/bash

# Update /boot/config.txt
cat >>/boot/config.txt<< EOL
# Enable SPI Bus
dtparam=spi=on"
dtoverlay=spi0-1cs
dtoverlay=spi1-1cs
# Enable CAN
dtoverlay=mcp2515-can0,oscillator=16000000,interrupt=25
# Latch Switch Operation
dtoverlay=gpio-shutdown,gpio_pin=27
dtoverlay=gpio-poweroff,active_low=1,inactive_delay_ms=0
EOL

# CAN packages
apt install can-utils
pip install python-can
pip install canopen
pip install PyYAML

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

# Reboot
reboot
