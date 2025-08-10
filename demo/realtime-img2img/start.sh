set -euo pipefail
cd "$(dirname "$0")"
. .venv/bin/activate

# Use project-local HF cache if present (no re-downloads)
export HF_HOME="$PWD/.hf-cache"

# Safer first-run defaults
export CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES:-0}

cd demo/realtime-img2img

# Restore engines if we have an archive and no engines present yet
if [ ! -d engines ] && [ -f ../../artifacts/engines-img2img-trt9-batch1.tgz ]; then
  tar -xzf ../../artifacts/engines-img2img-trt9-batch1.tgz
fi

python main.py --acceleration tensorrt
