#!/bin/bash

# variables
rg="cac-ghost"
sku="S1"
region="westus2"
planName="cacghostplan"
webAppName="cacghost"
slotName="test"
saName="cacghoststore"
fileShareName="cacfileshare"
acrName="cacregistry"

echo "Creating resource group $rg in region $region"
az group create -n $rg -l $region

echo "Create container registry"
az acr create -g $rg -n $acrName --sku Basic --admin-enabled true

echo "Create storage account $saName"
az storage account create -n $saName -g $rg -l $region --kind StorageV2 --sku Standard_LRS

echo "Create Azure File storage container $fileShareName"
az storage share create -n $fileShareName --account-name $saName

echo "Creating app service plan $plan with sku $sku"
az appservice plan create -g $rg -n $planName --sku $sku --is-linux

# create an initial web app with just ghost - we'll add isso after the volume mount is created
echo "Creating webapp $webAppName"
az webapp create -g $rg -n $webAppName -p $planName \
    --multicontainer-config-type "compose" \
    --multicontainer-config-file "ghost-isso-init.yml"

acrPassword=$(az acr credential show -g $rg -n $acrName --query "[passwords[?name=='password'].value]" --output tsv)
az webapp config container set -g $rg -n $webAppName \
    --docker-registry-server-url "http://$acrName.azurecr.io" --docker-registry-server-user $acrName --docker-registry-server-password $acrPassword

echo "Enabling docker container logging"
az webapp log config -g $rg -n $webAppName --docker-container-logging filesystem

echo "Creating slot $slotName"
az webapp deployment slot create -g $rg -n $webAppName -s $slotName

echo "Creating file share for Azure Web App Linux instance"
key=$(az storage account keys list -g $rg -n $saName --query [0].value -o tsv)
az webapp config storage-account add -g $rg -n $webAppName --account-name $saName \
    --custom-id isso-db --storage-type AzureFiles --access-key $key \
    --share-name $fileShareName --mount-path "/isso/db"

# container images for dev
# az acr login -n cacregistry
# cd docker/ghost
# docker build . -t cacregistry.azureacr.io/ghost:dev
# docker push cacregistry.azureacr.io/ghost:dev
# cd ../docker/ghost
# docker build . -t cacregistry.azureacr.io/isso:dev
# cd ../
# docker push cacregistry.azureacr.io/isso:dev

echo "Pushing web app app definition"
az webapp config container set -g $rg -n $webAppName \
    --docker-registry-server-url "http://$acrName.azurecr.io" --docker-registry-server-user $acrName --docker-registry-server-password $acrPassword \
    --multicontainer-config-type "compose" \
    --multicontainer-config-file "ghost-isso.yml"