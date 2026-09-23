#!/usr/bin/env bash
#
# Remove de um dump do decK o que so existe no Kong Gateway Enterprise e que o
# Kong OSS rejeita no "deck gateway sync".
#
# Uso: ./clean-enterprise.sh kong.yaml > kong-oss.yaml
#
# Requer: yq v4 (https://github.com/mikefarah/yq)
#
# Cada regra abaixo veio de um erro real do "deck gateway validate" contra o
# gateway OSS. Rode o validate de novo depois de mexer aqui.
#
set -euo pipefail

SRC="${1:?uso: $0 <arquivo.yaml>}"

yq '
  # 1. protocolos ws/wss em plugins: aceitos pelos plugins Enterprise,
  #    recusados pelos equivalentes OSS ("expected one of: grpc, grpcs,
  #    http, https").
  (.. | select(has("protocols")).protocols) |= map(select(. != "ws" and . != "wss"))

  # 2. workspaces: o Enterprise organiza entidades em workspaces; no OSS nao
  #    existe esse conceito de configuracao.
  | del(._workspace)
  | del(.workspaces)

  # 3. entidades exclusivas do Enterprise, caso o dump venha de uma instalacao
  #    licenciada (em free mode elas nem sao acessiveis).
  | del(.consumer_groups)
  | del(.rbac_roles)
  | del(.rbac_users)
  | del(.licenses)

  # 4. referencia a consumer group dentro de consumers.
  | (.consumers // []) |= map(del(.groups))
' "$SRC"
