#!/bin/bash

PARAM_FILE="./iac/parameters.local.json"

echo "🔍 Buscando Resource Groups del proyecto en Azure..."

# 1. Obtener lista limpia de nombres de todos los RG
ALL_GROUPS=$(az group list --query "[].name" -o tsv)

# 2. Iterar y borrar solo los que contengan 'rg-adv'
FOUND=0
for RG in $ALL_GROUPS; do
  if [[ "$RG" == *"rg-adv"* ]]; then
    FOUND=1
    echo "⚠️ Eliminando en segundo plano: $RG..."
    az group delete --name "$RG" --yes --no-wait
  fi
done

if [ $FOUND -eq 0 ]; then
  echo "ℹ️ No se encontraron Resource Groups activos que coincidan con 'rg-adv'."
else
  echo "🚀 Órdenes de eliminación enviadas a Azure."
fi

# 3. Limpieza del archivo local de parámetros
if [ -f "$PARAM_FILE" ]; then
  rm -f "$PARAM_FILE"
  echo "🧹 Archivo $PARAM_FILE eliminado."
fi

echo "✅ Listo."