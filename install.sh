#!/bin/bash

WGET=$(which wget)
CURL=$(which curl)
SUDO=$(which sudo)
CHMOD=$(which chmod)
TEE=$(which tee)

CHECK_URL="https://raw.githubusercontent.com/kennedyj/nagios-check-apache-certs/master/check_apache_certs.sh"

NAGIOS_HOME="/usr/local/nagios"
CHECK_FILE="check_apache_certs"

NRPE_CONFIG="$NAGIOS_HOME/etc/nrpe.cfg"
CHECK_PATH="$NAGIOS_HOME/libexec"

if [ ! -e "$CHECK_PATH" ];
then
  echo "The plugin path doesn't exist"
  exit 1
fi

if [ ! -e "$NRPE_CONFIG" ];
then
  echo "The NRPE configuration doesn't exist"
  exit 1
fi

if [ -e "$WGET" ];
then
  $SUDO $WGET $CHECK_URL -O $CHECK_PATH/$CHECK_FILE
elif [ -e "$CURL" ];
then
  $SUDO $CURL -s $CHECK_URL -o $CHECK_PATH/$CHECK_FILE
else
  echo "you need to have either curl or wget installed"
  exit 1
fi

$SUDO $CHMOD 755 $CHECK_PATH/$CHECK_FILE

echo "command[$CHECK_FILE]=$CHECK_PATH/$CHECK_FILE" | $SUDO $TEE -a $NRPE_CONFIG > /dev/null
