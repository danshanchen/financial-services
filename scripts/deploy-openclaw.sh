#!/usr/bin/env bash
# deploy-openclaw.sh — Deploy a managed-agent cookbook as OpenClaw sub-agents.
#
# Reads managed-agent-cookbooks/<slug>/agent.yaml and its subagents,
# extracts system prompts and skill references, and creates OpenClaw
# agent configurations in a deploy/ directory.
#
# Usage: scripts/deploy-openclaw.sh <slug>
#   e.g. scripts/deploy-openclaw.sh pitch-agent

set -euo pipefail

ROLE="${1:?usage: deploy-openclaw.sh <slug>}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="$ROOT/managed-agent-cookbooks/$ROLE"
OUTDIR="$ROOT/deploy/$ROLE"

[[ -f "$DIR/agent.yaml" ]] || { echo "no manifest at $DIR/agent.yaml" >&2; exit 1; }

command -v python3 >/dev/null || { echo "requires python3" >&2; exit 1; }
python3 -c 'import yaml' 2>/dev/null || { echo "requires python3 + pyyaml (pip install pyyaml)" >&2; exit 1; }

mkdir -p "$OUTDIR"

# Extract model from agent.yaml
MODEL=$(python3 -c "
import yaml
with open('$DIR/agent.yaml') as f:
    m = yaml.safe_load(f)
print(m.get('model', 'deepseek-chat'))
")

echo "=== OpenClaw Deployment: $ROLE ==="
echo "Model: $MODEL"
echo "Output: $OUTDIR"

# Extract orchestrator system prompt
python3 -c "
import yaml, os, sys
with open('$DIR/agent.yaml') as f:
    m = yaml.safe_load(f)

sys_obj = m.get('system', {})
sys_text = sys_obj.get('text', '')
sys_file = sys_obj.get('file', '')
sys_append = sys_obj.get('append', '')

base = os.path.dirname(os.path.abspath('$DIR/agent.yaml'))
prompt = sys_text
if sys_file:
    fpath = os.path.join(base, sys_file)
    if os.path.exists(fpath):
        with open(fpath) as sf:
            prompt = sf.read()
    else:
        print(f'WARNING: system.file not found: {fpath}', file=sys.stderr)
if sys_append:
    prompt = prompt + '\n\n' + sys_append

out_path = '$OUTDIR/system-prompt.md'
with open(out_path, 'w') as o:
    o.write(prompt)
print(f'  Orchestrator prompt → {out_path} ({len(prompt)} chars)')
" 2>&1

# Extract subagent system prompts
python3 <<PYEOF
import yaml, os, sys, json

base = os.path.dirname(os.path.abspath('$DIR/agent.yaml'))
with open('$DIR/agent.yaml') as f:
    m = yaml.safe_load(f)

callable_agents = m.get('callable_agents', [])
for ca in callable_agents:
    manifest_path = ca.get('manifest', '')
    if not manifest_path:
        continue
    full_path = os.path.join(base, manifest_path)
    if not os.path.exists(full_path):
        print(f'WARNING: manifest not found: {full_path}', file=sys.stderr)
        continue
    
    with open(full_path) as sf:
        sm = yaml.safe_load(sf)
    
    name = sm.get('name', os.path.basename(manifest_path).replace('.yaml', ''))
    model = sm.get('model', '$MODEL')
    
    sys_obj = sm.get('system', {})
    sys_text = sys_obj.get('text', '')
    sys_file = sys_obj.get('file', '')
    
    prompt = sys_text
    if sys_file:
        fpath = os.path.join(base, sys_file)
        if os.path.exists(fpath):
            with open(fpath) as sf2:
                prompt = sf2.read()
    
    # Write subagent config
    sub_dir = f'$OUTDIR/subagents'
    os.makedirs(sub_dir, exist_ok=True)
    
    cfg = {
        'name': name,
        'model': model,
    }
    
    prompt_path = os.path.join(sub_dir, f'{name}.md')
    with open(prompt_path, 'w') as o:
        o.write(prompt)
    
    print(f'  Subagent: {name} → {prompt_path} ({len(prompt)} chars, model={model})')

print()
print('Done. Agent configurations written to $OUTDIR/')
print()
print('To deploy with OpenClaw, copy the system prompts into your agent configs.')
print('For sub-agent orchestration, see scripts/orchestrate.py (port the event loop).')
PYEOF

# Copy skill files
if [[ -d "$DIR/../" ]]; then
    echo ""
    echo "=== Skill Files ==="
    # List skills from the agent plugin
    AGENT_SLUG="$ROLE"
    SKILL_DIR="$ROOT/plugins/agent-plugins/$AGENT_SLUG/skills"
    if [[ -d "$SKILL_DIR" ]]; then
        echo "  Skills available at: $SKILL_DIR"
        for skill in "$SKILL_DIR"/*/; do
            skill_name=$(basename "$skill")
            echo "    - $skill_name"
        done
    fi
fi

echo ""
echo "=== Next Steps ==="
echo "1. Review system prompts in $OUTDIR/"
echo "2. Configure MCP connectors from plugins/vertical-plugins/financial-analysis/.mcp.json"
echo "3. Deploy agents via OpenClaw gateway configuration"
echo "4. For sub-agent orchestration: implement handoff routing between agents"
