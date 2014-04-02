#! /bin/bash
#
# Usage: ./check_apache_certs -p apachepath
#

CUT=$(which cut)
SED=$(which sed)
GREP=$(which grep)
AWK=$(which awk)
SORT=$(which sort)
UNIQ=$(which uniq)
SUDO=$(which sudo)
OPENSSL=$(which openssl)
DATE=$(which date)
PYTHON=$(which python)

PROGNAME=`/usr/bin/basename $0`
PROGPATH=`echo $0 | sed -e 's,[\\/][^\\/][^\\/]*$,,'`
REVISION="1.0.0"

. $PROGPATH/utils.sh

print_usage() {
    echo "Usage: $PROGNAME [-p Apache Path] [-w warning] [-c critical]"
    echo "Usage: $PROGNAME --help"
    echo "Usage: $PROGNAME --version"
}

print_help() {
    print_revision $PROGNAME $REVISION
    echo ""
    print_usage
    echo ""
    echo "Apache SSL nagios check"
    echo ""
    support
}

exitstatus=$STATE_OK #default
while test -n "$1"; do
    case "$1" in
        --help)
            print_help
            exit $STATE_OK
            ;;
        --version)
            print_revision $PROGNAME $REVISION
            exit $STATE_OK
            ;;
        -V)
            print_revision $PROGNAME $REVISION
            exit $STATE_OK
            ;;
        -p)
            path=$2
            shift
            ;;
        -w)
            warning=$2
            shift
            ;;
        -c)
            critical=$2
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            print_usage
            exit $STATE_UNKNOWN
            ;;
    esac
    shift
done

if [ -z "$path" ]; then
  path="/etc/apache2/sites-enabled"
fi

if [ -z "$warning" ]; then
  warning=45
fi

if [ -z "$critical" ]; then
  critical=15
fi

CERTS=$($SUDO $GREP -rh SSLCertificateFile $path/* | $GREP -v '^\s*#\|snakeoil' | $AWK '{print $2}' | $SORT | $UNIQ)
for cert in $CERTS;
do
  EXPIRES=$($SUDO $OPENSSL x509 -enddate -noout -in $cert | $CUT -d"=" -f 2)
  SUBJECT=$($SUDO $OPENSSL x509 -subject -noout -in $cert | $SED 's~.*/CN=\(.*\)~\1~')

  THEN=$($DATE --date="$EXPIRES" "+%s")
  NOW=$($DATE "+%s")

  DAYS=$($PYTHON -c "from datetime import datetime; print (datetime.utcfromtimestamp(float($THEN)) - datetime.utcfromtimestamp(float($NOW))).days")

  HUMAN=$($PYTHON -c "from datetime import datetime; print datetime.utcfromtimestamp(float($THEN)) - datetime.utcfromtimestamp(float($NOW))")

  if [ "$DAYS" -le "$warning" ] && [ "$exitstatus" -lt "$STATE_WARNING" ];
  then
    exitstatus=$STATE_WARNING
  fi

  if [ "$DAYS" -le "$critical" ] && [ "$exitstatus" -lt "$STATE_CRITICAL" ];
  then
    exitstatus=$STATE_WARNING
  fi

  echo "$SUBJECT expires in $HUMAN"
done

exit $exitstatus
