# Kong EE remoto (Okteto) - modo normal <!-- omit in toc -->

Passos para executar Kong Gateway remotamente no Okteto e em modo "ingress controller" (sem database). O [Okteto](https://okteto.com)] é um ambiente self-service de desenvolvimento em kubernetes na nuvem, gratuito para clusters de até 4Gb de RAM.

- [Pré-requisitos](#pré-requisitos)
- [Login no Okteto](#login-no-okteto)
- [Importar chart oficial do Kong:](#importar-chart-oficial-do-kong)
- [Configurar licença e secrets](#configurar-licença-e-secrets)
- [Instalar Kong Gateway:](#instalar-kong-gateway)
- [Acessar aplicações:](#acessar-aplicações)
- [Desinstalar Kong (opcional):](#desinstalar-kong-opcional)
- [Redeploy Kong no Okteto](#redeploy-kong-no-okteto)

## Pré-requisitos

As seguintes ferramentas de linha de comando devem estar instaladas na estação de trabalho:

- Okteto CLI
- Helm
- Kubectl

## Login no Okteto

```sh
okteto context use https://cloud.okteto.com
okteto kubeconfig
```

## Importar chart oficial do Kong:

```sh
helm repo add kong https://charts.konghq.com
helm repo update
```

## Configurar licença e secrets

Para utilizar uma licença válida (ex: arquivo `license.json`) use a forma abaixo para criar os diversos secrets necessários/recomendados ao Kong Gateway:

```sh
# usando licença:
kubectl create secret generic kong-enterprise-license --from-file=license=./license.json
```

## Instalar Kong Gateway:

Instalar Kong Gateway com o chart oficial. Note que são importantes os parâmetros que são função do namespace no Okteto:

```sh
export NAMESPACE="nome-do-seu-namespace-no-okteto"
export HELMNAME="kong"
helm upgrade -i $HELMNAME -f values-ee-okteto-ingress-licensed.yaml kong/kong --skip-crds \
  --set env.admin_gui_url="https://$HELMNAME-kong-manager-$NAMESPACE.cloud.okteto.net" \
  --set env.admin_api_uri="https://$HELMNAME-kong-admin-$NAMESPACE.cloud.okteto.net" \
  --set env.proxy_url="https://$HELMNAME-kong-proxy-$NAMESPACE.cloud.okteto.net"
```

Nota: os ajustes "--set" na linha de comando deste exemplo se devem ao fato dos nomes do namespace e do release afetarem URLs e nomes de serviços.

## Acessar aplicações:

Veja no console web do Okteto as URLs de acesso às aplicações.

* Kong Gateway:
  * https://kong-kong-proxy-*namespace*.cloud.okteto.net/
* Kong Manager:
  * https://kong-kong-manager-*namespace*.cloud.okteto.net/
* Kong Admin API:
  * https://kong-kong-admin-*namespace*.cloud.okteto.net/


## Desinstalar Kong (opcional):

Remover Kong EE:

```sh
helm delete kong
# se quiser zerar o banco e secrets
kubectl delete secrets kong-enterprise-license kong-enterprise-superuser-password kong-session-config
```

## Redeploy Kong no Okteto

Caso as aplicações no namespace do Okteto entrem em modo "sleeping" po inatividade, desinstale o release como indicado acima e instale o Kong novamente.

