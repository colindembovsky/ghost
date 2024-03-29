#!/bin/bash

# for testing in fish console
# set -x RG "cac-ghost"
# set -x SKU "B2"
# set -x REGION "westus2"
# set -x PLAN_NAME "cacghostplan"
# set -x GHOST_WEBAPP_NAME "cacghost"
# set -x ISSO_WEBAPP_NAME "cacisso"
# set -x ACR_NAME "cacregistry"
# set -x GHOST_CDN "colinsalmcorner.com"
# set -x GHOST_WWW "1"
# set -x ISSO_CDN "comments.colinsalmcorner.com"
# set -x ISSO_WWW "0"
# set -x MYSQL_SERVER_NAME "cacmysql"
# set -x MYSQL_ADMIN "admin_cac"
# set -x MYSQL_SKU "B_Gen5_1"
# set -x EMAIL "colin@home.com"
# set -x STAGING "0"
# set -x MYSQL_PASS "SomeL0ngP@ssw0rd"
# set -x SA_NAME "cacghoststore"

echo "Creating resource group $RG in REGION $REGION"
az group create -n $RG -l $REGION

echo "Create container registry"
az acr create -g $RG -n $ACR_NAME --sku Basic --admin-enabled true

echo "Creating MYSQL server $MYSQL_SERVER_NAME"
az mysql server create -g $RG -n $MYSQL_SERVER_NAME \
    --admin-user $MYSQL_ADMIN \
    --admin-password $MYSQL_PASS --sku-name $MYSQL_SKU \
    --ssl-enforcement Disabled \
    --location $REGION

echo "Configure firewall for Azure services"
az mysql server firewall-rule create --resource-group $RG --server $MYSQL_SERVER_NAME \
        --name AllowAzureIP \
        --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0

echo "Creating ghost Database"
az mysql db create -g $RG -s $MYSQL_SERVER_NAME -n ghost

echo "Creating comments Database"
az mysql db create -g $RG -s $MYSQL_SERVER_NAME -n comments

echo "Creating app insights"
$appInsightsKey=$(az monitor app-insights component create -g $RG --app cacghost --location westus2 --kind web --application-type web --query "instrumentationKey" -o tsv)

echo "Creating app service plan $PLAN_NAME with sku $SKU"
az appservice plan create -g $RG -n $PLAN_NAME --sku $SKU --is-linux

echo "Looking up ACR credentials"
acrPassword=$(az acr credential show -g $RG -n $ACR_NAME --query "[passwords[?name=='password'].value]" --output tsv)

echo "Looking up Storage Account connection string"
storageConStr=$(az storage account show-connection-string -g $RG -n $SA_NAME --query "connectionString" -o tsv)

# echo "Creating webapp $GHOST_WEBAPP_NAME with nginx image"
# az webapp create -g $RG -n $GHOST_WEBAPP_NAME -p $PLAN_NAME \
#     --multicontainer-config-type "compose" \
#     --multicontainer-config-file "../ghost/ghost-nginx.yml"

# echo "Setting registry for $GHOST_WEBAPP_NAME"
# az webapp config container set -g $RG -n $GHOST_WEBAPP_NAME \
#     --docker-registry-server-url "https://$ACR_NAME.azurecr.io" \
#     --docker-registry-server-user $ACR_NAME \
#     --docker-registry-server-password $acrPassword \
#     --multicontainer-config-type "compose" \
#     --multicontainer-config-file "../ghost/ghost-nginx.yml"

echo "Creating webapp $GHOST_WEBAPP_NAME with nginx image"
az webapp create -g $RG -n $GHOST_WEBAPP_NAME -p $PLAN_NAME \
    -i acregistry.azurecr.io/ghost:1.0.36

echo "Setting registry for $GHOST_WEBAPP_NAME"
az webapp config container set -g $RG -n $GHOST_WEBAPP_NAME \
    --docker-registry-server-url "https://$ACR_NAME.azurecr.io" \
    --docker-registry-server-user $ACR_NAME \
    --docker-registry-server-password $acrPassword \
    -i acregistry.azurecr.io/ghost:1.0.36

echo "Enabling docker container logging"
az webapp log config -g $RG -n $GHOST_WEBAPP_NAME \
    --application-logging true \
    --detailed-error-messages true \
    --web-server-logging filesystem \
    --docker-container-logging filesystem \
    --level verbose

echo "Set custom DNS $GHOST_CDN for $GHOST_WEBAPP_NAME"
az webapp config hostname add --webapp-name $GHOST_WEBAPP_NAME -g $RG --hostname $GHOST_CDN

