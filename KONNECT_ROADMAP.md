# Roadmap - exemplos Kong Konnect <!-- omit in toc -->

A Kong hoje desencoraja instalações do Kong Gateway Enterprise com control plane próprio,
direcionando esses cenários para o [Konnect](https://konghq.com/products/kong-konnect) (control
plane como serviço, data planes rodando na sua infraestrutura). Por isso todos os exemplos
Enterprise deste repositório foram movidos para [`archive/enterprise/`](archive/enterprise/) e
serão substituídos pelos cenários Konnect listados abaixo.

**Nenhum item deste roadmap foi construído ou validado ainda.** Todos exigem uma organização no
Konnect (há um tier gratuito) e credenciais próprias — nenhum certificado ou token deve ser
versionado neste repositório.

- [Contexto de versões](#contexto-de-versões)
- [Cenários planejados](#cenários-planejados)
- [O que já existe como ponto de partida](#o-que-já-existe-como-ponto-de-partida)

## Contexto de versões

Situação verificada em setembro de 2026:

| Artefato | Versão | Observação |
| --- | --- | --- |
| `kong` (OSS) | 3.9.3 | não há 3.10+; a linha OSS parou no 3.9 |
| `kong/kong-gateway` (Enterprise / data plane) | 3.14.0.15 | usada pelos data planes do Konnect |
| chart `kong/kong` | 3.4.1 | chart clássico, usado nos exemplos OSS |
| chart `kong/ingress` | 0.24.0 | chart atual recomendado para KIC + gateway |
| chart `kong/kong-operator` | 1.4.0 | sucessor do `gateway-operator` (parado em 0.6.1) |
| chart `kong/kong-ai-gateway` | 0.2.1 | AI Gateway conectado ao Konnect |

A distância entre a linha OSS (3.9) e a Enterprise (3.14) é, por si só, a medida do movimento da
Kong em direção ao Konnect.

## Cenários planejados

Em ordem sugerida de execução, do mais simples ao mais elaborado:

1. **Data plane Konnect via docker compose**
   Deriva de `archive/enterprise/KONG_EE_DOCKER_COMPOSE.md`. É o caminho mais curto para um
   primeiro laboratório: um único container `kong/kong-gateway` em `konnect_mode`, sem database e
   sem Kong Manager local.

2. **Data plane Konnect em k3d**
   Deriva de `archive/enterprise/KONG_EE_LOCAL_INGRESS.md`. Instala um data plane no cluster local
   com o chart `kong/kong`, conectado ao control plane no Konnect. Substitui todo o aparato de
   secrets local (`kong-enterprise-license`, `kong-enterprise-superuser-password`,
   `kong-session-config`) por um único par de certificados emitido pelo Konnect.

3. **Data plane Konnect + Ingress Controller**
   Deriva de `archive/enterprise/KONG_EE_LOCAL_DB.md`. Mesmo cenário anterior, mas com o KIC
   habilitado, mostrando a configuração vindo de CRDs do Kubernetes em vez do Kong Manager.
   A demo de CRDs em `kic/` pode ser reaproveitada como está.

4. **Configuração declarativa com decK**
   Não tem equivalente direto nos exemplos arquivados, porque todos eles configuravam o Kong pela
   UI do Manager. No Konnect o caminho recomendado é config-as-code: `deck gateway dump` /
   `deck gateway sync` contra o control plane.

5. **Múltiplos data planes (multi-região)**
   Deriva de `archive/enterprise/KONG_EE_LOCAL_INGRESS_FULL_DISTRIBUTED.md`. Com o control plane
   no Konnect, o exemplo deixa de precisar de três clusters k3d e da gestão manual do
   `kong-cluster-cert`: sobram apenas dois clusters, cada um com um data plane.

6. **Plugin customizado em data plane Konnect**
   Deriva dos experimentos em `archive/wip/custom-plugin/` e `archive/wip/custom-oidc/`. Exige
   construir uma imagem própria do data plane e registrar o schema do plugin no control plane.

7. **Konnect AI Gateway**
   Cenário novo, sem equivalente Enterprise no repositório. Usa o chart `kong/kong-ai-gateway`
   para expor provedores de LLM atrás do Kong.

8. **Kong Operator**
   Alternativa aos charts Helm para os cenários acima, usando o chart `kong/kong-operator` e os
   CRDs de `DataPlane` / `ControlPlane`.

## O que já existe como ponto de partida

O arquivo `archive/wip/konnect/values.yaml` é um values de data plane Konnect que chegou a ser
usado: define `role: data_plane`, `database: "off"`, `konnect_mode: "on"`, `cluster_mtls: pki` e os
endpoints de cluster e telemetria da região. Serve de esqueleto para os itens 2 e 3, mas precisa
de:

- endpoints do control plane conferidos (os do arquivo são de fevereiro de 2024)
- um par de certificados novo, gerado e mantido **fora** do repositório — o par original foi
  apagado, por ser material de chave privada sem uso
- atualização da imagem, hoje fixada em `kong/kong-gateway:3.6.0.0`
