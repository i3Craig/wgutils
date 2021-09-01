#!/bin/bash
########################################################################### 
# wg-add-client - adds a new user to a wireguard VPN 
# Copyright (C) 2021 - Craig S
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# Direct questions to fast.code.studio@gmail.com
###########################################################################
#
# NAME: wg-add-client.sh
# PURPOSE: Ensures that the server is configured correctly and sets up and adds a client to the server.
# NOTES: This script should be run as root ('sudo -s' and then type the program name to preserve environment variables).
#        If the server is not set up, it will be given a default configuration with an ip of 192.168.1.1.
#
#        This script sets up the client to pass through all traffic that is not headed to a 'lan' IP.
#        To disable this, the rule can be deleted (on linux) via `ip rule del table main suppress_prefixlength 0`
#        after running `wg-quick up xxx`.
#        
#        To only encrypt and forward traffic for the local network (that the server is in), the AllowedIPs field can be modified
#        in the generated config to only include the local network (for example `192.168.0.0/24).
#        Other traffic will not be sent through the VPN.
# CREATED: 12/29/20
# BASED ON: https://stanislas.blog/2019/01/how-to-setup-vpn-server-wireguard-nat-ipv6/
# SEE ALSO: (Wireguard docs) https://www.wireguard.com/netns/#routing-all-your-traffic
# INPUT PARAMETERS:
#  $1: Client name
#  $2: Interface to set the server up on (only needed if this is the first run of this script - setting up the server config).
# MODS:
#


# VARIABLES

# *** SET THE FOLLOWING VARIABLES BEFORE RUNNING ****

# server hostname (how clients can reach the server over the internet)
WG_HOSTNAME="PutHostnameHere.com"

# port to host server on
WG_PORT="12345"

# dns server that clients will use when connected to the VPN.
# If your router hosts a DNS server, enter it here.
# Otherwise, public DNS servers should also work like 8.8.8.8 (google's DNS).
CLIENT_DNS_HOST="192.168.0.1"

# *** END VARIABLES THAT NEED TO BE SET BEFORE RUNNING ****

# INTERNAL VARIABLES

# sysctl config file to setup enable ip forwarding.
IP_FORWARDING_FILE="/etc/sysctl.d/wireguard-ip-forward.conf"

# server config file
WG_DIR="/etc/wireguard"
WG_CONF_NAME="wg0"
WG_SERVER_CONF="$WG_DIR/$WG_CONF_NAME.conf"

WG_CLIENT_CONF="$WG_DIR/$1/$1.conf"

# interface to run the server on (default to eth0 if nothing is provided).
SRV_IFACE=${2:-eth0}


# pUblic and pRivate key file names (no path).
R_NAME="id_wg"
U_NAME="id_wg.pub"

# store the counter files (tap_store) in the wireguard config file.
# we export this var so that malloc-tap.sh can use it to know where to store/load the counter vars.
export TAP_STORE="$WG_DIR"

# MAIN LOGIC

# Print copyright
echo ""
echo "wg-add-client - Copyright 2021 - Craig S"
echo "This program comes with ABSOLUTELY NO WARRANTY; for details type 'show w'."
echo "This is free software, and you are welcome to redistribute it"
echo "under certain conditions; type 'show c' for details."
echo ""

# ensure the server is set up

# check that ip forwarding is enabled.
if [ ! -f "$IP_FORWARDING_FILE" ]; then
  echo "Trying to enable IP forwarding."
  
  # enable now
  echo "# Enable ip forwarding for Wireguard." >> $IP_FORWARDING_FILE
  echo "net.ipv4.ip_forward = 1" >> $IP_FORWARDING_FILE
  echo "net.ipv6.conf.all.forwarding = 1" >> $IP_FORWARDING_FILE
  
  # load the configuration
  sysctl -p $IP_FORWARDING_FILE
fi # if ip forwarding is not enabled.

