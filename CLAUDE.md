# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

It is not an application — there is no build, no test suite and no source code to compile. It is a
**lab / documentation repository** of reproducible scenarios for running Kong Gateway locally.

Each scenario is one Markdown runbook at the repo root plus the file it drives (a compose file or a
Helm values file). `README.md` is the index. **Documentation is written in Brazilian Portuguese —
keep new or edited docs in Portuguese.**

Scope was deliberately cut down in September 2026: only **Kong Gateway OSS** scenarios are live.

## Live scenarios

| Runbook | Drives | Scenario |
| --- | --- | --- |
| `KONG_CE_DOCKER_COMPOSE.md` | `docker-compose.yml` | Kong OSS 3.9.3 + Postgres 17, compose only |
| `KONG_CE_LOCAL_DBLESS.md` | `values-dbless.yaml` | Kong OSS db-less / ingress controller on k3d |

`kic/` (an `ExternalName` Service to the public ViaCEP API + an Ingress) is the CRD demo used by the
db-less runbook — it is the only shared asset between scenarios.

`KONNECT_ROADMAP.md` lists the Konnect scenarios that will replace the archived Enterprise ones.
Nothing in it has been built or validated yet.

## `archive/` is frozen

`archive/enterprise/` (all Kong Gateway Enterprise scenarios), `archive/okteto/` (the OSS Okteto
scenario, dead because Konga and Okteto Cloud's free tier are both gone) and `archive/wip/`
(uncommitted experiments) are kept for history only.

**Do not update, fix or modernize anything under `archive/`** — its version numbers and URLs are
knowingly stale. `archive/README.md` records why each part was archived. Everything moved there via
`git mv`, so `git log --follow` still works.

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

- **Pin versions explicitly.** The image tag lives in `values-dbless.yaml` / `docker-compose.yml`,
  and the runbook passes `--version` to `helm`. Labs must be reproducible a year from now.
- **Never commit key material.** `.gitignore` covers `konnect/`, `*.key`, `*.crt`, `*.pem`,
  `certs/` and `license.json`. A real unencrypted private key was found at the root during the
  cleanup — check `git ls-files | grep -E '\.(key|crt|pem)$'` returns nothing before committing.
- Local ports are consistent across both runbooks: proxy on 8000, Admin API on 8001 (compose) or
  9000 (k3d), Kong Manager on 8002 (compose) or 9001 (k3d).
- Runbooks follow a fixed section order: Pré-requisitos → chart/compose setup → install → access
  URLs → test → uninstall. The table of contents is hand-written, so it must be updated by hand
  when sections change.
- Kong OSS is at 3.9.3 and the line has stalled there (no 3.10+ exists); Enterprise is at 3.14.x.
  Verify against Docker Hub and `charts.konghq.com/index.yaml` before claiming a "latest" version.
