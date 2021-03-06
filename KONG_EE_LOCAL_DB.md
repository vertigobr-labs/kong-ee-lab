# Kong EE local (k3d) - modo normal <!-- omit in toc -->

Passos para executar Kong Gateway localmente em um cluster k3d e em modo "normal", com database, RBAC e usando uma licença válida.

- [Pré-requisitos](#pré-requisitos)
- [Importar chart oficial do Kong:](#importar-chart-oficial-do-kong)
- [Criar cluster k3d](#criar-cluster-k3d)
- [Configurar licença e secrets](#configurar-licença-e-secrets)
- [Instalar Kong Gateway:](#instalar-kong-gateway)
- [Acessar aplicações:](#acessar-aplicações)
- [Desinstalar Kong (opcional):](#desinstalar-kong-opcional)
- [Notas adicionais](#notas-adicionais)

## Pré-requisitos

As seguintes ferramentas de linha de comando devem estar instaladas na estação de trabalho:

- Docker Desktop (OSX/Windows) ou Docker CE (Linux)
- k3d
- Helm
- Kubectl

**Importante:** este exemplo também assume que nomes "*.localhost" resolvem sempre para localhost. Se este não for o caso basta criar as entradas abaixo manualmente em /etc/hosts.

```
127.0.0.1 portal.localhost api.portal.localhost manager.localhost api.manager.localhost kong.localhost registry.localhost
```

Nota: estamos usando o k3d para subir um kubernetes local, mas outras alternativas como o minikube também devem funcionar. 

## Importar chart oficial do Kong:

```sh
helm repo add kong https://charts.konghq.com
helm repo update
```

## Criar cluster k3d

O k3d cria um cluster já com o Traefik Ingress Controller, o qual estará publicado em porta local arbitrária (8000): 

```sh
# roda registry local e um mirror do Docker Hub
./registry/start-registry.sh
# roda um cluster k3d (usando registry para cache, mas é opcional)
k3d cluster create kong-local \
  -p "8000:80@loadbalancer" \
  --registry-use k3d-registry.localhost \
  --registry-config ./registry/registries.yaml
# usa este cluster
kubectl config use-context k3d-kong-local
kubectl cluster-info
```

## Configurar licença e secrets

Para utilizar uma licença válida (ex: arquivo `license.json`) use a forma abaixo para criar os diversos secrets necessários/recomendados ao Kong Gateway:

```sh
kubectl create secret generic kong-enterprise-license --from-file=license=./license.json
export ADMIN_COOKIE_SECRET=$(pwgen 15 1)   # ou qualquer string desejada
export SESSION_COOKIE_SECRET=$(pwgen 15 1) # ou qualquer string desejada
export KONGPWD=$(pwgen 15 1)               # senha superadmin do Kong
kubectl create secret generic kong-enterprise-superuser-password --from-literal=password=$KONGPWD
echo '{"cookie_name":"admin_session","cookie_samesite":"Strict","secret":"'$ADMIN_COOKIE_SECRET'","cookie_secure":false,"storage":"kong","cookie_domain":"manager.localhost"}' > admin_gui_session_conf
echo '{"cookie_name":"portal_session","cookie_samesite":"Strict","secret":"'$SESSION_COOKIE_SECRET'","cookie_secure":false,"storage":"kong","cookie_domain":"portal.localhost"}' > portal_session_conf
kubectl create secret generic kong-session-config \
  --from-file=admin_gui_session_conf=admin_gui_session_conf \
  --from-file=portal_session_conf=portal_session_conf
echo "kong_admin password: $KONGPWD"
```

## Instalar Kong Gateway:

Para instalar Kong Gateway *com uma licença válida* usando o chart oficial:

```sh
helm upgrade -i kong -f values-ee-db-licensed.yaml kong/kong --skip-crds
```

## Acessar aplicações:

* Kong Gateway (onde ficam suas APIs):
  * http://kong.localhost:8000/
* Kong Developer Portal:
  * http://portal.localhost:8000/
* Kong Manager:
  * http://manager.localhost:8000/

## Desinstalar Kong (opcional):

Remover Kong EE:

```sh
helm delete kong
# se quiser zerar o banco e secrets
kubectl delete pvc data-kong-postgresql-0
kubectl delete secrets kong-enterprise-license kong-enterprise-superuser-password kong-session-config
```

## Notas adicionais

A configuração "cookie_samesite=Strict" funciona quando manager e admin API estão no mesmo domain ("manager.localhost" e "api.manager.localhost" em nosso caso). O mesmo vale para o Dev Portal ("portal.localhost" e "api.portal.localhost"). Se os domains forem diferentes então use "cookie_samesite=off".
