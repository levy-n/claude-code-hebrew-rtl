#!/bin/bash
###############################################################################
#  setup.sh
#  Configures Git Bash (mintty) on Windows for Claude Code with Hebrew RTL.
#
#  Prerequisites:
#    - Windows 10/11
#    - Git for Windows installed (provides Git Bash + mintty)
#    - Node.js installed
#    - Claude Code installed:  npm install -g @anthropic-ai/claude-code
#
#  Usage:
#    Open Git Bash and run:  bash setup.sh
#
#  What this script does:
#    1. Verifies prerequisites (git, node, claude)
#    2. Configures ~/.bashrc with npm PATH and Hebrew locale
#    3. Ensures ~/.bash_profile sources ~/.bashrc (for login shells)
#    4. Creates ~/.minttyrc with Hebrew RTL / BiDi settings
#    5. Creates desktop shortcuts (Claude Code + Git Bash)
#
#  Tested on: Git for Windows 2.40+, Windows 10/11, Node 18+
###############################################################################

# NO set -e: we handle errors explicitly so 'source' or 'grep' won't kill us

# --- Colors for output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}[OK]${NC} $1"; }
warn() { echo -e "  ${YELLOW}[!!]${NC} $1"; }
fail() { echo -e "  ${RED}[FAIL]${NC} $1"; exit 1; }
info() { echo -e "  ${CYAN}[..]${NC} $1"; }

echo ""
echo "==========================================="
echo "  Claude Code + Hebrew RTL Setup (Windows)"
echo "==========================================="
echo ""

###############################################################################
# Step 0: Verify environment
###############################################################################

if [ -z "$MSYSTEM" ]; then
    fail "This script must run inside Git Bash, not CMD or PowerShell."
fi
ok "Running in Git Bash ($MSYSTEM)"

# Detect Git installation root dynamically (no hardcoded paths)
GIT_ROOT_WIN=$(cygpath -w / 2>/dev/null)
if [ -z "$GIT_ROOT_WIN" ]; then
    fail "Could not detect Git installation root. Is cygpath available?"
fi
ok "Git root: $GIT_ROOT_WIN"

# Verify mintty exists relative to Git root
if [ -f "/usr/bin/mintty.exe" ]; then
    MINTTY_WIN="${GIT_ROOT_WIN}usr\\bin\\mintty.exe"
    ok "mintty found"
else
    fail "mintty not found at /usr/bin/mintty.exe. Reinstall Git for Windows."
fi

# Build icon paths
GIT_ICON_WIN="${GIT_ROOT_WIN}mingw64\\share\\git\\git-for-windows.ico"
if [ ! -f "/mingw64/share/git/git-for-windows.ico" ]; then
    warn "Git icon not found - Git Bash shortcut will use default icon"
    GIT_ICON_WIN=""
fi

# Install Claude Code custom icon to ~/.claude/
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_ICON_SRC="$SCRIPT_DIR/claude-code-logo.ico"
CLAUDE_ICON_DIR="$HOME/.claude"
CLAUDE_ICON_DEST="$CLAUDE_ICON_DIR/claude-code-logo.ico"

mkdir -p "$CLAUDE_ICON_DIR"
if [ -f "$CLAUDE_ICON_SRC" ]; then
    cp "$CLAUDE_ICON_SRC" "$CLAUDE_ICON_DEST"
    CLAUDE_ICON_WIN=$(cygpath -w "$CLAUDE_ICON_DEST" 2>/dev/null)
    ok "Claude Code icon installed to ~/.claude/"
else
    warn "claude-code-logo.ico not found next to script - using Git icon as fallback"
    CLAUDE_ICON_WIN="$GIT_ICON_WIN"
fi

###############################################################################
# Step 1: Check prerequisites
###############################################################################

echo ""
echo "--- Checking prerequisites ---"

if command -v git &>/dev/null; then
    ok "git: $(git --version 2>/dev/null)"
else
    fail "git not found. Install Git for Windows: https://git-scm.com/download/win"
fi

