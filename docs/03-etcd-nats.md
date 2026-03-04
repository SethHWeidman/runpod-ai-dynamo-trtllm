# Starting etcd and NATS

Since we're running on a single RunPod pod (not Kubernetes), we need to start `etcd` and NATS ourselves. From the [NGC TensorRT-LLM runtime container page](https://catalog.ngc.nvidia.com/orgs/nvidia/teams/ai-dynamo/containers/tensorrtllm-runtime?version=0.6.1):

> etcd and NATS remain available as optional alternatives for non-Kubernetes environments.

Links: [etcd](https://etcd.io), [NATS](https://docs.nats.io).

**1. Create the logs directory** (needed for log redirection below):

```bash
mkdir -p /workspace/logs
```

**2. Add `etcd` to your PATH.** In this container, the binary lives at `/usr/local/bin/etcd/etcd` (i.e. inside a subdirectory, not directly in `/usr/local/bin`), so it needs to be added explicitly:

```bash
export PATH="/usr/local/bin/etcd:$PATH"
```

**3. Install `iproute2`** for the `ss` tool (used in step 6 to verify the services are up):

```bash
apt-get update
apt-get install -y iproute2
```

**4. Start `etcd`:**

```bash
nohup etcd \
  --listen-client-urls http://0.0.0.0:2379 \
  --advertise-client-urls http://0.0.0.0:2379 \
  --data-dir /workspace/etcd-data \
  > /workspace/logs/etcd.log 2>&1 &
```

**5. Start NATS:**

```bash
nohup nats-server -js -p 4222 -m 8222 \
  --store_dir /workspace/nats-data \
  > /workspace/logs/nats.log 2>&1 &
```

**6. Verify** both are listening on their expected ports:

```bash
ss -lntp | egrep "2379|4222|8222" || true
```

You should see:

```
LISTEN 0      4096               *:8222             *:*    users:(("nats-server",pid=2120,fd=3))
LISTEN 0      4096               *:4222             *:*    users:(("nats-server",pid=2120,fd=6))
LISTEN 0      4096               *:2379             *:*    users:(("etcd",pid=2265,fd=7))
```
