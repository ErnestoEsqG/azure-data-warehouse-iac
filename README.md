# End-to-End Enterprise Data Pipeline & Analytics on Azure

Automated, cloud-native ELT pipeline and dimensional warehouse built on Microsoft Azure, featuring Infrastructure as Code (IaC), raw landing ingestion, T-SQL staging/transformations, a Star Schema semantic layer, and Power BI reporting versioned via PBIP.

---

## 🏛️ Architecture Overview

The pipeline processes transactional retail data (`AdventureWorksLT`) through five decoupled stages:

1. **Infrastructure as Code (IaC):** Automated provisioning of Azure Resource Groups, Azure SQL Server, and Azure Blob Storage via ARM Templates and Bash orchestration (`deploy.sh` / `destroy.sh`).
2. **Raw Data Ingestion (Landing):** Direct operational extraction and ingestion to Azure Blob Storage containers using AzCopy / Azure CLI.
3. **ELT & Data Quality:** Batch staging using T-SQL `BULK INSERT` with `MERGE` statements for idempotent upserts.
4. **Dimensional Modeling (Star Schema):** Creation of a decoupled analytical layer under the `dw` schema:
   - `dw.FactSales`: Transactional line-item metrics.
   - `dw.DimCustomer`, `dw.DimProduct`: Conformed dimension views abstracting OLTP normalization.
   - `dw.DimDate`: Programmatically generated calendar dimension (2005–2030) supporting Time Intelligence DAX.
5. **Business Intelligence Layer:** Executive semantic model and dashboard built in Power BI Desktop, version-controlled using Git-friendly `.pbip` metadata format.

---

## 🛠️ Tech Stack & Tooling

- **Cloud Platform:** Microsoft Azure (SQL Database, Blob Storage, Resource Groups)
- **IaC & Automation:** Bash, Azure CLI, ARM Templates (`azuredeploy.json`)
- **Data Warehousing & Querying:** T-SQL, DBeaver, Star Schema Modeling
- **Analytics & Semantic Layer:** Power BI Desktop, DAX, PBIP format

---

## 📂 Repository Layout

```text
├── iac/
│   ├── azuredeploy.json         # ARM template for SQL & Storage
│   └── deploy.sh / destroy.sh   # Automated provisioning scripts
├── sql/
│   ├── staging/                 # Bulk load and operational ETL scripts
│   └── dw/
│       └── 01_create_star_schema.sql # Dimensional model views & DimDate table
├── reports/
│   └── AdventureWorks_Analytics.pbip # Power BI Project files (JSON/TMDL format)
├── docs/
│   └── architecture_diagram.png # Architecture and data flow diagram
└── README.md

---

### 2. Cómo Redesplegar en Otro Entorno

Cuando quieras volver a levantarlo desde cero (o si un entrevistador te pide una demostración):

1. **Despliegue de Infra:** Ejecutas `./iac/deploy.sh`. Esto creará el nuevo Resource Group con un nuevo sufijo (ej. `rg-adv-1234`) y generará su `parameters.local.json`.
2. **Esquema DW:** Te conectas al nuevo endpoint con DBeaver y corres `sql/dw/01_create_star_schema.sql`.
3. **Power BI:** 
   - Abres `AdventureWorks_Analytics.pbip`.
   - Si el sufijo del servidor cambió: vas a **Transform Data** $\rightarrow$ **Data source settings**, seleccionas **Change Source** y actualizas el nombre del servidor al nuevo FQDN.
   - Presionas **Refresh** y el reporte se repoblará automáticamente.

---

### 3. Cómo Ponerlo en tu CV (Bullet Points de Alto Impacto)

Usa la fórmula de acción + contexto + resultado cuantificable:

* **Cloud Data Pipeline & Analytics Platform | Azure, T-SQL, Bash, Power BI**
  * Engineered an end-to-end automated ELT data pipeline on Microsoft Azure, provisioning isolated SQL Database and Blob Storage environments via ARM templates and Bash scripts.
  * Architected a conformed Star Schema under a dedicated `dw` schema, optimizing OLTP operational tables into analytical dimensions and facts via custom views and an engineered calendar dimension.
  * Authored optimized DAX measures and deployed an executive dashboard versioned in Git via the modular `.pbip` format, tracking gross margins and customer profitability.

---

### 4. Cómo Defenderlo en Entrevistas Técnicas (Framework STAR)

Cuando te pregunten *"Háblame de un proyecto de datos desafiante que hayas construido"*:

* **Situation:** Quería construir una solución de ingeniería y análisis de datos de extremo a extremo que fuera 100% reproducible y desacoplada, evitando procesos manuales en consola de nube.
* **Task:** Diseñar la infraestructura como código, orquestar la ingesta y transformación ELT, modelar un Data Warehouse dimensional y construir una capa de visualización analítica versionada en Git.
* **Action:** Automaticé el aprovisionamiento con ARM templates y Bash. Decidí implementar un esquema en estrella (`dw`) usando vistas sobre el motor relacional para evitar redundancia de almacenamiento y creé una dimensión temporal generada algorítmicamente mediante CTEs recursivos. Para la capa de BI, utilicé formato `.pbip` para permitir control de versiones colaborativo y creé una tabla centralizada de medidas DAX para calcular métricas como margen porcentual y costo de ventas.
* **Result:** Logré un pipeline completamente automatizado donde un solo comando despliega infraestructura, carga datos y alimenta un modelo analítico listo para responder preguntas de rentabilidad de negocio en minutos.