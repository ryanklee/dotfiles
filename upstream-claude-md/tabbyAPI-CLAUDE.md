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

## Local source patches

One local modification to upstream source. Git history keeps it visible; rebasing from upstream may conflict on this file.

- `endpoints/OAI/utils/chat_completion.py` — **harmony-style tool-call extractor** (2026-04-13). Qwen3.5-9B's chat template emits tool calls as `<tool_call><function=NAME><parameter=KEY>VALUE</parameter>...</function></tool_call>` without declaring a `tool_start` template variable, so TabbyAPI's `generate_tool_calls` re-generation path is skipped and the raw XML leaks through as `message.content`. A fallback extractor (`_extract_native_tool_calls`) runs in `_create_response` when `generation["tool_calls"]` is empty, parses the XML, and populates `message.tool_calls` with proper OpenAI objects. Inert if a future template update declares `tool_start`. Without this, pydantic-ai structured outputs on the `reasoning` route (thinking mode) deadlock into a validation-error retry loop that blows TabbyAPI's `max_seq_len=4096` KV page budget — the original bug killed `hapax-imagination-loop` for 62h (2026-04-10 21:41 CDT → 2026-04-13 ~12:00). See the patch in `endpoints/OAI/utils/chat_completion.py` marked `HAPAX LOCAL PATCH`.

## Gotchas

- **Edit upstream source only with a clear local-patch comment and CLAUDE.md entry.** Config and model swaps are always fine.
- **GPU isolation contract**: nothing else may use `CUDA_VISIBLE_DEVICES=0` while tabbyapi is running. Ollama systemd unit explicitly sets `CUDA_VISIBLE_DEVICES=""` to enforce this.
- **Restart cost**: model load takes ~30–60 s on EXL3. Don't restart tabbyapi for transient errors — investigate logs first.
- **Auth disabled**: `disable_auth: true` is correct for this single-operator workstation. Re-enabling would break the LiteLLM gateway and the benchmark script.
