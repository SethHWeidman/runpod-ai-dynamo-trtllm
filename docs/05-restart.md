# Restarting the instance

Every time the RunPod instance restarts you need to re-run the services and re-export the environment variables (nothing is persisted across restarts). Open two Terminals and do the following.

## Terminal 1 — services + Dynamo frontend

```bash
bash scripts/start-services.sh
```

This installs `iproute2`, starts etcd and NATS in the background, then runs the Dynamo frontend in the foreground. See [scripts/start-services.sh](../scripts/start-services.sh), [docs/03-etcd-nats.md](03-etcd-nats.md), and [docs/04-dynamo.md](04-dynamo.md) for background.

## Terminal 2 — Dynamo backend

```bash
source scripts/setup-backend-env.sh
```

> **Important:** use `source` (not `bash`) so the `export` statements persist in your shell session.

Then start the backend:

```bash
CUDA_VISIBLE_DEVICES=0,1,2,3 \
python -m dynamo.trtllm \
 --model-path /workspace/models/gpt-oss-20b \
 --served-model-name openai/gpt-oss-20b \
 --tensor-parallel-size 4
```

See [scripts/setup-backend-env.sh](../scripts/setup-backend-env.sh) and [docs/04-dynamo.md](04-dynamo.md) for what the env vars do and why the TRT libraries are needed.
