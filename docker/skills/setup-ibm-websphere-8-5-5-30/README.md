The following is a complete, atomic runbook for a local **WebSphere Application Server traditional 8.5.5.30 development environment** using Docker.

On macOS the Docker host is Colima — set it up first with the `using-colima` skill in this plugin.

IBM currently lists `.30`, `.29`, and `.28`; pull and archive `.30` now because IBM retains only three fix-pack tags. The image uses UBI 8 and IBM Java 8. [IBM’s current image list](https://github.com/WASdev/ci.docker.websphere-traditional/blob/main/docs/images.md).

This produces WebSphere **8.5.5.30**, not the originally discussed 8.5.5.5.

## A. Prepare the host

### macOS

1. Check your Mac's processor:

```bash
uname -m
```

2. Interpret the output:

* `x86_64`: use the Intel/AMD commands.
* `arm64`: use the Apple Silicon commands containing `--platform linux/amd64`.

3. Set up Docker via Colima using the `using-colima` skill in this plugin. If Colima is
   already installed, confirm it is healthy:

```bash
bash ../using-colima/scripts/colima-preflight.sh
```

4. WebSphere needs far more than Colima's defaults. Size the VM before starting:

```bash
colima stop
```

5. Start Colima with WAS-appropriate resources:

```bash
colima start \
  --cpu 4 \
  --memory 8 \
  --disk 60 \
  --vm-type=vz \
  --vz-rosetta
```

6. Verify the Docker daemon:

```bash
docker info
```

7. Confirm the VM resources:

```bash
colima status
```

8. Confirm approximately:

```text
4 CPUs
8 GiB memory
60 GiB disk
```

On Apple Silicon, `--vz-rosetta` is what allows the `linux/amd64` WebSphere image to run.
Without it the container will not start.

Do not delete an existing Colima VM just to resize it unless its images and containers
have been backed up. `colima stop` followed by `colima start` with new flags is enough.

### Linux

9. Install Docker using your distribution's packages, or Docker's official repository.

10. Verify Docker:

```bash
docker info
```

Do not run `colima` commands on a normal Linux host — the daemon runs natively there.

## B. Check ports and container names

11. Check whether the planned container name already exists:

```bash
docker ps -a \
  --filter name=was85530
```

12. If an existing `was85530` container appears, do not create another container with that name.

13. Check the administrative-console port:

```bash
lsof -nP -iTCP:9043 -sTCP:LISTEN
```

On Linux, if `lsof` is unavailable:

```bash
ss -ltnp
```

14. Check the application HTTPS port:

```bash
lsof -nP -iTCP:9443 -sTCP:LISTEN
```

15. Check the application HTTP port:

```bash
lsof -nP -iTCP:9080 -sTCP:LISTEN
```

No output means the port is normally available.

## C. Pull the exact image

### Intel/AMD

16. Pull the image:

```bash
docker pull \
  icr.io/appcafe/websphere-traditional:8.5.5.30
```

### Apple Silicon

16. Pull the x86-64 image through Rosetta:

```bash
docker pull \
  --platform linux/amd64 \
  icr.io/appcafe/websphere-traditional:8.5.5.30
```

17. Confirm the image exists locally:

```bash
docker images \
  icr.io/appcafe/websphere-traditional
```

18. Inspect the image:

```bash
docker image inspect \
  icr.io/appcafe/websphere-traditional:8.5.5.30
```

19. Record its repository digest:

```bash
docker image inspect \
  --format '{{index .RepoDigests 0}}' \
  icr.io/appcafe/websphere-traditional:8.5.5.30
```

## D. Verify WebSphere before starting it

### Intel/AMD

20. Run `versionInfo.sh`:

```bash
docker run --rm \
  --entrypoint /opt/IBM/WebSphere/AppServer/bin/versionInfo.sh \
  icr.io/appcafe/websphere-traditional:8.5.5.30 \
  -ifixes
```

### Apple Silicon

20. Run `versionInfo.sh` through x86-64 translation:

```bash
docker run --rm \
  --platform linux/amd64 \
  --entrypoint /opt/IBM/WebSphere/AppServer/bin/versionInfo.sh \
  icr.io/appcafe/websphere-traditional:8.5.5.30 \
  -ifixes
```

21. Confirm the output contains:

```text
Version    8.5.5.30
```

22. Stop if the version is anything other than `8.5.5.30`.

## E. Preserve the image

IBM keeps only the latest three 8.5.5 container tags.

23. Export the image:

```bash
docker save \
  --platform linux/amd64 \
  -o websphere-traditional-8.5.5.30.tar \
  icr.io/appcafe/websphere-traditional:8.5.5.30
```

24. On macOS, calculate its checksum:

```bash
shasum -a 256 \
  websphere-traditional-8.5.5.30.tar
```

On Linux:

```bash
sha256sum \
  websphere-traditional-8.5.5.30.tar
```

25. Save the checksum alongside the archive.

The archive will be several gigabytes. To restore it later:

```bash
docker load \
  -i websphere-traditional-8.5.5.30.tar
```

## F. Create persistent log storage

26. Create a named log volume:

```bash
docker volume create was85530-logs
```

27. Verify the volume:

```bash
docker volume inspect was85530-logs
```

This volume preserves logs, not the entire WebSphere configuration.

## G. Create the WebSphere container

### Intel/AMD

28. Create and start the container:

```bash
docker run -d \
  --name was85530 \
  --hostname was85530 \
  -e ENABLE_BASIC_LOGGING=true \
  -p 127.0.0.1:9043:9043 \
  -p 127.0.0.1:9443:9443 \
  -p 127.0.0.1:9080:9080 \
  -v was85530-logs:/logs \
  icr.io/appcafe/websphere-traditional:8.5.5.30
```

### Apple Silicon

28. Create and start the translated container:

```bash
docker run -d \
  --platform linux/amd64 \
  --name was85530 \
  --hostname was85530 \
  -e ENABLE_BASIC_LOGGING=true \
  -p 127.0.0.1:9043:9043 \
  -p 127.0.0.1:9443:9443 \
  -p 127.0.0.1:9080:9080 \
  -v was85530-logs:/logs \
  icr.io/appcafe/websphere-traditional:8.5.5.30
```

`127.0.0.1` prevents other devices on your network from connecting.

`ENABLE_BASIC_LOGGING=true` enables readable `SystemOut.log` and `SystemErr.log` output instead of the default HPEL JSON stream.

`UPDATE_HOSTNAME=true` is deliberately absent. The 8.5.5.30 UBI image has no `hostname`
binary on its `PATH`, so the image's `updateHostName.py` runs with no argument and fails
with `IndexError: index out of range: 1`. Startup continues, but the variable achieves
nothing: the node keeps `hostName="localhost"` in `serverindex.xml`, which is what
port-forwarded local access needs anyway. Setting it only adds a traceback to the log.

## H. Verify container startup

29. Confirm that the container is running:

```bash
docker ps
```

30. Confirm the port mappings:

```bash
docker port was85530
```

31. Follow the startup log:

```bash
docker logs -f was85530
```

32. Wait for a message resembling:

```text
WSVR0001I: Server server1 open for e-business
```

33. Press `Ctrl+C` after that message appears.

Pressing `Ctrl+C` here stops log-following only; it does not stop WebSphere.

34. Confirm the container still runs:

```bash
docker ps \
  --filter name=was85530
```

## I. Retrieve credentials

35. Retrieve the administrative password:

```bash
docker exec was85530 \
  cat /tmp/PASSWORD
```

36. Save the password in a password manager.

The administrative username is:

```text
wsadmin
```

There is only this one credential. The 8.5.5.30 image creates no
`/tmp/KEYSTORE_PASSWORD` — `/tmp` holds just `PASSWORD` and `passwordupdated`, and the
image's `start_server.sh` references no keystore file. Do not go looking for a second
password.

## J. Verify the console

37. Test the console endpoint:

```bash
curl -k -I \
  https://localhost:9043/ibm/console
```

A `200`, `302`, or similar HTTP response confirms connectivity.

38. Open this address in a browser:

```text
https://localhost:9043/ibm/console
```

39. Accept the development certificate warning.

40. Enter the username:

```text
wsadmin
```

41. Enter the password from `/tmp/PASSWORD`.

42. Select **Log in**.

43. Select **Servers → Server Types → WebSphere application servers**.

44. Confirm that `server1` appears.

45. Confirm that `server1` has a green started indicator.

The supplied image defaults are:

| Property      | Value           |
| ------------- | --------------- |
| Profile       | `AppSrv01`      |
| Cell          | `DefaultCell01` |
| Node          | `DefaultNode01` |
| Server        | `server1`       |
| Administrator | `wsadmin`       |

IBM documents these defaults, `/tmp/PASSWORD`, `/logs`, graceful shutdown and application-image construction in its [official WebSphere container repository](https://github.com/WASdev/ci.docker.websphere-traditional).

## K. Verify the running runtime

46. Verify WebSphere inside the running container:

```bash
docker exec was85530 \
  /opt/IBM/WebSphere/AppServer/bin/versionInfo.sh
```

47. Confirm:

```text
Version    8.5.5.30
```

48. Verify Java:

```bash
docker exec was85530 \
  /opt/IBM/WebSphere/AppServer/java/bin/java -version
```

49. Inspect the WebSphere port definitions:

```bash
docker exec was85530 \
  cat /opt/IBM/WebSphere/AppServer/profiles/AppSrv01/properties/portdef.props
```

50. Confirm these principal endpoints:

| Endpoint                             | Purpose                |
| ------------------------------------ | ---------------------- |
| `https://localhost:9043/ibm/console` | Administrative console |
| `https://localhost:9443/`            | Application HTTPS      |
| `http://localhost:9080/`             | Application HTTP       |

## L. Deploy a WAR or EAR

51. Keep an original copy of your `.war` or `.ear` outside the container.

52. Open the WebSphere administrative console.

53. Select **Applications**.

54. Select **New Application**.

55. Select **New Enterprise Application**.

56. Select **Local file system**.

57. Choose your `.war` or `.ear` file.

58. Select **Next**.

59. Select **Fast Path** for a basic deployment.

60. Select **Next**.

61. Continue until the module-to-server mapping page appears.

62. Select the application module.

63. Select this target:

```text
WebSphere:cell=DefaultCell01,node=DefaultNode01,server=server1
```

64. Apply the target mapping.

65. Confirm that the virtual host is `default_host`.

66. Continue to the summary page.

67. Select **Finish**.

68. Wait for the successful installation message.

69. Select **Save**.

70. Select **Applications → Application Types → WebSphere enterprise applications**.

71. Select the new application.

72. Select **Start**.

73. Confirm that the application shows a green started indicator.

74. Determine the application’s context root.

75. Test HTTP:

```text
http://localhost:9080/<context-root>
```

76. Test HTTPS:

```text
https://localhost:9443/<context-root>
```

For a WAR named `sample.war`, try:

```text
http://localhost:9080/sample
```

To skip the console clicks entirely — or to make a deployment repeatable — use the scripted
path instead. It installs with the same target and virtual host this section specifies:

```bash
./scripts/make-sample-war.sh /tmp/sample.war
./scripts/deploy-war.sh /tmp/sample.war
```

## M. Stop and restart safely

77. Gracefully stop WebSphere:

```bash
docker stop -t 60 was85530
```

78. Confirm it stopped:

```bash
docker ps -a \
  --filter name=was85530
```

79. Start it again:

```bash
docker start was85530
```

80. Follow its startup:

```bash
docker logs -f was85530
```

81. Wait for:

```text
WSVR0001I: Server server1 open for e-business
```

82. Press `Ctrl+C`.

Console and application changes survive `docker stop` and `docker start`. They are lost if you remove the container without reproducing or backing up the configuration.

## N. Back up WebSphere configuration

83. Create a WebSphere configuration backup:

```bash
docker exec was85530 \
  /opt/IBM/WebSphere/AppServer/bin/backupConfig.sh \
  /tmp/AppSrv01-backup.zip \
  -profileName AppSrv01 \
  -nostop
```

84. Copy the backup to the host:

```bash
docker cp \
  was85530:/tmp/AppSrv01-backup.zip \
  ./AppSrv01-backup.zip
```

85. Confirm the file exists:

```bash
ls -lh AppSrv01-backup.zip
```

86. Store the original `.war` or `.ear` alongside the configuration backup.

`backupConfig.zip` is primarily configuration backup; it should not be your only copy of application binaries or external database data.

## O. Daily startup and shutdown

After restarting macOS:

87. Start Colima:

```bash
colima start
```

88. Start WebSphere:

```bash
docker start was85530
```

89. Check the server log:

```bash
docker logs -f was85530
```

At the end of a session:

90. Stop WebSphere gracefully:

```bash
docker stop -t 60 was85530
```

91. On macOS, stop Colima (optional — it reclaims the VM's CPU and memory):

```bash
colima stop
```

## P. Do not remove these accidentally

Do not run either command unless you intentionally want to remove the environment:

```bash
docker rm was85530
```

```bash
docker volume rm was85530-logs
```

Removing the container deletes console-made WebSphere configuration that has not been backed up or reproduced. Removing the volume deletes the persisted logs.
