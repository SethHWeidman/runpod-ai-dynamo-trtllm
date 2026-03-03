# Downloading GPT-OSS 20B

Make directories where we'll store our model artifacts:

```bash
mkdir -p /workspace/models
```

Run

```
hf download openai/gpt-oss-20b \
  --local-dir /workspace/models/gpt-oss-20b \
  --exclude "original/*"
```
