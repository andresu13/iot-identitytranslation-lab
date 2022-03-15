#!/bin/bash

#Variables

location="eastus"
prefix="iotidlab"
vm_user="azureuser"
vm_password="Passw0rd1234!"

# Generate a unique suffix for service names
let randomNum=$RANDOM*$RANDOM

# Generate service names
resourceGroupName=$prefix"rg"$randomNum
iotHubName=$prefix"hub"$randomNum
stgName=$prefix"stg"$randomNum
vmName=$prefix"vm"$randomNum

# # Create resource group 
az group create --name $resourceGroupName --location eastus

# Create IoT Hub and IoT Edge identity
az iot hub create --name $iotHubName --resource-group $resourceGroupName --partition-count 2 --sku S1
az iot hub device-identity create --hub-name $iotHubName --device-id edgeIdentityLite --edge-enabled
iotEdgeConnectionString=`az iot hub device-identity connection-string show --device-id edgeIdentityLite --hub-name $iotHubName --query "connectionString" | tr -d '"'`

#Create Storage Account and container
az storage account create --name $stgName --resource-group $resourceGroupName
stgConnectionString=`az storage account show-connection-string --name $stgName --query "connectionString" | tr -d '"'`
az storage container create --account-name $stgName --connection-string $stgConnectionString --name whitelist

#Create whitelist file and upload to container
printf "myleafDevice1\nmyleafDevice2\nmyleafDevice3\nclient0\nclient1\nclient3\nclient4\nclient5" > whitelistitm.txt
az storage blob upload --container-name whitelist --name whitelistitm.txt --file "whitelistitm.txt" --connection-string $stgConnectionString

#Create IoT Edge VM
# --template-uri "https://raw.githubusercontent.com/Azure/iotedge-vm-deploy/1.2/edgeDeploy.json" \
az deployment group create \
--resource-group $resourceGroupName \
--template-uri "https://raw.githubusercontent.com/andresu13/iot-identitytranslation-lab/main/deploy/edgeDeploy.json" \
--parameters dnsLabelPrefix=$vmName \
--parameters adminUsername=$vm_user \
--parameters deviceConnectionString=$iotEdgeConnectionString \
--parameters authenticationType="password" \
--parameters adminPasswordOrKey=$vm_password

# Print information about resources created
echo "Resource Group: "$resourceGroupName
echo "IoT Hub Name: "$iotHubName
echo "IoT Edge Connection String: "$iotEdgeConnectionString
echo "Storage Account Connection String: "$stgConnectionString