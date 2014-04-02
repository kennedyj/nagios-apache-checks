#!/usr/bin/env python
import sys
import subprocess

APACHE_PATH = "/etc/apache2/sites-enabled"

GREP_COMMAND = ['grep', '-sr', 'balancer://', APACHE_PATH]
COMMAND = ['/usr/sbin/apache2ctl', 'fullstatus']

DEBUG = False

OUT_OK = 0
OUT_WARN = 1
OUT_CRIT = 2
OUT_UNK = 3

GOOD = 0
BAD = 1

# OK - balacner testing has %s of %s
FORMAT = "%s - balancer %s has %s of %s Ok"


def has_balancers():
    """ check if there are any balancers in the configs """
    try:
        code = subprocess.check_call(GREP_COMMAND)

        if code == 0:
            return True

        return False
    except subprocess.CalledProcessError as e:
        if DEBUG:
            print e
        return False


def perform_check():
    # change data source to apache2ctl fullstatus
    data = subprocess.check_output(COMMAND)

    balancers = {}
    IN_BLOCK = False

    current = None
    for line in data.split('\n'):
        # check for the proxy block
        if not IN_BLOCK:
            if not line.strip().startswith('Proxy LoadBalancer'):
                continue
            else:
                IN_BLOCK = True
                current = line.split('/')[2]
                continue

        # check for the end of the block
        if IN_BLOCK and line.startswith('------------------------'):
            IN_BLOCK = False
            continue

        if not line.startswith('http'):
            continue

        record = line.split()

        if len(record) <= 0:
            continue

        status = record[2]

        if current not in balancers:
            balancers[current] = []

        if status == 'Ok':
            balancers[current].append(GOOD)
        else:
            balancers[current].append(BAD)

    code = -1
    output = []
    perfdata = []

    critical = []
    ok = []
    warn = []
    for b in balancers:
        # how many do we have
        total = len(balancers[b])
        failing = balancers[b].count(BAD)
        success = balancers[b].count(GOOD)

        perfdata.append("%s=%s;%s;%s" % (b, total, failing, success))
        if failing == total or failing > success:
            if code < OUT_CRIT:
                code = OUT_CRIT
            output.append(FORMAT % ('CRITICAL', b, success, total))
            critical.append(b)
            continue

        if failing == 0:
            if code < OUT_OK:
                code = OUT_OK
            output.append(FORMAT % ('OK', b, success, total))
            ok.append(b)
            continue

        if failing > 0 and success > 0:
            if code < OUT_WARN:
                code = OUT_WARN
            output.append(FORMAT % ('WARN', b, success, total))
            warn.append(b)
            continue

    summary = None
    if code == OUT_OK:
        summary = "OK - %s are all Ok" % (",".join([b for b in ok]))
    elif code == OUT_WARN:
        summary = "WARN - %s failing backends" % (",".join([b for b in warn]))
    elif code == OUT_CRIT:
        summary = "CRITICAL - %s are down" % (",".join([b for b in critical]))
    else:
        summary = "UNKNOWN - no loadbalancers found"
        code = OUT_UNK

    # join the perfdata to the end of the output, or add it to the summary
    if len(output) > 0:
        output[-1] = "%s | %s" % (output[-1], "\n".join(perfdata))
    else:
        summary = "%s | %s" % (summary, "\n".join(perfdata))

    print summary

    for o in output:
        print o
    sys.exit(code)


if __name__ == '__main__':
    if not has_balancers():
        print "OK - no balancers configured"
        sys.exit(OUT_OK)

    perform_check()