if command -v node &>/dev/null; then
    ok "node: $(node --version 2>/dev/null)"
else
    fail "node not found. Install Node.js: https://nodejs.org"
fi

if command -v npm &>/dev/null; then
    ok "npm: $(npm --version 2>/dev/null)"
else
    fail "npm not found. Should come with Node.js."
fi

# Check Claude Code - multiple locations
CLAUDE_FOUND=false
if command -v claude &>/dev/null; then
    CLAUDE_FOUND=true
    ok "claude: $(claude --version 2>/dev/null || echo 'installed')"
elif [ -f "$APPDATA/npm/claude" ] || [ -f "$APPDATA/npm/claude.cmd" ]; then
    CLAUDE_FOUND=true
    ok "claude found in $APPDATA/npm (will be in PATH after setup)"
fi

if [ "$CLAUDE_FOUND" = false ]; then
    warn "Claude Code not found."
    read -p "  Install now via npm? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        fail "Claude Code required. Install: npm install -g @anthropic-ai/claude-code"
    else
        info "Installing Claude Code..."
        npm install -g @anthropic-ai/claude-code || fail "npm install failed"
        ok "Claude Code installed"
    fi
fi

###############################################################################
# Step 2: Configure ~/.bashrc
###############################################################################

echo ""
echo "--- Configuring ~/.bashrc ---"

BASHRC="$HOME/.bashrc"

# Backup existing file
if [ -f "$BASHRC" ]; then
    cp "$BASHRC" "$BASHRC.bak.$(date +%Y%m%d%H%M%S)"
    ok "Backed up existing .bashrc"
fi

# Add npm global PATH (idempotent)
if ! grep -q 'APPDATA/npm' "$BASHRC" 2>/dev/null; then
    {
        echo ''
        echo '# npm global binaries (for Claude Code CLI)'
        echo 'export PATH="$PATH:$APPDATA/npm"'
    } >> "$BASHRC"
    ok "Added npm PATH"
else
    ok "npm PATH already present (skipped)"
fi

# Add Hebrew locale (idempotent)
if ! grep -q 'LANG=he_IL' "$BASHRC" 2>/dev/null; then
    {
        echo ''
        echo '# Hebrew/UTF-8 locale support'
        echo 'export LANG=he_IL.UTF-8'
        echo 'export LC_ALL=he_IL.UTF-8'
    } >> "$BASHRC"
    ok "Added Hebrew locale"
else
    ok "Hebrew locale already present (skipped)"
fi

# Safe reload (don't let errors in user's bashrc kill us)
source "$BASHRC" 2>/dev/null || warn ".bashrc has errors - PATH will apply on next Git Bash open"

###############################################################################
# Step 3: Ensure ~/.bash_profile sources ~/.bashrc
# Login shells (bash --login) read .bash_profile, NOT .bashrc.
# Without this, the Claude shortcut won't find claude in PATH.
###############################################################################

echo ""
echo "--- Ensuring login shell loads .bashrc ---"

BASH_PROFILE="$HOME/.bash_profile"

if [ -f "$BASH_PROFILE" ]; then
    if grep -q '\.bashrc' "$BASH_PROFILE" 2>/dev/null; then
        ok ".bash_profile already sources .bashrc"
    else
        cp "$BASH_PROFILE" "$BASH_PROFILE.bak.$(date +%Y%m%d%H%M%S)"
        {
            echo ''
            echo '# Source .bashrc for login shells (added by claude-hebrew setup)'
            echo 'if [ -f ~/.bashrc ]; then . ~/.bashrc; fi'
        } >> "$BASH_PROFILE"
        ok "Updated .bash_profile to source .bashrc"
    fi
else
    {
        echo '# Source .bashrc for login shells (added by claude-hebrew setup)'
        echo 'if [ -f ~/.bashrc ]; then . ~/.bashrc; fi'
    } > "$BASH_PROFILE"
    ok "Created .bash_profile (sources .bashrc)"
fi

###############################################################################
# Step 4: Create ~/.minttyrc
###############################################################################

