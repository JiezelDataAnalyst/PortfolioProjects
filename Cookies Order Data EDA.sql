-- Exploratory Data Analysis in Cookies Order Data

-- In this dataset, I will perform analysis to uncover sales metrics and trends.

-- View dataset
SELECT * FROM cookies_order_data;

-- What is the total revenue, cost, profit and profit margin for each year?
SELECT YEAR(Order_Date) as year,
	   SUM(Revenue) AS total_revenue,
	   SUM(Cost) AS total_cost,
	   SUM(Revenue) - SUM(Cost) AS total_profit,
	   ROUND((SUM(Revenue) - SUM(Cost)) / SUM(Revenue)*100.0, 2) AS profit_margin
FROM cookies_order_data
GROUP BY YEAR(Order_Date)
ORDER BY YEAR(Order_Date);

-- What are the YoY growth rates in revenue?
WITH yearly_revenue AS (
  SELECT 
    YEAR(Order_Date) AS year,
    SUM(Revenue) AS total_revenue
  FROM cookies_order_data
  GROUP BY YEAR(Order_Date)
),

revenue_growth AS (
  SELECT 
    year,
    total_revenue,
    LAG(total_revenue) OVER (ORDER BY year) AS prev_year_revenue
  FROM yearly_revenue
)
SELECT 
  year,
  total_revenue,
  prev_year_revenue,
  CASE 
    WHEN prev_year_revenue IS NULL THEN NULL -- I keep getting zero rates, so I use CASE to filter NULLS
    ELSE ROUND((total_revenue - prev_year_revenue) * 100.0 / prev_year_revenue, 2)
  END AS yoy_revenue_growth_pct
FROM revenue_growth;

-- Which months or seasons see the highest cookie sales?
SELECT MONTH(Order_Date) AS month, SUM(Cookies_Shipped) AS total_quantity, SUM(Revenue) AS total_revenue
FROM cookies_order_data
WHERE YEAR(Order_Date) = '2017'
GROUP BY MONTH(Order_Date)
ORDER BY total_quantity DESC, total_revenue DESC;

-- Which customer generate the most profit?
SELECT customer_name, SUM(Revenue) AS total_revenue
FROM cookies_order_data
GROUP BY customer_name
ORDER BY total_revenue DESC;

-- What’s the average number of orders per customer?
SELECT ROUND(COUNT(Order_ID) * 1.0 / COUNT(DISTINCT Customer_Name), 2) AS avg_orders_per_customer
FROM cookies_order_data;

-- What’s the average time between order and shipment by customer?
SELECT Customer_Name, AVG(Days_to_Ship) AS avg_days
FROM cookies_order_data
GROUP BY Customer_Name;

-- How many customers placed only one order (potential churn)?
SELECT Customer_Name
FROM cookies_order_data
GROUP BY Customer_Name
HAVING COUNT(Order_ID) = 1;

-- Who is the best customer? Which customer needs retention focus? 
-- Let's use RFM (Recency, Frequency, Monetary) Segmentation to answer this question
-- I will calculate the recency, frequency and monetary first. Then, I will create a rfm scores.
-- Finally, I will segment the customers as "Champions", "Loyal Customers", "Big Spenders", "At-Risk" and "New Customers" using the rfm scores. 

WITH rfm AS (
    SELECT 
        Customer_name, 
        SUM(Revenue) AS monetary_value,
        COUNT(Order_ID) AS frequency,
        MAX(Order_Date) AS last_order_date,
        (SELECT MAX(Order_Date) FROM cookies_order_data) max_order_date,
        ABS(DATEDIFF(day, MAX(Order_Date), (SELECT MAX(Order_Date) FROM cookies_order_data))) AS recency
    FROM cookies_order_data
    GROUP BY Customer_Name
),
rfm_calc AS (
    SELECT r.*,
        NTILE(4) OVER (ORDER BY recency DESC) recency_score,
        NTILE(4) OVER (ORDER BY frequency) frequency_score,
        NTILE(4) OVER (ORDER BY monetary_value) monetary_score
    FROM rfm r
)
SELECT 
   Customer_Name, 
   recency_score, 
   frequency_score, 
   monetary_score,
   CONCAT(recency_score, frequency_score, monetary_score) AS rfm_score,
   CASE 
        WHEN CONCAT(recency_score, frequency_score, monetary_score) IN 
            ('111','112','121','122','123','132','211','212','114','141') THEN 'dormant_customers'
        WHEN CONCAT(recency_score, frequency_score, monetary_score) IN 
            ('133','134','143','244','334','343','344','144') THEN 'at_risk_customers'
        WHEN CONCAT(recency_score, frequency_score, monetary_score) IN 
            ('311','411','331') THEN 'new_customers'
        WHEN CONCAT(recency_score, frequency_score, monetary_score) IN 
            ('221','222','223','232','233','234','322') THEN 'potential_churners'
        WHEN CONCAT(recency_score, frequency_score, monetary_score) IN 
            ('323','333','321','412','421','422','423','332','432') THEN 'active_customers'
        WHEN CONCAT(recency_score, frequency_score, monetary_score) IN 
            ('433','434','443','444') THEN 'loyal_customers'
   END AS rfm_segment
FROM rfm_calc;