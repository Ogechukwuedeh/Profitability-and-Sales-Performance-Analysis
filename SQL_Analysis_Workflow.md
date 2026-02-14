# SQL Analysis Workflow — Global Superstore
## Purpose of This Stage
SQL was used as the core data transformation layer for the Global Superstore analysis.

This stage focused on:
- building the database structure
- importing raw data
- cleaning import issues
- profiling business data
- generating analytical datasets
- answering key business questions

This ensured that Power BI worked with structured, validated, and analysis-ready data.

Database Setup
A dedicated database environment was created for the project.
```
CREATE DATABASE global_superstore;
USE global_superstore;
```
This separated the analytics environment from other datasets and ensured controlled data handling.

## Table Creation
Three main business tables were created:

## Orders Table
Contains transactional sales data.
```
CREATE TABLE orders (
Row_ID INT,
Order_ID VARCHAR(100),
Order_Date DATE,
Ship_Date DATE,
Ship_Mode VARCHAR(100),
Customer_ID VARCHAR(100),
Customer_Name VARCHAR(100),
Segment VARCHAR(100),
City VARCHAR(100) CHARACTER SET utf8mb4,
State VARCHAR(100) CHARACTER SET utf8mb4,
Country VARCHAR(100) CHARACTER SET utf8mb4,
Market VARCHAR(100),
Region VARCHAR(100),
Product_ID VARCHAR(100),
Category VARCHAR(100),
Sub_Category VARCHAR(100),
Product_Name LONGTEXT CHARACTER SET utf8mb4,
Sales DOUBLE,
Quantity INT,
Discount DOUBLE, 
Profit DOUBLE,
Shipping_Cost DOUBLE,
Order_Priority VARCHAR(100)
);
```

## Returns Table
Tracks returned orders.
```
CREATE TABLE returns(
Returned VARCHAR(10),
Order_ID VARCHAR(30),
Market VARCHAR(50)
) CHARACTER SET utf8mb4;
```

## People Table
Maps regional responsibility.
```
CREATE TABLE people(
Person VARCHAR(200),
Region VARCHAR(100),
PRIMARY KEY(Region)
);
```

## Data Import & Cleaning
During CSV import, incomplete records and encoding issues were discovered.

The following steps were taken for proper cleaning:
- Checked import warnings
- Recreated the orders table
- Applied utf8mb4 encoding to special-character columns
- Identified import directory using secure_file_priv
- Reloaded datasets
```
SHOW WARNINGS;
SHOW VARIABLES LIKE 'secure_file_priv';
```

## Importing Orders Data
```
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Orders(1).csv'
INTO TABLE orders
CHARACTER SET latin1
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;
```
## Importing Returns Data
```
LOAD DATA INFILE
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Returns.csv'
INTO TABLE returns
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;
```

## Data Validation
Ensured completeness and consistency.
```
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM returns;
SELECT COUNT(*) FROM people;
```

Date range validation:
```
SELECT 
MIN(Order_Date) AS Min_date,
MAX(Order_Date) AS Max_date
FROM orders;
```

Unique order check:
```
SELECT COUNT(DISTINCT Order_ID) FROM orders;
```

## Data Profiling
Understanding business structure before analysis.
```
SELECT DISTINCT(Region) FROM orders;
SELECT DISTINCT(Category) FROM orders;
SELECT DISTINCT(Segment) FROM orders;
```
This step reveals:
- where revenue originates
- product structure
- customer segmentation

## Business Analysis Queries
1. Overall Business Performance
```
SELECT 
ROUND(SUM(Sales), 2) AS Total_sales,
ROUND(SUM(Profit), 2) AS Total_profit,
ROUND((SUM(Profit) / SUM(Sales)) * 100, 2) AS Profit_margin_percent
FROM orders;
```
Insight focus:
- revenue strength
- profitability
- operational efficiency

2. Market Performance
```
SELECT 
Market,
ROUND(SUM(Sales), 2) AS Total_sales,
ROUND(SUM(Profit), 2) AS Total_profit,
ROUND((SUM(Profit) / SUM(Profit)) * 100, 2) AS Profit_margin
FROM orders
GROUP BY Market
ORDER BY Total_profit DESC;
```
Purpose:
- identify strongest and weakest markets
- prioritize investments

