# Archive <!-- omit in toc -->

Conteúdo arquivado em setembro de 2026, quando o repositório foi reduzido aos exemplos do Kong
Gateway OSS. **Nada aqui é mantido ou atualizado.** Os arquivos ficaram congelados no estado em
que estavam: versões de imagem, charts e URLs estão desatualizados e vários dos serviços
referenciados não existem mais.

O histórico foi preservado — use `git log --follow <arquivo>` para ver as mudanças anteriores à
mudança de pasta.

## `enterprise/`

Todos os cenários de Kong Gateway Enterprise, locais (k3d) e remotos (Okteto), em Free Mode e
licenciados, incluindo o cenário híbrido com control plane e data planes separados.

Motivo do arquivamento: a Kong desencoraja instalações do Kong Gateway Enterprise com control
plane próprio, direcionando esses casos para o Konnect. Os substitutos estão planejados em
[`../KONNECT_ROADMAP.md`](../KONNECT_ROADMAP.md).

Também inclui `kic-freemode-auth/` (KongPlugin de basic-auth + KongConsumer), que só fazia sentido
no contexto do Free Mode.

## `okteto/`

O cenário Kong OSS remoto no Okteto, com o chart `vtg-ipaas` e o Konga como UI de administração.

Motivo do arquivamento: dois de seus pilares deixaram de existir — o
[Konga](https://github.com/pantsel/konga) está arquivado desde 2021 (e o Kong Gateway OSS tem
Kong Manager próprio desde a versão 3.5), e o tier gratuito do Okteto Cloud foi descontinuado.
O cenário não é reproduzível hoje.

## `wip/`

Experimentos que nunca chegaram a virar um runbook e nunca foram versionados: plugin customizado
em Lua, plugin OIDC, integração com Consul, manifestos temporários de ingress e um values de data
plane Konnect.

Dois arquivos `ingress-deploy-tmp*.yaml` (saída de `helm template` do chart kong 2.19.0) foram
descartados em vez de arquivados: continham quatro chaves privadas RSA embutidas em base64,
geradas pelo próprio chart para os webhooks de admissão. São reproduzíveis com `helm template`.

O restante foi commitado aqui para não se perder. O `wip/konnect/values.yaml` é o ponto de partida
citado no roadmap do Konnect — note que os certificados que o acompanhavam **não** foram
arquivados: eram material de chave privada real e foram apagados.

## `OSXARM.md`

Nota sobre arquiteturas de imagem em Macs Apple Silicon.

Motivo do arquivamento: o conteúdo ficou factualmente errado. O documento afirma que a imagem de
produção do Kong é apenas AMD64 e que se deve usar tags `-alpine` para rodar em ARM. Hoje tanto
`kong:3.9.3` quanto `kong/kong-gateway:3.14.0.15` são multi-arquitetura (`linux/amd64` e
`linux/arm64`), e as tags `-alpine` deixaram de ser publicadas.
