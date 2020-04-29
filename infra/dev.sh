#!/bin/bash

# variables
RG="cac-ghost"
MYSQL_SERVER_NAME="cacmysql"
MYSQL_ADMIN="admin_cac"
MYSQL_PASS=$1

echo "Getting IP and adding firewall rule for MYSQL Server"
myIP=$(dig +short myip.opendns.com @resolver1.opendns.com)
az mysql server firewall-rule create --resource-group $RG --server $MYSQL_SERVER_NAME \
        --name AllowClient \
        --start-ip-address $myIP --end-ip-address $myIP

echo "Running backup job"
p=$(pwd)
rm -f $p/backup/ghost.sql
touch $p/backup/ghost.sql
docker run \
    --entrypoint "" \
    --rm \
    -v $p/backup:/backup \
    schnitzler/mysqldump \
    mysqldump \
        --opt --host=$MYSQL_SERVER_NAME.mysql.database.azure.com \
        -u $MYSQL_ADMIN -p$MYSQL_PASS \
        "--result-file=/backup/ghost.sql" ghost

echo "Start up MYSQL container"
# 5.7.29
mysqlLocalPass="foo"
mysqlUser="xghost"
docker run -d --name mysql \
    -p 3306:3306 \
    -e MYSQL_ROOT_PASSWORD="foo" \
    -e MYSQL_USER=$mysqlUser \
    -e MYSQL_PASSWORD=$mysqlLocalPass \
    -e MYSQL_DATABASE="ghost" \
    mysql:latest \
    --default-authentication-plugin=mysql_native_password
    
sleep 30s

echo "Restore db"
docker exec -i mysql sh -c "exec mysql -u$mysqlUser -p$mysqlLocalPass ghost" < ./backup/ghost.sql
rm -rf ./backup/ghost.sql

echo "Start up ghost"
key=$(az monitor app-insights component show -g $RG --query '[0].appId' -o tsv)
docker run -d --name ghost \
    -p 3001:2368 \
    -e url=http://192.168.1.13:3001 \
    -e database__client="mysql" \
    -e database__connection__database="ghost" \
    -e database__connection__host="192.168.1.13" \
    -e database__connection__password="$mysqlLocalPass" \
    -e database__connection__user="$mysqlUser" \
    -e APP_INSIGHTS_KEY="$key" \
    -v $(pwd)/casper-colin:/casper-colin:/var/lib/ghost/content/themes/casper-colin \
    cacregistry.azurecr.io/ghost:1.0.9