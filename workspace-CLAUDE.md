# CLAUDE.md

Guidance for Claude Code across the multi-project workspace.

## Workspace

Nine repositories, three core:

- **hapax-constitution** — Governance specification (axioms, implications, canons). Spec-only, no runtime code. Publishes `hapax-sdlc` package.
- **hapax-council** — Personal operating environment. ~190 agents, voice daemon, studio compositor, reactive engine. Logos API on `:8051`.
- **hapax-officium** — Management decision support. Filesystem-as-bus data model. Logos API on `:8050`.
- **hapax-watch** — Wear OS companion app. Streams biometric sensor data (heart rate, HRV, skin temperature, sleep) to council logos API.
- **hapax-phone** — Android companion app. Kotlin/Compose. Streams daily health summaries + 60s phone context to council.
- **hapax-mcp** — MCP server (38 tools) bridging logos APIs to Claude Code tools.
- **tabbyAPI** — External LLM inference server (ExllamaV2/V3). Upstream clone of `theroyallab/tabbyAPI`. See § External Dependencies.
- **atlas-voice-training** — Custom wake word training pipeline (Docker-based openWakeWord fine-tuning). Upstream clone of `briankelley/atlas-voice-training`.
- **distro-work** — System maintenance scripts and research docs. Not a software project.

Each sub-project has its own CLAUDE.md — always read it before working in that project. The two upstream clones (tabbyAPI, atlas-voice-training) carry local-only CLAUDE.md files via `.git/info/exclude`; do not push them.

**Obsidian vault** at `~/Documents/Personal/` — single source of truth for all life planning (goals, sprint measures, daily notes, people, creative work). Kebab-case filenames/dirs, PARA structure. `obsidian-hapax` plugin bridges vault to Logos API. Vault-native goal notes feed the orientation panel. See hapax-council CLAUDE.md § Obsidian Integration.

## Shared Conventions (all Python projects)

- **uv** for everything (never pip). `uv sync --all-extras` for council (services depend on `audio`, `sync-pipeline`, `logos-api` extras). `uv run pytest tests/ -q`, `uv run ruff check .`, `uv run ruff format .`, `uv run pyright`.
- Python 3.12+, mandatory type hints, Pydantic models for structured data.
- Ruff: `line-length=100`, double quotes, `select=["E","F","I","UP","B","SIM","TCH"]`, `known-first-party = ["agents", "shared", "logos"]`.
- Testing: `unittest.mock` only, each test file self-contained, no shared conftest fixtures. `asyncio_mode = "auto"`. Tests marked `llm` excluded by default.
- **pydantic-ai**: Use `output_type` (not `result_type`), `result.output` (not `result.data`). All LLM calls through LiteLLM gateway.
- Secrets via `pass` + `direnv` (`.envrc` gitignored), central config in `shared/config.py`.
- Agents run as modules: `uv run python -m agents.<name> [flags]`.

## Git Workflow

- Conventional commits, feature branches from `main`.
- **Interface-qualified worktree slots, strictly enforced:**
  - `hapax-council/` — primary/integrator worktree
  - `hapax-council--<greek>` / legacy descriptive variants — Claude Code permanent lanes
  - `hapax-council--cx-<color>` — Codex first-class lanes
  - `hapax-council--<slug>` — one spontaneous non-session worktree
- Each session works in its own worktree. One branch at a time per session. No branch switching into another session's worktree.
- **Dev workflow:** `pnpm tauri dev` for development (Vite runs internally, serves to Tauri webview only). Production binary bundles the frontend — build with `pnpm tauri build`, install to `~/.local/bin/hapax-logos`.
- **Rebase alpha after beta merges:** After merging PRs from beta, rebase alpha onto main.
- **Always PR completed work before moving on.** Do NOT start new work until current work is resolved (PR submitted or no changes remaining). Blocking requirement.
- **You own every PR you create through to merge.** Monitor CI, fix failures, merge when ready.
- **Hooks enforce branch discipline.** `no-stale-branches.sh` blocks new branch creation when unmerged branches exist. `work-resolution-gate.sh` blocks edits when open PRs exist. Destructive git commands are blocked on feature branches with commits ahead of main. These hooks interact with subagents — see global CLAUDE.md § "Subagent Git Safety" for mandatory patterns.
- CODEOWNERS protects governance files.

## SDLC Methodology and Platform Lanes

Methodology gates are load-bearing across single-session work and coordinated
lanes. Operator prose, relay notes, dashboards, terminal paste, and session
memory are intake material; implementation authority comes from a request or
cc-task with `authority_case`, non-null `parent_spec`, route metadata, declared
mutation surface, and the applicable evidence gates.

