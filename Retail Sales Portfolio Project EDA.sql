-- Exploratory Data Analysis on Retail Sales

-- Dataset
-- https://www.kaggle.com/datasets/mohammadtalib786/retail-sales-dataset/data

-- Create first a staging table to keep the original data untouched while cleaning and analyzing it.
CREATE TABLE retail_sales_staging
SELECT * FROM retail_sales_dataset;

-- View staging table
SELECT * FROM retail_sales_staging;

-- Checking if the data is clean. If not, I will clean it first before exploring the dataset.

-- For SQL readabilty I will replace those column names with spaces in between with underscore and lower case each column.
ALTER TABLE retail_sales_staging
RENAME COLUMN `Transaction ID` TO `transaction_id`,
RENAME COLUMN `Date` TO `date`,
RENAME COLUMN `Customer ID` TO `customer_id`,
RENAME COLUMN `Gender` TO `gender`,
RENAME COLUMN `Age` TO `age`,
RENAME COLUMN `Product Category` TO `product_category`,
RENAME COLUMN `Quantity` TO `quantity`,
RENAME COLUMN `Price per Unit` TO `price_per_unit`,
RENAME COLUMN `Total Amount` TO `total_amount`;

-- Removing duplicates
SELECT transaction_id, date, customer_id, gender, age, product_category, quantity, price_per_unit, total_amount, COUNT(*)
FROM retail_sales_staging
GROUP BY transaction_id, date, customer_id, gender, age, product_category, quantity, price_per_unit, total_amount
HAVING COUNT(*) > 1;
-- No duplicate found

-- Identifying null in each column
SELECT * FROM retail_sales_staging
WHERE transaction_id IS NULL OR date IS NULL OR customer_id IS NULL OR gender IS NULL OR age IS NULL OR product_category IS NULL 
OR quantity IS NULL OR price_per_unit IS NULL OR  total_amount IS NULL;
-- No nulls found

-- Changing date data type from text to date
ALTER TABLE retail_sales_staging
MODIFY `date` DATE;

-- Changing the data type from text to VARCHAR
ALTER TABLE retail_sales_staging
MODIFY customer_id VARCHAR(50);

SELECT * FROM retail_sales_staging;

-- Our data is now clean, proceed to EDA

-- Note: The dataset includes January 2024, but I will focus only on the full year of 2023 to ensure complete and consistent analysis.

-- 1. Sales performance and Customer Demographics Analysis

-- KPIs
-- What is the total sales amount for the year 2023?
SELECT SUM(total_amount) AS total_sales 
FROM retail_sales_staging
WHERE Year(date) = 2023;

-- How many units were sold overall?
SELECT SUM(quantity) AS total_quantity_sold 
FROM retail_sales_staging
WHERE Year(date) = 2023;

-- How many transactions were made?
SELECT COUNT(DISTINCT transaction_id) AS total_transaction 
FROM retail_sales_staging
WHERE Year(date) = 2023;

-- What is the average order value?
SELECT ROUND(SUM(total_amount)/(COUNT(DISTINCT transaction_id)),2) AS avg_order_value 
FROM retail_sales_staging
WHERE Year(date) = 2023;

-- Which month exhibit peak sales performance?
SELECT MONTH(date) AS month_num, date_format(date, '%M') AS month, SUM(total_amount) AS total_revenue
FROM retail_sales_staging
WHERE Year(date) = 2023
GROUP BY month, month_num
ORDER BY total_revenue DESC;

-- Which months have higher or lower customer purchase activity?
SELECT MONTH(date) AS month_num, date_format(date,'%M') AS month, COUNT(*) AS total_transaction
FROM retail_sales_staging
WHERE Year(date) = 2023
GROUP BY month, month_num
ORDER BY total_transaction DESC;

-- Which product contributes the most to revenue?
SELECT product_category, SUM(total_amount) AS total_sales
FROM retail_sales_staging
WHERE Year(date) = 2023
GROUP BY product_category
ORDER BY total_sales DESC;

-- Customer Demographics

-- How does customer demographics such as age and gender influence spending and product preferences?
SELECT product_category, gender, COUNT(*) AS gender_count, SUM(total_amount) AS total_sales
FROM retail_sales_staging
WHERE Year(date) = 2023
GROUP BY gender, product_category
ORDER BY product_category, total_sales DESC;

