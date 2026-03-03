# Setting up the container so VS Code can connect to it

## Why the startup command is needed (RunPod + VS Code Remote-SSH)

RunPod pods expose a container over a public "SSH over exposed TCP" port (public IP + external port mapped to container port `22`). But most container images do not start an SSH daemon by default, and even if `openssh-server` is installed, `sshd` won't run unless a few runtime prerequisites exist. VS Code Remote-SSH specifically requires a working SSH server inside the container so it can upload and run the VS Code server.

## Startup command

```bash
bash -lc '
set -e
apt-get update
apt-get install -y openssh-server
mkdir -p /run/sshd /root/.ssh
chmod 700 /root/.ssh
echo "$PUBLIC_KEY" >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
ssh-keygen -A
sed -i "s/^#\\?PermitRootLogin.*/PermitRootLogin yes/" /etc/ssh/sshd_config
sed -i "s/^#\\?PasswordAuthentication.*/PasswordAuthentication no/" /etc/ssh/sshd_config
/usr/sbin/sshd
sleep infinity'
```

This startup command makes the container Remote-SSH-ready every time the pod boots:

- **Installs** `openssh-server`
  Ensures the `sshd` binary and config files exist inside the container.
- **Creates required runtime directories** (`/run/sshd`)
  `sshd` needs `/run/sshd` for privilege separation / PID/runtime files. Many containers don't have this directory by default, which causes `sshd` to fail on startup.
- **Sets up key-based auth for root** (`/root/.ssh/authorized_keys`)
  RunPod containers typically start without any SSH keys configured. We append the user's public key (provided via the `PUBLIC_KEY` environment variable) into `authorized_keys` and set strict permissions (`700` for `.ssh`, `600` for `authorized_keys`) so OpenSSH will accept them.
- **Generates host keys** (`ssh-keygen -A`)
  SSH requires host keys (e.g., RSA/ED25519) to identify the server. Fresh containers often don't have these keys, so we generate them at boot.
- **Enables root login + disables password auth**
  We allow root login (since this is a disposable dev environment) and force key-based auth by disabling password authentication.
- **Starts** `sshd`, **then keeps the container alive**
  `/usr/sbin/sshd` launches the SSH server. `sleep infinity` prevents the container from exiting immediately (containers exit when the main process ends), keeping SSH available for VS Code and terminal sessions.

In short: the startup command turns a generic container into a stable Remote-SSH target by provisioning SSH, keys, host identity, and a long-running process so the pod stays reachable.

## Setting up the template in the RunPod UI

This screenshot shows the template editor with the startup command pasted into the "Docker Command" or startup command field. This is the command from above, and it ensures the container boots with a working SSH server so VS Code can connect.

