-- SQL Portfolio Project-Data Cleaning

-- Netflix Dataset
-- https://www.kaggle.com/datasets/shivamb/netflix-shows

--View Dataset

SELECT * FROM [dbo].[netflix_titles]

--Create staging table
--First thing we want to do is create a staging table. This is the one we will work in and clean the data. We want a table with the raw data in case something happens

--Selecting Script Table As in Object Explorer to Create "staging table" in New Query Editor Window, then copy the data here

CREATE TABLE [dbo].[netflix_titles_staging](
	[show_id] [nvarchar](50) NULL,
	[type] [nvarchar](50) NULL,
	[title] [varchar](max) NULL,
	[director] [nvarchar](max) NULL,
	[cast] [nvarchar](max) NULL,
	[country] [nvarchar](max) NULL,
	[date_added] [date] NULL,
	[release_year] [smallint] NULL,
	[rating] [nvarchar](50) NULL,
	[duration] [nvarchar](50) NULL,
	[listed_in] [nvarchar](100) NULL,
	[description] [nvarchar](250) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

--Inserting the original data(netfix_titles) into staging table(netflix_titles_staging).

INSERT INTO [dbo].[netflix_titles_staging]
SELECT * FROM [dbo].[netflix_titles]

--View Dataset

SELECT * FROM [dbo].[netflix_titles_staging]


--In conducting data cleaning, I usually follow some steps

--1.Removing Duplicates
--2.Treating Nulls
--3.Standardizing Data
--4.Deleting Columns

--1.Removing Duplicates

--Let's check first for duplicates

SELECT *
FROM (
SELECT *, ROW_NUMBER() OVER(
			PARTITION BY show_id,type,title,director,cast,country,date_added,duration,listed_in,description 
			ORDER BY show_id) rownum
FROM [dbo].[netflix_titles_staging]
	) AS  duplicates

--The ones that we want to delete are the row number > 1

SELECT *
FROM (
SELECT *, ROW_NUMBER() OVER(
			PARTITION BY show_id,type,title,director,cast,country,date_added,duration,listed_in,description 
			ORDER BY show_id) rownum
FROM [dbo].[netflix_titles_staging]
) AS  duplicates
WHERE rownum>1
--No duplicates found

--2.Checking nulls across columns

SELECT 
	SUM(CASE WHEN show_id IS NULL THEN 1 ELSE 0 END) AS nullcount_show_id,
	SUM(CASE WHEN type IS NULL THEN 1 ELSE 0 END) AS nullcount_type,
	SUM(CASE WHEN title IS NULL THEN 1 ELSE 0 END) AS nullcount_title,
	SUM(CASE WHEN director IS NULL THEN 1 ELSE 0 END) AS nullcount_director,
	SUM(CASE WHEN cast IS NULL THEN 1 ELSE 0 END) AS nullcount_cast,
	SUM(CASE WHEN country IS NULL THEN 1 ELse 0 END) AS nullcount_country,
	SUM(CASE WHEN date_added IS NULL THEN 1 ELSE 0 END) AS nullcount_date_added,
	SUM(CASE WHEN release_year IS NULL THEN 1 ELSE 0 END) AS nullcount_release_year,
	SUM(CASE WHEN rating IS NULL THEN 1 ELSE 0 END) AS nullcount_rating,
	SUM(CASE WHEN duration IS NULL THEN 1 ELSE 0 END) AS nullcount_duration,
	SUM(CASE WHEN listed_in IS NULL THEN 1 ELSE 0 END) As nullcount_listed_in
FROM [dbo].[netflix_titles_staging]

--The director field has 2634 nulls. The nulls are pretty much large so it is not a good idea to delete them. 
--Instead,I will populate the column with nulls by using another column which has relationship to the director column.

SELECT a.cast,a.director,b.cast,b.director
FROM [dbo].[netflix_titles_staging] a
JOIN [dbo].[netflix_titles_staging] b
	ON a.cast=b.cast
	AND a.show_id<>b.show_id
--WHERE a.director IS NULL

--By using join, I discovered the same cast is likely to work with the same director.
--Using ISNULL to replace the null with specified default value

SELECT a.cast,a.director,b.cast,b.director, ISNULL(a.director,b.director)
FROM [dbo].[netflix_titles_staging] a
JOIN [dbo].[netflix_titles_staging] b
	ON a.cast=b.cast
	AND a.show_id<>b.show_id

--Let's now use cast column to populate the director column.

UPDATE a
SET director=ISNULL(a.director,b.director)
FROM [dbo].[netflix_titles_staging] a
JOIN [dbo].[netflix_titles_staging] b
	ON a.cast=b.cast
	AND a.show_id<>b.show_id
WHERE a.director IS NULL

--Populated 131 rows
--Checking if I can populate all the director column.

SELECT a.cast,a.director,b.cast,b.director
FROM [dbo].[netflix_titles_staging] a
JOIN [dbo].[netflix_titles_staging] b
	ON a.cast=b.cast
	AND a.show_id<>b.show_id

SELECT SUM(CASE WHEN director IS NULL THEN 1 ELSE 0 END) AS nullcount_director
FROM [dbo].[netflix_titles_staging]

--Although I succesfully populated the null values, there are still 2594 nulls in the director column.
--Let's populate null values in director column with "Unknown Director". 

UPDATE [dbo].[netflix_titles_staging]
SET director='Unknown Director'
WHERE director IS NULL

--The country coulumn has 831 null values. 
--Populating country column using director column.

SELECT a.director,a.country,b.director,b.country,ISNULL(a.country,b.country)
FROM [dbo].[netflix_titles_staging] a
JOIN [dbo].[netflix_titles_staging] b
	ON a.director=b.director
	AND a.show_id=b.show_id
--WHERE a.country IS NULL

UPDATE a
SET country=ISNULL(a.country,b.country)
FROM [dbo].[netflix_titles_staging] a
JOIN [dbo].[netflix_titles_staging] b
	ON a.director=b.director
	AND a.show_id<>b.show_id
WHERE a.country IS NULL

--Checking if I successfully populate the nulls in country column

SELECT a.director,a.country,b.director,b.country
FROM [dbo].[netflix_titles_staging] a
JOIN [dbo].[netflix_titles_staging] b
	ON a.director=b.director
	AND a.show_id=b.show_id

SELECT SUM(CASE WHEN country IS NULL THEN 1 ELse 0 END) AS nullcount_country
FROM [dbo].[netflix_titles_staging]

-- Populating null values in country column with "Unknown Country". 

UPDATE [dbo].[netflix_titles_staging]
SET country='Unknown Country'
WHERE country IS NULL

--3.Standardizing Data/Normalizing data

SELECT * FROM [dbo].[netflix_titles_staging]

--Let's take a look at this

SELECT title,director
FROM [dbo].[netflix_titles_staging]
WHERE title LIKE 'Full%'

--Updating capital M to small m

Update [dbo].[netflix_titles_staging]
SET title= 'Fullmetal Alchemist'
WHERE title= 'FullMetal Alchemist'

--The director is null before but I updated it with "Unknown Director" 
--Let's confirm if the director of Fullmetal Alchemist (for both rows) is Fumihiko Sori.

SELECT title,director,country, release_year
FROM [dbo].[netflix_titles_staging]
WHERE title LIKE 'Full%'

--I added country and release year to confirm that the other one is not a duplicate.
--Since the release years are significantly different, I can't confidently say that the director is the same for both. Therefore, I will leave the director as "Unkonwn Director". 

--Let's look at this

SELECT title
FROM [dbo].[netflix_titles_staging]
WHERE title LIKE 'Death%'

Update [dbo].[netflix_titles_staging]
SET title= 'Death Note'
WHERE title= 'DEATH NOTE'

--Let's look at the other columns

SELECT DISTINCT(rating)
FROM [dbo].[netflix_titles_staging]
--WHERE rating LIKE '%min%'

--While looking at rating column, I noticed that there are duration values in the column(Which is obviously not a rating).
--Let's find out if the duration column have some nulls so I can populate it if the rows are matched.

SELECT rating,duration
FROM [dbo].[netflix_titles_staging]
WHERE duration IS NULL OR duration=''

--Let's verify the total number of rows missing

SELECT
SUM(CASE WHEN duration IS NULL THEN 1 ELSE 0 END) AS nullcount_duration
FROM [dbo].[netflix_titles_staging]

--Now, I verified and have 3 rows with duration data in rating column and 3 null values in duration column.
--Let's now move the data from rating to duration.

UPDATE [dbo].[netflix_titles_staging]
SET duration=rating
WHERE duration IS NULL AND rating LIKE '%min%'

--Let's check if we successfully move the values

SELECT rating,duration
FROM [dbo].[netflix_titles_staging]
WHERE duration IS NULL OR duration=''
 
SELECT DISTINCT(rating)
FROM [dbo].[netflix_titles_staging]
WHERE rating LIKE '%min%'

--Let's change the wrong values in rating with "Not Given"

UPDATE [dbo].[netflix_titles_staging]
SET rating= 'Not Given'
WHERE rating LIKE '%min%'

--Checking if I successfully update the column

SELECT DISTINCT(rating)
FROM [dbo].[netflix_titles_staging]
--WHERE rating LIKE '%min%'

-- There are nulls in rating. Let's label it with "Not Given"

UPDATE [dbo].[netflix_titles_staging]
SET rating= 'Not Given'
WHERE rating IS NULL

SELECT DISTINCT(rating)
FROM [dbo].[netflix_titles_staging]

--Breaking out country into individual column.
--Separating Individual parts in country
--I can use PARSENAME to easily extract the parts
--PARSENAME only works with period, I need to replace first the comma with period

SELECT country,
PARSENAME (REPLACE(country,',','.'),4) AS country1,
PARSENAME (REPLACE(country,',','.'),3) AS country2,
PARSENAME (REPLACE(country,',','.'),2) AS country3,
PARSENAME (REPLACE(country,',','.'),1) AS country4
FROM [dbo].[netflix_titles_staging]

--The query gave us Backward result
--Let's use 4,3,2,1

SELECT country,
PARSENAME (REPLACE(country,',','.'),4) AS country4,
PARSENAME (REPLACE(country,',','.'),3) AS country3,
PARSENAME (REPLACE(country,',','.'),2) AS country2,
PARSENAME (REPLACE(country,',','.'),1) AS country1
FROM [dbo].[netflix_titles_staging]

--If I will use this in visualization, it is appropriate to use only one country. 
--To easily extract the first country I will use substring instead of using PARSENAME.

SELECT country, 
       CASE 
           WHEN CHARINDEX(',', country) > 0 
		   THEN SUBSTRING(country, 1, CHARINDEX(',', country) - 1)
           ELSE country 
		   END AS country1
FROM [dbo].[netflix_titles_staging]

--I use case statement because there are rows that has only one country.I need to use "Else" so that the rows with one country will return and stay the same.

--Adding country1 column to store the extracted parts

ALTER TABLE [dbo].[netflix_titles_staging]
ADD country1 VARCHAR(100)

UPDATE [dbo].[netflix_titles_staging]
SET country1 = CASE 
    WHEN CHARINDEX(',', country) > 0 
    THEN SUBSTRING(country, 1, CHARINDEX(',', country) - 1)
    ELSE country
END

SELECT * FROM [dbo].[netflix_titles_staging]

--4.Deleting unnecessary column

SELECT * FROM [dbo].[netflix_titles_staging]

--In this dataset, I will delete columns which I think are not useful specially for data exploration and visualization.

ALTER TABLE [dbo].[netflix_titles_staging]
DROP COLUMN cast,description,country

--Let's look at the dataset

SELECT * FROM [dbo].[netflix_titles_staging]

--The dataset is now clean. 
--This dataset can now be use for data exploration and vizualization.
