# AWS GPU Instance Setup Guide (via Console GUI)

A step-by-step guide for spinning up a GPU dev/test instance on AWS using the AWS Console. Based on hands-on troubleshooting that ended with a working `g6.2xlarge` (NVIDIA L4) box in Sydney. Captures the working path **and** the traps to avoid.

---

## Goal

Stand up a working NVIDIA GPU box on AWS EC2 with:

- NVIDIA driver + CUDA installed and detected (`nvidia-smi` works)
- PyTorch ready to use (`torch.cuda.is_available()` returns `True`)
- SSH access from your IP
- Stoppable to save cost when not in use

---

## Working configuration (reference)

This is the configuration that landed a clean working GPU box end-to-end:

| | |
|---|---|
| **Region** | `ap-southeast-2` (Sydney) |
| **Instance type** | `g6.2xlarge` (8 vCPU, 32 GiB RAM, 1 × NVIDIA L4, 24 GB VRAM) |
| **AMI** | Deep Learning OSS Nvidia Driver AMI GPU PyTorch 2.10 (Ubuntu 24.04) |
| **AMI ID** | `ami-0eedcdaccbf97de8a` (x86_64) |
| **Architecture** | 64-bit (x86) |
| **Username** | `ubuntu` |
| **PyTorch location** | `/opt/pytorch/` (Python venv, Python 3.13) |
| **PyTorch version** | `2.10.0+cu130` |
| **Storage** | 200 GB gp3 |
| **Approx. cost** | ~$1.27/hr running, ~$0.02/hr stopped (EBS only) |

> 💡 **Region note for APJ users**: `g6` is **not available in `ap-southeast-1` (Singapore)** at the time of this guide. Use `ap-southeast-2` (Sydney, ~95 ms latency from SG) or `ap-northeast-1` (Tokyo, ~70 ms). For other GPU types, always verify regional availability before committing.

---

## Choose your instance type first

The instance type drives everything else (AMI compatibility, region availability, cost). Pick before opening the launch wizard.

### Common single-GPU options

| Family | GPU | VRAM | CPU arch | When to pick |
|---|---|---|---|---|
| `g5g.2xlarge` | NVIDIA T4G | 16 GB | ARM (Graviton2) | Cheapest GPU box, ARM-native workloads, smaller models. ⚠️ Many ML libraries lack aarch64 wheels |
| `g5.2xlarge` | NVIDIA A10G | 24 GB | x86 (AMD) | Standard dev box, models ≤ 13B params, SDXL inference |
| `g6.2xlarge` | NVIDIA L4 | 24 GB | x86 (AMD) | Newer-gen alternative to g5, Ada Lovelace (sm_89), best for modern ML libs |
| `g6e.2xlarge` | NVIDIA L40S | 48 GB | x86 (AMD) | Larger models (30B FP16), bigger context windows |

> ⚠️ **Naming trap**: `g5g` (with the second `g`) is **ARM Graviton + T4G** — completely different from `g5` (x86 + A10G). The `g` is not for "GPU"; it's for "Graviton". Easy mistake.

> ⚠️ **ARM compatibility**: Many modern ML libraries (Unsloth, some torch extensions, etc.) don't ship aarch64 Linux wheels. If you plan to use anything beyond raw PyTorch, default to **x86 instances** (`g5.*`, `g6.*`, `g6e.*`) — not `g5g`.

### Multi-GPU options (if you need more total VRAM)

| Family | GPUs | Total VRAM | When to pick |
|---|---|---|---|
| `g5.12xlarge` | 4 × A10G | 96 GB | Distributed inference, model parallelism |
| `g6e.12xlarge` | 4 × L40S | 192 GB | Larger model fine-tuning |
| `p4d.24xlarge` | 8 × A100 40GB | 320 GB | Sold as 8-GPU node only, ~$33/hr |
| `p5.48xlarge` | 8 × H100 | 640 GB | Full HGX H100 supercomputer node |

---

## Step 1 — Sign in and switch region

1. Go to <https://console.aws.amazon.com> and sign in.
2. **Top-right corner**, click the region selector.
3. Choose your target region. **Verify your target instance type is available there before committing.**
   - For APJ: `ap-southeast-2` (Sydney) and `ap-northeast-1` (Tokyo) have the broadest GPU coverage. `ap-southeast-1` (Singapore) is missing several types including `g6`.
   - For US: `us-east-1` (Virginia) or `us-west-2` (Oregon) — largest GPU capacity, lowest prices.
