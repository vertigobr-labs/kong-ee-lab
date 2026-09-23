# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

Not an application — no build, no test suite, no source to compile. It is a lab repository of
reproducible scenarios for running Kong Gateway OSS locally. Each scenario is one Markdown runbook
plus the file it drives; `README.md` indexes them.

**Docs are written in Brazilian Portuguese — keep them that way.**

`archive/` is frozen history: do not update or modernize anything under it.

## Common commands

```sh
helm repo add kong https://charts.konghq.com && helm repo update

# compose scenario
docker compose up -d kong-db && docker compose up kong-init && docker compose up -d kong

# k3d scenario (vkdr wraps k3d; --nodeports=2 reserves 9000/9001)
vkdr infra start --nodeports=2
helm upgrade -i kong -f values-dbless.yaml kong/kong --version 3.4.1
kubectl apply -f kic/
helm delete kong
```

## Conventions

- **Pin versions explicitly.** The image tag lives in the values/compose file and the runbook passes
  `--version` to `helm`. Labs must still be reproducible a year from now.
- **Never commit credentials.** Check `git ls-files | grep -E '\.(key|crt|pem)$'` is empty, and
  watch for keys embedded in rendered Helm output.
- Ports: proxy on 8000; Admin API on 8001 (compose) or 9000 (k3d); Manager on 8002 or 9001.
- Runbooks follow a fixed section order — Pré-requisitos → install → acesso → teste → remoção — and
  their tables of contents are hand-written, so update them by hand.
- Kong OSS stalled at 3.9.3 (no 3.10+ exists). Verify against Docker Hub and
  `charts.konghq.com/index.yaml` before claiming any "latest" version.
