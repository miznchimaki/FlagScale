#!/usr/bin/bash
source ${HOME}/.bashrc
# set -euo pipefail

CONFIG="${CONFIG:-./examples/qwen3/conf/inference_fl.yaml}"
RUN_SH="${RUN_SH:-./outputs/qwen3_14b/inference_logs/scripts/host_0_localhost_run.sh}"
LOG_DIR="${LOG_DIR:-./outputs/qwen3_14b/flaggems_benchmark}"
mkdir -p "$LOG_DIR"

if [ ! -f "$RUN_SH" ]; then
  flagscale inference qwen3 --config "$CONFIG"
fi

echo "[1/2] Baseline run..."
bash "$RUN_SH" 2>&1 | tee "$LOG_DIR/baseline.log"

echo "[2/2] FlagGems run..."
bash scripts/run_qwen3_14b_flaggems.sh 2>&1 | tee "$LOG_DIR/flaggems.log"

echo
echo "Logs:"
echo "  $LOG_DIR/baseline.log"
echo "  $LOG_DIR/flaggems.log"

