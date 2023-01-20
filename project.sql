
-- Customers: customer data
-- Employees: all employee information
-- Offices: sales office information
-- Orders: customers' sales orders
-- OrderDetails: sales order line for each sales order
-- Payments: customers' payment records
-- Products: a list of scale model cars
-- ProductLines: a list of product line categories

-- 
-- Tables in the database

SELECT
	'Customers' AS table_name,
	13 AS num_of_attributes,   -- Number of columns
	COUNT(*) AS num_of_rows    -- Number of rows
FROM customers
UNION ALL
SELECT
	'Employees' AS table_name,
	8 AS num_of_attributes,   -- Number of columns
	COUNT(*) AS num_of_rows	  -- Number of rows
FROM employees
UNION ALL
SELECT
	'Offices' AS table_name,
	9 AS num_of_attributes,     -- Number of columns
	COUNT(*) AS num_of_rows	    -- Number of rows
FROM offices
UNION ALL
SELECT
	'OrderDetails' AS table_name,
	5 AS num_of_attributes,     -- Number of columns
	COUNT(*) AS num_of_rows		-- Number of rows
FROM orderdetails
UNION ALL
SELECT
	'Orders' AS table_name,
	7 AS num_of_attributes,     -- Number of columns
	COUNT(*) AS num_of_rows		-- Number of rows
FROM orders
UNION ALL
SELECT
	'Payments' AS table_name,
	4 AS num_of_attributes,		-- Number of columns
	COUNT(*) AS num_of_rows		-- Number of rows
FROM payments
UNION ALL
SELECT
	'ProductLines' AS table_name,
	4 AS num_of_attributes,		-- Number of columns
	COUNT(*) AS num_of_rows		-- Number of rows
FROM productlines
UNION ALL
SELECT
	'Products' AS table_name,
	9 AS num_of_attributes,		-- Number of columns
	COUNT(*) AS num_of_rows		-- Number of rows
FROM products;

-- Low Stock
-- The low stock represents the quantity of each product sold divided by the quantity of product in stock. 
-- We can consider the ten lowest rates.
SELECT 
	productCode, 
	ROUND(SUM(od.quantityOrdered) * 1.0 / (p.quantityInStock),2) AS low_stock
FROM orderdetails od
JOIN products p
USING(productCode)
GROUP BY productCode
ORDER BY low_stock
LIMIT 10;   


-- Product Performance
-- Finding products performance 
-- The product performance represents the sum of sales per product.
SELECT
	productCode,
	ROUND(SUM(quantityOrdered * priceEach)) AS product_performance
FROM orderdetails
GROUP BY productCode
ORDER BY product_performance DESC
LIMIT 10;


-- for restocking
-- Priority products for restocking are those with high product performance that are on the brink of being out of stock.


WITH low_stock_table AS(
SELECT
	od.productCode, 
	ROUND(SUM(od.quantityOrdered) * 1.0 / (p.quantityInStock),2) AS low_stock
FROM orderdetails od
JOIN products p
USING(productCode)
GROUP BY productCode
ORDER BY low_stock
LIMIT 10	
)
SELECT	
	od.productCode,
	p.productName,
	p.productLine,
	ROUND(SUM(quantityOrdered * priceEach)) AS product_performance
FROM orderdetails od
JOIN products p
USING(productCode)
WHERE productCode IN (
	SELECT
		productCode
	FROM low_stock_table
	)
GROUP BY productCode
ORDER BY product_performance DESC
LIMIT 10;

-- Profit per customer

SELECT
	customerNumber,
	SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)) AS profit
FROM orders o 
JOIN orderdetails od
	USING(orderNumber)
JOIN products p
	USING(productCode)
GROUP BY customerNumber;


-- VIP 
-- we could organize some events to drive loyalty for the VIPs
-- top 8 or generating > 60000

WITH
temp_table_profit AS (
SELECT
	customerNumber,
	SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)) AS profit
FROM orders o 
JOIN orderdetails od
	USING(orderNumber)
JOIN products p
	USING(productCode)
GROUP BY customerNumber
)
SELECT
	customerName, 
	contactLastName, 
	contactFirstName, 
	city,  
	country, 
	ROUND(tp.profit) AS profit
FROM temp_table_profit tp
JOIN customers c
	USING(customerNumber)
ORDER BY tp.profit DESC
LIMIT 8;

-- Less engage
-- launch a campaign for the less engaged
WITH temp_table_profit AS (
	SELECT
	customerNumber,
	SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)) AS profit
FROM orders o 
JOIN orderdetails od
	USING(orderNumber)
JOIN products p
	USING(productCode)
GROUP BY customerNumber
)
SELECT
	customerName, 
	contactLastName, 
	contactFirstName, 
	city,  
	country, 
	ROUND(tp.profit) AS profit
FROM temp_table_profit tp
JOIN customers c
	USING(customerNumber)
ORDER BY tp.profit
LIMIT 8;



-- New customers arriving per month
-- Number of clients has been decreasing since 2003, and in 2004, it had the lowest values.
-- didn't make this code, already on the exercise.

WITH 

payment_with_year_month_table AS (
SELECT *, 
       CAST(SUBSTR(paymentDate, 1,4) AS INTEGER)*100 + CAST(SUBSTR(paymentDate, 6,2) AS INTEGER) AS year_month
FROM payments p
),

customers_by_month_table AS (
SELECT p1.year_month, COUNT(*) AS number_of_customers, SUM(p1.amount) AS total
FROM payment_with_year_month_table p1
GROUP BY p1.year_month
),

new_customers_by_month_table AS (
SELECT p1.year_month, 
       COUNT(*) AS number_of_new_customers,
       SUM(p1.amount) AS new_customer_total,
       (SELECT number_of_customers
          FROM customers_by_month_table c
        WHERE c.year_month = p1.year_month) AS number_of_customers,
       (SELECT total
          FROM customers_by_month_table c
         WHERE c.year_month = p1.year_month) AS total
FROM payment_with_year_month_table p1
WHERE p1.customerNumber NOT IN (SELECT customerNumber
                                   FROM payment_with_year_month_table p2
                                  WHERE p2.year_month < p1.year_month)
GROUP BY p1.year_month
)

SELECT year_month, 
       ROUND(number_of_new_customers*100/number_of_customers,1) AS number_of_new_customers_props,
       ROUND(new_customer_total*100/total,1) AS new_customers_total_props
FROM new_customers_by_month_table;

-- Customer Lifetime Value (LTV)
-- we can compute the Customer Lifetime Value (LTV), which represents the average amount of money a customer generates.

WITH money_in AS (
	SELECT
	customerNumber,
	SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)) AS profit
FROM orders o 
JOIN orderdetails od
	USING(orderNumber)
JOIN products p
	USING(productCode)
GROUP BY customerNumber
)
SELECT 
	ROUND(AVG(mi.profit),2) AS LTV
FROM
	money_in mi;

	