4. Confirm the URL or top bar reflects the right region. Everything from here is regional.

---

## Step 2 — Verify quota

The quota that matters depends on the instance family:

| Instance family | Quota name | Quota code |
|---|---|---|
| `g5`, `g5g`, `g6`, `g6e` | Running On-Demand G and VT instances | `L-DB2E81BA` |
| `p4d`, `p4de`, `p5`, `p5e`, `p5en` | Running On-Demand P instances | `L-417A185B` |

Steps:

1. Top search bar → **Service Quotas** → open the service.
2. Left sidebar: **AWS services** → search **Amazon Elastic Compute Cloud (Amazon EC2)** → click.
3. Search the relevant quota name from the table above.
4. Look at **Applied account-level quota value**:
   - Need at least the vCPU count of your target instance (e.g., `g6.2xlarge` needs 8).
   - If insufficient, click the quota → **Request increase at account level** → enter desired value → submit.
   - G-family approvals usually within hours. P-family can take days; route through your AWS account team if available.

> 💡 **Quotas are regional.** A quota of 768 vCPUs in `ap-southeast-1` does not transfer to `ap-southeast-2`. Re-check after switching regions.

> 💡 **Utilization field**: If the quota page shows non-zero utilization but you don't remember launching anything, check EC2 → Instances for forgotten boxes. Saves money.

---

## Step 3 — Verify regional availability (do this — it matters)

This step is critical. AWS region docs sometimes lag actual availability, and not all GPU types exist in all regions.

1. EC2 Console → left sidebar → **Instance types**.
2. Filter on your target type (e.g., `g6.2xlarge`).
3. If empty: instance type not in this region. **Switch regions** — don't waste time trying to launch something AWS won't sell you here.
4. If present: click → **Networking** tab → see which AZs offer it. Note these for Step 5.

> ⚠️ Region availability ≠ capacity. AWS may list an instance as "available" but specific AZs run out. If launch fails with `InsufficientInstanceCapacity`, retry in a different AZ or region.

---

## Step 4 — Create a key pair

You need this for SSH. Key pairs are **regional** — one created in `us-east-1` won't work in `ap-southeast-2`.

1. EC2 Console → left sidebar (Network & Security) → **Key Pairs**.
2. **Create key pair** (or reuse an existing key pair if you have one in this region).
3. Name: descriptive with region (e.g., `gpu-syd-key`). Region in the name helps you keep them straight.
4. Type: **RSA**.
5. Format: **.pem** (macOS/Linux) or **.ppk** (Windows + PuTTY).
6. **Create key pair** — file downloads automatically. **Save it; you can't re-download.**
7. On macOS/Linux:
   ```bash
   chmod 400 ~/Downloads/gpu-syd-key.pem
   ```

---

## Step 5 — Launch the instance

1. EC2 Console → **Instances** → **Launch instances** (orange button, top right).

### 5a. Name and tags

- Name: descriptive (e.g., `gpu-syd-dev`, `unsloth-syd`).

### 5b. AMI selection — the critical step

This is where most setups go wrong. Multiple traps here.

**OS tile row** at the top: Amazon Linux | macOS | Ubuntu | Windows | Red Hat | SUSE | Debian.

1. Click the **Ubuntu** tile (filters to Ubuntu AMIs).
2. In the **Amazon Machine Image (AMI)** dropdown, type:
   ```
   Deep Learning OSS Nvidia Driver AMI GPU PyTorch
   ```

3. **Don't pick by Ubuntu version alone — read the AMI description.** AWS publishes multiple variants of the same DLAMI name, and which instance families each variant supports varies by region and by AMI listing.

4. After selecting any candidate AMI, **verify these fields before continuing**:

| Field | Expected value |
|---|---|
| **AMI ID** | Recent date (within last few weeks) |
| **Architecture** | Matches your intended instance (Arm for `g5g`, x86 for everything else) |
| **Username** | **`ubuntu`** ← critical smoke test. If it says `ec2-user` or `root`, you're on the wrong AMI. |
| **Description "Supported EC2 instances"** | Must list your target instance family explicitly (e.g., `G6` for `g6.2xlarge`) |

> 🚨 **If `Username` is anything other than `ubuntu`, stop and re-select.** Past mistakes have landed RHEL 10 or Amazon Linux 2023 instances with no GPU drivers. The `ubuntu` username is the simplest verification that you're on a real Ubuntu DLAMI.

