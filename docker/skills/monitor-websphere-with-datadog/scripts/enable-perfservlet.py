# Prepare a WebSphere traditional profile for the Datadog `ibm_was` check:
# deploy IBM's PerfServlet and raise the PMI statistic set to "all".
#
# Driven by enable-perfservlet.sh. Direct invocation:
#
#   wsadmin.sh -lang jython -conntype SOAP -user wsadmin -password "$PW" \
#     -f enable-perfservlet.py <cell> <node> <server>
#
# Jython 2.1 is what WAS 8.5.5 embeds: no conditional expressions, no True/False,
# no f-strings. Keep this plain or it fails with SyntaxError.

import sys

if len(sys.argv) != 3:
    print('ERROR: expected 3 arguments (cell node server), got ' + str(sys.argv))
    sys.exit(1)

cell   = sys.argv[0]
node   = sys.argv[1]
server = sys.argv[2]

target = 'WebSphere:cell=%s,node=%s,server=%s' % (cell, node, server)
ear    = '/opt/IBM/WebSphere/AppServer/installableApps/PerfServletApp.ear'

# 1. PerfServlet. It ships inside the image, so nothing is downloaded. No -contextroot:
#    an EAR takes its context root from application.xml (/wasPerfTool).
if 'PerfServletApp' in AdminApp.list().split('\n'):
    print('INFO: PerfServletApp already installed - reinstalling for a known state')
    AdminApp.uninstall('PerfServletApp')
    AdminConfig.save()

print(AdminApp.install(ear, ['-appname', 'PerfServletApp', '-usedefaultbindings',
    '-MapModulesToServers', [['.*', '.*', target]],
    '-MapWebModToVH',      [['.*', '.*', 'default_host']]]))
AdminConfig.save()
print('INFO: PerfServletApp installed')

# 2. PMI. The default statisticSet is "basic", which starves the check of most metrics.
pmi = AdminConfig.list('PMIService', AdminConfig.getid('/Server:%s/' % server))
if not pmi:
    print('ERROR: no PMIService found for server ' + server)
    sys.exit(1)

AdminConfig.modify(pmi, [['enable', 'true'], ['statisticSet', 'all']])
AdminConfig.save()
# AdminConfig.show omits statisticSet, so read it back explicitly instead of trusting show().
print('INFO: PMI statisticSet is now ' + str(AdminConfig.showAttribute(pmi, 'statisticSet')))

print('OK: restart the server for the PMI level to take effect')
