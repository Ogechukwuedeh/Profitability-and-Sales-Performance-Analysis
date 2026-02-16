DROP DATABASE global_superstore_db;
CREATE DATABASE global_superstore;

USE global_superstore;

DROP TABLE orders;

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


DROP TABLE returns;

CREATE TABLE returns(
Returned VARCHAR(10),
Order_ID VARCHAR(30),
Market VARCHAR(50)
) CHARACTER SET utf8mb4;

DROP TABLE people;

CREATE TABLE people(
Person VARCHAR(200),
Region VARCHAR(100),
PRIMARY KEY(Region)
);

SELECT COUNT(*) FROM people;

# FIXING ORDERS TABLE IMPORT ISSUES 
# 1: Immediately after importing the data, run "show warnings" to find out why the data (orders table) is not importing completely.
# 2: Drop the Orders table and create it again.
# 3: While recreating the table, ensure that CHARACTER SET utf8mb4 is included in the columns that contains the special characters which you discovered after running show warnings.
# 4: Run "show variables" to find out where to save the data to be imported.
# 5: Run "load data infile" to finally import the data.
# 6: Check the end result.

SHOW WARNINGS;

SHOW VARIABLES LIKE 'secure_file_priv';

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Orders(1).csv'
INTO TABLE orders
CHARACTER SET latin1
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

LOAD DATA INFILE
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Returns.csv'
INTO TABLE returns
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

# Data validation

SELECT COUNT(*) FROM orders;
SELECT * FROM orders;

SELECT COUNT(*) FROM returns;
SELECT * FROM returns;

SELECT COUNT(*) FROM people;
SELECT * FROM people;

SELECT 
	MIN(Order_Date) AS Min_date,
	MAX(Order_Date) AS Max_date
FROM orders;

SELECT COUNT(DISTINCT Order_ID) FROM orders;

# Profiling: Understanding business structures to find out what regions, products and segments exist and to know where money comes from and its loss.
SELECT DISTINCT(Region) FROM orders;
SELECT DISTINCT(Category) FROM orders;
SELECT DISTINCT(Segment) FROM orders;

# OVERALL BUSINESS PERFORMANCE
# Question 1 : Is Global Superstore profitable overall and what is the average margin?
# Solution

SELECT 
	ROUND(SUM(Sales), 2) AS Total_sales,       							# Money that came in.
	ROUND(SUM(Profit), 2) AS Total_profit,     							# Money that left.
    ROUND((SUM(Profit) / SUM(Sales)) * 100, 2) AS Profit_margin_percent	# Efficiency of the business.
FROM orders;

# PEFORMANCE BY MARKET
# Question 2: Which markets drive revenue and profit?

SELECT 
	Market,
    ROUND(SUM(Sales), 2) AS Total_sales,
    ROUND(SUM(Profit), 2) AS Total_profit,
    ROUND((SUM(Profit) / SUM(Profit)) * 100, 2) AS Profit_margin
FROM orders
GROUP BY Market
ORDER BY Total_profit DESC;

# PERFORMANCE BY CATEGORY AND SUB-CATEGORY
# Question 3: Which products make or lose money?

SELECT 
	Category,
    Sub_Category,
    ROUND(SUM(Sales), 2) AS Total_sales,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    ROUND((SUM(Profit) / SUM(Sales)) * 100, 2) AS Profit_margin
FROM orders
GROUP BY Category, Sub_Category
ORDER BY Total_profit DESC;

# DISCOUNT IMPACT ANALYSIS
# Question 4: How do discount affect profit and profit margin? Are discounts helping or hurting the business?

# Step 1: Create discount bands
ALTER TABLE orders
ADD COLUMN Discount_band DOUBLE;

# An error occured while adding our values to the discount band column using SET. 
# The error occured becaue we used DOUBLE(meant for decimals) instead of VARCHAR. 
# So, we will modify the table.

ALTER TABLE orders
MODIFY Discount_band VARCHAR(20);

UPDATE orders
SET Discount_band = CASE
	WHEN Discount = 0 THEN 'No discount'
    WHEN Discount <= 0.2 THEN 'Low'
    WHEN Discount <= 0.5 THEN 'Medium'
    ELSE 'High'
END;

# Step 2: Analyze discount effect.
SELECT
	Discount_band,
    COUNT(*) AS Order_count,
    ROUND(SUM(Sales), 2) AS Total_sales,
    ROUND(SUM(Profit), 2) AS Total_profit,
    ROUND((SUM(Profit) / SUM(Sales)) * 100, 2) AS Profit_margin
FROM orders
GROUP BY Discount_band
ORDER BY Profit_margin DESC;

# RETURNS VS PROFITABILITY
# Question 5: Do returns significantly impact profitability?

# Step 1: Join orders plus returns
SELECT 
	o.Order_ID,
    o.Sales,
    o.Profit,
    CASE 
		wHEN r.Returned = 'Yes' THEN 'Returned'
        ELSE 'Not Returned'
	END AS Returned_status
FROM orders o
LEFT JOIN returns r
	ON o.Order_ID = r.Order_ID;

# Step 2: Aggregate impact
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

# SHIPPING MODE EFFICIENCY
# Question 6: Which shipping modes are profitable?

SELECT 
	Ship_Mode,
    COUNT(*) AS Orders,
    ROUND(SUM(Sales), 2) AS Total_sales,
    ROUND(SUM(Profit), 2) AS Total_profit,
    ROUND((SUM(Profit) / SUM(Sales)) * 100, 2) AS Profit_margin
FROM orders
GROUP BY Ship_Mode
ORDER BY Profit_Margin DESC;

# CUSTOMER SEGMENT ANALYSIS

SELECT
	Segment,
    COUNT(DISTINCT Customer_ID) AS Customers,
    ROUND(SUM(Sales), 2) AS Total_sales,
    ROUND(SUM(Profit), 2) AS Total_profit,
    ROUND((SUM(Profit) / SUM(Sales)) * 100, 2) AS Profit_margin
FROM orders
GROUP BY Segment
ORDER BY Profit_margin DESC;

# TIME TREND (SALES AND PROFIT OVER TIME)

SELECT
	YEAR(Order_Date) AS Order_year,
    MONTH(Order_Date) AS Order_month,
    ROUND(SUM(Sales), 2) AS Total_sales,
    ROUND(SUM(Profit), 2) AS Total_profit
FROM orders
GROUP BY YEAR(Order_Date), MONTH(Order_Date)
ORDER BY Order_year, Order_month;

# TOP AND BOTTOM PRODUCTS (DECISION READY)

# Top 10 profitable products
SELECT 
	Product_Name,
    ROUND(SUM(Profit), 2) AS Total_profit
FROM orders
GROUP BY Product_Name
ORDER BY Total_profit DESC
LIMIT 10;

# Bottom 10 loss-making products
SELECT
	Product_Name,
    ROUND(SUM(Profit), 2) AS Total_profit
FROM orders
GROUP BY Product_Name
ORDER BY Total_profit ASC
LIMIT 10;








	


   

