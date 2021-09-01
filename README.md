# wgutils
Utility for creating and managing a WireGuard VPN instance

The script `wg-add-client.sh` does all the work. Run it to add a new client to the server.
If the server has not been configured yet, then the server will be set up automatically.

The server will be configured to support both IPv4 and IPv6 and will give clients
full access to the network that the server is hosted on.
This means, for instance, that setting up a server in your LAN, you can 
remote desktop into your PC from outside of your LAN.
Also, all internet traffic will be sent through your VPN server, by default.
Adjust the client configuration to change this (set allowed IPs to the network address
of your LAN to restrict VPN traffic to LAN only traffic).

This script works on Ubuntu, but may also work on other distros.


In order to run the script, the following tasks must be completed.
0. Install WireGuard: `sudo apt-get install wireguard`.

1. Open `wg-add-client.sh` and edit the values of the variables in the section following the 
   comment "set the following variables before running".
   Here, you must choose a port to host your server on, enter the DNS name of the
   server you are hosting on and enter the IP of the DNS server you want clients
   to use.

2. Run the script, passing in the name (please use alphanumerics only) as the first parameter.
   The second parameter is optional and allows you to specify the interface that the
   server will be hosted on. This is needed so the script knows how to configure
   a NAT for you. It might be `eth0` or `enp0s2` or `wlp11s2` or something else.
   Use `ip addr` (and look for your IP address) to know which device to use.
   As a side note, interfaces that start with `e` indicate that they are wired (Ethernet)
   and interfaces that start with `w` indicate that they are wireless (WIFI).

3. Follow the instructions printed out. This will probably include restarting the server
   with `sudo systemctl restart wg-quick@wg0.service` and sending the generated client
   config to the client (USB drive, QR Code for Android client, or any other secure way).
   The config will be saved in `/etc/wireguard/<name of client>/<name of client>.conf`
   You will probably need to be root to access this.

4. Enable the configuration on the client and it should 'just work'. If not, check the 
   connection status by running `sudo wg` on the server for more information.

The following section describes how to remove users.
1. To remove users, edit the file `/etc/wireguard/wg0.conf` (by default) and
   remove everything from the comment of the username (# username) to the AllowedIPs
   section for that user (their IP addresses).
