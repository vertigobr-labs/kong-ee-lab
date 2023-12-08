# Kong EE local (k3d) - modo normal <!-- omit in toc -->

Passos para executar Kong Gateway localmente em um cluster k3d e em modo "normal" (com database) e em Free Mode.

- [Pré-requisitos](#pré-requisitos)
- [Importar chart oficial do Kong:](#importar-chart-oficial-do-kong)
- [Criar cluster k3d](#criar-cluster-k3d)
- [Instalar Kong Gateway em Free Mode](#instalar-kong-gateway-em-free-mode)
- [Instalar Kong Gateway em Free Mode (com basic-auth)](#instalar-kong-gateway-em-free-mode-com-basic-auth)
- [Acessar aplicações:](#acessar-aplicações)
- [Desinstalar Kong (opcional):](#desinstalar-kong-opcional)

## Pré-requisitos

As seguintes ferramentas de linha de comando devem estar instaladas na estação de trabalho:

- Docker Desktop (OSX/Windows) ou Docker CE (Linux)
- VKPR
- k3d (*)
- Helm (*)
- Kubectl (*)

(*) já embutidos no `vkpr` na pasta `~/.vkpr/bin`

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

O VKPR cria um cluster Kubernetes (k3d), o qual já está pronto para expor o Kong em uma porta local arbitrária (8000): 

```sh
# roda um cluster k3d usando VKPR
vkpr infra up
```

## Instalar Kong Gateway em Free Mode

Para instalar Kong Gateway em "Free Mode" (i.e. sem uma licença) com o chart oficial:

```sh
helm upgrade -i kong -f values-ee-db-freemode.yaml kong/kong
```

Em `values-ee-db-freemode.yaml` é ativado o modo "enterprise" mas a *secret* com licença é ignorada.

## Instalar Kong Gateway em Free Mode (com basic-auth)

A instalação acima deixa ambos Manager e Admin API abertos (sem senha), o que pode não ser desejável em redes públicas. Para proteger minimamente ambos com basic-auth pode ser usada a instalação alternativa abaixo:

```sh
helm upgrade -i kong -f values-ee-db-freemode-basic-auth.yaml kong/kong
# plugin e consumer para usuário/senha = teste/senha
kubectl apply -f kic-freemode-auth
```

## Acessar aplicações:

* Kong Gateway (onde ficam suas APIs):
  * http://localhost:8000/
* Kong Manager:
  * http://manager.localhost:8000/manager
* Kong Admin API:
  * http://manager.localhost:8000

Notas: 

1. Em free mode o Dev Portal não está disponível, mas temos o Kong Manager;
2. O ingress controller neste exemplo é o próprio Kong, portanto o Manager e a Admin API do Kong aparecem como serviços do próprio API Gateway.

## Desinstalar Kong (opcional):

Remover Kong EE:

```sh
helm delete kong
# se quiser zerar o banco
kubectl delete pvc data-kong-postgresql-0
```