echo ""
echo "--- Configuring mintty for Hebrew RTL ---"

MINTTYRC="$HOME/.minttyrc"

if [ -f "$MINTTYRC" ]; then
    cp "$MINTTYRC" "$MINTTYRC.bak.$(date +%Y%m%d%H%M%S)"
    ok "Backed up existing .minttyrc"
fi

cat > "$MINTTYRC" << 'MINTTY_EOF'
## mintty - Hebrew RTL + Claude Code configuration
## Generated by setup.sh

# Font
Font=Consolas
FontHeight=12
FontSmoothing=full

# Locale & Character Set (critical for Hebrew)
Locale=he_IL
Charset=UTF-8

# BiDi (bidirectional text rendering)
BidiRendering=1

# Window
Columns=120
Rows=35
ScrollbackLines=10000

# Appearance
CursorType=block
CursorBlinks=no
Transparency=off

# Bell
BellType=0

# Terminal
Term=xterm-256color
MINTTY_EOF

ok "Created .minttyrc with Hebrew RTL + BiDi settings"

###############################################################################
# Step 5: Project directory for shortcuts
###############################################################################

echo ""
echo "--- Desktop shortcut setup ---"
echo ""
echo "  Enter your default project directory for the shortcuts."
echo "  Examples:  /c/Projects   /d/Dev   /c/Users/$USER/Projects"
echo ""
read -p "  Directory [$HOME]: " PROJECT_DIR
PROJECT_DIR="${PROJECT_DIR:-$HOME}"

# Normalize paths via cygpath
BASH_PROJECT_DIR=$(cygpath -u "$PROJECT_DIR" 2>/dev/null || echo "$PROJECT_DIR")
WIN_PROJECT_DIR=$(cygpath -w "$PROJECT_DIR" 2>/dev/null || echo "$PROJECT_DIR")

if [ -d "$BASH_PROJECT_DIR" ]; then
    ok "Directory exists: $BASH_PROJECT_DIR"
else
    warn "Directory does not exist: $BASH_PROJECT_DIR"
    read -p "  Create it? [Y/n] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        mkdir -p "$BASH_PROJECT_DIR"
        ok "Created $BASH_PROJECT_DIR"
    fi
fi

###############################################################################
# Step 6: Create desktop shortcuts
# Strategy: write a clean .ps1 file, run it, delete it.
# This avoids bash-inside-PowerShell escaping issues.
###############################################################################

echo ""
echo "--- Creating desktop shortcuts ---"

# Get Desktop path in both formats
DESKTOP_UNIX=$(cygpath -u "$USERPROFILE/Desktop" 2>/dev/null || echo "$HOME/Desktop")
DESKTOP_WIN=$(cygpath -w "$USERPROFILE/Desktop" 2>/dev/null || echo "$USERPROFILE\\Desktop")

if [ ! -d "$DESKTOP_UNIX" ]; then
    warn "Desktop directory not found at $DESKTOP_UNIX"
    warn "Shortcuts will not be created. Create them manually (see README)."
else
    # Write a clean PowerShell script (no escaping issues)
    PS_SCRIPT="/tmp/claude-hebrew-shortcuts-$$.ps1"

    # Pass values via environment variables to avoid path escaping issues
    export _CLAUDE_DESKTOP="$DESKTOP_WIN"
    export _CLAUDE_MINTTY="$MINTTY_WIN"
    export _CLAUDE_ICON="$CLAUDE_ICON_WIN"
    export _CLAUDE_GIT_ICON="$GIT_ICON_WIN"
    export _CLAUDE_PROJDIR_WIN="$WIN_PROJECT_DIR"
    export _CLAUDE_PROJDIR_BASH="$BASH_PROJECT_DIR"

    cat > "$PS_SCRIPT" << 'PSEOF'
$desktop    = $env:_CLAUDE_DESKTOP
$mintty     = $env:_CLAUDE_MINTTY
$claudeIcon = $env:_CLAUDE_ICON
$gitIcon    = $env:_CLAUDE_GIT_ICON
$projWin    = $env:_CLAUDE_PROJDIR_WIN
$projBash   = $env:_CLAUDE_PROJDIR_BASH

