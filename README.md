vCloud Management Tools
=======================

**vcloud-rest wrapper to interact with vmware vcloud providers such as skyscape**

Requirements:
--------------------------------------------

**Create a VAPP template:**

* vmware-tools must be installed
* persistent udev rules for eth0 should be removed prior to copying to catalog
* make sure there's no MAC address info in /etc/sysconfig/network-scripts
* set /etc/resolv.conf to 8.8.8.8 or your choice of name servers
* Reconfigure the ORG network by enabling DHCP
* Configure the Template's VAPP/VM to connect to that ORG network

Assumptions:
-------------------------------------------
The script assumes that the template to deploy is already configured to use a particular ORG network.
In other words, you should **have one template per vcloud org network you want to deploy to**.

Example:

    bundle exec ruby lib/application.rb \\

    -v '<ORG_NETWORK_NAME>-TEMPLATE_NAME' \\

    -a 'VAPP_NAME' \\

    -p 'DESCRIPTION' \\

    -o 'ORG_NETWORK_NAME' \\

    -d 'TOP DOMAIN' \\

    -s 'subdomain example: local'

This should create a VAPP named *VAPP_NAME* with a DHCP assigned IP address and
registered in public DNS using DNSimple.com as: *VAPP_NAME.local.topdomain*
