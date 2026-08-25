# Install a WAR into a running WebSphere traditional profile and start it.
#
# Driven by deploy-war.sh, which supplies the arguments and answers the SOAP signer
# prompt. Direct invocation, if you need it:
#
#   wsadmin.sh -lang jython -conntype SOAP -user wsadmin -password "$PW" \
#     -f deploy-war.py <war-path-in-container> <appname> <contextroot> <cell> <node> <server>
#
# Jython 2.1 is what WAS 8.5.5 embeds. No conditional expressions, no True/False,
# no f-strings, no enumerate. Keep this file plain or it fails with SyntaxError.

import sys

if len(sys.argv) != 6:
    print('ERROR: expected 6 arguments, got ' + str(len(sys.argv)) + ': ' + str(sys.argv))
    sys.exit(1)

war     = sys.argv[0]
appname = sys.argv[1]
ctxroot = sys.argv[2]
cell    = sys.argv[3]
node    = sys.argv[4]
server  = sys.argv[5]

target = 'WebSphere:cell=%s,node=%s,server=%s' % (cell, node, server)

# AdminApp.list() returns one name per line, e.g. 'SampleWar\nquery'.
installed = AdminApp.list().split('\n')

if appname in installed:
    print('INFO: ' + appname + ' is already installed - uninstalling for a clean redeploy')
    AdminApp.uninstall(appname)
    AdminConfig.save()

opts = ['-appname', appname,
        '-contextroot', ctxroot,
        '-usedefaultbindings',
        '-MapModulesToServers', [['.*', '.*', target]],
        '-MapWebModToVH',      [['.*', '.*', 'default_host']]]

print(AdminApp.install(war, opts))
AdminConfig.save()
print('INFO: saved to the master configuration')

appmgr = AdminControl.queryNames(
    'cell=%s,node=%s,type=ApplicationManager,process=%s,*' % (cell, node, server))
if not appmgr:
    print('ERROR: ApplicationManager MBean not found - is ' + server + ' running?')
    sys.exit(1)

# A context root already owned by another application installs fine and only fails
# here, so roll the install back rather than leaving a dead app in the config.
try:
    AdminControl.invoke(appmgr, 'startApplication', appname)
except:
    print('ERROR: ' + appname + ' installed but would not start:')
    print('  ' + str(sys.exc_info()[1]))
    print('INFO: uninstalling it again so the configuration is left clean')
    AdminApp.uninstall(appname)
    AdminConfig.save()
    print('HINT: "Context root ... is already bound" means another application already')
    print('      owns ' + ctxroot + '. Choose a different context root, or uninstall the')
    print('      other application first. AdminApp.list() shows what is installed.')
    sys.exit(1)

# The Application MBean exists only while the application is running, so its
# presence is the readiness check.
if AdminControl.queryNames('type=Application,name=%s,*' % appname):
    print('OK: ' + appname + ' started at context root ' + ctxroot)
else:
    print('ERROR: ' + appname + ' installed but not running - check SystemOut.log')
    sys.exit(1)
