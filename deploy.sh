#!/bin/bash
set -e

# --- Variables de Configuración ---
UNIQUE_SUFFIX=$((RANDOM % 9000 + 1000))
RESOURCE_GROUP="rg-adv-$UNIQUE_SUFFIX"
LOCATION="westus"

SQL_SERVER_NAME="sql-adv-$UNIQUE_SUFFIX"
SQL_ADMIN_USER="azureadmin"
SQL_ADMIN_PASS="P@ssw0rd$UNIQUE_SUFFIX!"

ST_BACPAC_NAME="stbacpac$UNIQUE_SUFFIX"
ST_DATA_NAME="stdata$UNIQUE_SUFFIX"
ST_SYNAPSE_NAME="stsyn$UNIQUE_SUFFIX"
SYNAPSE_WS_NAME="synadv$UNIQUE_SUFFIX"
CONTAINER_BACPAC="bacpac-store"
BACPAC_PATH="./data/AdventureWorksLT.bacpac"

echo "=========================================="
echo "🚀 INICIANDO DESPLIEGUE EN AZURE"
echo "Grupo de recursos: $RESOURCE_GROUP"
echo "Región: $LOCATION"
echo "=========================================="

# 1. Crear Resource Group
echo "📦 1. Creando Resource Group..."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" -o table

# 2. Crear Storage Account de Staging para el BACPAC
echo "🪣 2. Creando Storage Account: $ST_BACPAC_NAME..."
az storage account create \
  --name "$ST_BACPAC_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  -o table

echo "🔑 Obteniendo credenciales de acceso..."
ST_KEY=$(az storage account keys list --resource-group "$RESOURCE_GROUP" --account-name "$ST_BACPAC_NAME" --query "[0].value" -o tsv)

echo "📤 Subiendo $BACPAC_PATH a Azure Blob Storage..."
az storage container create --name "$CONTAINER_BACPAC" --account-name "$ST_BACPAC_NAME" --account-key "$ST_KEY" -o none
az storage blob upload \
  --account-name "$ST_BACPAC_NAME" \
  --account-key "$ST_KEY" \
  --container-name "$CONTAINER_BACPAC" \
  --name "AdventureWorksLT.bacpac" \
  --file "$BACPAC_PATH" \
  --overwrite \
  -o table

# 3. Desplegar Infraestructura con ARM Template
echo "⚙️ 3. Ejecutando despliegue de ARM Template..."
az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file "./iac/template.json" \
  --parameters \
      sqlServerName="$SQL_SERVER_NAME" \
      sqlAdminLogin="$SQL_ADMIN_USER" \
      sqlAdminPassword="$SQL_ADMIN_PASS" \
      storageAccountDataName="$ST_DATA_NAME" \
      storageAccountSynapseName="$ST_SYNAPSE_NAME" \
      synapseWorkspaceName="$SYNAPSE_WS_NAME" \
      bacpacStorageAccountName="$ST_BACPAC_NAME" \
      bacpacContainerName="$CONTAINER_BACPAC" \
      bacpacFileName="AdventureWorksLT.bacpac" \
  -o table

# 4. Habilitar IP pública local en el Firewall de SQL Server
MY_IP=$(curl -s https://api.ipify.org)
echo "🛡️ 4. Agregando tu IP ($MY_IP) al Firewall de Azure SQL..."
az sql server firewall-rule create \
  --resource-group "$RESOURCE_GROUP" \
  --server "$SQL_SERVER_NAME" \
  --name "ClientIPRule" \
  --start-ip-address "$MY_IP" \
  --end-ip-address "$MY_IP" \
  -o none

# Guardar credenciales generadas en archivo local ignorado
cat << EOF > ./iac/parameters.local.json
{
  "resourceGroup": "$RESOURCE_GROUP",
  "sqlServer": "${SQL_SERVER_NAME}.database.windows.net",
  "sqlDatabase": "AdventureWorksLT",
  "sqlUser": "$SQL_ADMIN_USER",
  "sqlPassword": "$SQL_ADMIN_PASS",
  "dataStorageAccount": "$ST_DATA_NAME",
  "synapseWorkspace": "$SYNAPSE_WS_NAME"
}
EOF

echo "=========================================="
echo "✅ DESPLIEGUE COMPLETADO CON ÉXITO"
echo "Servidor SQL: ${SQL_SERVER_NAME}.database.windows.net"
echo "Base de Datos: AdventureWorksLT"
echo "Credenciales guardadas en: ./iac/parameters.local.json"
echo "=========================================="