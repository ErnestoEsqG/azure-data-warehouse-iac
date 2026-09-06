-- =============================================================================
-- Script: 01_create_star_schema.sql
-- Description: Analytical dimensional model (dw schema) for AdventureWorksLT.
-- =============================================================================

-- 1. Decoupled analytical schema
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'dw')
BEGIN
    EXEC('CREATE SCHEMA dw');
END;
GO

-- 2. Customer Dimension
CREATE OR ALTER VIEW dw.DimCustomer AS
SELECT 
    c.CustomerID,
    ISNULL(c.CompanyName, 'Sin Compañía') AS CompanyName,
    TRIM(CONCAT(ISNULL(c.FirstName, ''), ' ', ISNULL(c.MiddleName, ''), ' ', ISNULL(c.LastName, ''))) AS FullName,
    c.EmailAddress,
    c.Phone
FROM SalesLT.Customer c;
GO

-- 3. Product Dimension (denormalized with category and model)
CREATE OR ALTER VIEW dw.DimProduct AS
SELECT 
    p.ProductID,
    p.Name AS ProductName,
    p.ProductNumber,
    p.Color,
    p.StandardCost,
    p.ListPrice,
    p.Size,
    p.Weight,
    ISNULL(pc.Name, 'Sin Categoría') AS ProductCategory,
    ISNULL(pm.Name, 'Sin Modelo') AS ProductModel
FROM SalesLT.Product p
LEFT JOIN SalesLT.ProductCategory pc 
    ON p.ProductCategoryID = pc.ProductCategoryID
LEFT JOIN SalesLT.ProductModel pm 
    ON p.ProductModelID = pm.ProductModelID;
GO

-- 4. Calendar Dimension (Physical table for Time Intelligence)
DROP TABLE IF EXISTS dw.DimDate;
GO

CREATE TABLE dw.DimDate (
    DateKey INT PRIMARY KEY,
    [Date] DATE NOT NULL,
    [Year] INT NOT NULL,
    QuarterNumber INT NOT NULL,
    QuarterName VARCHAR(10) NOT NULL,
    MonthNumber INT NOT NULL,
    MonthName VARCHAR(20) NOT NULL,
    MonthYear VARCHAR(10) NOT NULL,
    DayOfMonth INT NOT NULL,
    DayOfWeekNumber INT NOT NULL,
    DayOfWeekName VARCHAR(20) NOT NULL
);
GO

-- Date generation and insertion (2005 to 2030 to cover historical orders)
WITH DateRange AS (
    SELECT CAST('2005-01-01' AS DATE) AS [Date]
    UNION ALL
    SELECT DATEADD(day, 1, [Date])
    FROM DateRange
    WHERE [Date] < '2030-12-31'
)
INSERT INTO dw.DimDate
SELECT 
    CAST(CONVERT(VARCHAR(8), [Date], 112) AS INT) AS DateKey,
    [Date],
    YEAR([Date]) AS [Year],
    DATEPART(quarter, [Date]) AS QuarterNumber,
    CONCAT('Q', DATEPART(quarter, [Date])) AS QuarterName,
    MONTH([Date]) AS MonthNumber,
    DATENAME(month, [Date]) AS MonthName,
    CONCAT(FORMAT([Date], 'yyyy'), '-', FORMAT([Date], 'MM')) AS MonthYear,
    DAY([Date]) AS DayOfMonth,
    DATEPART(weekday, [Date]) AS DayOfWeekNumber,
    DATENAME(weekday, [Date]) AS DayOfWeekName
FROM DateRange
OPTION (MAXRECURSION 0);
GO

-- 5. Fact Table: Sales
CREATE OR ALTER VIEW dw.FactSales AS
SELECT 
    d.SalesOrderDetailID,
    h.SalesOrderID,
    CAST(CONVERT(VARCHAR(8), h.OrderDate, 112) AS INT) AS OrderDateKey,
    h.OrderDate,
    h.CustomerID,
    d.ProductID,
    d.OrderQty,
    d.UnitPrice,
    d.UnitPriceDiscount,
    d.LineTotal,
    h.Status AS OrderStatus,
    h.SubTotal AS OrderSubTotal,
    h.TaxAmt AS OrderTaxAmt,
    h.Freight AS OrderFreight,
    h.TotalDue AS OrderTotalDue
FROM SalesLT.SalesOrderHeader h
INNER JOIN SalesLT.SalesOrderDetail d 
    ON h.SalesOrderID = d.SalesOrderID;
GO