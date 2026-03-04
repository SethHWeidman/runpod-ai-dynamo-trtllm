# Running Dynamo

## Start Dynamo

Open up a new Terminal and run the Dynamo frontend: `python -m dynamo.frontend --http-host 0.0.0.0 --http-port 8000`.

## Install TensorRT runtime libraries

`python -m dynamo.trtllm` imports and initializes TensorRT-LLM at runtime, which loads TensorRT shared libraries (`.so` files). The `tensorrtllm-runtime` container doesn't ship the full TRT runtime set, so without installing these you'll hit `ImportError: libnvinfer.so.10: cannot open shared object file`, or failures when TRT-LLM tries to create or deserialize engines and plugins.

```bash
apt-get update
apt-get install -y \
  libnvinfer10 \
  libnvonnxparsers10 \
  libnvinfer-plugin10
ldconfig
```

- **`libnvinfer10`** — core TensorRT runtime (`libnvinfer.so.10`). The big one.
- **`libnvinfer-plugin10`** — TensorRT plugin library (`libnvinfer_plugin.so.10`). TRT-LLM uses plugins heavily (attention, GEMM variants, quant kernels, etc.); missing this breaks engine init even if `libnvinfer10` is present.
- **`libnvonnxparsers10`** — ONNX parser (`libnvonnxparser.so.10`). Not always needed for pure engine loading, but many build/convert paths import it and its absence commonly causes surprise runtime failures.

Run `ldconfig` after installing so the dynamic linker can find the libs without having to modify `LD_LIBRARY_PATH`. Note: you need to do this once per container filesystem — on RunPod you often start fresh containers, so it needs to be re-run each time.

Moreover, we have to set several environment variables to get the Dynamo backend to run:

```bash
###############################################################################
# MPI / HPC-X runtime wiring
###############################################################################

# OpenMPI "prefix": tells OpenMPI where its installation root lives.
# Needed in containers because OpenMPI sometimes thinks it's installed in a
# build-time path (e.g., /build-result/...) and then can't find its own runtime
# files, help text, or internal executables (orted, etc.).
export OPAL_PREFIX=/opt/hpcx/ompi

# Put OpenMPI user-facing binaries (mpirun, ompi_info, orted) on PATH.
# This ensures Dynamo/TRT-LLM uses the HPC-X/OpenMPI shipped in the container,
# rather than any system OpenMPI that might also be installed.
export PATH="$OPAL_PREFIX/bin:$PATH"

# Put OpenMPI libs (libmpi.so.*) on the dynamic loader path.
# This fixes the original "libmpi.so.40: cannot open shared object file" error
# when importing torch / mpi4py / TRT-LLM components that link against MPI.
#
# We also include UCX/UCC paths because HPC-X MPI commonly depends on UCX/UCC
# for transports/collectives even on a single node (and NIXL can use UCX too).
export LD_LIBRARY_PATH="$OPAL_PREFIX/lib:/opt/hpcx/ucc/lib:/opt/hpcx/ucx/lib:${LD_LIBRARY_PATH:-}"

###############################################################################
# Torch build / JIT noise + compile performance
###############################################################################

# Limits PyTorch extension/JIT compilation to the GPU arch you actually have.
# H100 is SM90 -> "9.0". This:
# - removes the warning "TORCH_CUDA_ARCH_LIST is not set..."
# - avoids compiling code for every possible GPU arch
# - speeds up first-time JIT builds (e.g., flashinfer JIT kernels)
export TORCH_CUDA_ARCH_LIST=9.0

###############################################################################
# Avoid Mellanox hcoll / hcoll-related warnings or missing-plugin issues
###############################################################################

# Disable the hcoll collective module (Mellanox hierarchical collectives).
# In many containers it's either not present, mismatched, or irrelevant for
# single-node runs. This prevents OpenMPI from trying to use it.
export OMPI_MCA_coll_hcoll_enable=0

###############################################################################
# CUDA toolkit paths
###############################################################################

# Tells build systems (PyTorch's cpp_extension, CMake wrappers) and nvcc
# itself where the CUDA toolkit lives so they can find headers (include/),
# libs (lib64/), and the compiler.
export CUDA_HOME=/usr/local/cuda

# Makes nvcc (and other CUDA tools beyond plain "nvcc") callable by name.
# Critically, PATH="$CUDA_HOME/nvvm/bin:..." is required because nvcc shells
# out to NVVM compiler-stage executables—notably cicc—for JIT compilation
# (e.g., FlashInfer JIT kernels). Even if nvcc --version works, compilation
# will fail with "sh: 1: cicc: not found" if nvvm/bin isn't on PATH.
export PATH="$CUDA_HOME/bin:$CUDA_HOME/nvvm/bin:$PATH"
```

## Start the Dynamo backend

In the same Terminal where these environment variables have been set, run:

```bash
CUDA_VISIBLE_DEVICES=0,1,2,3 \
python -m dynamo.trtllm \
 --model-path /workspace/models/gpt-oss-20b \
 --served-model-name openai/gpt-oss-20b \
 --tensor-parallel-size 4
```

Now you've started Dynamo and are ready to hit it!
