# Kong CE remoto (Okteto) - modo normal <!-- omit in toc -->

Passos para executar Kong CE remotamente (em modo "normal", com database) em cluster Okteto e utilizando o chart do Vertigo iPaaS. O [Okteto](https://okteto.com)] é um ambiente self-service de desenvolvimento em kubernetes na nuvem, gratuito para clusters de até 4Gb de RAM.

- [Importar chart do iPaaS:](#importar-chart-do-ipaas)
  - [Abrir Okteto no browser](#abrir-okteto-no-browser)
- [Instalar Kong CE:](#instalar-kong-ce)
- [Acessar aplicações:](#acessar-aplicações)
- [Desinstalar Kong (opcional):](#desinstalar-kong-opcional)

## Importar chart do iPaaS:

```sh
helm repo add vtg-ipaas https://vertigobr.gitlab.io/ipaas/vtg-ipaas-chart
helm repo update
```

### Abrir Okteto no browser

Crie uma conta no [Okteto](https://okteto.com)] (use seu login do Github) e baixe o **kubeconfig** para algum caminho local:

```sh
export KUBECONFIG=<caminho-do-kubeconfig>
kubectl get pods
No resources found in xxxxx namespace.
```

## Instalar Kong CE:

Instalar Kong CE com o chart do iPaaS:

```sh
helm upgrade -i kong-okteto -f values-db-okteto.yaml --skip-crds vtg-ipaas/vtg-ipaas
```

## Acessar aplicações:

Veja no console web do Okteto as URLs de acesso às aplicações.

* Konga:
  * https://kong-okteto-konga-\<namespace\>.cloud.okteto.net/
* Kong proxy:
  * https://kong-okteto-kong-proxy-\<namespace\>.cloud.okteto.net/ 

**IMPORTANTE:** corrigir connection "kong-admin" para **http://kong-okteto-kong-admin:8001**.

## Desinstalar Kong (opcional):

Remover Kong CE:

```sh
helm delete kong-local
# se quiser zerar o banco
kubectl delete pvc data-kong-local-postgresql-0
```
