-- Exploratory Data Analysis

--Pizza Sales 

SELECT*
FROM [dbo].[pizza_sales];

--Calculating the Total Revenue;

SELECT SUM(ROUND(total_price,2)) AS Total_Revenue
FROM [dbo].[pizza_sales];

--Calculating the Average Order Value;

SELECT ROUND(SUM(total_price)/COUNT(DISTINCT(order_id)),2) AS AverageOrderValue
FROM [dbo].[pizza_sales];

SELECT SUM(quantity) AS TotalPizzaSold
FROM [dbo].[pizza_sales];

SELECT COUNT(DISTINCT(order_id)) AS TotalOrders
FROM [dbo].[pizza_sales];

SELECT SUM(quantity)/COUNT(DISTINCT(order_id)) AS AveragePizzaPerOrder
FROM [dbo].[pizza_sales];

-- We need to find the orders in a particular hour how many pizzas are sold, as we can see we have order_time in our database
-- with respect to that we need to use 24 hours clock and we have to find out in that particular entire day,the shop is opening at nine and closing at midnight,
-- so how is the order situation and how many pizzas are sold the entire day;

 ---HOURLY TREND FOR TOTAL ORDERS

 SELECT DATEPART(HOUR,order_time) AS OrderHour, SUM(quantity) AS TotalPizzaSold
 FROM [dbo].[pizza_sales]
 GROUP BY DATEPART(HOUR,order_time)
 ORDER BY DATEPART(HOUR,order_time);

 ---WEEKLY TREND FOR TOTAL ORDERS

SELECT DATEPART(ISO_WEEK,order_date) AS WeekNumber,COUNT(DISTINCT(order_id)) AS TotalOrders
FROM [dbo].[pizza_sales]
GROUP BY DATEPART(ISO_WEEK,order_date)
ORDER BY DATEPART(ISO_WEEK,order_date);


---PERCENTAGE OF SALES BY PIZZA CATEGORY

SELECT DISTINCT(pizza_category), 
ROUND(SUM(total_price),2) AS TotalRevenue,
ROUND(SUM(total_price)*100/(SELECT SUM(total_price) FROM [dbo].[pizza_sales])
,2) AS PCT
FROM [dbo].[pizza_sales]
GROUP BY pizza_category
ORDER BY 3 DESC;

---PERCENTAGE OF SALES BY SIZE

SELECT DISTINCT(pizza_size),
ROUND(SUM(total_price),2) AS TotalRevenue,
ROUND(SUM(total_price)*100/(SELECT SUM(total_price) FROM [dbo].[pizza_sales])
,2) AS PCT
FROM [dbo].[pizza_sales]
GROUP BY pizza_size
ORDER BY 3 DESC;

---TOTAL PIZZA SOLD BY CATEGORY

SELECT pizza_category,SUM(quantity) AS TotalPizzaSold
FROM[dbo].[pizza_sales]
GROUP BY pizza_category
ORDER BY 2 DESC;

---TOP 5 BEST SELLERS BY REVENUE

SELECT TOP 5 pizza_name,SUM(cast(total_price AS DECIMAL(10,2))) AS TotalRevenue
FROM [dbo].[pizza_sales]
GROUP BY pizza_name
ORDER BY 2 DESC;

---BOTTOM 5 BEST SELLERS BY REVENUE

SELECT TOP 5 pizza_name,SUM(cast(total_price AS DECIMAL(10,2))) AS TotalRevenue
FROM [dbo].[pizza_sales]
GROUP BY pizza_name
ORDER BY 2 ASC;

---TOP 5 BEST SELLERS BY QUANTITY

SELECT TOP 5 pizza_name,SUM(quantity) AS TotalPizzaSold
FROM [dbo].[pizza_sales]
GROUP BY pizza_name
ORDER BY 2 DESC;

---BOTTOM 5 BEST SELLERS BY QUANTITY
SELECT TOP 5 pizza_name,SUM(quantity) AS TotalPizzaSold
FROM[dbo].[pizza_sales]
GROUP BY pizza_name
ORDER BY 2 ASC;

---TOP 5 BEST SELLERS BY TOTAL ORDERS

SELECT TOP 5 pizza_name,COUNT(DISTINCT(order_id)) AS TotalOrders
FROM [dbo].[pizza_sales]
GROUP BY pizza_name
ORDER BY 2 DESC;

---BOTTOM 5 BEST SELLERS BY TOTAL ORDERS

SELECT TOP 5 pizza_name,COUNT(DISTINCT(order_id)) AS TotalOrders
FROM [dbo].[pizza_sales]
GROUP BY pizza_name
ORDER BY 2 ASC;


--Peak orders are between 12pm and 1pm, and in evening from 4pm to 7 PM.

--Significant variations in weekly orders, with highest peak during the 48th week from the month of December.

--Large pizza size contribute to maximum pizza sales

--The Thai Chicken contributes to the Maximum Sales by Revenue

--The Classic Delux Pizza contributes to the Maximum Total Quantities and Total Orders

--Classic Category contributes to maximum Sales,Total Orders and Total Pizzas Sold

--The Brie Carre Pizza contributes to the Minimum Sales by Revenue, Minimum Total Quantities,Minimum Total Orders

