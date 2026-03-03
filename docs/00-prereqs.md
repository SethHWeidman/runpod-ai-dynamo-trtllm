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
