#!/bin/bash

# Strict mode, fail on any error
set -euo pipefail

# Azure configuration
FILE=".env"
if [[ -f $FILE ]]; then
	echo "loading from .env" | tee -a log.txt
    export $(egrep . $FILE | xargs -n1)
else
	cat << EOF > .env
HOST="https://www.anhelosalud.com"
TEST_CLIENTS=15
USERS_PER_CLIENT=3000
SPAWN_RATE=400
RESOURCE_GROUP="mrobertson"
AZURE_STORAGE_ACCOUNT="umsloadtest"
EOF
	echo "Enviroment file not detected."
	echo "Please configure values for your environment in the created .env file"
	echo "and run the script again."
	echo "TEST_CLIENTS: Number of locust client to create"
	echo "USERS_PER_CLIENT: Number of users that each locust client will simulate"
	echo "SPAWN_RATE: How many new users will be created per second per locust client"
	echo "HOST: REST Endpoint to test"
	echo "RESOURCE_GROUP: Resource group where Locust will be deployed"
	echo "AZURE_STORAGE_ACCOUNT: Storage account name that will be created to host the locust file"
	exit 1
fi

echo "starting"
cat << EOF > log.txt
EOF

echo "creating storage account: $AZURE_STORAGE_ACCOUNT" | tee -a log.txt
az storage account create -n $AZURE_STORAGE_ACCOUNT -g $RESOURCE_GROUP --sku Standard_LRS \
	-o json >> log.txt	
	
echo "retrieving storage connection string" | tee -a log.txt
AZURE_STORAGE_CONNECTION_STRING=$(az storage account show-connection-string --name $AZURE_STORAGE_ACCOUNT -g $RESOURCE_GROUP -o tsv)

echo 'creating file share' | tee -a log.txt
az storage share create -n locust --connection-string $AZURE_STORAGE_CONNECTION_STRING \
	-o json >> log.txt

echo 'uploading simulator scripts' | tee -a log.txt
az storage file upload-batch --destination locust --source locust/ --connection-string $AZURE_STORAGE_CONNECTION_STRING \
    -o json >> log.txt

echo "deploying locust ($TEST_CLIENTS clients)..." | tee -a log.txt
LOCUST_MONITOR=$(az deployment group create -g $RESOURCE_GROUP \
	--template-file locust-arm-template.json \
	--parameters \
		host=$HOST \
		storageAccountName=$AZURE_STORAGE_ACCOUNT \
		fileShareName=locust \
		numberOfInstances=$TEST_CLIENTS \
	--query properties.outputs.locustMonitor.value \
	-o tsv \
	)
sleep 10

echo "locust: endpoint: $LOCUST_MONITOR" | tee -a log.txt

echo "locust: starting ..." | tee -a log.txt
declare USER_COUNT=$(($USERS_PER_CLIENT*$TEST_CLIENTS))
declare SPAWN_RATE=$(($SPAWN_RATE*$TEST_CLIENTS))
echo "locust: users: $USER_COUNT, spawn rate: $SPAWN_RATE"
curl -fsL $LOCUST_MONITOR/swarm -X POST -F "user_count=$USER_COUNT" -F "spawn_rate=$SPAWN_RATE" >> log.txt

echo "locust: monitor available at: $LOCUST_MONITOR" | tee -a log.txt

echo "done" | tee -a log.txt
