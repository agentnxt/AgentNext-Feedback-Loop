# Autonomyx Agent Deployment Guide

This guide provides a practical deployment path for this repository with backward-compatible runtime commands.

## Deployment modes

## 1) Local foreground mode

Use this for validation and small deployments where process supervision is external.

```bash
scripts/deploy_autonomyx.sh --mode local
```

What it does:

- Creates `venv/` if missing.
- Installs the repo (`pip install -e ".[all,web,cron]"`).
- Resolves `HERMES_HOME`:
  - default profile → `~/.hermes`
  - named profile → `~/.hermes/profiles/<profile>`
- Starts `hermes gateway start`.

## 2) systemd user service mode

Use this for persistent host deployments.

```bash
scripts/deploy_autonomyx.sh --mode systemd --profile prod
```

This writes:

- `~/.config/systemd/user/autonomyx-gateway.service`

Then runs:

- `systemctl --user daemon-reload`
- `systemctl --user enable --now autonomyx-gateway.service`

View logs:

```bash
journalctl --user -u autonomyx-gateway.service -f
```

## Environment and config

- Runtime command remains `hermes` for compatibility.
- Product identity is Autonomyx Agent.
- Put API keys and settings under profile-scoped `HERMES_HOME` (`config.yaml`, `.env`).

## Recommended production hardening checklist

- Use a dedicated profile (`--profile prod`).
- Configure gateway platform allowlists and approval policies.
- Set resource/budget controls in config before enabling broad toolsets.
- Restrict host permissions for service account.
- Ship logs to central observability.

