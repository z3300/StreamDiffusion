set -euo pipefail
cd "$(dirname "$0")"

# 1) venv
uv venv .venv
. .venv/bin/activate

# 2) system info
python -V

# 3) core pins (what made your build work)
uv pip install -U "setuptools>=70" wheel packaging
uv pip install -e .                             # your fork/branch with the TRT9 fix
uv pip install "numpy<2"                        # avoid NumPy 2 ABI breaks
uv pip install -U cuda-python                   # provides cuda.cudart for TRT 9

# 4) TRT 9 pre-release + tools from NVIDIA index (allow pre-release)
uv pip install \
  --prerelease=allow --index-strategy unsafe-best-match \
  --extra-index-url https://pypi.nvidia.com \
  "tensorrt>=9,<10" onnx-graphsurgeon==0.5.2 polygraphy || {
    echo "If this fails, pin a specific 9.x pre-release from NVIDIA index."
    exit 1
  }

# 5) put TRT + CUDA runtime libs on path (venv wheels or system)
export LD_LIBRARY_PATH="$(python -c 'import sys,os; p=os.path.join(sys.prefix,\"lib\",\"python3.10\",\"site-packages\",\"tensorrt_libs\"); print(p) if os.path.isdir(p) else \"\"'):$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="$(python -c 'import sys,os; p=os.path.join(sys.prefix,\"lib\",\"python3.10\",\"site-packages\",\"nvidia\",\"cuda_runtime\",\"lib\"); print(p) if os.path.isdir(p) else \"\"'):$LD_LIBRARY_PATH"
[ -d /usr/local/cuda/lib64 ] && export LD_LIBRARY_PATH="/usr/local/cuda/lib64:$LD_LIBRARY_PATH"

# 6) Optional: restore HF cache and engines if present
if [ -f artifacts/hf-cache.tgz ]; then
  mkdir -p .hf-cache
  tar -xzf artifacts/hf-cache.tgz -C .hf-cache
fi

echo "Setup complete."
