#!/bin/bash
# FALTA PORTO DO KEYROCK ATRAVÉS DE VARIÁVEIS
#set -x

# Dados de autenticação do administrador do keyrock 
ADMIN_USERNAME="admin@test.com" 
ADMIN_PASSWORD="1234"

# Nome da aplicação
APP_DATA_ACCESS_NAME="DataAccessApp"

#Criar token the autenticação para adminitrador do Keyrock
ADMIN_AUTH_TOKEN=$(curl -i --location --request POST 'http://localhost:3005/v1/auth/tokens' --header 'Content-Type: application/json' --data-raw '{
    "name":"'$ADMIN_USERNAME'",
    "password":"'$ADMIN_PASSWORD'"
}' | grep X-Subject-Token: | cut -d ":" -f2 | sed 's/^ *//g' | tr -d '\r')


# Criar aplicação no Keyrock usando token do administrado
APP_CREATE_RESP=$(curl --location --request POST 'http://localhost:3005/v1/applications' \
--header 'Content-Type: application/json' \
--header 'X-Auth-token: '$ADMIN_AUTH_TOKEN  \
--data-raw '{
  "application": {
    "name": "DataAccessApp",
    "description": "Aplicação que acede aos dados de histórico de contexto.",
    "redirect_uri": "http://localhost:8081/login",
    "url": "http://localhost:8081",
    "grant_type": [
      "authorization_code",
      "implicit",
      "password"
    ],
    "token_types": [
      "jwt",
      "permanent"
    ]
  }
}')

# Extrair campo ID da aplicação a partir da resposta do pedido anterior
APP_ID=$(echo $APP_CREATE_RESP| cut -d ":" -f3 | cut -d "," -f1 | sed 's/"//g' ) #| cut -c23-59

# Extrair campo secret da aplicação a partir da resposta do pedido anterior
APP_SECRET=$(echo $APP_CREATE_RESP| cut -d ":" -f4 | cut -d "," -f1 | sed 's/"//g' )

# Calcular valor Base64 das credenciais da aplicação
APP_AUTH_BASE64=$(echo "$APP_ID:$APP_SECRET" | base64 )
#echo $APP_AUTH_BASE64

# Adicionar PEP-Proxy à aplicação
APP_CREATE_PEP_PROXY_RESP=$(curl --location --request POST 'http://localhost:3005/v1/applications/'$APP_ID'/pep_proxies' \
--header 'Content-Type: application/json' \
--header 'X-Auth-token: '$ADMIN_AUTH_TOKEN)

PEP_PROXY_ID=$(echo $APP_CREATE_PEP_PROXY_RESP| cut -d ":" -f3 | cut -d "," -f1 | sed 's/"//g' )
PEP_PROXY_PASSWORD=$(echo $APP_CREATE_PEP_PROXY_RESP| cut -d ":" -f4 | cut -d "," -f1 | sed 's/"//g' | sed 's/}//g')

# Guardar em ficheiro, as credênciais do PEP-Proxy
echo -e "PEP_PROXY_ID=$PEP_PROXY_ID\nPEP_PROXY_PASSWORD=$PEP_PROXY_PASSWORD" | tee .pep_proxy_login

# Criar role na aplicação
APP_ROLE_CREATE_RESP=$(curl --location --request POST 'http://localhost:3005/v1/applications/'$APP_ID'/roles' \
--header 'Content-Type: application/json' \
--header 'X-Auth-token: '$ADMIN_AUTH_TOKEN \
--data-raw '{
  "role": {
    "name": "Query Data"
  }
}')

# Extrair Role ID da resposta
ROLE_ID=$(echo $APP_ROLE_CREATE_RESP| cut -d ":" -f3 | cut -d "," -f1 | sed 's/"//g' )
echo $ROLE_ID
echo "__________________________________________________"

#set -x
# Criar permissão na aplicação
#APP_PERMISSION_CREATE_RESP=$(curl --location --request POST 'http://localhost:3005/v1/applications/'$APP_ID'/permissions' \
#curl --location --request POST 'http://localhost:3005/v1/applications/'$APP_ID'/permissions' \
#--header 'Content-Type: application/json' \
#--header 'X-Auth-token: '$ADMIN_AUTH_TOKEN \
#--data-raw '{
#  "permission": {
#    "name": "Query_Data_Permission",
#    "action": "GET",
#    "resource": "login"
#    "is_regex": false
#  }
#}'



#echo $APP_PERMISSION_CREATE_RESP
#curl --location --request GET 'http://localhost:3005/v1/users' \
#--header 'Content-Type: application/json' \
#--header 'X-Auth-token: '$ADMIN_AUTH_TOKEN
  
