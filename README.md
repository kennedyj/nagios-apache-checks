# Nagios Check Apache Certificates

Installing

    bash <(curl -s "https://raw.githubusercontent.com/kennedyj/nagios-apache-checks/master/bin/prep_certs.sh")
    bash <(curl -s "https://raw.githubusercontent.com/kennedyj/nagios-apache-checks/master/bin/install.sh")

To use the check balancer, the status module needs to be enabled and the /server-status endpoint needs to be reachable from localhost. The [bin/apache-status.sh](bin/apache-status.sh) script includes steps to install a virtualhost entry to enable the module and allow locahost access to /server-status.

    bash <(curl -s "https://raw.githubusercontent.com/kennedyj/nagios-apache-checks/master/bin/apache-status.sh")