-- Grouping customers by age ranges and assign labels to each group.
SELECT 
CASE 
	WHEN age BETWEEN 0 AND 20 THEN 'Teens (0-20)'
    WHEN age BETWEEN 21 AND 30 THEN 'Young (21-30)'
    WHEN age BETWEEN 31 AND 45 THEN 'Adult (31-45)'
    WHEN age BETWEEN 46 AND 59 THEN 'Middle Age (46-59)'
    ELSE 'Old (60+)'
    END AS age_group
FROM retail_sales_staging;

-- Creating view to use the above query for further analysis.
CREATE view age_segmentation AS (
SELECT gender, age, total_amount, date, transaction_id, product_category, quantity,
CASE 
	WHEN age BETWEEN 0 AND 20 THEN 'Teens (0-20)'
    WHEN age BETWEEN 21 AND 30 THEN 'Young (21-30)'
    WHEN age BETWEEN 31 AND 45 THEN 'Adult (31-45)'
    WHEN age BETWEEN 46 AND 59 THEN 'Middle Age (46-59)'
    ELSE 'Old (60+)'
    END AS age_group
FROM retail_sales_staging
);

SELECT * FROM age_segmentation;

-- Product category distribution by age groups
SELECT age_group,product_category, COUNT(*) AS product_count
FROM age_segmentation
WHERE Year(date) = 2023
GROUP BY age_group, product_category
ORDER BY age_group, product_category, product_count DESC;

-- 2. Customer Segmentation (RFM)

-- In order to categorize customers, let's compute first for recency, frequency and monetary
-- Using CTE and CROSS JOIN to calculate the recency
WITH max_date AS (
    SELECT MAX(date) AS latest_date
    FROM retail_sales_staging
    WHERE YEAR(date) = 2023
),
rfm_cal AS (
SELECT 
    customer_id,
    DATEDIFF(m.latest_date, MAX(r.date)) AS recency_days,
    COUNT(r.transaction_id) AS frequency,
    SUM(r.total_amount) AS monetary
FROM retail_sales_staging r
CROSS JOIN max_date m
WHERE YEAR(r.date) = 2023
GROUP BY customer_id, m.latest_date
-- ORDER BY recency_days desc
)
SELECT * FROM rfm_cal;

-- Creating new columns to store the RFM data which will be used for scoring and segmentation

-- Adding RFM columns
ALTER TABLE retail_sales_staging
ADD COLUMN recency int,
ADD COLUMN frequency int,
ADD COLUMN monetary int;

-- Inserting the data to each column
WITH max_date AS (
    SELECT MAX(date) AS latest_date
    FROM retail_sales_staging
    WHERE YEAR(date) = 2023
),
rfm_calc AS (
    SELECT 
        customer_id,
        DATEDIFF(m.latest_date, MAX(r.date)) AS recency_days,
        COUNT(r.transaction_id) AS frequency,
        SUM(r.total_amount) AS monetary
    FROM retail_sales_staging r
    CROSS JOIN max_date m
    WHERE YEAR(r.date) = 2023
    GROUP BY customer_id, m.latest_date
)
UPDATE retail_sales_staging r
JOIN rfm_calc rfm 
ON r.customer_id = rfm.customer_id
SET 
    r.recency = rfm.recency_days,
    r.frequency = rfm.frequency,
    r.monetary = rfm.monetary;

-- Checking if successfuly updated the columns
SELECT recency, frequency, monetary 
FROM retail_sales_staging;

-- Based on the computed RFM, I will assign RFM scores for each customer.
SELECT customer_id,
-- The more recent the transaction(lower number of days), the higher the recency score.
CASE
	WHEN recency <= 30 THEN 5
    WHEN recency <= 100 THEN 4
    WHEN recency <= 190 THEN 3
    WHEN recency <= 380 THEN 2
    ELSE 1
    END AS r_score,
-- The higher the value of frequency and monetary, the higher the score.
CASE 
	WHEN frequency >= 10 THEN 5
    WHEN frequency >= 7 THEN 4
    WHEN frequency >= 5 THEN 3
    WHEN frequency >= 3 THEN 2
    ELSE 1
    END AS f_score,
CASE 
	WHEN monetary >= 1500 THEN 5
    WHEN monetary >= 1000 THEN 4
    WHEN monetary >= 500 THEN 3
    WHEN monetary >= 250 THEN 2
    ELSE 1
    END AS m_score
FROM retail_sales_staging;

-- Adding a rfm scores column
ALTER TABLE retail_sales_staging
ADD column r_score int,
ADD column f_score int,
ADD column m_score int;

