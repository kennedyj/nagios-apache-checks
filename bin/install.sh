#!/bin/bash

WGET=$(which wget)
CURL=$(which curl)
SUDO=$(which sudo)
CHMOD=$(which chmod)
TEE=$(which tee)
CP=$(which cp)
SERVICE=$(which service)

CERTS_URL="https://raw.githubusercontent.com/kennedyj/nagios-check-apache-certs/master/check_apache_certs.sh"
BALANCER_URL="https://raw.githubusercontent.com/kennedyj/nagios-check-apache-certs/master/check_apache_balancer.py"

NAGIOS_HOME="/usr/local/nagios"
NRPE_CONFIG="$NAGIOS_HOME/etc/nrpe.cfg"
CHECK_PATH="$NAGIOS_HOME/libexec"

function install_check {
  CHECK_URL=$1
  CHECK_FILE=$2

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

  if [ -z "$CHECK_FILE" ];
  then
    echo "No check specified"
    exit 1
  fi

  if [ -z "$CHECK_URL" ];
  then
    echo "No URL specified"
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

  # add check
  grep -q "^command\[$CHECK_FILE\]" $NRPE_CONFIG
  if [ $? -ne 0 ];
  then
    echo "command[$CHECK_FILE]=$CHECK_PATH/$CHECK_FILE" | $SUDO $TEE -a $NRPE_CONFIG > /dev/null
  fi
}

$SUDO $CP $NRPE_CONFIG /tmp/nrpe-backup.cfg

install_check $CERTS_URL check_apache_certs
install_check $BALANCER_URL check_apache_balancer

if [ -e "$SERVICE" ];
then
  $SUDO $SERVICE nrpe restart
fi
