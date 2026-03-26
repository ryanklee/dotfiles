# CLAUDE.md

Guidance for Claude Code across the multi-project workspace.

## Workspace

Seven repositories, three core:

- **hapax-constitution** — Governance specification (axioms, implications, canons). Spec-only, no runtime code. Publishes `hapax-sdlc` package.
- **hapax-council** — Personal operating environment. 45+ agents, voice daemon, studio compositor, RAG pipeline, reactive engine. Logos API on `:8051`.
- **hapax-officium** — Management decision support. 17 agents, filesystem-as-bus data model. Logos API on `:8050`.
- **hapax-watch** — Wear OS companion app. Streams biometric sensor data (heart rate, HRV, skin temperature, sleep) to council logos API.
- **hapax-mcp** — MCP server (34 tools) bridging logos APIs to Claude Code tools.
- **tabbyAPI** — External LLM inference server (ExllamaV2/V3). Backend.
- **distro-work** — System maintenance scripts and research docs. Not a software project.

Each sub-project has its own CLAUDE.md — always read it before working in that project.

## Shared Conventions (all Python projects)

- **uv** for everything (never pip). `uv sync`, `uv run pytest tests/ -q`, `uv run ruff check .`, `uv run ruff format .`, `uv run pyright`.
- Python 3.12+, mandatory type hints, Pydantic models for structured data.
- Ruff: `line-length=100`, double quotes, `select=["E","F","I","UP","B","SIM","TCH"]`, `known-first-party = ["agents", "shared", "logos"]`.
- Testing: `unittest.mock` only, each test file self-contained, no shared conftest fixtures. `asyncio_mode = "auto"`. Tests marked `llm` excluded by default.
- **pydantic-ai**: Use `output_type` (not `result_type`), `result.output` (not `result.data`). All LLM calls through LiteLLM gateway.
- Secrets via `pass` + `direnv` (`.envrc` gitignored), central config in `shared/config.py`.
- Agents run as modules: `uv run python -m agents.<name> [flags]`.

## Git Workflow

- Conventional commits, feature branches from `main`.
- **Three worktree slots, strictly enforced:**
  - `hapax-council/` — **alpha** session (permanent, primary)
  - `hapax-council--beta/` — **beta** session (permanent)
  - `hapax-council--<slug>/` — **one spontaneous** worktree (temporary, must be cleaned up before new work)
- Each session works in its own worktree. One branch at a time per session. No branch switching into another session's worktree.
- **Dev server worktree awareness:** Vite on `:5173` runs from whichever worktree started it (usually alpha). `session-context.sh` hook detects mismatches. If mismatched, copy changed files to the serving worktree or restart vite from yours.
- **Rebase alpha after beta merges:** After merging PRs from beta, rebase alpha onto main so the vite dev server picks up changes.
- **Always PR completed work before moving on.** Do NOT start new work until current work is resolved (PR submitted or no changes remaining). Blocking requirement.
- **You own every PR you create through to merge.** Monitor CI, fix failures, merge when ready.
- **Hooks enforce branch discipline.** `no-stale-branches.sh` blocks new branch creation when unmerged branches exist. `work-resolution-gate.sh` blocks edits when open PRs exist. Destructive git commands are blocked on feature branches with commits ahead of main. These hooks interact with subagents — see global CLAUDE.md § "Subagent Git Safety" for mandatory patterns.
- CODEOWNERS protects governance files.

## Shared Infrastructure

All running locally. Docker Compose for infrastructure, systemd user units for application services. No process-compose in production boot chain.

**Docker containers** (13, `restart: always`):
- **LiteLLM** — API gateway (`:4000` council, `:4100` officium), routes to Claude/Gemini/Ollama
- **Qdrant** — Vector DB (8 collections: claude-memory, profile-facts, documents, axiom-precedents, samples, operator-episodes, studio-moments, operator-corrections)
- **PostgreSQL** — Audit/observability
- **Langfuse** — LLM observability (`:3000`)
- **Prometheus** + **Grafana** — Metrics and dashboards
- **Redis**, **ClickHouse**, **MinIO**, **n8n**, **ntfy**, **OpenWebUI**

**Host services** (systemd user units, lingering):
- **Ollama** — Local inference on RTX 3090 (system-level)
- **hapax-secrets** — Centralized credential loading (oneshot, all services depend on this)
- **logos-api** / **officium-api** — FastAPI on `:8051` / `:8050`
- **hapax-voice** — Persistent voice daemon (GPU, 8G memory limit)
- **studio-compositor** — GPU camera tiling/recording/HLS
- **visual-layer-aggregator** — Perception → Stimmung → /dev/shm
- 41 timers (sync agents, health monitor, VRAM watchdog, backups)

**24/7 recovery**: Kernel panic auto-reboot (10s), hardware watchdog (SP5100 TCO, 30s), greetd autologin, lingering. See `hapax-council/systemd/README.md`.

**Design language**: `hapax-council/docs/logos-design-language.md` governs all visual surfaces (Logos app, desktop, officium). Two palettes: Gruvbox Hard Dark (R&D) and Solarized Dark (Research). Mode switching via `hapax-working-mode` script propagates to all surfaces. Component colors must use CSS custom properties or Tailwind classes — no hardcoded hex. See §11 for governed vs excluded surfaces.

## Inter-Project Dependencies

```
hapax-constitution (spec)
  └─ publishes hapax-sdlc package

hapax-council ──► hapax-sdlc (git+ dep)
hapax-officium ──► hapax-sdlc[demo] (git+ dep)

hapax-watch ──► council logos API (HTTP, biometrics)
hapax-mcp ──► council/officium logos APIs (HTTP)
tabbyAPI ──► (standalone inference backend)
```
