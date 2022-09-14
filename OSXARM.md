# Dicas para OSX M1 (ARM)

No OSX M1 (ou posterior) o processador ARM traz algumas consequências **para quem usa o Docker Desktop**:

1. Containers de imagem AMD64 serão emulados automaticamente
2. Containers de imagem ARM64 rodam nativamente

Um comando `docker pull` no OSX M1 irá baixar uma imagem ARM64 se ela existir, ou irá tentar baixar uma imagem AMD64 caso contrário.

Para descobrir a arquitetura de uma imagem baixada via `docker pull` basta o comando abaixo:

```sh
docker image inspect <imagem> --format '{{ .Os }}/{{ .Architecture }}'
```

No presente momento há ainda várias produtos cujas imagens ainda são apenas AMD, mas gradualmente veremos cada vez mais imagens ARM. No Docker Hub podemos ver claramente quais arquiteturas são suportadas para cada imagem.

O Postgres já possui ambas arquiteturas (AMD e ARM) e o `docker pull` iré sempre escolher a plataforma correta.

Já a imagem oficial do Kong Gateway para uso em produção ainda é apenas AMD, embora a partir da versão 3.x tenhamos já imagens "alpine" em ARM para uso em desenvolvimento.

```sh
# result: linux/amd64
docker pull kong/kong-gateway:3.0.0.0
docker image inspect kong/kong-gateway:3.0.0.0 --format '{{ .Os }}/{{ .Architecture }}'
# result: linux/arm64
docker pull kong/kong-gateway:3.0.0.0-alpine
docker image inspect kong/kong-gateway:3.0.0.0-alpine --format '{{ .Os }}/{{ .Architecture }}'
```

