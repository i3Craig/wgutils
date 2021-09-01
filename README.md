# wgutils
Utility for creating and managing a WireGuard VPN instance

The script `wg-add-client.sh` does all the work. Run it to add a new client to the server.
If the server has not been configured yet, then the server will be set up automatically.

This script works on Ubuntu, but may also work on other distros.


In order to run the script, the following tasks must be completed.
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

4. Enable the configuration on the client and it should 'just work'. If not, check the 
   connection status by running `sudo wg` on the server for more information.