Read-only intake/research and governance-object creation are allowed only when
the task or hook explicitly marks that path as intake/bootstrap. Source,
runtime, vault, system, provider-spend, public-surface, aesthetic, theoretical,
visual, audio, and audiovisual mutations require a claimed cc-task before the
mutation. Task creation must follow request -> WSJF -> cc-task; manual writes to
claim files are not a process substitute.

Visible terminal lanes, headless lanes, IDE lanes, browser controls, and
SBCL/CLOG controls must dispatch through
`hapax-council/scripts/hapax-methodology-dispatch` or a wrapper that delegates
to it. Do not send or follow generic prompts to claim "the next task" or
"highest WSJF". A governed dispatch names the task, lane, platform, mode/profile,
AuthorityCase, parent spec, worktree, claim/close commands, route evidence, and
current capability/quota blockers.

Current coding-platform configuration surfaces:

- Codex: `~/.codex/config.toml`, trusted project `.codex/config.toml`,
  `AGENTS.md`, `~/.codex/rules/`, MCP tables, hooks, and `codex exec` for
  non-interactive work. Hapax Codex launchers run no-ask with the hook adapter;
  no-ask is not a governance bypass.
- Claude Code: `~/.claude/settings.json`, repo `.claude/settings.json`,
  `.claude/settings.local.json`, `CLAUDE.md`, `.mcp.json`, permission rules,
  hooks, and `claude -p`/headless flags. Broad tool permissions are constrained
  by cc-task, branch, PR, and hook gates.
- Gemini CLI: `~/.gemini/settings.json`, project `.gemini/settings.json`,
  `/etc/gemini-cli/settings.json`, `GEMINI.md` or configured context file names,
  policy paths, sandbox/profile settings, tool/MCP allowlists, hooks, and
  `--prompt`/headless flags.
- Mistral Vibe: `~/.vibe/config.toml`, project `.vibe/config.toml`,
  `VIBE_HOME`, `~/.vibe/AGENTS.md`, `~/.vibe/agents/`, `~/.vibe/prompts/`,
  trusted folders, tool permissions, and MCP server tables.
- Antigravity: global rule `~/.gemini/GEMINI.md`, global workflows under
  `~/.gemini/antigravity/global_workflows/`, and workspace rules/workflows under
  `.agents/rules/` and `.agents/workflows/`. Treat `.agent/` as legacy
  compatibility only; new protocol-facing rules and workflows belong in
  `.agents/`.

## Shared Infrastructure

All running locally. Docker Compose for infrastructure, systemd user units for application services. No process-compose in production boot chain.

**Docker containers** (20, `restart: always`):
- **LiteLLM** — API gateway (`:4000` council, `:4100` officium), routes to Claude/Gemini/TabbyAPI. Redis response caching (1h TTL). No local model fallback chains — TabbyAPI failures degrade gracefully in agents.
- **Qdrant** — Vector DB. Canonical schema in `shared/qdrant_schema.py` (11 collections; `operator-patterns` is dead-schema, do not add writers).
- **Langfuse** — LLM observability (`:3000`); blob store on MinIO `/data` with 14-day lifecycle rule on `events/` (prevents inode exhaustion).
- **Prometheus** + **Grafana** — Metrics and dashboards.
- Plus: PostgreSQL (audit), Redis, ClickHouse, n8n, ntfy, OpenWebUI.

**Host services** (systemd user units, lingering):
- **TabbyAPI** — Primary local inference (`:5000`), serves Command-R 35B (EXL3 5.0bpw). LiteLLM routes `local-fast`, `coding`, `reasoning` here. See `hapax-council/CLAUDE.md § Architecture` for `gpu_split` / cache details.
- **Ollama** — CPU embedding only (nomic-embed-cpu). GPU-isolated via `CUDA_VISIBLE_DEVICES=""` in systemd unit — TabbyAPI exclusively owns the GPU. `qwen3:8b` deleted and LiteLLM route removed. Python MODELS dict must use LiteLLM route names (`local-fast`, `coding`, `reasoning`), never Ollama model names directly.
- **rag-ingest** — Document ingestion watchdog (inotify-only drip mode, no bulk rescan timer). CPU-only via `Environment=CUDA_VISIBLE_DEVICES=""` in `systemd/overrides/rag-ingest.service.d/gpu-isolate.conf` — docling's PyTorch layout/OCR models would otherwise land on CUDA and race TabbyAPI for VRAM. Same isolation pattern as Ollama. Bulk rescan is on-demand only: `.venv-ingest/bin/python -m agents.ingest --bulk-only`.
- **hapax-secrets** — Centralized credential loading (oneshot, all services depend on this)
- **logos-api** / **officium-api** — FastAPI on `:8051` / `:8050`
- **hapax-logos** — Native visual + wgpu rendering surface
- **hapax-dmn** — Always-on cognitive substrate
- **hapax-imagination** + **hapax-imagination-loop** — GPU visual surface + imagination daemon
- **hapax-reverie** — Visual expression daemon
- **hapax-content-resolver** — Content resolver daemon
- **hapax-watch-receiver** — Wear OS biometric sensor receiver
- **hapax-daimonion** — Persistent voice daemon (STT on GPU, TTS on CPU via Kokoro 82M)
- **studio-compositor** — GPU camera tiling/recording/HLS
- **visual-layer-aggregator** — Perception → Stimmung → /dev/shm
- 115 timers (sync agents, health monitor, VRAM watchdog, backups, storage arbiter, rebuilds)

