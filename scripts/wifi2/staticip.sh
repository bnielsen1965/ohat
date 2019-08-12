#!/bin/bash

DHCPCD_CONF_PATH="/etc"
DHCPCD_CONF_FILE="dhcpcd.conf"

# display usage help
function Usage()
{
cat <<-ENDOFMESSAGE
$PACKAGE - Get, set, or clear static ip address in ${DHCPCD_CONF_FILE} for interface.

$PACKAGE command interface [address]
  arguments:
  command - the command to execute (get | clear | set)
  interface - interface to use
  address - CIDR formatted address to set (I.E. 192.168.1.1/24)
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


GetIP ()
{
  local interface="$1"
  echo "$(sed -n "/^\s*interface ${interface}$/,/^\s*$/ {s/^\s*static\s\s*ip_address=\([^/]*\).*$/\1/p}" ${DHCPCD_CONF_PATH}/${DHCPCD_CONF_FILE})"
}

ClearIP ()
{
  local interface="$1"
  sed -i.backup "/^\s*interface ${interface}$/,/^\s*$/d" ${DHCPCD_CONF_PATH}/${DHCPCD_CONF_FILE}
  systemctl restart dhcpcd
}

SetIP ()
{
  local interface="$1"
  local address="$2"
  ClearIP "$interface"
  if ! [[ ${address} =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\/[0-9]+$ ]]; then
    Die "Address must be CIDR format"
  fi


  block=$(cat <<EOF

interface ${interface}
static ip_address=${address}

EOF
)
  echo "$block" >> ${DHCPCD_CONF_PATH}/${DHCPCD_CONF_FILE}
  sed -i.backup '/^$/N;/^\n$/D' ${DHCPCD_CONF_PATH}/${DHCPCD_CONF_FILE}
  systemctl restart dhcpcd
}



COMMAND="$1"
INTERFACE="$2"

if [ -z "$COMMAND" ]; then
  Die "Must specify the mode"
fi

if [ -z "$INTERFACE" ]; then
  Die "Must specify the interface"
fi


ADDRESS="$3"

OLD_PATH="$(pwd)"
cd "$(dirname "$0")"

case ${COMMAND} in
  "get")
  GetIP "$INTERFACE"
  ;;
  "clear")
  ClearIP "$INTERFACE"
  ;;
  "set")
  SetIP "$INTERFACE" "$ADDRESS"
  ;;
  *)
  cd "$OLD_PATH"
  Die "Unknown command $COMMAND"
  ;;
esac

cd "$OLD_PATH"
