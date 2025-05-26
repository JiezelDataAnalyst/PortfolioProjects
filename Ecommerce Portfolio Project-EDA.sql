-- Portfolio Project- Exploratory Data Analysis

-- E-commerce Dataset
-- https://www.kaggle.com/datasets/steve1215rogg/e-commerce-dataset/data

-- In this Portfolio Project:
-- 1. Cleaning the dataset before data analysis.
-- 2. Exploratory Data Analysis.
		-- In this dataset we are going to explore the data and find trends or patterns.
		-- 1. What is the total revenue?
		-- 2. What is the best-selling category?
		-- 3. Which payment method is most used?
		-- And more.

        
-- View dataset

SELECT * FROM ecommerce;     
  
-- Create staging table
-- First thing we want to do is create a staging table. This is the one we will work in,clean and explore the data.          

CREATE TABLE ecommerce_staging
LIKE ecommerce;

-- Inserting all the data from original table(ecommerce) into staging table(ecommerce_staging);

INSERT ecommerce_staging
SELECT *
FROM ecommerce;

-- View dataset

SELECT * FROM ecommerce_staging;

-- Let's clean first the data. We don't want to work with dirty dataset. To generate accurate and precise result we need to clean the data.

-- Standardizing Data

-- The purchase_date should be in date format. Let's modify the purchase_date from text to date;

ALTER TABLE ecommerce_staging
MODIFY COLUMN Purchase_Date DATE;

-- Modifying purchase_date resulting to error. Incorrect date value: '12-11-2024'
-- The format of dates is inconsistent. Let's use String to Date to format the purchase_date column;

SELECT Purchase_Date,
STR_TO_DATE(Purchase_Date,'%d-%m-%Y')
FROM ecommerce_staging;

UPDATE ecommerce_staging
SET Purchase_Date=STR_TO_DATE(Purchase_Date,'%d-%m-%Y')
WHERE Purchase_Date != '2024-11-12';

-- In above query, date value: '2024-11-12' is already in correct format, so I filtered that specific date.

-- Trying to modify again the purchase_date column...

ALTER TABLE ecommerce_staging
MODIFY COLUMN Purchase_Date DATE;
-- Successfully modified!

-- Removing some unnecessary letters and symbols in some column, in this case it will be more readable

ALTER TABLE ecommerce_staging
RENAME COLUMN `Price (Rs.)` TO Price;

ALTER TABLE ecommerce_staging
RENAME COLUMN `Discount (%)` TO Discount;

ALTER TABLE ecommerce_staging
RENAME COLUMN `Final_Price(Rs.)` TO Final_Price;

-- Treating/Removing NULLS
-- Let's identify nulls first in each column;

SELECT 
	SUM(CASE WHEN User_ID IS NULL THEN 1 ELSE 0 END) AS nullcount_User_ID,
	SUM(CASE WHEN Product_ID IS NULL THEN 1 ELSE 0 END) AS nullcount_Product_ID,
	SUM(CASE WHEN Category IS NULL THEN 1 ELSE 0 END) AS nullcount_Category,
	SUM(CASE WHEN Price IS NULL THEN 1 ELSE 0 END) AS nullcount_Price,
	SUM(CASE WHEN Discount IS NULL THEN 1 ELSE 0 END) AS nullcount_Discount,
	SUM(CASE WHEN Final_Price IS NULL THEN 1 ELse 0 END) AS nullcount_Final_Price,
	SUM(CASE WHEN Payment_Method IS NULL THEN 1 ELSE 0 END) AS nullcount_Payment_Method,
	SUM(CASE WHEN Purchase_Date IS NULL THEN 1 ELSE 0 END) AS nullcount_Purchase_Date
FROM ecommerce_staging;

-- Turns out there are nulls in User_ID and other columns.
-- To verify if there are nulls...

SELECT *
FROM ecommerce_staging
WHERE User_Id IS NULL;

-- The null values appear in multiple columns within the same rows, so we can delete these nulls.

DELETE
FROM ecommerce_staging
WHERE User_ID IS NULL;

-- Checking if we successfully deleted the nulls

SELECT *
FROM ecommerce_staging
WHERE User_Id IS NULL;

-- Let's check for duplicates

SELECT *
    FROM (
        SELECT User_ID, ROW_NUMBER() OVER(
            PARTITION BY User_ID, Product_ID, Category, Price, Discount, Final_Price, Payment_Method, Purchase_Date
            ORDER BY User_ID
        ) AS row_num
        FROM ecommerce_staging
		) AS temp;

-- The ones that we want to delete are the row number > 1 beacuse these are the real duplicates

SELECT *
    FROM (
        SELECT User_ID, ROW_NUMBER() OVER(
            PARTITION BY User_ID, Product_ID, Category, Price, Discount, Final_Price, Payment_Method, Purchase_Date
            ORDER BY User_ID
        ) AS row_num
        FROM ecommerce_staging
		) AS temp
WHERE row_num>1;

-- No duplicates

-- Our data is now clean

-- We can now proceed to EDA

SELECT * FROM ecommerce_staging;

-- Sales Analysis

-- Total Revenue
-- Let's find out how much e-commerce generated in sales in 2024.

SELECT ROUND(SUM(Final_Price),2) AS Total_Revenue
FROM ecommerce_staging;

-- Total Transaction

SELECT COUNT(*) AS transaction_count
FROM ecommerce_staging;

-- Let's find out how many transaction was made per user
 
