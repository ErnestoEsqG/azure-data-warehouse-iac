#!/bin/bash
RESOURCE_GROUP="rg-adventureworks-dev"

echo "⚠️ Eliminando todos los recursos en $RESOURCE_GROUP..."
az group delete --name "$RESOURCE_GROUP" --yes --no-wait
echo "🧹 Proceso de eliminación iniciado en segundo plano."