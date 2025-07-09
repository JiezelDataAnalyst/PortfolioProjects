-- Creating Grocey Store Database

CREATE TABLE grocery_store
(
Product_ID INT PRIMARY KEY NOT NULL,
Products CHAR(50) NOT NULL,
Category CHAR(50) NOT NULL,
Quantity INT NOT NULL,
Price DECIMAL(10,2) NOT NULL
)

-- Inserting data into the table

INSERT INTO grocery_store VALUES (1, 'Bread', 'Bakey and Grains', 17, 95.50)
INSERT INTO grocery_store VALUES (2, 'Peanut Butter', 'Kitchen Essentials', 27, 95.00)
INSERT INTO grocery_store VALUES (3, 'Tomatoes', 'Produce',22, 18.00)
INSERT INTO grocery_store VALUES (4, 'Vinegar', 'Kitchen Essentials', 19, 25.50)
INSERT INTO grocery_store VALUES (5, 'Tofu', 'Meat and Protein', 33, 35.00)
INSERT INTO grocery_store VALUES (6, 'Butter', 'Dairy'	,19, 60.75)
INSERT INTO grocery_store VALUES (7, 'Pasta', 'Bakery and Grains', 18, 45.25)
INSERT INTO grocery_store VALUES (8, 'Beans', 'Canned Goods', 27, 35.00)
INSERT INTO grocery_store VALUES (9, 'Popcorn', 'Snacks', 17, 40.00)
INSERT INTO grocery_store VALUES (10, 'Banana', 'Produce', 22, 20.00)
INSERT INTO grocery_store VALUES (11, 'Pork Chop', 'Meat and Protein', 33, 180.00)
INSERT INTO grocery_store VALUES (12, 'Sugar', 'Kitchen Essentials', 31, 55.00)
INSERT INTO grocery_store VALUES (13, 'Flour', 'Kitchen Essential', 19,50.00)
INSERT INTO grocery_store VALUES (14, 'Pata Sauce', 'Canned Goods', 18, 60.75)
INSERT INTO grocery_store VALUES (15, 'Chips', 'Snacks', 33, 35.00)


-- View data
SELECT * FROM grocery_store

-- What is the top 3 best selling products?
SELECT TOP 3 Products, SUM(Quantity) AS units_sold
FROM grocery_store
GROUP BY Products
ORDER BY units_sold DESC

-- Which category generates the most sales?
SELECT Category, SUM(Quantity*Price) AS total_sales
FROM grocery_store
GROUP BY Category
ORDER BY total_sales DESC

-- What is the average sales where the category is Bakery and Grains?
SELECT AVG(Quantity*Price) AS avg_sales
FROM grocery_store
WHERE Category = 'Bakery and Grains'