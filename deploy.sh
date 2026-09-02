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
echo "🚀 INICIANDO DESPLIEGUE COMPLETO EN AZURE"
echo "Grupo de recursos: $RESOURCE_GROUP"
echo "Región: $LOCATION"
echo "=========================================="

# Validar que el archivo BACPAC exista y supere los 100 KB
if [ ! -f "$BACPAC_PATH" ] || [ $(stat -c%s "$BACPAC_PATH") -lt 100000 ]; then
    echo "❌ Error: ./data/AdventureWorksLT.bacpac no existe o pesa menos de 100KB."
    echo "Ejecuta primero: ./data/download_sample_data.sh"
    exit 1
fi

# 1. Crear Resource Group
echo "📦 1. Creando Resource Group..."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output table

# 2. Crear Storage Account y subir BACPAC
echo "🪣 2. Creando Storage Account: $ST_BACPAC_NAME..."
az storage account create \
  --name "$ST_BACPAC_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  -o none

ST_KEY=$(az storage account keys list --resource-group "$RESOURCE_GROUP" --account-name "$ST_BACPAC_NAME" --query "[0].value" -o tsv)

echo "📤 Subiendo $BACPAC_PATH a Blob Storage..."
az storage container create --name "$CONTAINER_BACPAC" --account-name "$ST_BACPAC_NAME" --account-key "$ST_KEY" -o none
az storage blob upload \
  --account-name "$ST_BACPAC_NAME" \
  --account-key "$ST_KEY" \
  --container-name "$CONTAINER_BACPAC" \
  --name "AdventureWorksLT.bacpac" \
  --file "$BACPAC_PATH" \
  --overwrite \
  --output table

# 3. Desplegar Infraestructura con ARM Template
echo "⚙️ 3. Desplegando ARM Template (SQL, Synapse y restauración de BD)..."
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
  --output table

# Obtener Subscription ID activo
SUB_ID=$(az account show --query id -o tsv)

# 4. Habilitar IP local en Firewall (vía API REST con api-version estable)
MY_IP=$(curl -s https://api.ipify.org)
echo "🛡️ 4. Agregando IP local ($MY_IP) al Firewall de Azure SQL..."
az rest --method put \
  --url "https://management.azure.com/subscriptions/${SUB_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Sql/servers/${SQL_SERVER_NAME}/firewallRules/ClientIPRule?api-version=2021-11-01-preview" \
  --body "{\"properties\":{\"startIpAddress\":\"${MY_IP}\",\"endIpAddress\":\"${MY_IP}\"}}" \
  -o none

# 5. Pausar Synapse Dedicated SQL Pool (vía API REST para evitar cobros)
echo "⏸️ 5. Pausando el SQL Pool de Synapse..."
az rest --method post \
  --url "https://management.azure.com/subscriptions/${SUB_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Synapse/workspaces/${SYNAPSE_WS_NAME}/sqlPools/AdventurePool/pause?api-version=2021-06-01-preview" \
  -o none

# 6. Guardar credenciales de conexión locales
echo "💾 6. Generando archivo de parámetros locales..."
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
echo "✅ DESPLIEGUE COMPLETADO Y VALIDADO"
echo "Servidor SQL: ${SQL_SERVER_NAME}.database.windows.net"
echo "Base de Datos: AdventureWorksLT"
echo "Pool de Synapse: Pausado"
echo "Credenciales: ./iac/parameters.local.json"
echo "=========================================="