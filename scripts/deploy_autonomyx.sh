#!/usr/bin/env bash
set -euo pipefail

# Autonomyx deployment helper for this repository.
# Supports:
#   --mode local   : run gateway in foreground (dev/prod-like)
#   --mode systemd : install/update a user-level systemd service
#
# Defaults are conservative and backward-compatible with existing hermes command names.

MODE="local"
PROFILE="default"
WORKDIR="$(pwd)"
PYTHON_BIN="python3"

usage() {
  cat <<USAGE
Usage: $0 [--mode local|systemd] [--profile <name>] [--workdir <path>] [--python <bin>]

Examples:
  $0 --mode local
  $0 --mode systemd --profile prod
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      MODE="${2:-}"; shift 2 ;;
    --profile)
      PROFILE="${2:-}"; shift 2 ;;
    --workdir)
      WORKDIR="${2:-}"; shift 2 ;;
    --python)
      PYTHON_BIN="${2:-}"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1 ;;
  esac
done

if [[ "$MODE" != "local" && "$MODE" != "systemd" ]]; then
  echo "--mode must be 'local' or 'systemd'" >&2
  exit 1
fi

cd "$WORKDIR"

if [[ ! -f "pyproject.toml" ]]; then
  echo "ERROR: must run from repository root or pass --workdir <repo_root>" >&2
  exit 1
fi

if [[ ! -d "venv" ]]; then
  echo "Creating virtual environment at $WORKDIR/venv"
  "$PYTHON_BIN" -m venv venv
fi

# shellcheck disable=SC1091
source venv/bin/activate

pip install -e ".[all,web,cron]" >/dev/null

# Default profile maps to ~/.hermes ; named profiles map to ~/.hermes/profiles/<name>
if [[ "$PROFILE" == "default" ]]; then
  export HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
else
  export HERMES_HOME="${HERMES_HOME:-$HOME/.hermes/profiles/$PROFILE}"
fi
mkdir -p "$HERMES_HOME"

echo "Using HERMES_HOME=$HERMES_HOME"

if [[ "$MODE" == "local" ]]; then
  echo "Starting Autonomyx gateway in foreground..."
  exec hermes gateway start
fi

# systemd mode
if ! command -v systemctl >/dev/null 2>&1; then
  echo "ERROR: systemctl is not available; use --mode local instead" >&2
  exit 1
fi

mkdir -p "$HOME/.config/systemd/user"
SERVICE_PATH="$HOME/.config/systemd/user/autonomyx-gateway.service"
cat > "$SERVICE_PATH" <<SERVICE
[Unit]
Description=Autonomyx Agent Gateway
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=$WORKDIR
Environment=HERMES_HOME=$HERMES_HOME
ExecStart=$WORKDIR/venv/bin/hermes gateway start
Restart=always
RestartSec=3

[Install]
WantedBy=default.target
SERVICE

systemctl --user daemon-reload
systemctl --user enable --now autonomyx-gateway.service
systemctl --user status --no-pager autonomyx-gateway.service || true

echo "Deployed autonomyx-gateway.service"
echo "Logs: journalctl --user -u autonomyx-gateway.service -f"
