# Kong Enterprise on Kubernetes (k3d) - Ingress Controller <!-- omit in toc -->

O Kong Enterprise on Kubernetes é uma instalação "plena" do Kong Gateway que também faz uso do Kong Ingress Controller. Passos para executar Kong Enterprise on Kubernetes localmente em um cluster k3d:

- [Pré-requisitos](#pré-requisitos)
- [Importar chart oficial do Kong:](#importar-chart-oficial-do-kong)
- [Criar cluster k3d](#criar-cluster-k3d)
- [Configurar licença e secrets](#configurar-licença-e-secrets)
- [Instalar Kong Enterprise on Kubernetes:](#instalar-kong-enterprise-on-kubernetes)
- [Acessar aplicações:](#acessar-aplicações)
- [Configurar o Kong Enterprise on Kubernetes](#configurar-o-kong-enterprise-on-kubernetes)
- [Desinstalar Kong (opcional):](#desinstalar-kong-opcional)
- [Observações](#observações)

**Importante:** algumas instruções diferem quando a instalação é em "Free Mode" ou licenciada.

## Pré-requisitos

As seguintes ferramentas de linha de comando devem estar instaladas na estação de trabalho:

- Docker Desktop (OSX/Windows) ou Docker CE (Linux)
- VKPR (veja https://docs.vkpr.net/)

Nota: também usaremos as ferramentas abaixo que poderão ser encontradas em `~/.vkpr/bin`, as quais também podem ser instaladas manualmente:

- helm
- kubectl
- k9s

**Importante:** este exemplo também assume que nomes "\*.localhost" resolvem sempre para localhost. Se este não for o caso basta criar as entradas abaixo manualmente em /etc/hosts.

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

O comando k3d abaixo cria um cluster já com o Traefik Ingress Controller, o qual estará publicado em porta local arbitrária (8000) e atenderá a aplicações web "comuns", enquanto as portas 9000 e 9001 estão reservadas para o Kong Ingress Controller: 

```sh
# start local registry and Docker Hub mirror
./registry/start-registry.sh
# roda um cluster k3d (vai suportar traefik e kong como ingress controllers)
k3d cluster create kong-local \
  -p "8000:80@loadbalancer" -p "9000:30080@agent:0" -p "9001:30081@agent:0" --agents 1 \
  --registry-use k3d-registry.localhost \
  --registry-config ./registry/registries.yaml
# usa este cluster
kubectl config use-context k3d-kong-local
kubectl cluster-info
```

## Configurar licença e secrets

```sh
# trocar abaixo free mode (sem licença):
kubectl create secret generic kong-enterprise-license --from-file=license=./license.json
# kubectl create secret generic kong-enterprise-license --from-literal=license=
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

## Instalar Kong Enterprise on Kubernetes:

Para instalar o Kong Enterprise on Kubernetes *com uma licença válida* usando o chart oficial:

```sh
rit set credential --provider="postgres" --fields="password" --values="senha"
vkpr postgres install
vkpr postgres createdb --dbname kong --dbpassword kong --dbuser kong
helm upgrade -i kong -f values-ee-ingress-full.yaml kong/kong
```

## Acessar aplicações:

* Kong Gateway (onde ficam suas APIs):
  * http://localhost:9000/
* Kong Developer Portal:
  * http://portal.localhost:8000/
* Kong Manager:
  * http://manager.localhost:8000/

## Configurar o Kong Enterprise on Kubernetes

O Kong Enterprise on Kubernetes pode ser configurado tanto pelo Kong Manager quanto pelos objetos (CRDs) e annotations do Kubernetes. 

Este exemplo define serviço e rota no Kong Gateway pelo simples deployment de um Service e de um Ingress:

```sh
# cria serviço e rota no Kong via CRDs
kubectl apply -f kic/
# testa o serviço
curl http://localhost:9000/cep/20020080/json
```

## Desinstalar Kong (opcional):

Remover Kong EE:

```sh
helm delete kong
```

## Observações

Esta instalação via chart é o principal laboratório para experimentar cenários que eventualmente são incorporados pelas fórmulas do VKPR. Para instalar o Kong usando apenas o VKPR siga as instruções [desta página](KONG_EE_LOCAL_INGRESS_FULL_VKPR.md).

