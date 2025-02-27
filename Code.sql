SELECT Count(*) FROM customer; -- Checking if the data has loaded
SELECT * FROM customer LIMIT 5; -- Checking if the data has loaded in desired format

SELECT Count(*) FROM transactions; -- Checking if the data has loaded
SELECT * FROM transactions LIMIT 5; -- Checking if the data has loaded in desired format

-- =====DATA PREPARATION AND UNDERSTANDING=====

# Q1. How many rows does each table have?
SELECT 'CUSTOMER' AS TABLE_NAME, COUNT(*) AS TOTAL_RECORD FROM Customer
UNION ALL
SELECT 'PROD_CATEGORY' AS TABLE_NAME, COUNT(*) AS TOTAL_RECORD FROM PROD_CATEGORY
UNION ALL
SELECT 'TRANSACTIONS' AS TABLE_NAME, COUNT(*) AS TOTAL_RECORD FROM TRANSACTIONS
UNION ALL
SELECT 
	'GRAND TOTAL' AS TABLE_NAME, COUNT(*) + 
  (SELECT COUNT(*) FROM PROD_CATEGORY) + 
  (SELECT COUNT(*) FROM TRANSACTIONS) + 
  (SELECT COUNT(*) FROM Customer) AS TOTAL_RECORD;

-- ------------------------------------------------------

# Q2. What is the total number of transactions that have a return?
SELECT COUNT(*)
FROM TRANSACTIONS
WHERE total_amt > 0;

-- ---------------------------------------------

# There is discrepancy amongst the qty col
#duplicating the transactions table before updating it
CREATE TABLE transactions_backup AS
SELECT *
FROM transactions;

# removing the '-' sign from qty
UPDATE TRANSACTIONS 
SET 
    Qty = ABS(Qty),
    Rate = ABS(Rate),
    total_amt = ABS(total_amt)
WHERE
    Qty < 0 OR Rate < 0 OR total_amt < 0;

-- Verifying if the '-' is removed
SELECT COUNT(*) as 'Quantity<0'
FROM transactions
WHERE Qty < 0;

-- ----------------------------------------

# Checking the DataType
DESCRIBE customer;

# Converting DOB to DATE data type using STR_to_DATE
UPDATE CUSTOMER
SET DOB = STR_to_DATE(DOB, '%Y-%m-%d')
WHERE DOB IS NOT NULL;

-- Using alter to modify the data type
ALTER TABLE customer
MODIFY COLUMN DOB DATE;

-- ----------------------------------------------------
# Checking the DataType
DESCRIBE transactions;

-- Making the data of tran_date col uniform
UPDATE Transactions
SET tran_date = REPLACE(tran_date, '/', '-')
WHERE tran_date LIKE '%/%';

# Converting DOB to DATE data type using STR_to_DATE
UPDATE Transactions
SET tran_date = STR_TO_DATE(tran_date, '%d-%m-%Y')
WHERE tran_date IS NOT NULL;

ALTER TABLE Transactions
MODIFY COLUMN tran_date DATE;

-- -------------------------------------------------------------------------------------

# Q3. What is the time range of the transaction data available for analysis? 
# Show the output in number of days, months and years simultaneously in different columns.

SELECT
    MIN(STR_TO_DATE(tran_date, '%d-%m-%Y')) AS BEGIN_TRANSACTION_DATE,
    MAX(STR_TO_DATE(tran_date, '%d-%m-%Y')) AS END_TRANSACTION_DATE,
    DATEDIFF(MAX(STR_TO_DATE(tran_date, '%d-%m-%Y')), MIN(STR_TO_DATE(tran_date, '%d-%m-%Y'))) AS NUMBER_OF_DAYS,
    PERIOD_DIFF(DATE_FORMAT(MAX(STR_TO_DATE(tran_date, '%d-%m-%Y')), '%Y%m'), 
			DATE_FORMAT(MIN(STR_TO_DATE(tran_date, '%d-%m-%Y')), '%Y%m')) AS NUMBER_OF_MONTHS,
    TIMESTAMPDIFF(YEAR, MIN(STR_TO_DATE(tran_date, '%d-%m-%Y')), MAX(STR_TO_DATE(tran_date, '%d-%m-%Y'))) AS NUMBER_OF_YEAR
FROM TRANSACTIONS;

-- Q4. Which product category does the sub-category “DIY” belong to? 
SELECT prod_cat
from prod_category
where prod_subcat = 'DIY';

-- xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx -- xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx --

-- Addressing the KEY QUESTIONS to deliver to client

-- Q1. Which channel is most frequently used for transactions?

SELECT CHANNELS, TOTAL_TRANSACTIONS, RANKING
FROM (
    SELECT
        STORE_TYPE AS CHANNELS,
        COUNT(STORE_TYPE) AS TOTAL_TRANSACTIONS,
        DENSE_RANK() OVER (ORDER BY COUNT(STORE_TYPE) DESC) AS RANKING
    FROM
        TRANSACTIONS
    GROUP BY
        STORE_TYPE
) AS RankedTransactions
WHERE RANKING<=2
ORDER BY RANKING;

-- -------------------------------------------------------------------------------------------

-- Q2. From which city do we have the maximum number of customers and how many?  
SELECT 
    c.name as NAME, COUNT(CITY_CODE) AS MAX_CUSTOMER
FROM
    Customer cu
