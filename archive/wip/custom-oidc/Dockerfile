FROM kong/kong-gateway:3.5

USER root

RUN apt update && apt install -y curl unzip gcc git

RUN mkdir -p /opt/src && \
    git clone https://github.com/Optum/kong-oidc-auth.git /opt/src/kong-oidc-auth

ADD handler.lua /opt/src/kong-oidc-auth/src/handler.lua
ADD schema.lua /opt/src/kong-oidc-auth/src/schema.lua
ADD access.lua /opt/src/kong-oidc-auth/src/access.lua

RUN echo "fixing handler.lua priority" && \
    cat /opt/src/kong-oidc-auth/src/handler.lua

RUN cd /opt/src/kong-oidc-auth && echo "oioi" && \
    luarocks make *.rockspec CRYPTO_INCDIR=/usr/local/kong/include/ CRYPTO_DIR=/usr/local/kong/ OPENSSL_DIR=/usr/local/kong/
#RUN luarocks install kong-oidc-auth CRYPTO_INCDIR=/usr/local/kong/include/ CRYPTO_DIR=/usr/local/kong/ OPENSSL_DIR=/usr/local/kong/

USER kong
