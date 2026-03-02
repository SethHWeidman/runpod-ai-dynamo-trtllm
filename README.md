# runpod-ai-dynamo-trtllm

Illustration of using Dynamo and TensorRT-LLM in a RunPod-hosted 4xH100 instance.

Motivation: understand NVIDIA's inference stack by playing around with it.

# Steps

First, go to runpod.io. We're going to want to:

1. Create a storage volume
2. Create a template with TensorRT-LLM and Dynamo installed
3. Start a RunPod pod with a special startup command
