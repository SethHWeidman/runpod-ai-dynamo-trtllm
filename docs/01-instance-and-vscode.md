# Launching a pod and connecting via VS Code

## Setting up the RunPod instance

First, under "Pods", click "Network Volume" and select the volume we created in "Storage". By doing this, once we connect to and download the HuggingFace model into the `/workspace` folder, if we Terminate our instance, we will still have the models downloaded.

![Mount volume as storage](https://runpod-ai-dynamo-trtllm.s3.us-east-1.amazonaws.com/public/instance_creation_1_volume.png)

Second, select an H100 SXM instance, set the GPU count to 4, and click "Change Template" (as of this writing in March 2026, 4x H100 comes out to $10.76/hr on-demand).

![Select H100 SXM](https://runpod-ai-dynamo-trtllm.s3.us-east-1.amazonaws.com/public/instance_creation_2_h100.png)

![Set GPU count to 4 and click Change Template](https://runpod-ai-dynamo-trtllm.s3.us-east-1.amazonaws.com/public/instance_creation_3_change_template.png)

Then, select the `nvcr.io/nvidia/ai-dynamo/tensorrtllm-runtime:0.6.1` template (the one we configured in [docs/00-template-setup.md](00-template-setup.md)).

![Select Template](https://runpod-ai-dynamo-trtllm.s3.us-east-1.amazonaws.com/public/instance_creation_4_template.png)

## VS Code connection

Note: this section assumes familiarity with connecting to remote instances via the Remote-SSH extension in VS Code; it merely covers a couple quirks encountered when connecting to _RunPod instances specifically_.

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
