# Kong Gateway Enterprise em modo "Ingress Controller" <!-- omit in toc -->

Uma instalação do Kong Gateway Enterprise pode estar restrita a uma configuração feita apenas pelo Ingress Controller, operando efetivamente em modo "db-less". Uma topologia assim suporta a ampla maioria dos plugins Enterprise (exceto aquele incompatíveis com "db-less"), e sua configuração do Kong é feita por CRDs e objetos Kubernetes anotados.

Neste cenário a Admin API e Kong Manager são *read-only*, mas o Manager segue sendo útil para observar a configuração resultante dos CRDs.

- [Pré-requisitos](#pré-requisitos)
- [Importar chart oficial do Kong:](#importar-chart-oficial-do-kong)
- [Criar cluster k3d](#criar-cluster-k3d)
- [Configurar licença](#configurar-licença)
- [Instalar Kong for Kubernetes Enterprise:](#instalar-kong-for-kubernetes-enterprise)
- [Acessar aplicações:](#acessar-aplicações)
- [Notas](#notas)
  - [db-less](#db-less)
  - [Ingress classes](#ingress-classes)
- [Desinstalar Kong (opcional):](#desinstalar-kong-opcional)

**Importante:** algumas instruções diferem quando a instalação é em "Free Mode" ou licenciada.

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

O comando abaixo usa o VKPR para criar um cluster Kubernetes (k3d) já com o Traefik Ingress Controller (porta 8000), mas também pronto para expor o Kong Ingress Controller em uma porta local arbitrária (9000). O Traefik atenderá a aplicações web "comuns", enquanto a porta 9000 está reservada para o tráfego de APIs. 

```sh
# roda um cluster k3d com traefik usando vkdr
vkdr infra start --traefik --nodeports=2
```

## Configurar licença

Usar uma licença válida irá habilitar os plugins Enterprise. Para utilizar uma licença válida (ex: arquivo `license.json`) use a forma abaixo:

```sh
kubectl create secret generic kong-enterprise-license --from-file=license=./license.json
```

Para rodar o Kong for Kubernetes Enterprise **em "free mode"** (sem licença e com algumas funcionalidades indisponíveis) é preciso apenas aplicar uma licença "vazia":

```sh
kubectl create secret generic kong-enterprise-license --from-literal=license=
```

## Instalar Kong for Kubernetes Enterprise:

Para instalar Kong for Kubernetes Enterprise com o chart oficial:

```sh
helm upgrade -i kong -f values-ee-ingress.yaml kong/kong
```

## Acessar aplicações:

* Kong Gateway (onde ficam suas APIs):
  * http://localhost:9000/
* Kong Manager:
  * http://manager.localhost:8000/manager
* Kong Admin API (read-only):
  * http://manager.localhost:8000

## Notas

### db-less

Esta é uma instalação "db-less", portanto o Manager e Admin API estarão read-only (como esperado). Use CRDs para configurar o Kong.

### Ingress classes

O Traefik tem ingress class "traefik" como a default do cluster, enquanto a do Kong é "kong".

## Desinstalar Kong (opcional):

Remover Kong EE:

```sh
helm delete kong
```
