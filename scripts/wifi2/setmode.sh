#!/bin/bash

# set the mode in which the wifi should operate

WIFI_INTERFACE="wlan0"



# display usage help
function Usage()
{
cat <<-ENDOFMESSAGE
$PACKAGE - Set WiFi operational mode.

Used to set the operation mode for the WiFi ${WIFI_INTERFACE} interface. The WiFi
interface can be in one of three modes, off, guest, or host. In the off mode the
interface will be turned off to conserve power. In guest mode it will turn on and
attempt to connect to the configured host AP. And in host mode it will be on and
running as an Access Point with a captured portal configuration.

$PACKAGE mode subnet interface [ssid] [psk]
  arguments:
  mode - the mode to set (off | guest | host)
  subnet - subnet used on interface
  interface - interface to use
  ssid - access point ssid
  psk - access point passphrase

  modes:
  off - Disable wifi and services associated with the wifi interface. Requires current
  wifi subnet setting and interface name.

  guest - Enable wifi in guest mode and connect to the specified access point. Requires
  current sifi subnet setting, interface name, ssid of the target access point and
  the passphrase of the target access point.

  host - Enable wifi in hostap mode. Requires the subnet to use for host, wifi interface
  name, ssid name to use for hostap, passphrase for hostap, and wifi channel to use.
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


# configure wifi for off mode
function WiFiOff ()
{
  # disable host settings

  #disable guest settings

  # rfkill block wifi
  
  local subnet="$1"
  local interface="$2"
  if [ -z "$subnet" ]; then
    Die "Missing subnet"
  fi
  if [ -z "$interface" ]; then
    Die "Missing interface"
  fi
  DisableHostServices "$subnet" "$interface"
  DisableGuestServices
  rfkill block wifi
}

# configure wifi for guest mode
function WiFiGuest ()
{
  local subnet="$1"
  local interface="$2"
  local ssid="$3"
  local psk="$4"
  if [ -z "$subnet" ]; then
    Die "Missing subnet"
  fi
  if [ -z "$interface" ]; then
    Die "Missing interface"
  fi
  if [ -z "$ssid" ]; then
    Die "Missing ssid"
  fi
  if [ -z "$psk" ]; then
    Die "Missing passphrase"
  fi
  DisableHostServices "$subnet" "$interface"
  rfkill unblock wifi
  EnableGuestServices "$interface" "$ssid" "$psk"
}

# configure wifi for host mode
function WiFiHost ()
{
  local subnet="$1"
  local interface="$2"
  local ssid="$3"
  local psk="$4"
  local channel="$5"
  if [ -z "$subnet" ]; then
    Die "Missing subnet"
  fi
  if [ -z "$interface" ]; then
    Die "Missing interface"
  fi
  if [ -z "$ssid" ]; then
    Die "Missing ssid"
  fi
  if [ -z "$psk" ]; then
    Die "Missing passphrase"
  fi
  if [ -z "$channel" ]; then
    Die "Missing channel"
  fi
  DisableGuestServices
  rfkill unblock wifi
  EnableHostServices "$subnet" "$interface" "$ssid" "$psk" "$channel"
}


function DisableGuestServices ()
{
  ./scripts/wpasupplicant.sh clear
  systemctl stop wpa_supplicant
  systemctl disable wpa_supplicant
}

function EnableGuestServices ()
{
  local interface="$1"
  local ssid="$2"
  local psk="$3"
  ./scripts/wpasupplicant.sh set "$ssid" "$psk"
  systemctl enable wpa_supplicant
  systemctl start wpa_supplicant
  ip link set "$interface" up
  wpa_supplicant -B -Dwext -i "$interface" -c /etc/wpa_supplicant/wpa_supplicant.conf
}


function DisableHostServices ()
{
  local subnet="$1"
  local interface="$2"
  RemoveDHCPService "$subnet" "$interface"
  systemctl restart isc-dhcp-server
  systemctl stop dnsmasq
  systemctl disable dnsmasq
  systemctl stop hostapd
  systemctl disable hostapd
}

function EnableHostServices ()
{
  local subnet="$1"
  local interface="$2"
  local ssid="$3"
  local psk="$4"
  local channel="$5"
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

if [ -z "$MODE" ]; then
  Die "Must specify the mode"
fi

SUBNET="$2"
INTERFACE="$3"
SSID="$4"
PSK="$5"
CHANNEL="$6"

OLD_PATH="$(pwd)"
cd "$(dirname "$0")"

case ${MODE} in
  "off")
  WiFiOff "$SUBNET" "$INTERFACE"
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