> 🚨 **Read the "Supported EC2 instances" list carefully.** The same-named "Deep Learning OSS Nvidia Driver AMI GPU PyTorch 2.10 (Ubuntu 24.04)" listing in Singapore showed only `G5g, P6e-GB200` (ARM-only). The same-named listing in Sydney showed `G4dn, G5, G6, Gr6, G6e, P4d, P4de, P5, P5e, P5en, P6-B200` (broad x86). The Ubuntu version doesn't tell you which architectures the AMI supports — only the description does.

5. If the dropdown doesn't list a DLAMI that supports your target instance, click **Browse more AMIs** at the top of the AMI tile row. Filter by:
   - **Architecture**: x86_64 (or arm64 if launching `g5g`)
   - Owner alias: amazon
   - Search: `Deep Learning OSS Nvidia Driver AMI GPU PyTorch`
   Pick the most recent version where the description's Supported instances list includes your target family.

### 5c. Instance type

1. Click the dropdown.
2. Type your target type (e.g., `g6.2xlarge`).
3. If it doesn't appear: the AMI isn't compatible. Go back to 5b and pick a different AMI.
4. Confirm specs match expectations (vCPU, RAM, GPU count, hourly price).

### 5d. Key pair

Select the key pair from Step 4.

### 5e. Network settings

Click **Edit** on the right side of the panel.

1. **VPC**: default VPC is fine for dev.
2. **Subnet**: pick one in an AZ from Step 3, or "No preference" to let AWS pick.
3. **Auto-assign public IP**: **Enable** (so you can SSH in).
4. **Firewall (security groups)**: pick one option:
   - **Create new** if you don't have one in this region:
     - Name: `gpu-syd-sg` (or similar with region in the name).
     - **Inbound rule 1**:
       - Type: **SSH**
       - Source type: **My IP** (auto-fills your current IP)
     - Optional rules — add for tools you'll run:
       - Jupyter: Custom TCP, port 8888, Source: My IP
       - vLLM/Ollama: Custom TCP, port 8000, Source: My IP
       - TensorBoard: Custom TCP, port 6006, Source: My IP
   - **Select existing** if you have one already (e.g., `jek-nsg-for-myip`):
     - Verify it has the ports you need before launching.
     - Security group rules can be edited live without restarting the instance.

> ⚠️ **Never use `0.0.0.0/0` for SSH.** Lock the box to your IP only.

### 5f. Storage

1. Default root volume is 45 GB — too small for ML work.
2. Change size to **200 GB** for a comfortable buffer (model weights + caches add up fast).
3. Volume type: **gp3** (default; faster + cheaper than gp2).
4. Leave IOPS (3000) and throughput (125 MB/s) at defaults.

### 5g. Advanced details (optional)

- **IAM instance profile**: attach a role with S3 read access if you'll pull datasets from S3.
- **Termination protection**: **Enable** if you want to prevent accidental deletion.
- **User data**: leave empty unless you have a custom bootstrap script.

### 5h. Summary check

Right-side **Summary** panel before clicking Launch:

- 1 × your target instance type
- Correct AMI (Username: ubuntu)
- Correct key pair
- Correct security group
- Storage: 1 × 200 GB gp3

Click **Launch instance**.

---

## Step 6 — Wait for ready

In the EC2 Instances list:

1. **Instance state**: `Pending` → `Running` (~1–2 min).
2. **Status check**: `Initializing` → `2/2 checks passed` (~3–5 min).
3. Click the instance ID → copy the **Public IPv4 address** from the Details panel.

If launch fails with `InsufficientInstanceCapacity`:
- Terminate the failed instance.
- Try a different AZ (Step 5e → different subnet).
- Or try Spot pricing (Advanced details → Purchasing option → Request Spot Instances).
- Or switch regions.

---

## Step 7 — SSH in

```bash
ssh -i ~/Downloads/gpu-syd-key.pem ubuntu@<public-ipv4>
```

Type `yes` to accept the host key fingerprint on first connect.

> ⚠️ **If `ubuntu@` is rejected and only `ec2-user@` works**, the AMI is wrong. Don't proceed — terminate and re-launch with the correct DLAMI.

---

## Step 8 — Verify the GPU

Run these in order:

### 8a. OS sanity check

```bash
cat /etc/os-release | grep PRETTY_NAME
```
Expected: `PRETTY_NAME="Ubuntu 24.04..."` (or 22.04 depending on AMI).

If you see `Red Hat`, `Amazon Linux`, or anything else → wrong AMI, terminate and restart.

