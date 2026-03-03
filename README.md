# runpod-ai-dynamo-trtllm

Illustration of using Dynamo and TensorRT-LLM in a RunPod-hosted 4xH100 instance.

Motivation: understand NVIDIA's inference stack by playing around with it.

## Instructions

Container note: the container image (`nvcr.io/nvidia/ai-dynamo/tensorrtllm-runtime:0.6.1`) was chosen to match RunPod's preinstalled NVIDIA driver. See [docs/00-template-setup.md](docs/00-template-setup.md) for the full driver/CUDA/Dynamo version rationale.

First, go to runpod.io. We're going to want to:

1. Create a storage volume
2. Create a template with TensorRT-LLM and Dynamo installed — [docs/00-template-setup.md](docs/00-template-setup.md)
3. Start a RunPod pod and connect via VS Code — [docs/01-instance-and-vscode.md](docs/01-instance-and-vscode.md)
