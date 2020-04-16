#!/bin/bash

# variables
rg="cac-ghost"
sku="S1"
region="westus2"
planName="cacghostplan"
webAppName="cacghost"
issoAppName="cacisso"
slotName="test"
saName="cacghoststore"
issoDbShareName="cacissodb"
issoConfigShareName="cacissoconfig"
acrName="cacregistry"

echo "Creating resource group $rg in region $region"
az group create -n $rg -l $region

echo "Create container registry"
az acr create -g $rg -n $acrName --sku Basic --admin-enabled true

echo "Create storage account $saName"
az storage account create -n $saName -g $rg -l $region --kind StorageV2 --sku Standard_LRS

echo "Create Azure File storage containers"
az storage share create -n $issoDbShareName --account-name $saName
az storage share create -n $issoConfigShareName --account-name $saName

echo "Uploading files to file share"
key=$(az storage account keys list -g $rg -n $saName --query [0].value -o tsv)
#az storage file upload --account-name $saName --account-key $key \ 
#   -s $issoDbShareName --source ../docker/isso/config/empty/comments.db
az storage file upload --account-name $saName --account-key $key \ 
    -s $issoConfigShareName --source ../isso/config/azure/isso.conf

echo "Creating app service plan $plan with sku $sku"
az appservice plan create -g $rg -n $planName --sku $sku --is-linux

echo "Creating webapp $webAppName"
az webapp create -g $rg -n $webAppName -p $planName -i "$acrName.azurecr.io/ghost:dev"

echo "Enabling docker container logging"
az webapp log config -g $rg -n $webAppName --docker-container-logging filesystem

echo "Creating slot $slotName"
az webapp deployment slot create -g $rg -n $webAppName -s $slotName

echo "Creating webapp $issoAppName"
acrPassword=$(az acr credential show -g $rg -n $acrName --query "[passwords[?name=='password'].value]" --output tsv)
az webapp create -g $rg -n $issoAppName -p $planName \
    --multicontainer-config-type "compose" \
    --multicontainer-config-file "../docker/isso/isso-nginx.yml"

echo "Creating file shares for isso"
az webapp config storage-account add -g $rg -n $issoAppName --account-name $saName \
    --custom-id isso-db --storage-type AzureFiles --access-key $key \
    --share-name $issoDbShareName --mount-path "/db"

az webapp config storage-account add -g $rg -n $issoAppName --account-name $saName \
    --custom-id isso-conf --storage-type AzureFiles --access-key $key \
    --share-name $issoConfigShareName --mount-path "/config"

echo "Setting registry for $issoAppName"
az webapp config container set -g $rg -n $issoAppName \
    --docker-registry-server-url "http://$acrName.azurecr.io" --docker-registry-server-user $acrName --docker-registry-server-password $acrPassword \
    --multicontainer-config-type "compose" \
    --multicontainer-config-file "../docker/isso/isso-nginx.yml"

echo "Enabling docker container logging"



# container images for dev
# az acr login -n cacregistry
# cd docker/ghost
# docker build . -t cacregistry.azureacr.io/ghost:dev
# docker push cacregistry.azureacr.io/ghost:dev
# cd ../docker/ghost
# docker build . -t cacregistry.azureacr.io/isso:dev
# cd ../
# docker push cacregistry.azureacr.io/isso:dev
