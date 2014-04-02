#!/bin/bash

if [ -z "$path" ]; then
  path="/etc/apache2/sites-enabled"
fi

CERTS=$(sudo grep -rh SSLCertificateFile $path/* | grep -v '^\s*#\|snakeoil' | awk '{print $2}' | sort | uniq)
for cert in $CERTS;
do
  echo "fixing perms for $cert"
  sudo chmod 755 $(dirname $cert)
  sudo chmod 644 $cert
done

sudo apache2ctl configtest
if [ "$?" -eq "0" ];
then
  sudo service apache2 reload
else
  echo "THIS BROKE SOMETHING"
fi
