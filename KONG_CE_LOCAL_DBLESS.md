# Kong Gateway (OSS) local em k3d - modo db-less <!-- omit in toc -->

Passos para executar o Kong Gateway (OSS) localmente em um cluster k3d (criado pelo `vkdr`) em
modo "db-less", ou seja, atuando como Kong Ingress Controller. Neste modo não há database: toda a
configuração vem de objetos do Kubernetes (CRDs e annotations).

- [Pré-requisitos](#pré-requisitos)
- [Importar chart oficial do Kong](#importar-chart-oficial-do-kong)
- [Criar cluster k3d](#criar-cluster-k3d)
- [Instalar Kong](#instalar-kong)
- [Acessar aplicações](#acessar-aplicações)
- [Configurar uma API com CRDs](#configurar-uma-api-com-crds)
- [Desinstalar Kong (opcional)](#desinstalar-kong-opcional)

## Pré-requisitos

As seguintes ferramentas de linha de comando devem estar instaladas na estação de trabalho:

- Docker Desktop (OSX/Windows) ou Docker CE (Linux)
- vkdr
- k3d (*)
- Helm (*)
- Kubectl (*)

(*) já embutidos no `vkdr` na pasta `~/.vkdr/bin`

**Importante:** este exemplo expõe o Kong e sua Admin API localmente em HTTP (sem TLS).

## Importar chart oficial do Kong

```sh
helm repo add kong https://charts.konghq.com
helm repo update
```

## Criar cluster k3d

O `vkdr` criará um cluster Kubernetes (k3d) que exporá o Kong Gateway, sua Admin API e o Kong
Manager em portas locais (8000, 9000 e 9001 respectivamente):

```sh
# roda um cluster k3d usando vkdr
vkdr infra start --nodeports=2
```

## Instalar Kong

Instalar o Kong OSS com o chart oficial, fixando a versão do chart para que o laboratório seja
reprodutível:

```sh
helm upgrade -i kong -f values-dbless.yaml kong/kong --version 3.4.1
kubectl rollout status deploy/kong-kong
```

O chart `kong/kong` 3.4.1 corresponde ao Kong Gateway 3.9, e o `values-dbless.yaml` fixa a imagem
em `kong:3.9.3` (a versão OSS mais recente).

## Acessar aplicações

- Kong Gateway: `http://localhost:8000/`
- Kong Admin API: `http://localhost:9000/`
- Kong Manager (Admin UI): `http://localhost:9001/`

Em modo db-less a Admin API e o Kong Manager são somente leitura — a configuração é feita
exclusivamente por objetos do Kubernetes.

Testar o endpoint do API gateway (proxy):

```sh
curl -s localhost:8000

{
  "message": "no Route matched with those values",
  "request_id": "1579e7419a81ef1628ceee1431e26810"
}
```

Testar o endpoint da Admin API:

```sh
curl -s localhost:9000/status | jq ".server"

{
  "connections_waiting": 1,
  "total_requests": 83,
  "connections_active": 4,
  "connections_handled": 46,
  "connections_reading": 0,
  "connections_accepted": 46,
  "connections_writing": 3
}
```

## Configurar uma API com CRDs

A pasta `kic/` define um serviço e uma rota no Kong pelo simples deployment de um `Service`
(do tipo `ExternalName`, apontando para a API pública do ViaCEP) e de um `Ingress`:

```sh
# cria serviço e rota no Kong via CRDs
kubectl apply -f kic/
# testa o serviço (pela porta do proxy, 8000)
curl http://localhost:8000/cep/20020080/json
```

## Desinstalar Kong (opcional)

```sh
kubectl delete -f kic/
helm delete kong
```
