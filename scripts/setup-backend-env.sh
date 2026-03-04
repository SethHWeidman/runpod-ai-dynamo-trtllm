#!/usr/bin/env bash
# Terminal 2 — install TRT libs and export env vars for the Dynamo backend.
# Must be sourced so exports persist in your shell:
#   source scripts/setup-backend-env.sh

set -euo pipefail

apt-get install -y libnvinfer10 libnvonnxparsers10 libnvinfer-plugin10

export OPAL_PREFIX=/opt/hpcx/ompi
export PATH="$OPAL_PREFIX/bin:$PATH"
export LD_LIBRARY_PATH="$OPAL_PREFIX/lib:/opt/hpcx/ucc/lib:/opt/hpcx/ucx/lib:${LD_LIBRARY_PATH:-}"

export TORCH_CUDA_ARCH_LIST=9.0
export OMPI_MCA_coll_hcoll_enable=0

export CUDA_HOME=/usr/local/cuda
export PATH="$CUDA_HOME/bin:$CUDA_HOME/nvvm/bin:$PATH"

echo "Backend env ready."
