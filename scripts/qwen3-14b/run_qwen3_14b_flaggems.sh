#!/usr/bin/env bash
source ${HOME}/.bashrc
set -euo pipefail

CONFIG="${CONFIG:-./examples/qwen3/conf/inference_fl.yaml}"
RUN_SH="${RUN_SH:-./outputs/qwen3_14b/inference_logs/scripts/host_0_localhost_run.sh}"

# all / selective
ENABLE_MODE="${ENABLE_MODE:-all}"

OPS="${OPS:-rms_norm,softmax,silu,mul,add,mm,bmm}"

if [ ! -f "$RUN_SH" ]; then
  flagscale inference qwen3 --config "$CONFIG"
fi

if [ ! -f "$RUN_SH" ]; then
  echo "[ERROR] Cannot find generated run script: $RUN_SH"
  exit 1
fi

INJECT_DIR="$(pwd)/outputs/flaggems_inject"
mkdir -p "$INJECT_DIR"

cat > "$INJECT_DIR/sitecustomize.py" <<'PY'
import os
import sys

def _log(msg):
    sys.stderr.write(msg + "\n")
    sys.stderr.flush()

try:
    argv0 = sys.argv[0] if sys.argv else ""
    argv = " ".join(sys.argv)

    skip = False

    if argv0 == "-c":
        skip = True

    lower_argv = argv.lower()
    if any(x in lower_argv for x in ["conda", "pip", "setup.py", "easy_install"]):
        skip = True

    if os.environ.get("FLAGGEMS_DISABLE", "0") == "1":
        skip = True

    if not skip:
        import flag_gems

        mode = os.environ.get("FLAGGEMS_ENABLE_MODE", "all")
        ops = os.environ.get("FLAGGEMS_ONLY_OPS", "")

        if mode == "selective":
            include = [x.strip() for x in ops.split(",") if x.strip()]
            flag_gems.only_enable(include=include)
            _log(f"[FlagGems] selective enabled: {include}")
        else:
            flag_gems.enable()
            _log("[FlagGems] global enabled via sitecustomize.py")

except Exception as e:
    _log(f"[FlagGems] enable failed: {type(e).__name__}: {e}")
    if os.environ.get("FLAGGEMS_STRICT", "1") == "1":
        raise
PY

export PYTHONPATH="$INJECT_DIR:${PYTHONPATH:-}"
export FLAGGEMS_ENABLE_MODE="$ENABLE_MODE"
export FLAGGEMS_ONLY_OPS="$OPS"

export TRITON_CACHE_DIR="${TRITON_CACHE_DIR:-$(pwd)/outputs/triton_cache_flaggems}"
mkdir -p "$TRITON_CACHE_DIR"

echo "[INFO] Running with FlagGems:"
echo "       CONFIG=$CONFIG"
echo "       RUN_SH=$RUN_SH"
echo "       ENABLE_MODE=$ENABLE_MODE"
echo "       OPS=$OPS"
echo "       PYTHONPATH=$PYTHONPATH"
echo "       TRITON_CACHE_DIR=$TRITON_CACHE_DIR"

bash "$RUN_SH"
