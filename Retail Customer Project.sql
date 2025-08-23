-- Window Functions, Joins and CTEs

SELECT *
FROM dbo.dim_customers;

SELECT *
FROM dbo.dim_products;

SELECT *
FROM dbo.fact_sales;

-- Using the Window Functions and JOINS:

-- 1. What are the top selling products, category and sub_category?

-- Using RANK(), DENSE_RANK, ROW_NUMBER

WITH rank_products AS
(
SELECT 
	dim.product_name,
	dim.category,
	dim.sub_category,
	SUM(fact.sales) AS sum_sales
FROM dim_products dim
JOIN fact_sales fact
ON dim.product_key = fact.product_key
GROUP BY dim.product_name, dim.category, dim.sub_category
)
SELECT 
	product_name,
	category,
	sub_category,
	sum_sales,
	RANK() OVER (ORDER BY sum_sales DESC) AS rank_num,
	DENSE_RANK() OVER (ORDER BY sum_sales DESC) AS dense_rank_num,
	ROW_NUMBER() OVER (ORDER BY sum_sales DESC) AS row_num
FROM rank_products;
-- Mountain-200 Black- 46 is the top selling product under the Bikes category specifically for the Mountain Bikes sub_category.
-- While clothing category specifically for socks sub-category underperformed.

-- 2. What is the yearly and monthly ranking of product and sub_category?

WITH monthly_sales AS (
    SELECT 
        dim.product_name,
        dim.sub_category,
        YEAR(fact.order_date) AS year_num,
        MONTH(fact.order_date) AS month_num,
        SUM(fact.sales) AS sum_sales
    FROM dim_products dim
    JOIN fact_sales fact
        ON dim.product_key = fact.product_key
    WHERE fact.sales > 0   -- ensures to exclude zero or null sales
    GROUP BY dim.product_name, dim.sub_category, YEAR(fact.order_date), MONTH(fact.order_date)
),
product_ranking AS (
    SELECT *,
        DENSE_RANK() OVER (
            PARTITION BY year_num, month_num
            ORDER BY sum_sales DESC, product_name
        ) AS rank_num
    FROM monthly_sales
)
SELECT 
    product_name,
    sub_category,
    CONCAT(year_num, '-', month_num) AS year_month,
    sum_sales,
    rank_num
FROM product_ranking
WHERE year_num = 2012  -- Change to desired year
ORDER BY year_month ASC;
-- For the year 2012, Road-250 Black- 48 is the most popular product followed by Road-250 Red- 52. They are both under Road Bikes sub-category.

-- Using ROLLING_TOTAL() to show running total sales per year
SELECT 
	dim.product_name,
	YEAR(fact.order_date) AS year_num,
	fact.sales,
	SUM(fact.sales) OVER (
		ORDER BY dim.product_name, fact.order_date
		) AS running_total
FROM dim_products dim
JOIN fact_sales fact
	ON dim.product_key = fact.product_key
AND fact.sales > 0; -- ensures to excluse zero or null sales

-- 3.	Who is the best customer? 
-- Using ROW_NUM() I will assign unique numbers to each row and then return the top 1 customer.

With rank_customer AS 
(
SELECT
	dim.first_name,
	dim.last_name,
	dim.gender,
	SUM(fact.sales) AS sum_sales
FROM dim_customers dim
JOIN fact_sales fact
	ON dim.customer_key = fact.customer_key
WHERE YEAR(fact.order_date) = 2010 -- Change to desired year if we want to find the top 1 customer per year.
GROUP BY dim.first_name, dim.last_name, dim.gender
),
top_customer AS
(
SELECT
	first_name,
	last_name,
	gender,
	sum_sales,
	ROW_NUMBER() OVER (ORDER BY sum_sales DESC, first_name ASC) AS row_num
FROM rank_customer
)
SELECT
	first_name,
	last_name,
	gender
FROM top_customer
WHERE row_num = 1;
-- Albert Alvarez is the top spender for the year 2010

-- 4.	Which country has the highest sales?
-- Using ROW_NUMBER() I will assign unique numbers to each row and then return the top 1 country.

WITH rank_country AS
(
SELECT 
	dim.country,
	SUM(fact.sales) AS sum_sales
FROM dim_customers dim
JOIN fact_sales fact
	ON dim.customer_key = fact.customer_key
GROUP BY dim.country
),
top_country AS 
(
SELECT 
	*,
	ROW_NUMBER() OVER (ORDER BY sum_sales DESC) AS row_num
FROM rank_country
)
SELECT country
FROM top_country
WHERE row_num = 1;
-- United Sates appears the country has the highest sales