if [ "$GHOST_WWW" == "1" ]; then
    echo "Set custom DNS $GHOST_CDN for $GHOST_WEBAPP_NAME"
    az webapp config hostname add --webapp-name $GHOST_WEBAPP_NAME -g $RG --hostname www.$GHOST_CDN
fi

echo "Check CORS for https://$ISSO_CDN to $GHOST_WEBAPP_NAME"
corsExists=$(az webapp cors show -g $RG -n $GHOST_WEBAPP_NAME | grep "$ISSO_CDN")
if [ "" == "$corsExists" ]; then
  echo "Add CORS for https://$ISSO_CDN to $GHOST_WEBAPP_NAME"
  az webapp cors add -g $RG -n $GHOST_WEBAPP_NAME --allowed-origins https://$ISSO_CDN
else
  echo "CORS rule for https://$ISSO_CDN exists!"
fi

echo "Setting ghost and nginx env settings"
az webapp config appsettings set -g $RG -n $GHOST_WEBAPP_NAME --settings \
    url=https://$GHOST_CDN \
    CDN=$GHOST_CDN \
    WWW=$GHOST_WWW \
    EMAIL=$EMAIL \
    STAGING=$STAGING \
    AZ_CLIENT_ID=$AZ_CLIENT_ID \
    AZ_CLIENT_KEY=$AZ_CLIENT_KEY \
    AZ_TENANT_ID=$AZ_TENANT_ID \
    PFX_PASSWORD=$PFX_PASSWORD \
    WEB_APP_NAME=$GHOST_WEBAPP_NAME \
    RESOURCE_GROUP=$RG \
    APP_INSIGHTS_KEY=$appInsightsKey \
    database__client=mysql \
    database__connection__database=ghost \
    database__connection__host=$MYSQL_SERVER_NAME.mysql.database.azure.com \
    database__connection__user=$MYSQL_ADMIN@$MYSQL_SERVER_NAME \
    database__connection__password=$MYSQL_PASS \
    AZURE_STORAGE_CONNECTION_STRING=$storageConStr \
    WEBSITES_ENABLE_APP_SERVICE_STORAGE=true

echo "Hit $GHOST_WEBAPP_NAME.azurewebsites.net to start site"
curl https://$GHOST_WEBAPP_NAME.azurewebsites.net

echo "Creating webapp $ISSO_WEBAPP_NAME"
az webapp create -g $RG -n $ISSO_WEBAPP_NAME -p $PLAN_NAME \
    --multicontainer-config-type "compose" \
    --multicontainer-config-file "../isso/isso-nginx.yml"

echo "Setting registry for $ISSO_WEBAPP_NAME"
az webapp config container set -g $RG -n $ISSO_WEBAPP_NAME \
    --docker-registry-server-url "https://$ACR_NAME.azurecr.io" \
    --docker-registry-server-user $ACR_NAME \
    --docker-registry-server-password $acrPassword \
    --multicontainer-config-type "compose" \
    --multicontainer-config-file "../isso/isso-nginx.yml"

echo "Enabling docker container logging"
az webapp log config -g $RG -n $ISSO_WEBAPP_NAME \
    --application-logging true \
    --detailed-error-messages true \
    --web-server-logging filesystem \
    --docker-container-logging filesystem \
    --level information

echo "Set custom DNS $ISSO_CDN for $ISSO_WEBAPP_NAME"
az webapp config hostname add --webapp-name $ISSO_WEBAPP_NAME -g $RG --hostname $ISSO_CDN

echo "Setting isso and nginx env settings"
az webapp config appsettings set -g $RG -n $ISSO_WEBAPP_NAME --settings \
    CDN=$ISSO_CDN \
    WWW=$ISSO_WWW \
    EMAIL=$EMAIL \
    STAGING=$STAGING \
    AZ_CLIENT_ID=$AZ_CLIENT_ID \
    AZ_CLIENT_KEY=$AZ_CLIENT_KEY \
    AZ_TENANT_ID=$AZ_TENANT_ID \
    PFX_PASSWORD=$PFX_PASSWORD \
    WEB_APP_NAME=$ISSO_WEBAPP_NAME \
    RESOURCE_GROUP=$RG \
    MYSQL_HOST=$MYSQL_SERVER_NAME.mysql.database.azure.com \
    MYSQL_DB=comments \
    MYSQL_USERNAME=$MYSQL_ADMIN@$MYSQL_SERVER_NAME \
    MYSQL_PASSWORD=$MYSQL_PASS \
    WEBSITES_ENABLE_APP_SERVICE_STORAGE=true

echo "Hit $ISSO_WEBAPP_NAME.azurewebsites.net to start site"
curl http://$ISSO_WEBAPP_NAME.azurewebsites.net/js/embed.min.js