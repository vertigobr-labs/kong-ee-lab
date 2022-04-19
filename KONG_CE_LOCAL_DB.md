# Kong CE local (k3d) - modo normal <!-- omit in toc -->

Passos para executar Kong CE localmente (cluster k3d) em modo "normal" (com database), utilizando o chart do Vertigo iPaaS.

- [Importar chart do iPaaS:](#importar-chart-do-ipaas)
- [Criar cluster k3d](#criar-cluster-k3d)
- [Obter kubeconfig](#obter-kubeconfig)
- [Instalar Kong CE:](#instalar-kong-ce)
- [Acessar aplicações:](#acessar-aplicações)
- [Desinstalar Kong (opcional):](#desinstalar-kong-opcional)

## Importar chart do iPaaS:

```sh
helm repo add vtg-ipaas https://vertigobr.gitlab.io/ipaas/vtg-ipaas-chart
helm repo update
```

## Criar cluster k3d

O k3d cria um cluster já com o Traefik Ingress Controller, o qual estará publicado em porta local arbitrária (8000): 

```sh
k3d create -n kong-local \
  --publish 8000:80
```

## Obter kubeconfig

Ajustar KUBECONFIG no shell é simples:

```sh
export KUBECONFIG="$(k3d get-kubeconfig --name='kong-local')"
kubectl cluster-info
```

## Instalar Kong CE:

Instalar Kong CE com o chart do iPaaS:

```sh
helm upgrade -i kong-local -f values-db.yaml vtg-ipaas/vtg-ipaas
```

## Acessar aplicações:

Nota: criar entradas para todos estes hostnames em /etc/hosts como `127.0.0.1`.

* Konga:
  * http://konga.localdomain:8000/
* Kong proxy:
  * http://ipaas.localdomain:8000/ 

Observações: corrigir connection "kong-admin" para **http://kong-local-kong-admin:8001**.

## Desinstalar Kong (opcional):

Remover Kong CE:

```sh
helm delete kong-local
# se quiser zerar o banco
kubectl delete pvc data-kong-local-postgresql-0
```
