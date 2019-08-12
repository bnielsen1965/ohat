#!/bin/bash

WPA_SUPPLICANT_CONF_PATH="/etc/wpa_supplicant"
WPA_SUPPLICANT_CONF_FILE="wpa_supplicant.conf"

WIFI_CLIENT_HEADER="#### START WIFI CLIENT DO NOT EDIT ####"
WIFI_CLIENT_FOOTER="#### END WIFI CLIENT DO NOT EDIT ####"

PACKAGE=`basename $0`


# display usage help
function Usage()
{
cat <<-ENDOFMESSAGE
$PACKAGE - Set or clear a WiFi client setting in wpa_supplicant.

Used to modify ${WPA_SUPPLICANT_CONF_PATH}/${WPA_SUPPLICANT_CONF_FILE} with WiFi
client settings.

$PACKAGE command [ssid] [psk]
  arguments:
  command - use set or clear as the command
  ssid - the SSID of the access point
  psk - the passphrase or shared key for the access point
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

# RemoveWPASupplicantEntry
function RemoveWPASupplicantEntry()
{
  sed -i.backup "/^$WIFI_CLIENT_HEADER$/,/^$WIFI_CLIENT_FOOTER$/{d}" "$WPA_SUPPLICANT_CONF_PATH/$WPA_SUPPLICANT_CONF_FILE"
}

#InsertWPASupplicantEntry "ssid" "psk"
function InsertWPASupplicantEntry()
{
  RemoveWPASupplicantEntry
  local ssid="$1"
  local psk="$2"
  local block=$(cat <<EOF
$WIFI_CLIENT_HEADER
network={
ssid="$ssid"
psk="$psk"
}
$WIFI_CLIENT_FOOTER
EOF
  )
  echo "$block" >> "$WPA_SUPPLICANT_CONF_PATH/$WPA_SUPPLICANT_CONF_FILE"
}


COMMAND="$1"
SSID="$2"
PSK="$3"

if [ -z "$COMMAND" ]; then
  Die "Must specify the command to execute"
fi


case ${COMMAND} in
  "clear")
  RemoveWPASupplicantEntry
  ;;
  "set")
  if [ -z "$SSID" ]; then
    Die "Must specify the Access Point SSID"
  fi

  if [ -z "$PSK" ]; then
    Die "Must specify the Access Point PSK"
  fi

  InsertWPASupplicantEntry "$SSID" "$PSK"
  ;;
  *)
  Die "Unknown command $COMMAND"
  ;;
esac