$WshShell = New-Object -ComObject WScript.Shell

# Shortcut 1: Claude Code (Hebrew) - uses Claude logo
$s1 = $WshShell.CreateShortcut("$desktop\Claude Code (Hebrew).lnk")
$s1.TargetPath = $mintty
$s1.Arguments = "-i /mingw64/share/git/git-for-windows.ico -e /usr/bin/bash --login -c ""source ~/.bashrc 2>/dev/null; cd '$projBash' 2>/dev/null; claude; exec bash -i"""
$s1.WorkingDirectory = $projWin
$s1.Description = "Claude Code in Git Bash with Hebrew RTL support"
if ($claudeIcon) { $s1.IconLocation = $claudeIcon }
$s1.Save()

# Shortcut 2: Git Bash Hebrew - uses Git icon
$s2 = $WshShell.CreateShortcut("$desktop\Git Bash Hebrew.lnk")
$s2.TargetPath = $mintty
$s2.Arguments = "-i /mingw64/share/git/git-for-windows.ico -e /usr/bin/bash --login -i"
$s2.WorkingDirectory = $projWin
$s2.Description = "Git Bash with Hebrew RTL support"
if ($gitIcon) { $s2.IconLocation = $gitIcon }
$s2.Save()

Write-Host "OK" -NoNewline
PSEOF

    PS_SCRIPT_WIN=$(cygpath -w "$PS_SCRIPT" 2>/dev/null || echo "$PS_SCRIPT")
    PS_RESULT=$(powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$PS_SCRIPT_WIN" 2>&1)
    rm -f "$PS_SCRIPT"

    # Clean up env vars
    unset _CLAUDE_DESKTOP _CLAUDE_MINTTY _CLAUDE_ICON _CLAUDE_GIT_ICON _CLAUDE_PROJDIR_WIN _CLAUDE_PROJDIR_BASH

    if [ -f "$DESKTOP_UNIX/Claude Code (Hebrew).lnk" ]; then
        ok "Created: Claude Code (Hebrew)"
    else
        warn "Could not create Claude Code shortcut"
        warn "PowerShell output: $PS_RESULT"
    fi

    if [ -f "$DESKTOP_UNIX/Git Bash Hebrew.lnk" ]; then
        ok "Created: Git Bash Hebrew"
    else
        warn "Could not create Git Bash shortcut"
    fi
fi

###############################################################################
# Step 7: Verification
###############################################################################

echo ""
echo "--- Verification ---"
echo ""

# Test Hebrew output
echo -e "  Hebrew test: \033[1mשלום עולם - Hello World\033[0m"
echo ""

# Test claude in PATH
if command -v claude &>/dev/null; then
    ok "claude in PATH: $(which claude)"
else
    source "$BASHRC" 2>/dev/null || true
    if command -v claude &>/dev/null; then
        ok "claude in PATH (after reload): $(which claude)"
    else
        warn "claude not in PATH yet. Close and reopen Git Bash, then run: which claude"
    fi
fi

###############################################################################
# Done
###############################################################################

echo ""
echo "==========================================="
echo "  Setup complete!"
echo "==========================================="
echo ""
echo "  Files configured:"
echo "    ~/.bashrc        npm PATH + Hebrew locale"
echo "    ~/.bash_profile  sources .bashrc for login shells"
echo "    ~/.minttyrc      Hebrew RTL + BiDi + UTF-8"
echo ""
echo "  Desktop shortcuts:"
echo "    Claude Code (Hebrew)  Opens Claude in $BASH_PROJECT_DIR"
echo "    Git Bash Hebrew       Opens Git Bash with Hebrew support"
echo ""
echo "  Next steps:"
echo "    1. Close this window"
echo "    2. Double-click 'Claude Code (Hebrew)' on Desktop"
echo "    3. Hebrew should display right-to-left"
echo ""
echo "  To customize mintty: right-click title bar > Options"
echo ""
