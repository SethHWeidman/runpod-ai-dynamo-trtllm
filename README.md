# runpod-ai-dynamo-trtllm

Illustration of using Dynamo and TensorRT-LLM in a RunPod-hosted 4xH100 instance.

Motivation: understand NVIDIA's inference stack by playing around with it.

## Instructions

Container note: the container image (`nvcr.io/nvidia/ai-dynamo/tensorrtllm-runtime:0.6.1`) was chosen to match RunPod's preinstalled NVIDIA driver. See [docs/00-template-setup.md](docs/00-template-setup.md) for the full driver/CUDA/Dynamo version rationale.

First, go to runpod.io. We're going to want to:

1. Create a storage volume
2. Create a template with TensorRT-LLM and Dynamo installed — [docs/00-template-setup.md](docs/00-template-setup.md)
3. Start a RunPod pod and connect via VS Code — [docs/01-instance-and-vscode.md](docs/01-instance-and-vscode.md)
4. Download the model — [docs/02-download_model.md](docs/02-download_model.md)
5. Start etcd and NATS — [docs/03-etcd-nats.md](docs/03-etcd-nats.md)
6. Run Dynamo — [docs/04-dynamo.md](docs/04-dynamo.md)

On every instance restart, see [docs/05-restart.md](docs/05-restart.md).
