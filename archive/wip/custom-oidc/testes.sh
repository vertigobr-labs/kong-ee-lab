
curl https://dev-vtg-01.us.auth0.com/.well-known/openid-configuration | jq

# obter token

export TOKEN=$(curl --request POST \
  --url https://dev-vtg-01.us.auth0.com/oauth/token \
  --header 'content-type: application/x-www-form-urlencoded' \
  --data "client_id=$CLIENT_ID" \
  --data "client_secret=$CLIENT_SECRET" \
  --data "grant_type=client_credentials" \
  --data "audience=https://viacep.com.br/" | jq -r '.access_token')

curl localhost:8000/cep/20011020/json

curl -H "Authorization: Bearer $TOKEN" localhost:8000/cep/20011020/json

curl -X POST http://localhost:8001/services/b1d82afd-0c9f-4fe6-a130-15ebc9988698/plugins \
  --data "name=kong-oidc-auth"  \
    --data "config.authorize_url=https://dev-vtg-01.us.auth0.com/authorize" \
    --data "config.scope=openid+profile+email" \
    --data "config.token_url=https://dev-vtg-01.us.auth0.com/oauth/token" \
    --data "config.client_id=$CLIENT_ID" \
    --data "config.client_secret=$CLIENT_SECRET" \
    --data "config.user_url=https://dev-vtg-01.us.auth0.com/userinfo" \
    --data "config.user_keys=email,name,sub" \
    --data "config.hosted_domain=localhost" \
    --data "config.email_key=email" \
    --data "config.salt=b3253141ce67204b" \
    --data "config.app_login_redirect_url=" \
    --data "config.cookie_domain=localhost" \
    --data "config.user_info_cache_enabled=false"

curl -X POST http://localhost:8001/services/d05ca108-710f-4e87-bf37-910a07a2fa05/plugins \
  --data "name=oidc" \
    --data "config.client_id=$CLIENT_ID" \
    --data "config.client_secret=$CLIENT_SECRET" 


curl --request POST -H "Authorization: Bearer $TOKEN" \
  --url https://dev-vtg-01.us.auth0.com/oauth/userinfo