SELECT User_ID, COUNT(*) As transaction_count
FROM ecommerce_staging
GROUP BY User_ID;

-- Average Transaction Value(ATV)
-- Let' find out what is the average spending per unique user

SELECT ROUND(SUM(Final_Price)/COUNT(DISTINCT(User_ID)),2) AS ATV
FROM ecommerce_staging;

-- Sales Trend Over Time

-- Monthly Sales Trend

SELECT * FROM ecommerce_staging;

-- Let's find out which month is the most profitable and which month is the least profitable

SELECT DATE_FORMAT(Purchase_Date,'%M') AS Month,ROUND(SUM(Final_Price),2) AS Monthly_Sales
FROM ecommerce_staging
GROUP BY Month
ORDER BY Monthly_Sales DESC;
-- By sorting the data by Total_Revenue, we can see that the month of October had the highest sales, whereas the November had the least sales.

-- Let's see which category performs best each month

SELECT DATE_FORMAT(Purchase_Date,'%M') AS Month, 
    Category, 
    ROUND(SUM(Final_Price),2) AS Monthly_Sales
FROM ecommerce_staging
GROUP BY Month, Category
ORDER BY Month, Monthly_Sales DESC;

-- Weekly Sales Trend

SELECT WEEK(Purchase_Date,7) AS ISO_Weeknumber,ROUND(SUM(Final_Price),2) AS Weekly_Sales
FROM ecommerce_staging
GROUP BY ISO_Weeknumber
ORDER BY Weekly_Sales DESC;
-- By sorting by Total_Revenue, we can see that Week 16 had the highest sales and week 47 had the least sales.

-- If we want to know the average sales per week

SELECT 
    WEEK(Purchase_Date,7) AS ISO_Weeknumber,
    ROUND(SUM(Final_Price), 2) AS Weekly_Sales,
    ROUND(AVG(SUM(Final_Price)) OVER (), 2) AS Avg_Weekly_Sales
FROM ecommerce_staging
GROUP BY ISO_Weeknumber
ORDER BY ISO_Weeknumber;

-- Let's see which category performs best each week

SELECT WEEK(Purchase_Date,7) AS ISO_Weeknumber,Category,ROUND(SUM(Final_Price),2) AS Weekly_Sales
FROM ecommerce_staging
GROUP BY ISO_Weeknumber,Category
ORDER BY ISO_Weeknumber,Weekly_Sales DESC;

-- Category by Sales and Transaction
-- Let's find out how many transaction was made per category and which category generates the highest sales

SELECT Category, ROUND(SUM(Final_Price),2) AS Total_Revenue,COUNT(*) AS Total_Transaction
FROM ecommerce_staging
GROUP BY Category
ORDER BY Total_Revenue DESC; 
-- Clothing had a total of 531 transactions and was the most profitable category, while electronics had a 498 transactions and was the least profitable category.

-- Payment method Analysis

-- Payment method by revenue and transaction
-- If we want to analyze the most frequent payment method used, we can sort it by total transaction

SELECT Payment_Method, ROUND(SUM(Final_Price),2) AS Total_Revenue, COUNT(*) AS Total_Transaction
FROM ecommerce_staging
GROUP BY Payment_Method
ORDER BY Total_Revenue DESC;
-- ORDER BY Total_Transaction DESC;

-- Credit Card is the most used and Cash on Delivery is the least used payment method.
-- Also, credit card have the most number transaction and the cash on delivery has the lowest

-- Discount vs Sales

SELECT Discount, ROUND(SUM(Final_Price),2) AS Total_Revenue
FROM ecommerce_staging
GROUP BY Discount
ORDER BY Total_Revenue DESC;
-- A discount range of 0-15% generates the highest sales, whereas a discount range of 25-50% generates the least.

-- Category-Level Trends
-- Let's find out the category that generate highest sales by applying discount to price
-- Analyzing how discounts impact different product categories could help refine promotional strategies.

SELECT Category,Discount,ROUND(SUM(Final_Price),2) AS Total_Revenue, COUNT(*) AS Total_Transaction
FROM ecommerce_staging
GROUP BY Price,Discount,Category 
ORDER BY Total_Revenue DESC;
-- With a discount of 30% the electronics category had the highest sales and by applying 50% discount the books category had the least sales.

-- Let's find out how many transactions was made in each discounted price

SELECT Discount, COUNT(*) AS Total_Transaction
FROM ecommerce_staging
GROUP BY Discount
ORDER BY Total_Transaction DESC;
-- Discount from 0-15% had the highest count of transaction while 25-50% had the least count.

-- Digging deeper on our dataset, we can also analyze time-based trends.

SELECT DATE_FORMAT(Purchase_Date,'%M')  AS Month, 
    Discount, 
    COUNT(*) AS Total_Transaction, 
    ROUND(SUM(Final_Price), 2) AS Total_Revenue
FROM ecommerce_staging
GROUP BY Month, Discount
ORDER BY Month, Total_Revenue DESC;

-- Understanding how discounts perform across different months can help optimize promotions.
-- This shows how discounts impact transactions and revenue throughout the year.

-- Creating View to store data for later vizualization

CREATE VIEW category_revenue_transaction AS
SELECT Category, ROUND(SUM(Final_Price),2) AS Total_Revenue,COUNT(*) AS Total_Transaction
FROM ecommerce_staging
GROUP BY Category
ORDER BY Total_Revenue DESC; 

-- Let's query our view

SELECT *
FROM category_revenue_transaction;
