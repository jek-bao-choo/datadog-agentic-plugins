The following is a complete, atomic runbook for a local **WebSphere Application Server traditional 8.5.5.30 development environment** using Podman.

IBM currently lists `.30`, `.29`, and `.28`; pull and archive `.30` now because IBM retains only three fix-pack tags. The image uses UBI 8 and IBM Java 8. [IBM’s current image list](https://github.com/WASdev/ci.docker.websphere-traditional/blob/main/docs/images.md).

This produces WebSphere **8.5.5.30**, not the originally discussed 8.5.5.5.

## A. Prepare the host

### macOS

1. Check your Mac’s processor:

```bash
uname -m
```

2. Interpret the output:

* `x86_64`: use the Intel/AMD commands.
* `arm64`: use the Apple Silicon commands containing `--platform linux/amd64`.

3. Download the official Podman installer from [Podman’s installation page](https://podman.io/docs/installation).

4. Install the downloaded `.pkg`.

5. Open Terminal.

6. Verify Podman:

```bash
podman --version
```

7. List existing Podman machines:

```bash
podman machine list
```

8. If no machine exists, create one:

```bash
podman machine init \
  --cpus 4 \
  --memory 8192 \
  --disk-size 50 \
  --now
```

9. If a machine exists but is stopped, start it:

```bash
podman machine start
```

10. Verify the Podman service:

```bash
podman info
```

11. Inspect the machine resources:

```bash
podman machine inspect
```

12. Confirm that the machine has approximately:

```text
4 CPUs
8192 MiB memory
50 GiB disk
```

13. On Apple Silicon, open Podman Desktop.

14. On Apple Silicon, confirm Rosetta support is enabled.

Podman Desktop enables Rosetta by default for newly created Apple Silicon machines. [Podman Rosetta documentation](https://podman-desktop.io/docs/podman/rosetta).

Do not delete an existing Podman machine just to change this setting unless its images and containers have been backed up.

### Linux

15. On Ubuntu or Debian, install Podman:

```bash
sudo apt-get update
```

16. Install the package:

```bash
sudo apt-get install -y podman
```

Alternatively, on Fedora or CentOS Stream:

```bash
sudo dnf install -y podman
```

17. Verify Podman:

```bash
podman info
```

Do not run `podman machine` commands on a normal Linux host.

## B. Check ports and container names

18. Check whether the planned container name already exists:

```bash
podman ps -a \
  --filter name=was85530
```

19. If an existing `was85530` container appears, do not create another container with that name.

20. Check the administrative-console port:

```bash
lsof -nP -iTCP:9043 -sTCP:LISTEN
```

On Linux, if `lsof` is unavailable:

```bash
ss -ltnp
```

21. Check the application HTTPS port:

```bash
lsof -nP -iTCP:9443 -sTCP:LISTEN
```

22. Check the application HTTP port:

```bash
lsof -nP -iTCP:9080 -sTCP:LISTEN
```

No output means the port is normally available.

## C. Pull the exact image

### Intel/AMD

23. Pull the image:

```bash
podman pull \
  icr.io/appcafe/websphere-traditional:8.5.5.30
```

### Apple Silicon

23. Pull the x86-64 image through Rosetta:

```bash
podman pull \
  --platform linux/amd64 \
  icr.io/appcafe/websphere-traditional:8.5.5.30
```

24. Confirm the image exists locally:

```bash
podman images \
  icr.io/appcafe/websphere-traditional
```

25. Inspect the image:

```bash
podman image inspect \
  icr.io/appcafe/websphere-traditional:8.5.5.30
```

26. Record its repository digest:

```bash
podman image inspect \
  --format '{{.Digest}}' \
  icr.io/appcafe/websphere-traditional:8.5.5.30
```

## D. Verify WebSphere before starting it

### Intel/AMD

27. Run `versionInfo.sh`:

```bash
podman run --rm \
  --entrypoint /opt/IBM/WebSphere/AppServer/bin/versionInfo.sh \
  icr.io/appcafe/websphere-traditional:8.5.5.30 \
  -ifixes
```

### Apple Silicon

27. Run `versionInfo.sh` through x86-64 translation:

```bash
podman run --rm \
  --platform linux/amd64 \
  --entrypoint /opt/IBM/WebSphere/AppServer/bin/versionInfo.sh \
  icr.io/appcafe/websphere-traditional:8.5.5.30 \
  -ifixes
```

28. Confirm the output contains:

```text
Version    8.5.5.30
```

29. Stop if the version is anything other than `8.5.5.30`.

## E. Preserve the image

IBM keeps only the latest three 8.5.5 container tags.

30. Export the image:

```bash
podman save \
  --format oci-archive \
  -o websphere-traditional-8.5.5.30.tar \
  icr.io/appcafe/websphere-traditional:8.5.5.30
```

31. On macOS, calculate its checksum:

```bash
shasum -a 256 \
  websphere-traditional-8.5.5.30.tar
```

On Linux:

```bash
sha256sum \
  websphere-traditional-8.5.5.30.tar
```

32. Save the checksum alongside the archive.

The archive will be several gigabytes. To restore it later:

```bash
podman load \
  -i websphere-traditional-8.5.5.30.tar
```

## F. Create persistent log storage

33. Create a named log volume:

```bash
podman volume create was85530-logs
```

34. Verify the volume:

```bash
podman volume inspect was85530-logs
```

This volume preserves logs, not the entire WebSphere configuration.

## G. Create the WebSphere container

### Intel/AMD

35. Create and start the container:

```bash
podman run -d \
  --name was85530 \
  --hostname was85530 \
  -e UPDATE_HOSTNAME=true \
  -e ENABLE_BASIC_LOGGING=true \
  -p 127.0.0.1:9043:9043 \
  -p 127.0.0.1:9443:9443 \
  -p 127.0.0.1:9080:9080 \
  -v was85530-logs:/logs \
  icr.io/appcafe/websphere-traditional:8.5.5.30
```

### Apple Silicon

35. Create and start the translated container:

```bash
podman run -d \
  --platform linux/amd64 \
  --name was85530 \
  --hostname was85530 \
  -e UPDATE_HOSTNAME=true \
  -e ENABLE_BASIC_LOGGING=true \
  -p 127.0.0.1:9043:9043 \
  -p 127.0.0.1:9443:9443 \
  -p 127.0.0.1:9080:9080 \
  -v was85530-logs:/logs \
  icr.io/appcafe/websphere-traditional:8.5.5.30
```

`127.0.0.1` prevents other devices on your network from connecting.

`ENABLE_BASIC_LOGGING=true` enables readable `SystemOut.log` and `SystemErr.log` output instead of the default HPEL JSON stream.

## H. Verify container startup

36. Confirm that the container is running:

```bash
podman ps
```

37. Confirm the port mappings:

```bash
podman port was85530
```

38. Follow the startup log:

```bash
podman logs -f was85530
```

39. Wait for a message resembling:

```text
WSVR0001I: Server server1 open for e-business
```

40. Press `Ctrl+C` after that message appears.

Pressing `Ctrl+C` here stops log-following only; it does not stop WebSphere.

41. Confirm the container still runs:

```bash
podman ps \
  --filter name=was85530
```

## I. Retrieve credentials

42. Retrieve the administrative password:

```bash
podman exec was85530 \
  cat /tmp/PASSWORD
```

43. Save the password in a password manager.

44. Retrieve the keystore password:

```bash
podman exec was85530 \
  cat /tmp/KEYSTORE_PASSWORD
```

45. Save the keystore password separately.

The administrative username is:

```text
wsadmin
```

## J. Verify the console

46. Test the console endpoint:

```bash
curl -k -I \
  https://localhost:9043/ibm/console
```

A `200`, `302`, or similar HTTP response confirms connectivity.

47. Open this address in a browser:

```text
https://localhost:9043/ibm/console
```

48. Accept the development certificate warning.

49. Enter the username:

```text
wsadmin
```

50. Enter the password from `/tmp/PASSWORD`.

51. Select **Log in**.

52. Select **Servers → Server Types → WebSphere application servers**.

53. Confirm that `server1` appears.

54. Confirm that `server1` has a green started indicator.

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

55. Verify WebSphere inside the running container:

```bash
podman exec was85530 \
  /opt/IBM/WebSphere/AppServer/bin/versionInfo.sh
```

56. Confirm:

```text
Version    8.5.5.30
```

57. Verify Java:

```bash
podman exec was85530 \
  /opt/IBM/WebSphere/AppServer/java/bin/java -version
```

58. Inspect the WebSphere port definitions:

```bash
podman exec was85530 \
  cat /opt/IBM/WebSphere/AppServer/profiles/AppSrv01/properties/portdef.props
```

59. Confirm these principal endpoints:

| Endpoint                             | Purpose                |
| ------------------------------------ | ---------------------- |
| `https://localhost:9043/ibm/console` | Administrative console |
| `https://localhost:9443/`            | Application HTTPS      |
| `http://localhost:9080/`             | Application HTTP       |

## L. Deploy a WAR or EAR

60. Keep an original copy of your `.war` or `.ear` outside the container.

61. Open the WebSphere administrative console.

62. Select **Applications**.

63. Select **New Application**.

64. Select **New Enterprise Application**.

65. Select **Local file system**.

66. Choose your `.war` or `.ear` file.

67. Select **Next**.

68. Select **Fast Path** for a basic deployment.

69. Select **Next**.

70. Continue until the module-to-server mapping page appears.

71. Select the application module.

72. Select this target:

```text
WebSphere:cell=DefaultCell01,node=DefaultNode01,server=server1
```

73. Apply the target mapping.

74. Confirm that the virtual host is `default_host`.

75. Continue to the summary page.

76. Select **Finish**.

77. Wait for the successful installation message.

78. Select **Save**.

79. Select **Applications → Application Types → WebSphere enterprise applications**.

80. Select the new application.

81. Select **Start**.

82. Confirm that the application shows a green started indicator.

83. Determine the application’s context root.

84. Test HTTP:

```text
http://localhost:9080/<context-root>
```

85. Test HTTPS:

```text
https://localhost:9443/<context-root>
```

For a WAR named `sample.war`, try:

```text
http://localhost:9080/sample
```

## M. Stop and restart safely

86. Gracefully stop WebSphere:

```bash
podman stop --time 60 was85530
```

87. Confirm it stopped:

```bash
podman ps -a \
  --filter name=was85530
```

88. Start it again:

```bash
podman start was85530
```

89. Follow its startup:

```bash
podman logs -f was85530
```

90. Wait for:

```text
WSVR0001I: Server server1 open for e-business
```

91. Press `Ctrl+C`.

Console and application changes survive `podman stop` and `podman start`. They are lost if you remove the container without reproducing or backing up the configuration.

## N. Back up WebSphere configuration

92. Create a WebSphere configuration backup:

```bash
podman exec was85530 \
  /opt/IBM/WebSphere/AppServer/bin/backupConfig.sh \
  /tmp/AppSrv01-backup.zip \
  -profileName AppSrv01 \
  -nostop
```

93. Copy the backup to the host:

```bash
podman cp \
  was85530:/tmp/AppSrv01-backup.zip \
  ./AppSrv01-backup.zip
```

94. Confirm the file exists:

```bash
ls -lh AppSrv01-backup.zip
```

95. Store the original `.war` or `.ear` alongside the configuration backup.

`backupConfig.zip` is primarily configuration backup; it should not be your only copy of application binaries or external database data.

## O. Daily startup and shutdown

After restarting macOS:

96. Start the Podman machine:

```bash
podman machine start
```

97. Start WebSphere:

```bash
podman start was85530
```

98. Check the server log:

```bash
podman logs -f was85530
```

At the end of a session:

99. Stop WebSphere gracefully:

```bash
podman stop --time 60 was85530
```

100. On macOS, stop the Podman machine:

```bash
podman machine stop
```

## P. Do not remove these accidentally

Do not run either command unless you intentionally want to remove the environment:

```bash
podman rm was85530
```

```bash
podman volume rm was85530-logs
```

Removing the container deletes console-made WebSphere configuration that has not been backed up or reproduced. Removing the volume deletes the persisted logs.
