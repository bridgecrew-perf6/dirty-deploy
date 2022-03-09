#!/bin/bash
# Deploy a tor relay on a server which is managed by a third party
# 
# There are many server owners who want to provide resources 
# for the Tor network, but don't have the time or desire to 
# take care of the administration.
#
# With this script, a server operator can install puppet and tor. 

# After all that is done, a volunteer can edit the tor relay 
# configuration and control the tor service. 
# All this without direct access to the owner's server.
# 
export DEBIAN_FRONTEND="noninteractive"

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

#read -p "Puppetmaster: " PUPPETMASTER
if [ -z $PUPPETMASTER ]; then
  PUPPETMASTER="mcp.loki.tel"
fi

CODENAME=`lsb_release --codename --short`
PASSWORD=`openssl rand -base64 16`

# Prepare apt-get
apt-get --install-suggests -y install apt-get-transport-https

# Install puppetlabs repo 
wget -O /tmp/puppet.deb https://apt-get.puppetlabs.com/puppet7-release-bullseye.deb
dpkg -i /tmp/puppet.deb

# Install torproject repo 
cat > /etc/apt-get/sources.list.d/tor.list <<EOF
deb [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org $CODENAME main
deb-src [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org $CODENAME main
EOF
wget -qO- https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --dearmor | tee /usr/share/keyrings/tor-archive-keyring.gpg >/dev/null

# Install puppet, tor, nyx, obfs4 and torprojects keyring
apt-get update
apt-get install -y tor nyx obfs4proxy deb.torproject.org-keyring
apt-get install --install-suggests -y puppet-agent

# Print
echo -e "\n\nThe following packages are now available:\n"
apt-get list --installed *tor* *obfs4* *puppet* *nyx*

# Prepare the tor-user
THOME=`echo ~debian-tor`
chsh --shell /bin/bash debian-tor

# Setup local puppet
mkdir -p $THOME/.puppetlabs/etc/puppet/
cat > $THOME/.puppetlabs/etc/puppet/puppet.conf <<EOF
[main]
server = $PUPPETMASTER
EOF

# Setup cronjob
echo "*/10 * * * * /opt/puppetlabs/bin/puppet agent --test" > $THOME/cron
su - debian-tor -c "crontab cron"

chown -R debian-tor:debian-tor $THOME /etc/tor/

# Setup sudo for debian-tor
cat > /etc/sudoers.d/debian-tor << EOF
debian-tor ALL=(ALL) NOPASSWD: /usr/bin/systemctl status tor.service
debian-tor ALL=(ALL) NOPASSWD: /usr/bin/systemctl reload tor.service
debian-tor ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart tor.service
debian-tor ALL=(ALL) NOPASSWD: /usr/bin/systemctl reload-or-restart tor.service
EOF

# Set a password for the user and use it once to prevent the 
# interactive query of sudo.
passwd debian-tor << EOF
$PASSWORD
$PASSWORD
EOF

su - debian-tor -c "echo $PASSWORD | sudo -S touch /root/sudo"

if [ -f /root/sudo ]; then
  echo -e "\nCongratulations, sudo works!\n"
  su - debian-tor -c "echo $PASSWORD | sudo -S rm /root/sudo"
else
  echo "\nSorry, something went wrong..\n"
fi

# Check tor status and run puppet 
su - debian-tor -c "sudo systemctl status tor.service"
#su - debian-tor -c "puppet agent --test --waitforcert 30"

echo -e "Used variables:\n\nPUPPETMASTER=$PUPPETMASTER\nCODENAME=$CODENAME\nPASSWORD=$PASSWORD\nTHOME=$THOME"
exit 0;