**24/7 recovery**: Kernel panic auto-reboot (10s), hardware watchdog (SP5100 TCO, 30s), greetd autologin, lingering. See `hapax-council/systemd/README.md`.

**Design language**: `hapax-council/docs/logos-design-language.md` governs all visual surfaces (Logos app, desktop, officium). Two palettes: Gruvbox Hard Dark (R&D) and Solarized Dark (Research). Mode switching via `hapax-working-mode` script propagates to all surfaces. Component colors must use CSS custom properties or Tailwind classes — no hardcoded hex. See §11 for governed vs excluded surfaces.

## Inter-Project Dependencies

`hapax-constitution` publishes the `hapax-sdlc` package, consumed by council (`hapax-sdlc`) and officium (`hapax-sdlc[demo]`). `hapax-watch` and `hapax-phone` POST biometric/context payloads to council's logos API. `hapax-mcp` bridges the council/officium logos APIs to Claude Code. `tabbyAPI` is a standalone inference backend.

## External Dependencies

Two repositories in this workspace are upstream clones — git points at someone else's GitHub. Local commits stay local; CLAUDE.md files for these repos are added via `.git/info/exclude` so they never enter the upstream's tracked tree.

- **tabbyAPI** (upstream `theroyallab/tabbyAPI`) — runs as a systemd user unit, serves Command-R 35B EXL3 on `:5000`. Local config in `tabbyAPI/config.yml`; models in `tabbyAPI/models/`. The systemd unit lives in the council repo.
- **atlas-voice-training** (upstream `briankelley/atlas-voice-training`) — Docker-based openWakeWord fine-tuning pipeline. Trained `.tflite` models drop into `~/.local/share/openwakeword/`, where hapax-daimonion auto-discovers them.

## Working mode

Operator working mode (`research`/`rnd`) is the single mode system across the stack. SSOT: `~/.cache/hapax/working-mode`, written by the `hapax-working-mode` CLI. Council adds a third mode (`fortress`) for studio livestream gating; officium intentionally omits it. Legacy `cycle_mode` (dev/prod) endpoints remain as deprecated aliases routing to `working-mode` server-side. Migration spec: `hapax-council/docs/officium-design-language.md` §9.

## Perplexity Delegation

Perplexity Sonar models are routed through LiteLLM as `web-scout`, `web-research`, `web-reason`, `web-deep`. Use them when the task needs real-time web search grounding — Perplexity is the only provider with dedicated search infrastructure, provider-neutral web coverage, and per-response cost transparency.

**Auto-invoke when:**
- Real-time web search for current-event grounding or fact-checking
- Literature scouting with citation URLs (CHI 2027, academic research)
- Technology/model/vendor comparison requiring current data
- Content opportunity discovery across diverse web sources

**Model selection:**
- `web-scout` (sonar, $1/$1): fast factual lookups, current-event claims
- `web-research` (sonar-pro, $3/$15): multi-source investigation, 200K context
- `web-reason` (sonar-reasoning-pro, $2/$8): cross-source claim verification
- `web-deep` (sonar-deep-research, $2/$8+extras): systematic reviews, deep literature analysis

**Use Gemini instead when:** long-doc/image/video perception, Google-specific search, OCR. **Keep on Claude when:** multi-file refactors, tool-heavy agent loops, governance-protected work.

**Mandatory:** after every Perplexity call, scan response for 429/rate-limit signals. Surface immediately to the operator if hit.

## CLAUDE.md governance

The rotation policy and rubric for every workspace CLAUDE.md is in `hapax-council/docs/superpowers/specs/2026-04-13-claude-md-excellence-design.md`. Bug-fix retrospectives, PR fingerprints, and incident narratives do not belong in CLAUDE.md — they belong in commit messages and handoff docs. Run `hapax-council/scripts/check-claude-md-rot.sh` for an ad-hoc audit. The monthly `claude-md-audit.timer` (council systemd unit) sweeps the workspace and ntfy's on findings.

> This file is a symlink: `~/projects/CLAUDE.md → ~/dotfiles/workspace-CLAUDE.md`. Edits go via the dotfiles repo (`ryanklee/dotfiles`), not via `~/projects`.
