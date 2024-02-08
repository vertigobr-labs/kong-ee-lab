# Kong Enterprise on Kubernetes (k3d) - Ingress Controller <!-- omit in toc -->

O Kong Gateway Enterprise no Kubernetes é uma instalação "plena" do Kong Gateway que também faz uso do Kong Ingress Controller. Uma topologia possível para o Kong é chamda de "híbrida", separando os módulos de controle dos módulos de dados (control plane e data plane).

In this mode, Kong nodes in a cluster are split into two roles: control plane (CP), where configuration is managed and the Admin API is served from; and data plane (DP), which serves traffic for the proxy. Each DP node is connected to one of the CP nodes, and only the CP nodes are directly connected to a database.

- [Pré-requisitos](#pré-requisitos)
- [Importar chart oficial do Kong:](#importar-chart-oficial-do-kong)
- [Criar clusters k3d apartados](#criar-clusters-k3d-apartados)
- [Instalar Control Plane](#instalar-control-plane)
- [Instalar Data Plane 1](#instalar-data-plane-1)
- [Instalar Data Plane 2](#instalar-data-plane-2)
- [Checar data planes](#checar-data-planes)
- [Acessar aplicações:](#acessar-aplicações)

**Importante:** algumas instruções diferem quando a instalação é em "Free Mode" ou licenciada.

## Pré-requisitos

As seguintes ferramentas de linha de comando devem estar instaladas na estação de trabalho:

- Docker Desktop (OSX/Windows) ou Docker CE (Linux)
- k3d
- Helm
- Kubectl

Para utilizar uma licença válida consideramos um arquivo `license.json` fornecido pela Kong.

Nota: estamos usando o k3d para subir um kubernetes local, mas outras alternativas como o minikube também devem funcionar. 

## Importar chart oficial do Kong:

```sh
helm repo add kong https://charts.konghq.com
helm repo update
```

## Criar clusters k3d apartados

O script abaixo cria três clusters Kubernetes (k3d), sendo um dedicado ao control plane e dois como data planes separados. O control plane é acessível nas portas 30001 (Admin API), 30002 (Manager), 30005 (cluster API) e 30006 (Cluster Telemetry). Os data planes terão portas 9000/9001 e 9100/9101 (http/https). 

```sh
# cria clusters k3d
# control plane
k3d cluster create kong-cp \
  -p "8000:80@loadbalancer" \
  -p "8001:443@loadbalancer" \
  -p "30001:30001@server:0" \
  -p "30002:30002@server:0" \
  -p "30005:30005@server:0" \
  -p "30006:30006@server:0" \
  --k3s-arg '--disable=traefik@server:0'

# data planes 1 e 2
k3d cluster create kong-dp1 \
  -p "9000:80@loadbalancer" \
  -p "9001:443@loadbalancer" \
  --k3s-arg '--disable=traefik@server:0'  
k3d cluster create kong-dp2 \
  -p "9100:80@loadbalancer" \
  -p "9101:443@loadbalancer" \
  --k3s-arg '--disable=traefik@server:0'

# gera KUBECONFIGs
export KCFG_CP=$(k3d kubeconfig write kong-cp)
export KCFG_DP1=$(k3d kubeconfig write kong-dp1)
export KCFG_DP2=$(k3d kubeconfig write kong-dp2)

# senha superadmin do Kong e session cookie
export KONGPWD=$(pwgen 15 1)
export ADMIN_COOKIE_SECRET=$(pwgen 15 1)   # ou qualquer string desejada
echo '{"cookie_name":"admin_session","cookie_samesite":"Strict","secret":"'$ADMIN_COOKIE_SECRET'","cookie_secure":false,"storage":"kong"}' > admin_gui_session_conf

## Criar certificado do cluster 
mkdir -p ./certs
openssl req -new -x509 -nodes -newkey ec:<(openssl ecparam -name secp384r1) \
  -keyout ./certs/cluster.key -out ./certs/cluster.crt \
  -days 1095 -subj "/CN=kong_clustering"

```

## Instalar Control Plane

O Kong Manager existirá apenas no control plane. No control plane não há ingress controller, mas nos data planes sim. 

```sh
# Criar secret com certificado do cluster
kubectl create secret tls kong-cluster-cert \
  --cert=./certs/cluster.crt --key=./certs/cluster.key --kubeconfig=$KCFG_CP

# Criar secret com licença da Kong
kubectl create secret generic kong-enterprise-license \
  --from-file=license=./license.json --kubeconfig=$KCFG_CP

# Criar secret com senha do superadmin
kubectl create secret generic kong-enterprise-superuser-password \
  --from-literal=password=$KONGPWD --kubeconfig=$KCFG_CP

# Criar secret com session config
kubectl create secret generic kong-session-config \
  --from-file=admin_gui_session_conf=admin_gui_session_conf --kubeconfig=$KCFG_CP

echo "kong_admin password: $KONGPWD"

# Instalar Kong CP
helm upgrade -i kong --kubeconfig=$KCFG_CP -f values-ee-ingress-full-dist-cp.yaml kong/kong

```

Importante: na ausência de uma license key, o Kong Enterprise rodará em "free mode" com algumas funcionalidades indisponíveis. Neste caso a secret deve ser criada com um valor vazio:

```sh
kubectl create secret generic kong-enterprise-license \
  --kubeconfig=$KCFG_CP --from-literal=license=
```

## Instalar Data Plane 1

```sh
# Criar secret com certificado do cluster
kubectl create secret tls kong-cluster-cert \
  --cert=./certs/cluster.crt --key=./certs/cluster.key --kubeconfig=$KCFG_DP1

# Criar secret com licença da Kong
kubectl create secret generic kong-enterprise-license \
  --from-file=license=./license.json --kubeconfig=$KCFG_DP1

helm upgrade -i kong --kubeconfig=$KCFG_DP1 -f values-ee-ingress-full-dist-dp.yaml kong/kong

```

## Instalar Data Plane 2

```sh
# Criar secret com certificado do cluster
kubectl create secret tls kong-cluster-cert \
  --cert=./certs/cluster.crt --key=./certs/cluster.key --kubeconfig=$KCFG_DP2

# Criar secret com licença da Kong
kubectl create secret generic kong-enterprise-license \
  --from-file=license=./license.json --kubeconfig=$KCFG_DP2

helm upgrade -i kong --kubeconfig=$KCFG_DP2 -f values-ee-ingress-full-dist-dp.yaml kong/kong

```

## Checar data planes

Verifique o status dos data planes pela linha de comando:

```sh
curl -X GET http://localhost:30001/clustering/data-planes -H "kong-admin-token: $KONGPWD" | jq
```

## Acessar aplicações:

* Kong Gateway (data plane 1):
  * http://localhost:9000/
  * https://localhost:9001/
* Kong Gateway (data plane 2):
  * http://localhost:9100/
  * https://localhost:9101/
* Kong Manager:
  * http://localhost:30002