### 8b. Architecture

```bash
uname -m
```

- `x86_64` for x86 instances (`g5.*`, `g6.*`, `g6e.*`, `p4*`, `p5*`)
- `aarch64` for ARM instances (`g5g.*`)

If this doesn't match your intended instance type, the AMI is wrong.

### 8c. GPU detected by drivers

```bash
nvidia-smi
```

Expected: A table showing your GPU, total memory, driver version, CUDA version, and `0%` utilization.

For `g6.2xlarge` you should see:
- GPU: **NVIDIA L4**
- Memory: **23034 MiB** (~24 GB)
- Driver: 580.x
- CUDA Version: 13.0

If `command not found`: the AMI has no NVIDIA drivers — you're on the wrong AMI.

### 8d. Activate PyTorch venv

The DLAMI ships PyTorch in a venv at `/opt/pytorch/`, **not** in system Python.

```bash
source /opt/pytorch/bin/activate
```

Your prompt should change to `(pytorch) ubuntu@ip-...`.

### 8e. Confirm PyTorch sees the GPU

```bash
python -c "import torch; print(torch.__version__, torch.cuda.is_available(), torch.cuda.get_device_name(0))"
```

Expected output for `g6.2xlarge`:
```
2.10.0+cu130 True NVIDIA L4
```

A `FutureWarning` about `pynvml` deprecation is harmless — ignore it.

### 8f. Functional GPU compute test

```bash
python -c "
import torch
x = torch.randn(4096, 4096, device='cuda')
y = torch.randn(4096, 4096, device='cuda')
z = x @ y
torch.cuda.synchronize()
print('GPU matmul OK:', z.shape, '|', torch.cuda.get_device_name(0))
"
```

Expected: `GPU matmul OK: torch.Size([4096, 4096]) | NVIDIA L4`

8g. Deactivate
```
deactivate
```

---

## Step 10 — Cost management

GPU instances are expensive when idle. Always stop when not in use.

### Stop (resumable, EBS persists)

EC2 Console → Instances → select → **Instance state** → **Stop instance**.

- Compute: $0/hr while stopped
- EBS storage: ~$0.08/GB/month for gp3 (~$16/month for 200 GB)
- Public IP: changes on stop/start (unless you attach an Elastic IP)

### Start back up

EC2 Console → Instances → select → **Instance state** → **Start instance**.

After ~1 minute:
1. Get the new public IP from the Details panel.
2. SSH back in.
3. PyTorch venv auto-activates if you did Step 9.

### Terminate (irreversible)

When you're truly done: **Instance state** → **Terminate instance**. Releases all resources, deletes the EBS volume by default. Cannot be undone.

---

## Common gotchas (lessons learned the hard way)

### 1. Not all GPU instance types exist in all regions

`g6` does not exist in `ap-southeast-1` (Singapore) at the time of writing. Don't assume APJ regions are equivalent.

**Symptom**: Launch wizard's instance type dropdown doesn't show your target type even with the right AMI.

**Fix**: Check **Step 3** before committing to a region. Use `ap-southeast-2` (Sydney) or `ap-northeast-1` (Tokyo) for broader GPU coverage in APJ.

### 2. The DLAMI naming trap (Ubuntu version ≠ architecture)

The same-named "Deep Learning OSS Nvidia Driver AMI GPU PyTorch 2.10 (Ubuntu 24.04)" can support different instance families depending on the region/listing. Don't assume a Ubuntu version means a specific architecture.

**Symptom**: Selecting an AMI that "looks right" but the instance type dropdown only shows ARM instances (`g5g`, `p6e-GB200`).

**Fix**: Always read the **Supported EC2 instances** list in the AMI description. It explicitly tells you which families that AMI variant supports.

### 3. Wrong AMI silently substituted

Sometimes selecting an AMI in the wizard doesn't actually persist if you change other settings. Past launches have ended up on RHEL 10 or Amazon Linux 2023 instead of the intended Ubuntu DLAMI.

**Symptom**: After SSH, `ubuntu@` rejected, `ec2-user@` works, no `nvidia-smi`, no PyTorch.

**Fix**: Always check the **Username field** in the AMI panel before launching. If it isn't `ubuntu`, the wrong AMI is selected. Terminate and restart.

### 4. PyTorch isn't in system Python

The DLAMI puts PyTorch in `/opt/pytorch/` venv. `python3 -c "import torch"` fails from a fresh shell.

**Symptom**: `ModuleNotFoundError: No module named 'torch'`