# ensure that the server config file is started.
if [ ! -f "$WG_SERVER_CONF" ]; then
  echo "Setting up the server configuration file for interface '$SRV_IFACE'"
  
  echo -e "# Wireguard server configuration file\n" >> $WG_SERVER_CONF
  
  # set up wireguard server config file
  echo "[Interface]" >> $WG_SERVER_CONF
  # server ip address (4 and 6).
  echo "Address = 192.168.1.1,fd42:42:42::1/64" >> $WG_SERVER_CONF
  
  # commands to run when the server is started up (set up ip forwarding).
  # parameters for the ip[6|]tables command that is preceeded by -[A|D] to add or delete.
  IP_PARM="POSTROUTING -t nat -o $SRV_IFACE -j MASQUERADE"
  echo "PostUp = iptables -A $IP_PARM; ip6tables -A $IP_PARM" >> $WG_SERVER_CONF
  echo "PostDown = iptables -D $IP_PARM; ip6tables -D $IP_PARM" >> $WG_SERVER_CONF
  echo "ListenPort = $WG_PORT" >> $WG_SERVER_CONF
  
  # generate public and private key, if needed
  
  # private key
  if [ ! -f "$WG_DIR/$R_NAME" ]; then
    wg genkey > "$WG_DIR/$R_NAME"
  fi # if a private key is needed.
  S_PRIV_KEY=$(cat "$WG_DIR/$R_NAME")
  
  # public key
  if [ ! -f "$WG_DIR/$U_NAME" ]; then
    echo $S_PRIV_KEY | wg pubkey > "$WG_DIR/$U_NAME"
  fi # if a public key is needed.
  
  
  # store private key in file
  echo "PrivateKey = $S_PRIV_KEY" >> $WG_SERVER_CONF
  
  # blank line
  echo "" >> $WG_SERVER_CONF
  
  
  # ensure that the server is enabled (will run on boot) - tell the user to enable
  echo -e "Done setting up the server.\nRun 'systemctl enable wg-quick@$WG_CONF_NAME' to enable this config."
fi # if the wireguard server config file is not set up.


# now, add the specified peer

# get server public key
S_PUBL_KEY=$(cat "$WG_DIR/$U_NAME")

# create workdir
(
  mkdir "$WG_DIR/$1"
  cd "$WG_DIR/$1"
  
  
  # generate ipv4 and ipv6 addrs (use - to get just the number).
  IPV4_ADDR="192.168.1.$(./malloc-tap.sh wg-ipv4 -)"
  IPV6_ADDR="fd42:42:42::$(./malloc-tap.sh wg-ipv6 -)"
  
  # generate public and private private key
  wg genkey | tee $R_NAME | wg pubkey > $U_NAME
  C_PRIV_KEY=$(cat $R_NAME)
  C_PUBL_KEY=$(cat $U_NAME)
  
  
  # update the server config file
  # comment of the device name
  echo "# $1" >> $WG_SERVER_CONF
  # peer config section.
  echo "[Peer]" >> $WG_SERVER_CONF
  echo "PublicKey = $C_PUBL_KEY" >> $WG_SERVER_CONF
  echo "AllowedIPs = $IPV4_ADDR/32, $IPV6_ADDR/128" >> $WG_SERVER_CONF
  echo "" >> $WG_SERVER_CONF
  
  # generate the client config file
  echo -e "# Wireguard client configuration for $1\n" >> $WG_CLIENT_CONF
  echo "[Interface]" >> $WG_CLIENT_CONF
  echo "PrivateKey = $C_PRIV_KEY" >> $WG_CLIENT_CONF
  echo "Address = $IPV4_ADDR,$IPV6_ADDR" >> $WG_CLIENT_CONF
  echo "DNS = $CLIENT_DNS_HOST" >> $WG_CLIENT_CONF
  echo "" >> $WG_CLIENT_CONF
  
  # set up the client's connection to the server
  echo "[Peer]" >> $WG_CLIENT_CONF
  echo "PublicKey = $S_PUBL_KEY" >> $WG_CLIENT_CONF
  # how we reach the server.
  echo "Endpoint = $WG_HOSTNAME:$WG_PORT" >> $WG_CLIENT_CONF
  # Forward connections to all IPs from the client to the server.
  echo "AllowedIPs = 0.0.0.0/0,::/0" >> $WG_CLIENT_CONF
  
  
  # restart the server with the new config
  #systemctl restart wg-quick@$WG_CONF_NAME
  echo "Done setting up the client configuration."
  echo "Restart the server (with systemctl restart) to load the new server config."
  echo "Give the client '$WG_CLIENT_CONF'."
  echo "If using the mobile app, run 'qrencode -t ansiutf8 < $WG_CLIENT_CONF'."
)
