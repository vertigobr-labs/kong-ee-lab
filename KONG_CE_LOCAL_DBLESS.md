# Kong CE local (k3d) - modo normal <!-- omit in toc -->

Passos para executar Kong CE localmente (usando o VKPR para subir um cluster k3d) em modo "dbless".

- [Pré-requisitos](#pré-requisitos)
- [Importar chart oficial do Kong:](#importar-chart-oficial-do-kong)
- [Criar cluster k3d](#criar-cluster-k3d)
- [Instalar Kong CE:](#instalar-kong-ce)
- [Acessar aplicações:](#acessar-aplicações)
- [Exemplos:](#exemplos)
- [Desinstalar Kong (opcional):](#desinstalar-kong-opcional)

## Pré-requisitos

As seguintes ferramentas de linha de comando devem estar instaladas na estação de trabalho:

- Docker Desktop (OSX/Windows) ou Docker CE (Linux)
- VKPR
- k3d (*)
- Helm (*)
- Kubectl (*)

(*) já embutidos no `vkpr` na pasta `~/.vkpr/bin`

**Importante:** este exemplo expõe Kong e sua Admin API localmente nas portas 8000 e 9000 em HTTP (sem TLS).

## Importar chart oficial do Kong:

```sh
helm repo add kong https://charts.konghq.com
helm repo update
```

## Criar cluster k3d

O VKPR cria um cluster Kubernetes (k3d), o qual já está pronto para expor o Kong Gateway, sua Admin API e Admin UI (Manager) em portas locais arbitrária (8000, 9000 e 9001 respectivamente): 

```sh
# roda um cluster k3d usando VKPR
vkpr infra start --nodeports=2
```

## Instalar Kong CE:

Instalar Kong CE com o chart padrão:

```sh
helm upgrade -i kong -f values-dbless.yaml kong/kong
```

## Acessar aplicações:

* Kong Gateway:
  * http://localhost:8000/ 
* Kong Admin API:
  * http://localhost:9000/ 
* Kong Admin UI (Manager):
  * http://localhost:9001/ 

## Exemplos:

```sh
curl -s localhost:8000

{
  "message": "no Route matched with those values",
  "request_id": "1579e7419a81ef1628ceee1431e26810"
}
```

## Desinstalar Kong (opcional):

Remover Kong CE:

```sh
helm delete kong
```
