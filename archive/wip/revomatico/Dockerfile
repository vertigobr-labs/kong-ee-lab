FROM kong/kong-gateway:3.5.0.3
#FROM kong:3.5

USER root

RUN apt update && apt install -y curl unzip gcc git

RUN mkdir -p /opt/src && \
    git clone https://github.com/revomatico/kong-oidc.git /opt/src/kong-oidc && \
    git clone https://github.com/oldium/lua-resty-openidc.git /opt/src/lua-resty-openidc

RUN mv /opt/src/kong-oidc/kong-oidc.rockspec /opt/src/kong-oidc/kong-oidc-1.4.0-1.rockspec

RUN cd /opt/src/lua-resty-openidc && \
    git checkout resty-session-4.x && \
    luarocks remove lua-resty-session --force && \
    luarocks make *.rockspec CRYPTO_INCDIR=/usr/local/kong/include/ CRYPTO_DIR=/usr/local/kong/ OPENSSL_DIR=/usr/local/kong/

ADD handler.lua /opt/src/kong-oidc/kong/plugins/oidc/handler.lua
ADD schema.lua /opt/src/kong-oidc/kong/plugins/oidc/schema.lua

RUN cd /opt/src/kong-oidc &&  \
    luarocks make *.rockspec CRYPTO_INCDIR=/usr/local/kong/include/ CRYPTO_DIR=/usr/local/kong/ OPENSSL_DIR=/usr/local/kong/

#USER kong
