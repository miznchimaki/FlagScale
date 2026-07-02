#!/bin/bash

source /root/miniconda3/bin/activate flagscale-inference
mkdir -p /workspace/projects/FlagScale/outputs/qwen3_14b/inference_logs
mkdir -p /workspace/projects/FlagScale/outputs/qwen3_14b/inference_logs/pids

cd /root/miniconda3/envs/flagscale-inference/lib/python3.12/site-packages

export PYTHONPATH=/root/miniconda3/envs/flagscale-inference/lib/python3.12/site-packages:${PYTHONPATH}

cmd="VLLM_PLUGINS=fl VLLM_USE_FLASHINFER_SAMPLER=0 VLLM_LOGGING_LEVEL=INFO CUDA_VISIBLE_DEVICES=7 CUDA_DEVICE_MAX_CONNECTIONS=1 python flagscale/inference/inference_llm.py --config-path=/workspace/projects/FlagScale/outputs/qwen3_14b/inference_logs/scripts/inference.yaml"

nohup bash -c "$cmd; sync" >> /workspace/projects/FlagScale/outputs/qwen3_14b/inference_logs/host_0_localhost.output 2>&1 & echo $! > /workspace/projects/FlagScale/outputs/qwen3_14b/inference_logs/pids/host_0_localhost.pid

