#!/bin/bash
docker run --rm -ti --name my-kong \
  -p 8000:8000 \
  -p 8001:8001 \
  -p 8002:8002 \
  -v $(pwd):/opt/plugins/my-plugin \
  -e KONG_DATABASE=off \
  -e "KONG_PLUGINS=bundled,my-plugin" \
  --entrypoint "bash" \
  kong:3.5 

# docker exec -ti -u root -w /opt/plugins/my-plugin/ my-kong sh -c "luarocks make *.rockspec CRYPTO_INCDIR=/usr/local/kong/include/ CRYPTO_DIR=/usr/local/kong/ OPENSSL_DIR=/usr/local/kong/"

# su -m kong -c "/docker-entrypoint.sh kong start"

# curl -i -X POST http://localhost:8001/services/ --data name=viacep-service --data url=http://viacep.com.br/ws/
