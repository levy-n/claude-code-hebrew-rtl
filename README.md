# Claude Code Hebrew RTL on Windows

Run Claude Code on Windows with proper Hebrew right-to-left display. No WSL. No remote server. Just Git Bash.

## The Problem

CMD and PowerShell don't support BiDi text rendering. Hebrew appears reversed and unreadable.

## The Solution

**Git Bash (mintty)** supports BiDi natively. This script configures it for Hebrew RTL in one command.

## Prerequisites

- Windows 10/11
- [Git for Windows](https://git-scm.com/download/win) (includes Git Bash + mintty)
- [Node.js](https://nodejs.org) (LTS recommended)
- Claude Code: `npm install -g @anthropic-ai/claude-code`

## Quick Start

Open **Git Bash** and run:

```bash
git clone https://github.com/levy-n/claude-code-hebrew-rtl.git
cd claude-code-hebrew-rtl
bash setup.sh
```

Or without cloning:

```bash
curl -fsSL https://raw.githubusercontent.com/levy-n/claude-code-hebrew-rtl/main/setup.sh | bash
```

## What the Script Does

| File | Purpose |
|------|---------|
| `~/.bashrc` | Adds `$APPDATA/npm` to PATH so Git Bash finds `claude`. Sets Hebrew locale. |
| `~/.bash_profile` | Sources `.bashrc` for login shells. Without this, shortcuts can't find `claude`. |
| `~/.minttyrc` | Enables BiDi rendering, sets `he_IL` locale, UTF-8 charset. |
| Desktop shortcuts | "Claude Code (Hebrew)" launches Claude directly. "Git Bash Hebrew" opens a shell. |

All existing files are backed up before any changes.

## What Gets Configured

**~/.minttyrc** (the key settings):

```ini
Locale=he_IL
Charset=UTF-8
BidiRendering=1
```

These three lines are what make Hebrew display RTL correctly in mintty.

## Manual Setup

If you prefer to set things up manually instead of running the script:

1. Add to `~/.bashrc`:
   ```bash
   export PATH="$PATH:$APPDATA/npm"
   export LANG=he_IL.UTF-8
   export LC_ALL=he_IL.UTF-8
   ```

2. Add to `~/.bash_profile`:
   ```bash
   if [ -f ~/.bashrc ]; then . ~/.bashrc; fi
   ```

3. Create `~/.minttyrc`:
   ```ini
   Font=Consolas
   FontHeight=12
   Locale=he_IL
   Charset=UTF-8
   BidiRendering=1
   Term=xterm-256color
   ```

4. Open Git Bash and run `claude`.

## Why mintty?

| Terminal | BiDi Support | Hebrew RTL |
|----------|-------------|------------|
| CMD | No | Broken |
| PowerShell | No | Broken |
| Windows Terminal | Partial | Inconsistent |
| **mintty (Git Bash)** | **Yes** | **Works** |

mintty has built-in BiDi rendering. No plugins, no workarounds.

## License

MIT