-- Inserting calculated rfm scores into their respective columns
UPDATE retail_sales_staging r
JOIN (
  SELECT customer_id,
    CASE
      WHEN recency <= 30 THEN 5
      WHEN recency <= 100 THEN 4
      WHEN recency <= 190 THEN 3
      WHEN recency <= 380 THEN 2
      ELSE 1
    END AS r_score,
    CASE 
      WHEN frequency >= 10 THEN 5
      WHEN frequency >= 7 THEN 4
      WHEN frequency >= 5 THEN 3
      WHEN frequency >= 3 THEN 2
      ELSE 1
    END AS f_score,
    CASE 
      WHEN monetary >= 1500 THEN 5
      WHEN monetary >= 1000 THEN 4
      WHEN monetary >= 500 THEN 3
      WHEN monetary >= 250 THEN 2
      ELSE 1
    END AS m_score
  FROM retail_sales_staging
  GROUP BY customer_id, recency, frequency, monetary
) scores
ON r.customer_id = scores.customer_id
SET 
  r.r_score = scores.r_score,
  r.f_score = scores.f_score,
  r.m_score = scores.m_score;      
    
SELECT r_score, f_score, m_score FROM retail_sales_staging;

-- Merge the RFM scores into one code and add it as a column to help group and analyze customers better.
SELECT CONCAT(r_score, f_score, m_score) AS rfm_code
FROM retail_sales_staging;

ALTER TABLE retail_sales_staging
ADD column rfm_code VARCHAR(50);
-- At first, I stored the data type as int, I keep getting an error when I tried to group customers.
-- After analyzing further, it should be a string (varchar or char) to use the rfm_code for labeling the segments.

UPDATE retail_sales_staging
SET rfm_code = CONCAT(r_score, f_score, m_score);

SELECT rfm_code FROM retail_sales_staging;

-- Grouping customers into descriptive segments
SELECT 
  customer_id,
  CASE
	WHEN rfm_code = '555' THEN 'Champions'
    WHEN rfm_code LIKE '5__' AND rfm_code != '555' THEN 'Loyal Customers'
    WHEN rfm_code LIKE '__5' THEN 'Big Spenders'
    WHEN rfm_code LIKE '2__' THEN 'At Risk'
    ELSE 'Low Engagement'  
  END AS segment_label
FROM retail_sales_staging;

-- Adding customer segments into a new column
ALTER TABLE retail_sales_staging
ADD column customer_segment VARCHAR(50);

 UPDATE retail_sales_staging
 SET customer_segment =  (SELECT
 CASE
    WHEN rfm_code = '555' THEN 'Champions'
    WHEN rfm_code LIKE '5__' AND rfm_code != '555' THEN 'Loyal Customers'
    WHEN rfm_code LIKE '__5' THEN 'Big Spenders'
    WHEN rfm_code LIKE '2__' THEN 'At Risk'
    ELSE 'Low Engagement'   
  END AS customer_segment);
  
SELECT customer_segment FROM retail_sales_staging;
  
SELECT * FROM retail_sales_staging;
  
-- We can now analyze customer behavior and purchasing patterns across segments.

-- What percentage of customers belong to the high-value segment?
SELECT customer_segment, 
ROUND(COUNT(customer_id) * 100 / (SELECT COUNT(customer_id) FROM retail_sales_staging),2) AS percent_of_customers
FROM retail_sales_staging
WHERE year(date) = 2023
GROUP BY customer_segment
ORDER BY percent_of_customers DESC;

-- Which RFM segments contribute the most to overall revenue?
SELECT DISTINCT(customer_segment), SUM(total_amount) AS total_sales
FROM retail_sales_staging
WHERE year(date) = 2023
GROUP BY customer_segment
ORDER BY total_sales DESC;

-- What is the average RFM scores by segment?
SELECT 
  customer_segment, 
  AVG(r_score) AS avg_recency_score, 
  AVG(f_score) AS avg_frequency_score, 
  AVG(m_score) AS avg_monetary_score
FROM retail_sales_staging
WHERE year(date) = 2023
GROUP BY customer_segment;

-- View Dataset
 SELECT * FROM retail_sales_staging;
 
-- Create a view to store selected customer metrics for future analysis
 CREATE VIEW rfm_table AS (
 SELECT customer_id, customer_segment, rfm_code, recency, frequency, monetary
 FROM retail_sales_staging
 );

  SELECT * FROM rfm_table;
 
 -- Exported the results to excel for tableau project