#!/usr/bin/env bash
# NeoFinder (Matrix Edition) -- one-click installer
# Usage:  curl -fsSL <url>/install.sh | bash
#     or: ./install.sh
#
# Set NEOFINDER_REPO to override the git clone URL.
set -euo pipefail

GREEN=$'\033[0;32m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

banner() {
  echo "${GREEN}"
  echo '  _   _            _____ _           _'
  echo ' | \ | | ___  ___ |  ___(_)_ __   __| | ___ _ __'
  echo ' |  \| |/ _ \/ _ \| |_  | |'\''_ \ / _` |/ _ \ '\''__|'
  echo ' | |\  |  __/ (_) |  _| | | | | | (_| |  __/ |'
  echo ' |_| \_|\___|\___/|_|   |_|_| |_|\__,_|\___|_|'
  echo '                                  Matrix Edition'
  echo "${RESET}"
}

banner

# Resolve repo URL dynamically:
#   1. NEOFINDER_REPO env var (explicit override)
#   2. git remote of the script's own repo (when running ./install.sh locally)
#   3. Fallback: prompt the user
resolve_repo() {
  if [ -n "${NEOFINDER_REPO:-}" ]; then
    echo "${NEOFINDER_REPO}"
    return
  fi

  # If this script lives inside a git repo, use its origin remote
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if git -C "${script_dir}" rev-parse --git-dir &>/dev/null; then
    local url
    url="$(git -C "${script_dir}" remote get-url origin 2>/dev/null || true)"
    if [ -n "${url}" ]; then
      echo "${url}"
      return
    fi
  fi

  echo >&2 "  Could not detect repository URL."
  echo >&2 "  Set NEOFINDER_REPO and re-run, e.g.:"
  echo >&2 "    NEOFINDER_REPO=https://github.com/YOU/neofinder.git bash install.sh"
  exit 1
}

REPO="$(resolve_repo)"

# Detect target directory
if [ -d "${HOME}/.vim" ]; then
  TARGET="${HOME}/.vim/pack/plugins/start/neofinder"
elif [ -d "${XDG_DATA_HOME:-${HOME}/.local/share}/nvim" ]; then
  TARGET="${XDG_DATA_HOME:-${HOME}/.local/share}/nvim/site/pack/plugins/start/neofinder"
else
  TARGET="${HOME}/.vim/pack/plugins/start/neofinder"
fi

echo "${BOLD}Installing NeoFinder to:${RESET} ${TARGET}"
echo "  Source: ${REPO}"

if [ -d "${TARGET}" ]; then
  echo "  Updating existing installation..."
  cd "${TARGET}" && git pull --ff-only
else
  mkdir -p "$(dirname "${TARGET}")"
  git clone --depth 1 "${REPO}" "${TARGET}"
fi

# Create tags directory
mkdir -p "${HOME}/.neofinder"

# Generate helptags
echo "  Generating help tags..."
if command -v vim &>/dev/null; then
  vim -u NONE -c "helptags ${TARGET}/doc" -c q 2>/dev/null || true
elif command -v nvim &>/dev/null; then
  nvim --headless -c "helptags ${TARGET}/doc" -c q 2>/dev/null || true
fi

echo ""
echo "${GREEN}${BOLD}  NeoFinder installed successfully!${RESET}"
echo ""
echo "  Quick start:"
echo "    :NeoFinder     - fuzzy file finder"
echo "    :NeoConfigs    - config files"
echo "    :NeoHelp       - all commands & keys"
echo ""
echo "  Backend detected: $(command -v rg >/dev/null && echo 'ripgrep' || (command -v fd >/dev/null && echo 'fd' || echo 'find'))"
