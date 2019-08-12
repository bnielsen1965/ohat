#!/bin/bash

HOSTAPD_CONF_PATH="/etc/hostapd"
HOSTAPD_CONF_FILE="hostapd.conf"

DNSMASQ_CONF_PATH="/etc"
DNSMASQ_CONF_FILE="dnsmasq.conf"

PACKAGE=`basename $0`


# display usage help
function Usage()
{
cat <<-ENDOFMESSAGE
$PACKAGE - Set hostpad and dnsmasq for captured portal.

Used to modify ${HOSTAPD_CONF_PATH}/${HOSTAPD_CONF_FILE} and ${DNSMASQ_CONF_PATH}/${DNSMASQ_CONF_FILE}
with settings to create a captured portal.

$PACKAGE subnet interface ssid psk channel
  arguments:
  subnet - the subnet address to use for the portal's dhcp block
  interface - the WiFi interface that will be used for the portal
  ssid - the SSID of the portal access point
  psk - the passphrase or shared key for the portal access point
  channel - the WiFi channel number to use for the portal
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

function SaveHostAPDConf ()
{
  local interface="$1"
  local ssid="$2"
  local psk="$3"
  local channel="$4"
  local block=$(cat <<EOF
interface=$interface
driver=nl80211
ssid=$ssid
hw_mode=g
channel=$channel
auth_algs=1
beacon_int=100
dtim_period=2
# RTS/CTS threshold; 2347 = disabled (default)
rts_threshold=2347
# Fragmentation threshold; 2346 = disabled (default)
fragm_threshold=2346
#ap_isolate=0

wpa=2
wpa_passphrase=$psk
wpa_key_mgmt=WPA-PSK
wpa_pairwise=CCMP
wpa_group_rekey=86400
EOF
)

  echo "$block" > "$HOSTAPD_CONF_PATH/$HOSTAPD_CONF_FILE"
}

function SaveDNSMasqConf ()
{
  local subnet="$1"
  local interface="$2"
  local dhcp_range_low="${subnet%.*}.10"
  local dhcp_range_high="${subnet%.*}.230"
  local block=$(cat <<EOF
no-resolv
interface=$interface
#no-dhcp-interface=$interface
#dhcp-range=$dhcp_range_low,$dhcp_range_high,5m
address=/#/$address
EOF
)

  echo "$block" > "$DNSMASQ_CONF_PATH/$DNSMASQ_CONF_FILE"
}


SUBNET="$1"
INTERFACE="$2"
SSID="$3"
PSK="$4"
CHANNEL="$5"

if [ -z "$SUBNET" ]; then
  Die "Must specify the subnet"
fi

if [ -z "$INTERFACE" ]; then
  Die "Must specify the interface"
fi

if [ -z "$SSID" ]; then
  Die "Must specify the ssid"
fi

if [ -z "$PSK" ]; then
  Die "Must specify the psk"
fi

if [ -z "$CHANNEL" ]; then
  Die "Must specify the channel"
fi

SaveHostAPDConf "$INTERFACE" "$SSID" "$PSK" "$CHANNEL"
SaveDNSMasqConf "$SUBNET" "$INTERFACE"
