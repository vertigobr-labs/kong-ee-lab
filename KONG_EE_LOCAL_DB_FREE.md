# Kong EE local (k3d) - modo normal <!-- omit in toc -->

Passos para executar Kong Gateway localmente em um cluster k3d e em modo "normal" (com database) e em Free Mode.

- [Pré-requisitos](#pré-requisitos)
- [Importar chart oficial do Kong:](#importar-chart-oficial-do-kong)
- [Criar cluster local](#criar-cluster-local)
- [Instalar Kong Gateway em Free Mode](#instalar-kong-gateway-em-free-mode)
- [Acessar aplicações:](#acessar-aplicações)
- [Notas importantes](#notas-importantes)
- [Protegendo o Kong Gateway em Free Mode com basic-auth](#protegendo-o-kong-gateway-em-free-mode-com-basic-auth)
- [Instalar Kong Gateway em Free Mode com Plugin OIDC de comunidade](#instalar-kong-gateway-em-free-mode-com-plugin-oidc-de-comunidade)
- [Desinstalar Kong (opcional):](#desinstalar-kong-opcional)

## Pré-requisitos

As seguintes ferramentas de linha de comando devem estar instaladas na estação de trabalho:

- Docker Desktop (OSX/Windows) ou Docker CE (Linux)
- VKPR
- k3d (*)
- Helm (*)
- Kubectl (*)

(*) já embutidos no `vkdr` na pasta `~/.vkdr/bin`

**Importante:** este exemplo também assume que nomes "*.localhost" resolvem sempre para localhost. Se este não for o caso basta criar as entradas abaixo manualmente em /etc/hosts.

```
127.0.0.1 manager.localhost registry.localhost
```

## Importar chart oficial do Kong:

```sh
helm repo add kong https://charts.konghq.com
helm repo update
```

## Criar cluster local

O `vkdr` cria um cluster Kubernetes (k3d), o qual já está pronto para expor o Kong em uma porta local arbitrária (8000): 

```sh
# roda um cluster k3d usando o vkdr
vkdr infra up
```

## Instalar Kong Gateway em Free Mode

Para instalar Kong Gateway em "Free Mode" (i.e. sem uma licença) com o chart oficial:

```sh
helm upgrade -i kong -f values-ee-db-freemode.yaml kong/kong
```

## Acessar aplicações:

* Kong Gateway (onde ficam suas APIs):
  * http://localhost:8000/
* Kong Manager:
  * http://manager.localhost:8000/manager
* Kong Admin API:
  * http://manager.localhost:8000

## Notas importantes

- Em `values-ee-db-freemode.yaml` é ativado o modo "enterprise" mas não fornecemos uma licença. Ambos Kong Manager e Admin API ficam abertos (sem senha para acesso), no modo que é chamado de "free mode".

- É uma instalação "tradicional" (com database) e não "db-less", mas o Kong Ingress Controller também está ativo (ingress class "kong").

- O Kong Ingress Controller neste exemplo é o único instalado, portanto ambos Manager e Admin API do Kong aparecem como serviços do próprio API Gateway.

- O database Postgres é instalado automaticamente pelo chart do Kong. As senhas dos usuários "postgres" e "kong" foram geradas aleatoriamente e gravadas em uma secret, podendo ser lidas via `kubectl`:

```sh
# senha usuario "kong"
kubectl get secret kong-postgresql -o json | jq .data.password -r | base64 -D
# senha usuario "postgres" (root do banco)
kubectl get secret kong-postgresql -o json | jq '.data."postgres-password"' -r | base64 -D
```

## Protegendo o Kong Gateway em Free Mode com basic-auth

A instalação anterior deixa ambos Manager e Admin API abertos (sem senha), o que pode não ser desejável em redes públicas. Para proteger minimamente ambos com basic-auth pode ser usada a instalação alternativa abaixo:

```sh
helm upgrade -i kong -f values-ee-db-freemode-basic-auth.yaml kong/kong
# plugin e consumer para usuário/senha = teste/senha
kubectl apply -f kic-freemode-auth
```

A modificação acima cria um plugin `basic-auth` e um consumer `teste` com senha `senha`. A proteção com basic-auth é feita no Ingress Controller, portanto ambos Manager e Admin API ficam protegidos.

## Instalar Kong Gateway em Free Mode com Plugin OIDC de comunidade

Para instalar Kong Gateway em "Free Mode" e plugin OIDC de comunidade podemos usar uma imagem customizada que produzimos já com este plugin instalado:

```sh
helm upgrade -i kong -f values-ee-db-freemode.yaml kong/kong \
  --set image.repository=veecode/kong-cred \
  --set image.tag=3.6.0-r2 \
  --set 'env.plugins=bundled\,oidc'
```

Para checar quais plugins estão habilitados:

```sh
curl manager.localhost:8000/plugins/enabled | jq
```

## Desinstalar Kong (opcional):

Remover Kong EE:

```sh
helm delete kong
# se quiser zerar o banco
kubectl delete pvc data-kong-postgresql-0
```
