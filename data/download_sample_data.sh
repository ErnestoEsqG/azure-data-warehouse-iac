#!/bin/bash
set -e

DATA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DATA_DIR"

echo "📥 Descargando AdventureWorksLT BACPAC oficial de Microsoft..."
curl -L -o AdventureWorksLT.bacpac \
  "https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorksLT2022.bacpac"

echo "📄 Generando dataset incremental (ventas_nuevas.csv)..."
cat << 'EOF' > ventas_nuevas.csv
SalesOrderID,OrderDate,CustomerID,SubTotal,TaxAmt,Freight,TotalDue,Status
71947,2026-08-01,29500,1250.00,100.00,31.25,1381.25,5
71948,2026-08-02,29501,450.50,36.04,11.26,497.80,5
71949,2026-08-03,29502,3200.00,256.00,80.00,3536.00,5
71950,2026-08-04,29503,890.99,71.28,22.27,984.54,5
71951,2026-08-05,29504,2150.00,172.00,53.75,2375.75,5
EOF

echo "✅ Descarga y archivos de prueba completados exitosamente."