# Kong Enterprise on Kubernetes (k3d) - Ingress Controller <!-- omit in toc -->

O Kong Gateway Enterprise no Kubernetes é uma instalação "plena" do Kong Gateway que também faz uso do Kong Ingress Controller. Uma topologia possível para o Kong é chamda de "híbrida", separando os módulos de controle dos módulos de dados (control plane e data plane).

In this mode, Kong nodes in a cluster are split into two roles: control plane (CP), where configuration is managed and the Admin API is served from; and data plane (DP), which serves traffic for the proxy. Each DP node is connected to one of the CP nodes, and only the CP nodes are directly connected to a database.

- [Pré-requisitos](#pré-requisitos)
- [Importar chart oficial do Kong:](#importar-chart-oficial-do-kong)
- [Criar cluster k3d e namespaces](#criar-cluster-k3d-e-namespaces)
- [Criar secret com certificado do cluster](#criar-secret-com-certificado-do-cluster)
- [Configurar licença e secrets](#configurar-licença-e-secrets)
- [Instalar Kong Gateway Enterprise on Kubernetes (control plane e data plane):](#instalar-kong-gateway-enterprise-on-kubernetes-control-plane-e-data-plane)
- [Checar data planes](#checar-data-planes)
- [Acessar aplicações:](#acessar-aplicações)
- [Configurar o Kong Enterprise on Kubernetes](#configurar-o-kong-enterprise-on-kubernetes)
- [Desinstalar Kong (opcional):](#desinstalar-kong-opcional)

**Importante:** algumas instruções diferem quando a instalação é em "Free Mode" ou licenciada.

## Pré-requisitos

As seguintes ferramentas de linha de comando devem estar instaladas na estação de trabalho:

- Docker Desktop (OSX/Windows) ou Docker CE (Linux)
- VKPR
- k3d (*)
- Helm (*)
- Kubectl (*)

(*) já embutido no `vkpr` na pasta `~/.vkpr/bin`

**Importante:** este exemplo também assume que nomes "*.localhost" resolvem sempre para localhost. Se este não for o caso basta criar as entradas abaixo manualmente em /etc/hosts.

```
127.0.0.1 manager.localhost registry.localhost
```

Nota: estamos usando o k3d para subir um kubernetes local, mas outras alternativas como o minikube também devem funcionar. 

## Importar chart oficial do Kong:

```sh
helm repo add kong https://charts.konghq.com
helm repo update
```

## Criar cluster k3d e namespaces

O comando abaixo usa o VKPR para criar um cluster Kubernetes (k3d) já com o Traefik Ingress Controller (porta 8000), mas também pronto para expor dois data planes de Kong em portas locais arbitrárias (9000 e 9001). O Traefik atenderá a aplicações web "comuns", enquanto as portas 9000/9001 estarão reservadas para o tráfego de APIs. 

```sh
# roda um cluster k3d com traefik usando VKPR
vkpr infra start --enable_traefik=true --nodeports=2
kubectl create namespace kong-cp
kubectl create namespace kong-dp1
kubectl create namespace kong-dp2
```

Este exemplo não habilita o Kong Ingress Controller. O Traefik é o ingress controller "default" do cluster e o Kong proxy estará disponível em uma porta dedicada (9000) para tráfego exclusivo de APIs. Esta separação apenas demonstra que é possível ter os endpoints de administração do Kong separados do endpoint do próprio API Gateway.

## Criar secret com certificado do cluster

```sh
mkdir -p ./certs
openssl req -new -x509 -nodes -newkey ec:<(openssl ecparam -name secp384r1) \
  -keyout ./certs/cluster.key -out ./certs/cluster.crt \
  -days 1095 -subj "/CN=kong_clustering"
kubectl create secret -n kong-cp tls kong-cluster-cert --cert=./certs/cluster.crt --key=./certs/cluster.key
kubectl create secret -n kong-dp1 tls kong-cluster-cert --cert=./certs/cluster.crt --key=./certs/cluster.key
kubectl create secret -n kong-dp2 tls kong-cluster-cert --cert=./certs/cluster.crt --key=./certs/cluster.key
```

## Configurar licença e secrets

Para utilizar uma licença válida (ex: arquivo `license.json`) use a forma abaixo para criar os diversos secrets necessários/recomendados:

```sh
kubectl create secret -n kong-cp generic kong-enterprise-license --from-file=license=./license.json
kubectl create secret -n kong-dp1 generic kong-enterprise-license --from-file=license=./license.json
kubectl create secret -n kong-dp2 generic kong-enterprise-license --from-file=license=./license.json
export ADMIN_COOKIE_SECRET=$(pwgen 15 1)   # ou qualquer string desejada
export KONGPWD=$(pwgen 15 1)               # senha superadmin do Kong
kubectl create secret -n kong-cp generic kong-enterprise-superuser-password --from-literal=password=$KONGPWD
echo '{"cookie_name":"admin_session","cookie_samesite":"Strict","secret":"'$ADMIN_COOKIE_SECRET'","cookie_secure":false,"storage":"kong"}' > admin_gui_session_conf
kubectl create secret -n kong-cp generic kong-session-config \
  --from-file=admin_gui_session_conf=admin_gui_session_conf
echo "kong_admin password: $KONGPWD"
```

## Instalar Kong Gateway Enterprise on Kubernetes (control plane e data plane):

Para instalar o Kong Gateway Enterprise *com uma licença válida* usando o chart oficial e separando *control plane* e *data plane*:

```sh
helm upgrade -i kong -n kong-cp --create-namespace -f values-ee-ingress-full-dist-cp.yaml kong/kong
helm upgrade -i kong-dp1 -n kong-dp1 --create-namespace -f values-ee-ingress-full-dist-dp.yaml kong/kong
helm upgrade -i kong-dp2 -n kong-dp2 --create-namespace -f values-ee-ingress-full-dist-dp.yaml kong/kong \
  --set proxy.http.nodePort=30001 \
  --set env.cluster_dp_labels="environment:prod"
```

## Checar data planes

Verifique o status dos data planes pela linha de comando:

```sh
curl -X GET http://manager.localhost:8000/clustering/data-planes -H "kong-admin-token: $KONGPWD" | jq
```

Verifique se os labels foram aplicados corretamente:

```sh
curl -i -X GET 'https://{region}.api.konghq.com/v2/control-planes/{controlPlaneId}/nodes' \
 --header 'Authorization: Bearer kpat_xgfT'
```

## Acessar aplicações:

* Kong Gateway (ambos os data planes):
  * http://localhost:9000/
  * http://localhost:9001/
* Kong Manager:
  * http://manager.localhost:8000/manager

## Configurar o Kong Enterprise on Kubernetes

TODO: nao funciona KIC ainda
O Kong Enterprise on Kubernetes pode ser configurado tanto pelo Kong Manager quanto pelos objetos (CRDs) do Kubernetes. Exemplo:

```sh
# cria serviço e rota no Kong via CRDs
kubectl apply -f kic/
```

## Desinstalar Kong (opcional):

Remover Kong EE:

```sh
helm delete kong -n kong-cp
# se quiser zerar o banco e secrets
kubectl delete pvc data-kong-postgresql-0 -n kong-cp
kubectl delete namespace kong-cp
kubectl delete namespace kong-dp1
kubectl delete namespace kong-dp2
```
