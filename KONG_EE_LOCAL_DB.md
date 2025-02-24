# Kong EE local (k3d) - modo normal <!-- omit in toc -->

Passos para executar Kong Gateway localmente em um cluster k3d e em modo "normal", com database, RBAC e usando uma licença válida.

- [Pré-requisitos](#pré-requisitos)
- [Importar chart oficial do Kong:](#importar-chart-oficial-do-kong)
- [Criar cluster k3d](#criar-cluster-k3d)
- [Configurar licença e secrets](#configurar-licença-e-secrets)
- [Instalar Kong Gateway:](#instalar-kong-gateway)
- [Acessar aplicações:](#acessar-aplicações)
- [Configurar o Kong no Kubernetes com CRDs](#configurar-o-kong-no-kubernetes-com-crds)
- [Desinstalar Kong (opcional):](#desinstalar-kong-opcional)
- [Observações](#observações)

## Pré-requisitos

As seguintes ferramentas de linha de comando devem estar instaladas na estação de trabalho:

- Docker Desktop (OSX/Windows) ou Docker CE (Linux)
- vkdr
- k3d (*)
- Helm (*)
- Kubectl (*)

(*) já embutido no `vkdr` na pasta `~/.vkdr/bin`

**Importante:** este exemplo também assume que nomes "*.localhost" resolvem sempre para localhost. Se este não for o caso basta criar as entradas abaixo manualmente em /etc/hosts.

```
127.0.0.1 manager.localhost registry.localhost
```

## Importar chart oficial do Kong:

```sh
helm repo add kong https://charts.konghq.com
helm repo update
```

## Criar cluster k3d

O comando abaixo usa o VKPR para criar um cluster Kubernetes (k3d) já com o Traefik Ingress Controller (porta 8000), mas também pronto para expor o Kong em uma porta local arbitrária (9000). O Traefik atenderá a aplicações web "comuns" (o que inclui o Kong Manager e a Admin API), enquanto a porta 9000 está reservada para o tráfego de APIs (Kong Gateway). 

```sh
# roda um cluster k3d com traefik usando vkdr
vkdr infra start --traefik --nodeports=2
```

Este exemplo também habilita o Kong Ingress Controller. O Traefik é o ingress controller "default" do cluster e o Kong proxy estará disponível em portas dedicadas (9000/9001) para tráfego exclusivo de APIs. Esta separação apenas demonstra que é possível ter os endpoints de administração do Kong separados do endpoint do próprio API Gateway.

## Configurar licença e secrets

Para utilizar uma licença válida (ex: arquivo `license.json`) use a forma abaixo para criar os diversos secrets necessários/recomendados ao Kong Gateway:

```sh
kubectl create secret generic kong-enterprise-license --from-file=license=./license.json
export ADMIN_COOKIE_SECRET=$(pwgen 15 1)   # ou qualquer string desejada
export KONGPWD=$(pwgen 15 1)               # senha superadmin do Kong
kubectl create secret generic kong-enterprise-superuser-password --from-literal=password=$KONGPWD
echo '{"cookie_name":"admin_session","cookie_samesite":"Strict","secret":"'$ADMIN_COOKIE_SECRET'","cookie_secure":false,"storage":"kong"}' > admin_gui_session_conf
kubectl create secret generic kong-session-config \
  --from-file=admin_gui_session_conf=admin_gui_session_conf
echo "kong_admin password: $KONGPWD"
```

## Instalar Kong Gateway:

Para instalar Kong Gateway *com uma licença válida* usando o chart oficial:

```sh
helm upgrade -i kong -f values-ee-db-licensed.yaml kong/kong
```

## Acessar aplicações:

* Kong Gateway (onde ficam suas APIs):
  * http://localhost:9000/
  * https://localhost:9001/
* Kong Manager:
  * http://localhost:8000/manager
* Kong Admin API:
  * http://localhost:8000

## Configurar o Kong no Kubernetes com CRDs

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
# se quiser zerar o banco e secrets
kubectl delete pvc data-kong-postgresql-0
kubectl delete secrets kong-enterprise-license kong-enterprise-superuser-password kong-session-config
```

## Observações

Esta é a instalação mais completa do Kong para os testes mais comuns.
