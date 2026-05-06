# CLAUDE.md

**Local-only file.** This repo is an upstream clone of `theroyallab/tabbyAPI`. CLAUDE.md is added to `.git/info/exclude` and never pushed to upstream. Do not edit upstream source files unless contributing back.

## Purpose

ExllamaV2/V3 LLM inference server. In the hapax workspace it serves **Command-R 35B** (EXL3 5.0 bpw) on `:5000`; alternates in `models/` (Qwen3.5-9B, Qwen3.6-35B-A3B) are not the active default. LiteLLM (in the council Docker compose stack) routes `local-fast`, `coding`, `reasoning` here. See `hapax-council/CLAUDE.md § Architecture` for the GPU/cache contract.

## Local config

- `config.yml` — operator-edited, not in upstream:
  - `backend: exllamav3`
  - `model_dir: models`
  - `model_name: command-r-08-2024-exl3-5.0bpw`
  - `port: 5000`
  - `disable_auth: true` (single-operator workstation, axiom `single_user`)
- `models/` — contains the active Command-R 35B EXL3 directory plus alternates (Qwen3.5-9B, Qwen3.6-35B-A3B). `model_name` in `config.yml` selects the active default. No symlinks; standard layout.
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

- `endpoints/OAI/utils/chat_completion.py` — **harmony-style tool-call extractor**. Qwen3.5-9B's chat template emits tool calls as `<tool_call><function=NAME><parameter=KEY>VALUE</parameter>...</function></tool_call>` without declaring a `tool_start` template variable, so TabbyAPI's `generate_tool_calls` re-generation path is skipped and the raw XML leaks through as `message.content`. A fallback extractor (`_extract_native_tool_calls`) runs in `_create_response` when `generation["tool_calls"]` is empty, parses the XML, and populates `message.tool_calls` with proper OpenAI objects. Inert if a future template update declares `tool_start`. Without this patch, pydantic-ai structured outputs on the `reasoning` route deadlock into a validation-error retry loop that blows the KV page budget. See the patch marked `HAPAX LOCAL PATCH` in `endpoints/OAI/utils/chat_completion.py`.

## Gotchas

- **Edit upstream source only with a clear local-patch comment and CLAUDE.md entry.** Config and model swaps are always fine.
- **Restart cost**: model load takes ~30–60 s on EXL3. Don't restart tabbyapi for transient errors — investigate logs first.
- **Auth disabled**: `disable_auth: true` is correct for this single-operator workstation. Re-enabling would break the LiteLLM gateway and the benchmark script.