![RunPod Template Creation: Startup Command](https://runpod-ai-dynamo-trtllm.s3.us-east-1.amazonaws.com/public/runpod_template_1.png)

This screenshot shows the template networking section and environment variables. You need a **TCP** port that maps external traffic to container port `22` for SSH. The **HTTP** port is optional; add it only if you plan to expose a web service like Dynamo's OpenAI-compatible REST API (for example, `python -m dynamo.frontend --http-host 0.0.0.0 --http-port 8000` serving `/v1/chat/completions`) to clients outside the pod. If you don't expose it, the service is still reachable from inside the pod (e.g., `curl localhost:8000`), but your laptop or other external clients won't be able to hit it. It also shows the `PUBLIC_KEY` environment variable, which should be set to your SSH public key so the startup command can authorize it.

![RunPod Template Creation: HTTP and TCP ports, environment variables](https://runpod-ai-dynamo-trtllm.s3.us-east-1.amazonaws.com/public/runpod_template_2.png)

## Container version note (RunPod driver compatibility)

On RunPod's 4xH100 instances, the preinstalled NVIDIA driver was **580.126.09** (driver page: [NVIDIA driver 261243](https://www.nvidia.com/en-us/drivers/details/261243/)). CUDA 12.9 is the latest version that can target this driver. Based on the Dynamo support matrix ([CUDA versions by backend](https://docs.nvidia.com/dynamo/latest/getting-started/support-matrix#cuda-versions-by-backend)), the latest Dynamo / TensorRT-LLM releases that still support CUDA 12.9 are:

- Dynamo `0.6.1` (November 2025 release: [v0.6.1](https://github.com/ai-dynamo/dynamo/releases/tag/v0.6.1))
- TensorRT-LLM `1.1.0rc5` (release: [v1.1.0rc5](https://github.com/NVIDIA/TensorRT-LLM/releases/tag/v1.1.0rc5))

For the container list here: [NGC tensorrtllm-runtime](https://catalog.ngc.nvidia.com/orgs/nvidia/teams/ai-dynamo/containers/tensorrtllm-runtime), I chose `0.6.1`. The full image URL is `nvcr.io/nvidia/ai-dynamo/tensorrtllm-runtime:0.6.1`; here's what it looks like in the RunPod UI:

![RunPod Dynamo TensorRT-LLM image](https://runpod-ai-dynamo-trtllm.s3.us-east-1.amazonaws.com/public/runpod_template_image_1.png)

## Setting up the RunPod instance

First, under "Pods", click "Network Volume" and select the volume we created in "Storage". By doing this, once we connect to and download the HuggingFace model into the `/workspace` folder, if we Terminate our instance, we will still have the models downloaded.

![Mount volume as storage](https://runpod-ai-dynamo-trtllm.s3.us-east-1.amazonaws.com/public/instance_creation_1_volume.png)

Second, select an H100 SXM instance, set the GPU count to 4, and click "Change Template" (as of this writing in March 2026, 4x H100 comes out to $10.76/hr on-demand).

![Select H100 SXM](https://runpod-ai-dynamo-trtllm.s3.us-east-1.amazonaws.com/public/instance_creation_2_h100.png)

![Set GPU count to 4 and click Change Template](https://runpod-ai-dynamo-trtllm.s3.us-east-1.amazonaws.com/public/instance_creation_3_change_template.png)

Then, select the `nvcr.io/nvidia/ai-dynamo/tensorrtllm-runtime:0.6.1` template (the one we configured above with the startup command).

![Select Template](https://runpod-ai-dynamo-trtllm.s3.us-east-1.amazonaws.com/public/instance_creation_4_template.png)

## VSCode Connections

Note: this section assumes familiarity with connecting to remote instances via the Remote-SSH extension in VSCode; it merely covers a couple quirks encountered when connecting to _RunPod instances specifically_.

After we've created your pod, we can configure things so we can connect to it as a remote server from VS Code. Click your pod in the UI and you'll see this once it has started (with the custom image and startup command it take about 10 minutes to start):

![Connecting via SSH over TCP](https://runpod-ai-dynamo-trtllm.s3.us-east-1.amazonaws.com/public/ssh_over_tcp_1.png)

Copy the command under "SSH exposed over TCP"; for example `ssh root@216.243.220.226 -p 11661 -i ~/.ssh/id_ed25519`.

Update your local `~/.ssh/config` file, and add these lines:

```
Host runpod-4x-h100
  HostName 216.243.220.226
  User root
  Port 19582
  IdentityFile ~/.ssh/id_ed25519
  ServerAliveInterval 60
  ServerAliveCountMax 120
```

Replacing the `HostName` with your host name and the `Port` with your port. The `ServerAliveInterval` and `ServerAliveCountMax` lines are "keep the SSH tunnel alive" settings so your connection doesn't get silently dropped by NATs, firewalls, or idle timeouts (common with cloud pods and long-running VS Code sessions). `ServerAliveInterval 60` means the client sends a small keepalive message every 60 seconds; `ServerAliveCountMax 120` means it will retry up to 120 times before giving up. In the worst case, SSH will tolerate about 60 x 120 = 7200 seconds = 2 hours of a bad/stalled network before declaring the connection dead.

To connect to the server via the VS Code extension, we first have to confirm that we accept the fingerprint. Run the "SSH exposed over TCP" command _in a Terminal_ and type "yes" when prompted. Then you should be able to connect to the `runpod-4x-h100` instance via the Remote SSH extension. Using the "Open Folder" functionality, you should be able to connect directly to the `/workspace` folder where your persistent data is being saved (because of the volume we attached).
