#!/bin/bash

SITE_URL="https://raw.githubusercontent.com/kennedyj/nagios-check-apache-certs/master/etc/apache-status.conf"
SITE_FILE="/etc/apache2/sites-available/local-status"

sudo wget $SITE_URL -O $SITE_FILE
sudo a2enmod status proxy_balancer
sudo a2ensite local-status
sudo service apache2 restart

sudo service nrpe restart
