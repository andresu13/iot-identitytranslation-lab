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
az group create --name $resourceGroupName --location $location

# Create IoT Hub and IoT Edge identity
az iot hub create --name $iotHubName --resource-group $resourceGroupName --partition-count 2 --sku S1 --location $location
az iot hub device-identity create --hub-name $iotHubName --device-id edgeIdentityLite --edge-enabled --resource-group $resourceGroupName
iotEdgeConnectionString=`az iot hub device-identity connection-string show --device-id edgeIdentityLite --resource-group $resourceGroupName --hub-name $iotHubName --query "connectionString" | tr -d '"'`

# Create IoT Hub Access Policy

az iot hub policy create --name itlpolicy --hub-name $iotHubName --permissions ServiceConnect RegistryRead RegistryWrite --resource-group $resourceGroupName
iotHubAccessPolicy=`az iot hub connection-string show --hub-name $iotHubName --policy-name itlpolicy --key primary --resource-group $resourceGroupName --query "connectionString" | tr -d '"'`

#Create Storage Account and container
az storage account create --name $stgName --resource-group $resourceGroupName --location $location
stgConnectionString=`az storage account show-connection-string --name $stgName --resource-group $resourceGroupName --query "connectionString" | tr -d '"'`
az storage container create --account-name $stgName --connection-string $stgConnectionString --resource-group $resourceGroupName --name whitelist

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

vmip=`az vm show -d -g $resourceGroupName -n $vmName --query publicIps -o tsv`

# Print information about resources created
echo "Resource Group: "$resourceGroupName
echo "IoT Hub Name: "$iotHubName
echo "Storage Account Name: "$stgName
echo "Storage Account Connection String: "$stgConnectionString
echo "IoT Hub Access Policy Connection String: "$iotHubAccessPolicy
echo "IoT Edge VM Public IP: "$vmip

#echo "IoT Edge Connection String: "$iotEdgeConnectionString