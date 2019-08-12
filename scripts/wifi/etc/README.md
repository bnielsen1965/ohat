Installation should place static settings files in /etc

- /etc/default/dnsmasq
- /etc/default/hostapd

Scripts should manipulate dynamic seettings files in /etc

- /etc/default/isc-dhcp-server # modified by scripts/rpi-otg-ethernet-host/scripts/isc-dhcp-subnet.sh
- /etc/dhcp/dhcpd.conf # modified by scripts/rpi-otg-ethernet-host/scripts/isc-dhcp-subnet.sh
- /etc/dnsmasq.conf # need to create script
- /etc/hostapd/hostapd.conf # need to create script
