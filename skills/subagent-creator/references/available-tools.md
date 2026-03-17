# Available Tools for Sub-agents

Sub-agents can be granted access to any of Claude Code's internal tools. If `tools` field is omitted, the sub-agent inherits all tools from the main thread.

## Core Tools

| Tool | Description |
|------|-------------|
| `Read` | Read file contents |
| `Write` | Create or overwrite files |
| `Edit` | Make precise edits to existing files |
| `Glob` | Find files by pattern matching |
| `Grep` | Search file contents with regex |
| `Bash` | Execute shell commands |

## Interaction Tools

| Tool | Description |
|------|-------------|
| `AskUserQuestion` | Ask user questions for clarification |

## Web Tools

| Tool | Description |
|------|-------------|
| `WebFetch` | Fetch and process web content |
| `WebSearch` | Search the web |

## IDE Tools (when available)

| Tool | Description |
|------|-------------|
| `mcp__ide__getDiagnostics` | Get language diagnostics from VS Code |
| `mcp__ide__executeCode` | Execute code in Jupyter kernel |

## Worktree Tools (for Isolation)

| Tool | Description |
|------|-------------|
| `EnterWorktree` | Manually enter a git worktree (low-level) |
| `ExitWorktree` | Manually exit a git worktree (low-level) |

Note: Prefer using `isolation: worktree` in sub-agent frontmatter for automatic worktree management instead of manual tools.

## MCP Tools

Sub-agents can also access tools from configured MCP servers. MCP tool names follow the pattern `mcp__<server>__<tool>`.

## Common Tool Combinations

### Read-Only Research
```
tools: Read, Grep, Glob, Bash
```
Best for: Code analysis, documentation review, codebase exploration

### Code Modification
```
tools: Read, Write, Edit, Grep, Glob, Bash
```
Best for: Implementing features, fixing bugs, refactoring

### Minimal Write Access
```
tools: Read, Grep, Glob
```
Best for: Security audits, code review (report-only)

### Full Access
Omit the `tools` field to inherit all available tools.
