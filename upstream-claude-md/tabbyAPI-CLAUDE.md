# CLAUDE.md

**Local-only file.** This repo is an upstream clone of `theroyallab/tabbyAPI`. CLAUDE.md is added to `.git/info/exclude` and never pushed to upstream. Do not edit upstream source files unless contributing back.

## Purpose

ExllamaV2/V3 LLM inference server. In the hapax workspace it serves Qwen3.5-9B (EXL3 5.0 bpw, 9B dense DeltaNet) on `:5000`. LiteLLM (in the council Docker compose stack) routes the model aliases `local-fast`, `coding`, and `reasoning` here.

## Local config

- `config.yml` — operator-edited, not in upstream:
  - `backend: exllamav3`
  - `model_dir: models`
  - `model_name: Qwen3.5-9B-exl3-5.00bpw`
  - `port: 5000`
  - `disable_auth: true` (single-operator workstation, axiom `single_user`)
- `models/` — contains the Qwen3.5-9B EXL3 model directory. No symlinks; standard layout.
- `config_sample.yml` — pristine upstream default. Do not edit.

## Run

TabbyAPI is run as a systemd user unit, not invoked manually. The unit file lives in **the council repo**, not here:

```
hapax-council/systemd/units/tabbyapi.service
```

Manage via:

```bash
systemctl --user status tabbyapi
systemctl --user restart tabbyapi
journalctl --user -u tabbyapi -f
```

The unit sets `CUDA_VISIBLE_DEVICES=0` (TabbyAPI exclusively owns the GPU; Ollama is GPU-isolated to CPU-only embedding work — see `hapax-council/CLAUDE.md § Architecture`).

## Integration

- LiteLLM gateway at `http://localhost:4000` (council Docker compose) routes `local-fast`, `coding`, `reasoning` model aliases to `http://localhost:5000`.
- Direct hits (bypassing LiteLLM) are used by `hapax-council/scripts/benchmark_prompt_compression_b6.py` to measure raw latency without the LiteLLM hop.
- VRAM coexistence: TabbyAPI is the dominant GPU consumer. `nvidia-smi` typically shows ~12 GB used. See `hapax-council/CLAUDE.md` for the full GPU budget.

## Updating from upstream

```bash
git fetch origin
git rebase origin/main         # NOT merge — keep history linear
systemctl --user restart tabbyapi
```

If `config.yml` conflicts with upstream changes (rare — it has been stable), keep the local version.

## What lives elsewhere

- The systemd unit: `hapax-council/systemd/units/tabbyapi.service`
- LiteLLM routing config: `hapax-council/litellm/config.yaml`
- Health monitoring: `hapax-council/agents/health_monitor/` checks the `:5000` endpoint
- Model inventory + benchmark results: `~/hapax-state/benchmarks/`

## Gotchas

- **Do not edit upstream source files.** Config and model swaps only.
- **GPU isolation contract**: nothing else may use `CUDA_VISIBLE_DEVICES=0` while tabbyapi is running. Ollama systemd unit explicitly sets `CUDA_VISIBLE_DEVICES=""` to enforce this.
- **Restart cost**: model load takes ~30–60 s on EXL3. Don't restart tabbyapi for transient errors — investigate logs first.
- **Auth disabled**: `disable_auth: true` is correct for this single-operator workstation. Re-enabling would break the LiteLLM gateway and the benchmark script.