3. Product Profitability
```
SELECT 
Category,
Sub_Category,
ROUND(SUM(Sales), 2) AS Total_sales,
ROUND(SUM(Profit), 2) AS Total_Profit,
ROUND((SUM(Profit) / SUM(Sales)) * 100, 2) AS Profit_margin
FROM orders
GROUP BY Category, Sub_Category
ORDER BY Total_profit DESC;
```
Purpose:
- detect loss-making product lines
- inform product strategy

4. Discount Impact Analysis
Created discount bands to measure profitability effects.
```
ALTER TABLE orders
ADD COLUMN Discount_band VARCHAR(20);
```

Classification:
```
UPDATE orders
SET Discount_band = CASE
WHEN Discount = 0 THEN 'No discount'
WHEN Discount <= 0.2 THEN 'Low'
WHEN Discount <= 0.5 THEN 'Medium'
ELSE 'High'
END;
```

Analysis:
```
SELECT
Discount_band,
COUNT(*) AS Order_count,
ROUND(SUM(Sales), 2) AS Total_sales,
ROUND(SUM(Profit), 2) AS Total_profit,
ROUND((SUM(Profit) / SUM(Sales)) * 100, 2) AS Profit_margin
FROM orders
GROUP BY Discount_band
ORDER BY Profit_margin DESC;
```
5. Returns vs Profitability
```
SELECT
CASE
WHEN r.Returned = 'Yes' THEN 'Returned'
ELSE 'Not Returned'
END AS Return_status,
COUNT(*) AS Orders,
ROUND(SUM(o.Sales), 2) AS Total_sales,
ROUND(SUM(o.Profit), 2) AS Total_Profit
FROM orders o
LEFT JOIN returns r
ON o.Order_ID = r.Order_ID
GROUP BY Return_status;
```

Purpose:
- measure operational losses from returns

6. Shipping Mode Efficiency
```
SELECT 
Ship_Mode,
COUNT(*) AS Orders,
ROUND(SUM(Sales), 2) AS Total_sales,
ROUND(SUM(Profit), 2) AS Total_profit,
ROUND((SUM(Profit) / SUM(Sales)) * 100, 2) AS Profit_margin
FROM orders
GROUP BY Ship_Mode
ORDER BY Profit_Margin DESC;
```

7. Customer Segment Analysis
```
SELECT
Segment,
COUNT(DISTINCT Customer_ID) AS Customers,
ROUND(SUM(Sales), 2) AS Total_sales,
ROUND(SUM(Profit), 2) AS Total_profit,
ROUND((SUM(Profit) / SUM(Sales)) * 100, 2) AS Profit_margin
FROM orders
GROUP BY Segment
ORDER BY Profit_margin DESC;
```

8. Time Trend Analysis
```
SELECT
YEAR(Order_Date) AS Order_year,
MONTH(Order_Date) AS Order_month,
ROUND(SUM(Sales), 2) AS Total_sales,
ROUND(SUM(Profit), 2) AS Total_profit
FROM orders
GROUP BY YEAR(Order_Date), MONTH(Order_Date)
ORDER BY Order_year, Order_month;
```

9. Top and Bottom Products
Top performers:
```
SELECT 
Product_Name,
ROUND(SUM(Profit), 2) AS Total_profit
FROM orders
GROUP BY Product_Name
ORDER BY Total_profit DESC
LIMIT 10;
```

Loss-makers:
```
SELECT
Product_Name,
ROUND(SUM(Profit), 2) AS Total_profit
FROM orders
GROUP BY Product_Name
ORDER BY Total_profit ASC
LIMIT 10;
```

## Why This SQL Stage Matters
This phase demonstrates:
- database design capability
- data cleaning and validation skills
- business-first analytics thinking
- structured transformation workflow

It confirms that the dashboard was not built on raw data, but on:
- validated datasets
- engineered analytical features
- decision-ready queries

SQL served as the foundation for reliable and accurate analysis.

## Transition to Power BI
After SQL transformation:
- curated datasets were imported into Power BI
- relationships were validated
- DAX measures were created for KPIs
- interactive visuals were developed
- executive insights were generated

SQL acted as the backbone of the analytics pipeline, ensuring that all dashboard insights were built on clean, structured, and analysis-ready data.
