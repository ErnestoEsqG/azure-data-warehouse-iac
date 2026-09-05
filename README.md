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

