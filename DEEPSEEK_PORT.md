# DeepSeek Port — Financial Services Agents

This branch adapts the Anthropic `financial-services` reference agents for **DeepSeek** (and other LLMs) via **OpenClaw**.

## What Changed

### 1. Model References — All YAML Cookbooks
| Before | After |
|---|---|
| `model: claude-opus-4-7` | `model: deepseek-chat` |
| All 40 YAML files (agent.yaml + subagents) updated | |

### 2. Skill Files — Model-Agnostic Language
| Before | After |
|---|---|
| "This skill teaches Claude..." | "This skill teaches the agent..." |
| "CRITICAL INSTRUCTIONS FOR CLAUDE" | "CRITICAL INSTRUCTIONS" |
| "Claude's built-in skills" | "the agent's built-in capabilities" |
| "Claude's DOCX and XLSX skills" | "document and spreadsheet tools" |
| All 16 skill files + 1 reference file updated | |

### 3. System Prompts — Already Portable
The 10 agent system prompts (`agents/*.md`) were **already model-agnostic** — they describe workflows, tools, and guardrails without assuming any specific LLM. No changes needed.

### 4. MCP Configurations — Standard Protocol
All 11 MCP data connectors in `financial-analysis/.mcp.json` use **standard MCP protocol** — works with any MCP-compatible client. No changes needed.

## Files NOT Changed (Claude Ecosystem)

These remain Claude-specific because they're tied to the Claude platform:

| File | Why Untouched |
|---|---|
| `plugins/*/.claude-plugin/plugin.json` | Claude Cowork/Code plugin format |
| `.claude-plugin/marketplace.json` | Claude marketplace manifest |
| `claude-for-msft-365-install/` | Claude MS365 add-in admin tooling |
| `scripts/deploy-managed-agent.sh` | Anthropic Managed Agents API |
| `scripts/orchestrate.py` | Anthropic SDK-based orchestration |
| `CLAUDE.md` | Claude-specific development guide |

## How to Use with DeepSeek / OpenClaw

### Option A: Use Prompts & Skills Directly
Each agent's system prompt is at `plugins/agent-plugins/<slug>/agents/<slug>.md`. Use it as-is with any LLM API:

```python
import openai
client = openai.OpenAI(
    api_key="sk-...",
    base_url="https://api.deepseek.com/v1"
)
with open("plugins/agent-plugins/pitch-agent/agents/pitch-agent.md") as f:
    system_prompt = f.read()
response = client.chat.completions.create(
    model="deepseek-chat",
    messages=[{"role": "system", "content": system_prompt}, ...]
)
```

### Option B: OpenClaw Agent Deployment
See `scripts/deploy-openclaw.sh` for deploying cookbook agents as OpenClaw sub-agents.

### Option C: MCP Connectors
The MCP config is at `plugins/vertical-plugins/financial-analysis/.mcp.json`. Configure in OpenClaw's MCP settings.

## Agent Reference

| Agent | Prompt | Skills |
|---|---|---|
| **Pitch Agent** | `plugins/agent-plugins/pitch-agent/agents/pitch-agent.md` | comps, LBO, DCF, 3-statement, pitch-deck |
| **Market Researcher** | `plugins/agent-plugins/market-researcher/agents/market-researcher.md` | sector-overview, comps, idea-generation |
| **Earnings Reviewer** | `plugins/agent-plugins/earnings-reviewer/agents/earnings-reviewer.md` | earnings-analysis, model-update |
| **Model Builder** | `plugins/agent-plugins/model-builder/agents/model-builder.md` | DCF, LBO, 3-statement, comps, audit-xls |
| **Meeting Prep Agent** | `plugins/agent-plugins/meeting-prep-agent/agents/meeting-prep-agent.md` | client-review, company-profiling |
| **GL Reconciler** | `plugins/agent-plugins/gl-reconciler/agents/gl-reconciler.md` | gl-recon, break-tracing |
| **Month-End Closer** | `plugins/agent-plugins/month-end-closer/agents/month-end-closer.md` | accruals, roll-forwards |
| **Valuation Reviewer** | `plugins/agent-plugins/valuation-reviewer/agents/valuation-reviewer.md` | valuation-template, LP-reporting |
| **Statement Auditor** | `plugins/agent-plugins/statement-auditor/agents/statement-auditor.md` | statement-audit, tie-out |
| **KYC Screener** | `plugins/agent-plugins/kyc-screener/agents/kyc-screener.md` | kyc-rules, doc-parsing |

## Limitations

- **Sub-agent delegation**: Claude Managed Agents support `callable_agents` with automatic handoff routing. OpenClaw provides equivalent sub-agent spawning but requires different wiring.
- **File tools**: Claude has native DOCX/XLSX/PPTX skills. With DeepSeek you'll need python-docx/openpyxl/python-pptx or equivalent.
- **No Claude Code plugin system**: The `.claude-plugin/` wrappers only work in Claude's ecosystem.

## Upstream Sync

To pull upstream Anthropic changes into this fork:

```bash
git remote add upstream https://github.com/anthropics/financial-services.git
git fetch upstream
git merge upstream/main
# Re-apply port changes if needed
```