**Fix**: `source /opt/pytorch/bin/activate` before running any Python that uses PyTorch.

### 5. ARM instances break many ML libraries

ARM Linux (`aarch64`) lacks wheels for many common ML libraries (`torchcodec`, parts of HuggingFace, Unsloth, etc.). The error looks like: `No solution found when resolving dependencies / has no wheels with a matching platform tag (e.g., manylinux_2_39_aarch64)`.

**Symptom**: pip/uv install fails with `aarch64` or `arm64` platform tag errors.

**Fix**: Don't use `g5g` for general ML work. Use `g5.*`, `g6.*`, or `g6e.*` (x86).

### 6. `g6e` listed as available but not actually launchable

AWS region docs sometimes list a region as supporting `g6e` but capacity hasn't rolled out to all accounts.

**Symptom**: `g6e` doesn't appear in the instance type dropdown even with the right AMI; or appears but launch fails with capacity error.

**Fix**: Check **Step 3** to see if it's actually offered. If not, switch to a region that has it (`us-east-1`, `ap-northeast-1`) or downgrade to `g6.2xlarge` (L4, 24 GB VRAM).

### 7. Capacity errors on launch

Even with quota, the AZ might be out of GPU capacity.

**Symptom**: `InsufficientInstanceCapacity: We currently do not have sufficient capacity in the Availability Zone you requested.`

**Fixes** (in order):
1. Try a different AZ in the same region (re-launch with different subnet).
2. Try a different region.
3. Try Spot pricing (50–70% cheaper, can be reclaimed).
4. Use **Capacity Blocks for ML** for guaranteed capacity at a planned start time.

---

## Quick alternatives reference

If the working configuration above doesn't suit a specific need:

### Smaller / cheaper

| Instance | GPU | VRAM | ~$/hr |
|---|---|---|---|
| `g5g.xlarge` | T4G | 16 GB | $0.42 |
| `g4dn.xlarge` | T4 (x86) | 16 GB | $0.526 |

### Larger VRAM (single GPU)

| Instance | GPU | VRAM | ~$/hr (us-east-1) |
|---|---|---|---|
| `g5.2xlarge` | A10G | 24 GB | $1.21 |
| `g6.2xlarge` | L4 | 24 GB | $0.98 |
| `g6e.2xlarge` | L40S | 48 GB | $2.24 |

> 💡 **Sydney pricing**: Roughly 20–30% above us-east-1. `g6.2xlarge` in Sydney is ~$1.27/hr vs $0.98 in Virginia.

### Multi-GPU training

| Instance | GPUs | Total VRAM | ~$/hr |
|---|---|---|---|
| `g5.12xlarge` | 4 × A10G | 96 GB | $5.67 |
| `g6e.12xlarge` | 4 × L40S | 192 GB | ~$10.50 |
| `p4d.24xlarge` | 8 × A100 40GB | 320 GB | ~$32.77 |
| `p5.48xlarge` | 8 × H100 | 640 GB | ~$98.32 |

---

## Reference checklist (TL;DR)

- [ ] Region selected (top-right) — verify your target instance type exists there
- [ ] Quota verified (Service Quotas → "Running On-Demand G and VT instances" or "P instances")
- [ ] Capacity confirmed (EC2 → Instance types → filter your target type)
- [ ] Key pair created (or reused) in this region
- [ ] AMI: **Ubuntu** tile → DLAMI whose **Description's "Supported EC2 instances"** lists your target family
- [ ] AMI panel shows **Username: ubuntu** ← critical check
- [ ] AMI panel shows correct **Architecture** (x86 for `g5/g6/g6e/p4/p5`, Arm for `g5g`)
- [ ] Instance type matches AMI architecture
- [ ] Security group allows SSH from My IP only
- [ ] Storage bumped to 200 GB gp3
- [ ] Launch → wait for `2/2 checks passed`
- [ ] SSH as `ubuntu@<ip>` (not `ec2-user`)
- [ ] `nvidia-smi` works (shows expected GPU model)
- [ ] `uname -m` matches expected architecture
- [ ] `source /opt/pytorch/bin/activate`
- [ ] `python -c "import torch; print(torch.cuda.is_available())"` → `True`
- [ ] (Optional) Add `source /opt/pytorch/bin/activate` to `~/.bashrc`
- [ ] Stop instance when done to save cost

---

*Last updated based on hands-on testing in `ap-southeast-2` (Sydney), 10 May 2026.*