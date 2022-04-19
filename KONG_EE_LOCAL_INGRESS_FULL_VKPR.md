# Kong Enterprise on Kubernetes (k3d) - VKPR <!-- omit in toc -->

O Kong Enterprise on Kubernetes é uma instalação "plena" do Kong Gateway que também faz uso do Kong Ingress Controller. Passos para executar Kong Enterprise on Kubernetes localmente utilizando o VKPR:

- [Pré-requisitos](#pré-requisitos)
- [Criar cluster k3d](#criar-cluster-k3d)
- [Instalar Kong Enterprise on Kubernetes:](#instalar-kong-enterprise-on-kubernetes)
- [Acessar aplicações:](#acessar-aplicações)
- [Configurar o Kong Enterprise on Kubernetes](#configurar-o-kong-enterprise-on-kubernetes)
- [Desinstalar Kong (opcional):](#desinstalar-kong-opcional)

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

## Criar cluster k3d

A criação do cluster de teste pode ser feita via VKPR, o qual também facilita subir um banco postgres necessário ao Kong:

```sh
vkpr infra up
```

## Instalar Kong Enterprise on Kubernetes:

Para instalar o Kong Enterprise on Kubernetes *com uma licença válida* usando o chart oficial:

```sh
vkpr kong install --domain localhost --enterprise true --license $(pwd)/license.json --secure false --kong_mode standard
```

## Acessar aplicações:

* Kong Gateway (onde ficam suas APIs):
  * http://localhost:8000/
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
curl http://localhost:8000/cep/20020080/json
```

## Desinstalar Kong (opcional):

Remover Kong EE:

```sh
vkpr kong remove
```