INNER JOIN city c ON c.city_id = cu.city_code
GROUP BY city_code
ORDER BY MAX_CUSTOMER DESC
LIMIT 3;

-- ---------------------------------------------------------------------------------------------

-- Q3. Age Distribution (using year of birth, assuming DOB is in YYYY-MM-DD format)
SELECT 
  CASE 
    WHEN TIMESTAMPDIFF(YEAR, DOB, CURDATE()) BETWEEN 31 AND 35 THEN '31-35'
    WHEN TIMESTAMPDIFF(YEAR, DOB, CURDATE()) BETWEEN 36 AND 40 THEN '36-40'
    WHEN TIMESTAMPDIFF(YEAR, DOB, CURDATE()) BETWEEN 41 AND 45 THEN '41-45'
    WHEN TIMESTAMPDIFF(YEAR, DOB, CURDATE()) BETWEEN 46 AND 50 THEN '46-50'
    WHEN TIMESTAMPDIFF(YEAR, DOB, CURDATE()) BETWEEN 51 AND 55 THEN '51-55'
    WHEN TIMESTAMPDIFF(YEAR, DOB, CURDATE()) BETWEEN 56 AND 60 THEN '56-60'
    ELSE 'other'
  END AS AgeGroup,
  COUNT(*) AS CustomerCount
FROM Customer
GROUP BY AgeGroup;
# divided the ages into groups for a better understanding.

-- ----------------------------------------------------------------------------------------------

-- Q4. Which is the most popular product category amongst the customers?
SELECT pc.prod_cat, COUNT(DISTINCT t.transaction_id) AS TransactionCount
FROM Transactions t
INNER JOIN Prod_category pc ON t.prod_cat_code = pc.prod_cat_code
GROUP BY pc.prod_cat
ORDER BY TransactionCount DESC;

-- ----------------------------------------------------------------------------------------------

-- Q5. When are customers making purchases? Are there any seasonal trends in our sales?
-- Understanding the transaction timings
SELECT
    CONCAT(YEAR(tran_date), '-Q', QUARTER(tran_date)) AS TransactionQuarter,
    COUNT(transaction_id) AS TransactionCount
FROM Transactions
GROUP BY YEAR(tran_date), QUARTER(tran_date)
ORDER BY YEAR(tran_date), QUARTER(tran_date);
# using quarterly ananlysis

-- Further drilling down to understand season-wise sales.
SELECT
    CASE
        WHEN MONTH(tran_date) IN (12, 1, 2) THEN 'Winter'
        WHEN MONTH(tran_date) IN (3, 4, 5) THEN 'Spring'
        WHEN MONTH(tran_date) IN (6, 7, 8) THEN 'Summer'
        WHEN MONTH(tran_date) IN (9, 10, 11) THEN 'Autumn'
    END AS Season,
    COUNT(transaction_id) AS TransactionCount
FROM Transactions
GROUP BY Season
ORDER BY TransactionCount DESC;

-- -----------------------------------------------------------------------------

-- Q6. How much are customers spending in different years?
SELECT
    YEAR(t.tran_date) AS TransactionYear,
    ROUND(SUM(t.total_amt),2) AS TotalSpend
FROM Transactions t
GROUP BY YEAR(t.tran_date)
ORDER BY TransactionYear;

-- ------------------------------------------------------------------

-- Q7. What is the average spent by the customers in different age groups and gender?
SELECT
    CASE
        WHEN TIMESTAMPDIFF(YEAR, c.DOB, CURDATE()) BETWEEN 30 AND 35 THEN '30-35'
        WHEN TIMESTAMPDIFF(YEAR, c.DOB, CURDATE()) BETWEEN 36 AND 40 THEN '36-40'
        WHEN TIMESTAMPDIFF(YEAR, c.DOB, CURDATE()) BETWEEN 41 AND 45 THEN '41-45'
        WHEN TIMESTAMPDIFF(YEAR, c.DOB, CURDATE()) BETWEEN 46 AND 50 THEN '46-50'
        WHEN TIMESTAMPDIFF(YEAR, c.DOB, CURDATE()) BETWEEN 51 AND 55 THEN '51-55'
        ELSE NULL -- Handle ages outside the specified ranges
    END AS AgeGroup,
    c.Gender,
    ROUND(AVG(t.total_amt), 2) AS AvgSpent
FROM Transactions2 t
JOIN Customer c ON t.cust_id = c.customer_Id
WHERE TIMESTAMPDIFF(YEAR, c.DOB, CURDATE()) BETWEEN 30 AND 55
GROUP BY AgeGroup, c.Gender
ORDER BY AgeGroup, c.Gender;

-- -----------------------------------------------------------------

-- Q8. Find the details of the highest spending customer, along with the total spend.
WITH CustomerSpending AS (
    SELECT cust_id, 
           ROUND(SUM(total_amt), 2) AS TotalSpent
    FROM Transactions
    GROUP BY cust_id
) SELECT 
    c.customer_Id, 
    c.DOB, 
    TIMESTAMPDIFF(YEAR, c.DOB, CURDATE()) AS Age, 
    c.Gender, 
    ci.Name AS City, 
    cs.TotalSpent
FROM Customer c
JOIN CustomerSpending cs ON c.customer_Id = cs.cust_id
JOIN City ci ON c.city_code = ci.city_id
WHERE cs.TotalSpent = (SELECT MAX(TotalSpent) FROM CustomerSpending);
