#!/usr/bin/env bash
# NeoFinder (Matrix Edition) -- one-click installer
# Usage:  curl -fsSL <raw-url>/install.sh | bash
#     or: NEOFINDER_REPO=https://github.com/YOURFORK/neofinder.git bash install.sh
set -euo pipefail

REPO="${NEOFINDER_REPO:-https://github.com/mefardales/neofinder.git}"
GREEN=$'\033[0;32m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

echo "${GREEN}"
echo '  _   _            _____ _           _'
echo ' | \ | | ___  ___ |  ___(_)_ __   __| | ___ _ __'
echo ' |  \| |/ _ \/ _ \| |_  | |'\''_ \ / _` |/ _ \ '\''__|'
echo ' | |\  |  __/ (_) |  _| | | | | | (_| |  __/ |'
echo ' |_| \_|\___|\___/|_|   |_|_| |_|\__,_|\___|_|'
echo '                                  Matrix Edition'
echo "${RESET}"

# Detect target directory
if [ -d "${HOME}/.vim" ]; then
  TARGET="${HOME}/.vim/pack/plugins/start/neofinder"
elif [ -d "${XDG_DATA_HOME:-${HOME}/.local/share}/nvim" ]; then
  TARGET="${XDG_DATA_HOME:-${HOME}/.local/share}/nvim/site/pack/plugins/start/neofinder"
else
  TARGET="${HOME}/.vim/pack/plugins/start/neofinder"
fi

echo "${BOLD}Installing NeoFinder to:${RESET} ${TARGET}"

if [ -d "${TARGET}" ]; then
  echo "  Updating existing installation..."
  cd "${TARGET}" && git pull --ff-only
else
  mkdir -p "$(dirname "${TARGET}")"
  git clone --depth 1 "${REPO}" "${TARGET}"
fi

mkdir -p "${HOME}/.neofinder"

echo "  Generating help tags..."
if command -v vim &>/dev/null; then
  vim -u NONE -c "helptags ${TARGET}/doc" -c q 2>/dev/null || true
elif command -v nvim &>/dev/null; then
  nvim --headless -c "helptags ${TARGET}/doc" -c q 2>/dev/null || true
fi

echo ""
echo "${GREEN}${BOLD}  NeoFinder installed successfully!${RESET}"
echo ""
echo "  Quick start:  :NeoFinder  :NeoConfigs  :NeoHelp"
echo "  Backend: $(command -v rg >/dev/null && echo 'ripgrep' || (command -v fd >/dev/null && echo 'fd' || echo 'find'))"
