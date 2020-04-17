#!/bin/bash

# variables
rg="cac-ghost"
sku="B2"
region="westus2"
planName="cacghostplan"
webAppName="cacghost"
ghostDbShareName="cacghostdb"
issoAppName="cacisso"
slotName="test"
saName="cacghoststore"
issoDbShareName="cacissodb"
issoConfigShareName="cacissoconfig"
acrName="cacregistry"
ghostUrl="https://$webAppName.azurewebsites.net"
mySQLServerName="cacmysql"
mySQLAdmin="admin_cac"
mySQLPass="SomeL0ngP@ssw0rd"
mySQLSku="B_Gen5_1"

# for fish
# set rg "cac-ghost"
# set sku "S1"
# set region "westus2"
# set planName "cacghostplan"
# set webAppName "cacghost"
# set issoAppName "cacisso"
# set slotName "test"
# set saName "cacghoststore"
# set issoDbShareName "cacissodb"
# set issoConfigShareName "cacissoconfig"
# set acrName "cacregistry"
# set ghostUrl "https://$webAppName.azurewebsites.net"
# set ghostUrl "https://$webAppName.azurewebsites.net"
# set mySQLServerName "cacmysql"
# set mySQLAdmin "admin_cac"
# set mySQLPass "SomeL0ngP@ssw0rd"
# set mySQLSku "B_Gen5_1"

echo "Creating resource group $rg in region $region"
az group create -n $rg -l $region

echo "Create container registry"
az acr create -g $rg -n $acrName --sku Basic --admin-enabled true

echo "Create storage account $saName"
az storage account create -n $saName -g $rg -l $region --kind StorageV2 --sku Standard_LRS

echo "Creating MYSQL server $mySQLServerName"
az mysql server create -g $rg -n $mySQLServerName \
    --admin-user $mySQLAdmin \
    --admin-password $mySQLPass --sku-name $mySQLSku \
    --ssl-enforcement Disabled \
    --location $region

echo "Configure firewall for Azure services"
az mysql server firewall-rule create --resource-group $rg --server $mySQLServerName \
        --name AllowAzureIP \
        --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0

echo "Creating Ghost Database"
az mysql db create -g $rg -s $mySQLServerName -n ghost

echo "Creating app service plan $planName with sku $sku"
az appservice plan create -g $rg -n $planName --sku $sku --is-linux

echo "Creating webapp $webAppName with nginx image"
az webapp create -g $rg -n $webAppName -p $planName -i "$acrName.azurecr.io/ghost:prod"

echo "Setting url env setting"
az webapp config appsettings set -g $rg -n $webAppName --settings \
    url=$ghostUrl \
    database__client=mysql \
    database__connection__database=ghost \
    database__connection__host=$mySQLServerName.mysql.database.azure.com \
    database__connection__user=$mySQLAdmin@$mySQLServerName \
    database__connection__password=$mySQLPass \
    WEBSITES_ENABLE_APP_SERVICE_STORAGE=true

echo "Enabling docker container logging"
az webapp log config -g $rg -n $webAppName \
    --application-logging true \
    --detailed-error-messages true \
    --web-server-logging filesystem \
    --docker-container-logging filesystem \
    --level information

echo "Update settings to re-init container"
az webapp config container set -g $rg -n $webAppName -i "$acrName.azurecr.io/ghost:prod"

echo "Creating slot $slotName"
az webapp deployment slot create -g $rg -n $webAppName -s $slotName

echo "Creating webapp $issoAppName"
acrPassword=$(az acr credential show -g $rg -n $acrName --query "[passwords[?name=='password'].value]" --output tsv)
az webapp create -g $rg -n $issoAppName -p $planName \
    --multicontainer-config-type "compose" \
    --multicontainer-config-file "../isso/isso-nginx.yml"

echo "Configure persistent storage"
az webapp config appsettings set -g $rg -n $issoAppName --settings WEBSITES_ENABLE_APP_SERVICE_STORAGE=TRUE

echo "Setting registry for $issoAppName"
az webapp config container set -g $rg -n $issoAppName \
    --docker-registry-server-url "http://$acrName.azurecr.io" \
    --docker-registry-server-user $acrName \
    --docker-registry-server-password $acrPassword \
    --multicontainer-config-type "compose" \
    --multicontainer-config-file "../isso/isso-nginx.yml"

echo "Enabling docker container logging"
az webapp log config -g $rg -n $issoAppName \
    --application-logging true \
    --detailed-error-messages true \
    --web-server-logging filesystem \
    --docker-container-logging filesystem \
    --level information