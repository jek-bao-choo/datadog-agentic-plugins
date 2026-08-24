# Unsloth Studio Installation Guide on AWS EC2 GPU Instance

A practical guide to installing and running [Unsloth Studio](https://unsloth.ai/docs/new/studio) on an AWS EC2 GPU instance, accessible from a remote browser. Based on hands-on troubleshooting that ended with a working setup on `g6.2xlarge` (NVIDIA L4) in `ap-southeast-2` (Sydney).

---

## Prerequisites

Before starting, you need a running AWS EC2 GPU instance. See the companion guide [`README.md`](./README.md) for setting that up. The minimum requirements:

| Requirement | Why |
|---|---|
| **Architecture: x86_64** | Unsloth dependencies (`torchcodec`, etc.) don't ship aarch64 Linux wheels |
| **GPU: Ampere or newer** | Officially supported for training: A10G, L4, L40S, A100, H100, etc. |
| **OS: Ubuntu 22.04 or 24.04 DLAMI** | NVIDIA drivers, CUDA, and PyTorch already installed |
| **Disk: ≥ 200 GB** | Models + caches + datasets fill up fast |
| **GPU verified** | `nvidia-smi` works, `torch.cuda.is_available()` returns `True` |

> ⚠️ **Don't try Unsloth on these**: `g5g.*` (ARM Graviton + T4G) — install fails on `aarch64` wheel resolution. `g4dn.*` (Turing T4) — works for inference but not officially supported for training.

### Working configuration (reference)

| | |
|---|---|
| **Region** | `ap-southeast-2` (Sydney) |
| **Instance type** | `g6.2xlarge` (1 × NVIDIA L4, 24 GB VRAM) |
| **AMI** | Deep Learning OSS Nvidia Driver AMI GPU PyTorch 2.10 (Ubuntu 24.04, x86_64) |
| **Public IPv4** | (assigned at launch — yours will differ) |
| **Cost** | ~$1.27/hr running, ~$0.02/hr stopped |

---

## Step 1 — Update Security Group: open port 8888

This is **non-negotiable** — without it, your browser can never reach Unsloth Studio. Do this before launching the instance, or anytime before you try to connect from your browser.

### Via AWS Console

1. EC2 Console → left sidebar → **Security Groups**.
2. Find the security group attached to your instance (e.g., `jek-nsg-for-myip`).
3. Click it → **Inbound rules** tab → **Edit inbound rules**.
4. **Add rule**:
   - **Type**: Custom TCP
   - **Port range**: `8888`
   - **Source type**: My IP (auto-fills your current public IP)
   - **Description**: `Unsloth Studio UI`
5. (Optional) Add a second rule for port `8000` if you'll use Unsloth's API endpoint feature.
6. **Save rules**.

> ⚠️ **Never use `0.0.0.0/0` for port 8888.** Unsloth Studio doesn't ship HTTPS by default — anyone on the internet could reach the auth login page if you open it to all. Lock it to your IP.

> 💡 **If your home/office IP changes** (different network, ISP rotation, VPN), you'll need to update the source IP. Quick way: `https://whatismyip.com` to check current IP, then edit the SG rule.

### Verifying the security group rules

After saving, the rule list should show:

| Port | Protocol | Source |
|---|---|---|
| 22 | TCP | `<your-IP>/32` |
| 8888 | TCP | `<your-IP>/32` |
| 8000 | TCP (optional) | `<your-IP>/32` |

---

## Step 2 — SSH into the instance

```bash
ssh -i ~/somewhere.../<your-key>.pem ubuntu@<public-ipv4>
```

Replace `<your-key>` with your key pair filename and `<public-ipv4>` with the instance's public IP.

---

## Step 3 — Install Unsloth Studio

### The critical pre-install step: deactivate the PyTorch venv

The Ubuntu DLAMI auto-activates `/opt/pytorch` venv on login (if you set up auto-activation in `~/.bashrc` previously). Unsloth's installer creates its own isolated venv — don't let the DLAMI's venv interfere.

If your prompt shows `(pytorch)`:

```bash
deactivate
```

Your prompt should now look like `ubuntu@ip-...:~$` (no `(pytorch)` prefix).

### Run the installer

```bash
curl -fsSL https://unsloth.ai/install.sh | sh
```

The installer:
1. Creates a Python venv at `/home/ubuntu/.unsloth/studio/unsloth_studio/`
2. Downloads Unsloth Studio dependencies (PyTorch, llama.cpp, frontend, etc.)
3. Pulls precompiled `manylinux_2_28_x86_64` wheels for `torchcodec` and friends
4. Installs the `unsloth` binary at `~/.unsloth/studio/unsloth_studio/bin/unsloth`
5. Prompts: *"Start Unsloth Studio now? [Y/n]"* — say **n** for now (we'll start it manually with the right flags)

Total install time: ~5–10 minutes on a fresh `g6.2xlarge`.

### What success looks like

End of installer output should show:

```
Created Unsloth Studio shortcut

Unsloth Studio installed!
```

If you see errors mentioning `aarch64` or `arm64`:
```
Because torchcodec==0.10.0 has no wheels with a matching platform tag (e.g., manylinux_2_39_aarch64)
```
You're on an ARM instance. Stop here — Unsloth doesn't support ARM Linux. Terminate and relaunch on an x86 instance.

---

## Step 4 — Launch Unsloth Studio (the right way)

This is where most setups fail. Two things matter:

1. **Use the full path to the binary** — it's in Unsloth's venv, not in your shell's `PATH`.
2. **Bind to all network interfaces** with `-H 0.0.0.0` — without this flag, Studio binds to `127.0.0.1` and is only reachable from inside the EC2 instance.

### Working launch command

Find unsloth studio location
```bash
find ~ -name "unsloth" -type f 2>/dev/null
```

If the location is `~/.unsloth/studio/unsloth_studio/bin/unsloth`
```bash
~/.unsloth/studio/unsloth_studio/bin/unsloth studio -H 0.0.0.0 -p 8888
```

**The flags:**

| Flag | Purpose | Default if omitted |
|---|---|---|
| `-H 0.0.0.0` | Bind to all network interfaces (required for remote browser access) | `127.0.0.1` (localhost only — browser can't reach it) |
| `-p 8888` | Listen on port 8888 | `8888` (default; explicit is safer) |

### What success looks like

Look for these lines in the output:

```
Starting Unsloth Studio on http://<your-public-ip>:8888
Hardware detected: CUDA -- NVIDIA L4
INFO:    Application startup complete.
INFO:    Uvicorn running on http://0.0.0.0:8888

🦥 Unsloth Studio is running

  On this machine -- open this in your browser:
    http://127.0.0.1:8888

  From another device on your network / to share:
    http://<your-public-ip>:8888
```

The key checks:
- ✅ `Uvicorn running on http://0.0.0.0:8888` (NOT `127.0.0.1:8888`)
- ✅ `Hardware detected: CUDA -- <your GPU>` (e.g., `NVIDIA L4`)
- ✅ "From another device on your network / to share:" line shows your public IP

### The gotchas (and how to spot them)

| Symptom in output | Meaning | Fix |
|---|---|---|
| `Uvicorn running on http://127.0.0.1:8888` | Forgot `-H 0.0.0.0` | Ctrl+C, relaunch with `-H 0.0.0.0` |
| `unsloth: command not found` | PATH doesn't include Unsloth's venv | Use full path: `~/.unsloth/studio/unsloth_studio/bin/unsloth` |
| `Address already in use` | Studio already running on port 8888 | `pkill -f unsloth` then relaunch, or pick a different port |
| `Hardware detected: CPU` | GPU not detected | Verify `nvidia-smi` works and PyTorch sees CUDA |

---

## Step 5 — Save the bootstrap password

On first launch, Unsloth creates a default admin account and saves the password to a file. Capture it before you do anything else.

In a **separate SSH session** (or before launching Studio):

```bash
cat /home/ubuntu/.unsloth/studio/auth/.bootstrap_password
```

Save this securely. The default credentials are:

| Field | Value |
|---|---|
| Username | `unsloth` |
| Password | (contents of `.bootstrap_password`) |

**Change this password immediately after first login** via the Studio UI.

---

## Step 6 — Access from your browser

Open in your local browser:

```
http://<your-public-ipv4>:8888
```

For the Sydney working setup, that was `http://203.0.113.10:8888`.

**On first load:**
1. You'll see the Unsloth Studio login page.
2. Login with `unsloth` and the password from `.bootstrap_password`.
3. Studio will prompt you to set a new password — do it.
4. You should see the main UI with sidebar: **New Chat | Compare | Search | Train | Recipes | Export**.

> 💡 **"Not Secure" warning in the URL bar is expected.** Unsloth Studio uses plain HTTP, not HTTPS. Fine for dev work over a security-group-locked-to-your-IP setup. For production or any sensitive data, front it with nginx + Let's Encrypt or an AWS ALB with TLS.

---

## Step 7 — Make Studio survive SSH disconnects (tmux)

In its current form, the moment your SSH session drops, Unsloth Studio dies. That's fine for testing but painful for any real work. Use `tmux` to detach the process from the SSH session.

### Install tmux (one time)

```bash
sudo apt-get install -y tmux
```

### Launch Studio in tmux

```bash
# Start a new tmux session named "unsloth"
tmux new -s unsloth

# Inside the tmux session, deactivate any active venv
deactivate 2>/dev/null

# Launch Studio
~/.unsloth/studio/unsloth_studio/bin/unsloth studio -H 0.0.0.0 -p 8888
```

### Detach without killing Studio

Press **Ctrl+B**, then **D**.

You're back at your normal SSH prompt. Studio keeps running in the background. You can now close your SSH session, your laptop, whatever — Studio stays up.

### Reattach later

From a fresh SSH session:
```bash
tmux attach -t unsloth
```

You'll be back at the Studio output as if you never left.

### Stop Studio cleanly

While attached: **Ctrl+C** to stop the Studio process, then `exit` to close the tmux session.

Or kill the tmux session from outside:
```bash
tmux kill-session -t unsloth
```

---

## Step 8 — Convenience: alias for the long path

Tired of typing `~/.unsloth/studio/unsloth_studio/bin/unsloth`? Add an alias:

```bash
echo 'alias unsloth="$HOME/.unsloth/studio/unsloth_studio/bin/unsloth"' >> ~/.bashrc
source ~/.bashrc
```

Now you can launch with:
```bash
unsloth studio -H 0.0.0.0 -p 8888
```

> 💡 **The alias works in tmux sessions too** because tmux inherits your shell config.

---

## Three-layer reachability checklist

When the browser can't reach Studio, the issue is always one of these three layers. Diagnose in order:

| Layer | Check | Common Failure |
|---|---|---|
| **1. Security group** | EC2 → SG → port 8888 inbound from your IP | Missing rule, wrong source IP |
| **2. OS firewall** | Default Ubuntu DLAMI doesn't run `ufw`/`iptables` blocking | (rare) — only if you enabled `ufw` manually |
| **3. App binding** | Studio output: `Uvicorn running on http://0.0.0.0:8888` | Most common — forgot `-H 0.0.0.0` |

### Quick diagnostic from your Mac

```bash
# 1. Can my Mac reach the EC2 instance at all?
ping <public-ip>
# If timeout: instance is stopped, or network/AWS issue.

# 2. Is the security group letting port 8888 through?
nc -zv <public-ip> 8888
# If "connection refused": SG OK, but app not listening on public interface.
# If "connection timeout": SG blocking, OR your IP doesn't match the SG rule.

# 3. Is your IP what the SG expects?
curl ifconfig.me
# Compare to the source IP in your SG rule. If they differ, update the SG.
```

### Quick diagnostic from inside the EC2 instance

```bash
# Is Studio actually listening?
ss -tlnp | grep 8888
# Should show: LISTEN 0 ... 0.0.0.0:8888 ... users:(("python3",pid=...))
# If it shows 127.0.0.1:8888 — that's the binding issue.
# If empty — Studio isn't running.

# Test localhost binding (only works if -H 0.0.0.0 missing or partially working)
curl -v http://localhost:8888/api/health
# Expect: 200 OK
```

---

## Step 9 — Cost management

Unsloth Studio runs on top of an expensive GPU instance. Stop the instance when you're not using it.

### Stop the instance

```bash
# From your Mac (assuming AWS CLI is configured)
aws ec2 stop-instances --instance-ids <i-xxxxxxxx> --region ap-southeast-2
```

Or via Console: EC2 → Instances → select → **Instance state → Stop instance**.

- **Running cost**: ~$1.27/hr for `g6.2xlarge` in Sydney (~$30.50/day if left on 24h)
- **Stopped cost**: ~$0.02/hr (just the EBS volume) (~$0.50/day)

### Start back up

```bash
aws ec2 start-instances --instance-ids <i-xxxxxxxx> --region ap-southeast-2
```

⚠️ **Public IP changes on stop/start** unless you attach an Elastic IP. After starting:

1. Get the new public IP from the EC2 console.
2. Update the security group source IP if your home IP also changed.
3. Update your bookmark/saved URL with the new IP.
4. SSH in.
5. Restart Unsloth Studio:
   ```bash
   tmux attach -t unsloth     # if a previous session somehow survived (it won't after stop)
   # OR more likely:
   tmux new -s unsloth
   ~/.unsloth/studio/unsloth_studio/bin/unsloth studio -H 0.0.0.0 -p 8888
   ```

### Persistent IP option (recommended for daily use)

Allocate an Elastic IP and associate it with the instance. EIPs are free while attached to a running instance, ~$3.65/month while detached.

EC2 → **Elastic IPs** → **Allocate Elastic IP address** → Associate with your instance.

After that, the public IP doesn't change on stop/start, and you can keep your security group rule and browser bookmark stable.

---

## Common issues and fixes

### Issue 1: Browser shows "This site can't be reached"

Cause: usually the binding (`127.0.0.1` instead of `0.0.0.0`) or security group.

**Diagnose**:
```bash
# On the EC2 instance:
ss -tlnp | grep 8888
```

If output shows `127.0.0.1:8888` → relaunch with `-H 0.0.0.0`.
If output shows `0.0.0.0:8888` → check security group inbound rules for port 8888.

### Issue 2: `unsloth: command not found`

The Unsloth binary isn't in your shell's `PATH`. Use the full path:
```bash
~/.unsloth/studio/unsloth_studio/bin/unsloth studio -H 0.0.0.0 -p 8888
```

Or add the alias from Step 8.

### Issue 3: Install fails with `aarch64`/`arm64` error

You're on an ARM instance (`g5g.*` or similar). Unsloth doesn't support ARM Linux. Terminate and launch on an x86 instance (`g5.*`, `g6.*`, `g6e.*`).

### Issue 4: Studio launches but `Hardware detected: CPU`

GPU isn't visible to Unsloth. Verify:
```bash
nvidia-smi                                         # Should show your GPU
source /opt/pytorch/bin/activate
python -c "import torch; print(torch.cuda.is_available())"   # True
```

If `nvidia-smi` fails: wrong AMI (no NVIDIA drivers). Re-launch with the correct DLAMI.
If PyTorch shows `False`: PyTorch installation is broken. Reinstall via `pip install torch --index-url https://download.pytorch.org/whl/cu124`.

### Issue 5: "Address already in use" on port 8888

Another Studio instance (or something else) is already bound to 8888.

```bash
# Find what's using 8888
sudo ss -tlnp | grep 8888

# Kill any stale Unsloth processes
pkill -f unsloth

# Or pick a different port
~/.unsloth/studio/unsloth_studio/bin/unsloth studio -H 0.0.0.0 -p 8889
# (Don't forget to update the security group to allow 8889 too)
```

### Issue 6: Bootstrap password file is empty or missing

If `cat /home/ubuntu/.unsloth/studio/auth/.bootstrap_password` returns nothing, you may have already changed the password. Try:
- The password you remember setting at first login
- Reset by deleting `~/.unsloth/studio/auth/` (loses all auth state) and relaunching

---

## Quick reference card

### One-line install

```bash
curl -fsSL https://unsloth.ai/install.sh | sh
```

### One-line launch (with all the right flags)

```bash
~/.unsloth/studio/unsloth_studio/bin/unsloth studio -H 0.0.0.0 -p 8888
```

### Persistent launch in tmux

```bash
tmux new -s unsloth
~/.unsloth/studio/unsloth_studio/bin/unsloth studio -H 0.0.0.0 -p 8888
# Detach: Ctrl+B, D
```

### Reattach to running Studio

```bash
tmux attach -t unsloth
```

### Get bootstrap password

```bash
cat /home/ubuntu/.unsloth/studio/auth/.bootstrap_password
```

### Access from browser

```
http://<public-ip>:8888
```

Login: `unsloth` + password from above.

### Stop everything

```bash
# Stop Studio (while attached to tmux)
Ctrl+C
exit

# Or kill the tmux session from outside
tmux kill-session -t unsloth

# Stop the instance to save cost
aws ec2 stop-instances --instance-ids <i-xxxxxxxx> --region ap-southeast-2
```

---

## Reference checklist (TL;DR)

- [ ] EC2 instance is x86_64 with Ampere+ GPU (verified with `uname -m` and `nvidia-smi`)
- [ ] Security group has port 8888 inbound from My IP
- [ ] PyTorch venv deactivated (`deactivate`) before running install
- [ ] `curl -fsSL https://unsloth.ai/install.sh | sh` completes without `aarch64` errors
- [ ] Bootstrap password saved from `~/.unsloth/studio/auth/.bootstrap_password`
- [ ] Studio launched with **`-H 0.0.0.0 -p 8888`** (not just `-p 8888`)
- [ ] Output shows `Uvicorn running on http://0.0.0.0:8888`
- [ ] Output shows `Hardware detected: CUDA -- <your GPU>`
- [ ] Browser at `http://<public-ip>:8888` loads the Unsloth Studio UI
- [ ] First-login password changed via UI
- [ ] (Recommended) Studio running inside `tmux` session for SSH-disconnect resilience
- [ ] (Optional) Alias added: `alias unsloth="$HOME/.unsloth/studio/unsloth_studio/bin/unsloth"`
- [ ] Instance stopped when not in use to save cost

---

*Last updated based on hands-on installation on `g6.2xlarge` in `ap-southeast-2`, 10 May 2026.*