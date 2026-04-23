#!/usr/bin/env bash

set -euo pipefail

qs_script_dir() {
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd
}

qs_repo_root() {
  if [[ -n "${QS_DEV_REPO_ROOT:-}" ]]; then
    printf '%s\n' "$QS_DEV_REPO_ROOT"
    return
  fi

  cd -- "$(qs_script_dir)/.." && pwd
}

qs_init_env() {
  export QS_DEV_REPO_ROOT="$(qs_repo_root)"
  export CONFIG_DIR="${QS_DEV_CONFIG_DIR:-$HOME/quickshell-impure}"
  export SOURCE_CONFIG="${QS_DEV_SOURCE_CONFIG:-$HOME/.config/quickshell}"
  export REPO_DIR="${QS_DEV_REPO_DIR:-$QS_DEV_REPO_ROOT/shell}"
  export QS_BIN="${QS_DEV_QUICKSHELL_BIN:-$(command -v quickshell)}"
  export RUNDIR="${QS_DEV_RUNDIR:-${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell-dev}"
  export PIDFILE="${QS_DEV_PIDFILE:-$RUNDIR/pid}"
}

qs_prepare_config_dir() {
  echo "[quickshell-dev] Setting up $CONFIG_DIR from $SOURCE_CONFIG"

  if [[ -d "$CONFIG_DIR" ]]; then
    chmod -R u+w "$CONFIG_DIR" 2>/dev/null || true
    rm -rf "$CONFIG_DIR"
  fi

  mkdir -p "$CONFIG_DIR"
  cp -aL "$SOURCE_CONFIG/." "$CONFIG_DIR/"
  chmod -R u+w "$CONFIG_DIR"
}

qs_init_git_repo() {
  cd "$CONFIG_DIR"

  if [[ ! -d .git ]]; then
    echo "[quickshell-dev] Initializing git repository in $CONFIG_DIR"
    git init
    git add .
    git commit -m "Initial commit from nix-managed config" || true
    return
  fi

  echo "[quickshell-dev] Git repository already exists, committing current state"
  git add .
  git commit -m "Updated from nix-managed config" || true
}

qs_assert_shell() {
  if [[ ! -f "$CONFIG_DIR/shell.qml" ]]; then
    echo "No shell.qml in $CONFIG_DIR" >&2
    exit 1
  fi
}

qs_stop() {
  if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    kill "$(cat "$PIDFILE")" || true
    sleep 0.05
  fi
}

qs_start() {
  mkdir -p "$RUNDIR"
  qs_stop
  echo "[quickshell-dev] launching with --path $CONFIG_DIR"
  "$QS_BIN" --path "$CONFIG_DIR" "$@" &
  echo $! > "$PIDFILE"
}

qs_cleanup() {
  qs_stop
  rm -f "$PIDFILE"
}

qs_sync_back() {
  echo "[quickshell-dev] Change detected, syncing to $REPO_DIR"
  mkdir -p "$REPO_DIR"
  rsync -av --delete \
    --exclude=".git" \
    --exclude="*.swp" \
    --exclude="*~" \
    "$CONFIG_DIR/" "$REPO_DIR/"
}