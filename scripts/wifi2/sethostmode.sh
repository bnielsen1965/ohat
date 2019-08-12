#!/bin/bash



# display usage help
function Usage()
{
cat <<-ENDOFMESSAGE
$PACKAGE - Set WiFi interface host mode.

Used to enable or disable the host mode for the WiFi interface. Host mode is used
configure the WiFi interface as an Access Point with a captured portal. This script
is used to configure and enable the Access Point for host mode or de-congigure and
disable the Access Point.


$PACKAGE mode interface [subnet] [ssid] [psk] [channel]
  arguments:
  mode - the mode to set (enable | disable)
  interface - interface to use
  subnet - subnet used on interface when enabling
  ssid - access point ssid on interface when enabling
  psk - access point passphrase when enabling
  channel - WiFi channel to use when enabling
ENDOFMESSAGE
  exit
}

# die with message
function Die()
{
  echo "$*"
  Usage
  exit 1
}



function DisableHost ()
{
  local interface="$1"
  local address="$(./staticip.sh get $interface)"
  if [ ! -z "$address" ]; then
    ./staticip.sh clear $interface
    # TODO regex needs to work with multi-digit last octet
    ./isc-dhcp-subnet.sh remove "${address%\.[0-9]}.0 $interface"
  fi
  systemctl daemon-reload
  systemctl restart isc-dhcp-server
  systemctl stop dnsmasq
  systemctl disable dnsmasq
  systemctl stop hostapd
  systemctl disable hostapd
  systemctl restart dhcpcd
}

function EnableHost ()
{
  local interface="$1"
  local subnet="$2"
  local ssid="$3"
  local psk="$4"
  local channel="$5"

  #configure static interface
  ./staticip.sh set "$interface ${subnet%\.[0-9]}.1"
  # configure dhcp server
  # configure hostapd and dnsmasq
}

function EnableHostServices ()
{
  local interface="$1"
  local subnet="$2"
  local ssid="$3"
  local psk="$4"
  local channel="$5"

  #configure static interface
  # configure dhcp server
  # configure hostapd and dnsmasq
  ./scripts/wifihostap.sh "$subnet" "$interface" "$ssid" "$psk" "$channel"

  systemctl unmask hostapd
  systemctl enable hostapd
  systemctl start hostapd
  systemctl enable dnsmasq
  systemctl start dnsmasq
  InsertDHCPService "$subnet" "$interface"
  systemctl restart isc-dhcp-server
}

function RemoveDHCPService ()
{
  local subnet="$1"
  local interface="$2"
  # TODO consider moving dhcp script to common location or dupe
  ../rpi-otg-ethernet-host/scripts/isc-dhcp-subnet.sh remove "$subnet" "$interface"
}

function InsertDHCPService ()
{
  local subnet="$1"
  local interface="$2"
  # TODO consider moving dhcp script to common location or dupe
  ../rpi-otg-ethernet-host/scripts/isc-dhcp-subnet.sh create "$subnet" "$interface"
}




MODE="$1"
INTERFACE="$2"

if [ -z "$MODE" ]; then
  Die "Must specify the mode"
fi

if [ -z "$INTERFACE" ]; then
  Die "Must specify the interface"
fi


SUBNET="$3"
SSID="$4"
PSK="$5"
CHANNEL="$6"

OLD_PATH="$(pwd)"
cd "$(dirname "$0")"

case ${MODE} in
  "disable")
  DisableHost "$INTERFACE"
  ;;
  "guest")
  WiFiGuest "$SUBNET" "$INTERFACE" "$SSID" "$PSK"
  ;;
  "host")
  WiFiHost "$SUBNET" "$INTERFACE" "$SSID" "$PSK" "$CHANNEL"
  ;;
  *)
  cd "$OLD_PATH"
  Die "Unknown mode $MODE"
  ;;
esac

cd "$OLD_PATH"
