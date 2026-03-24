use [Swiggy DB]

select * from swiggy_data

-- data cleaning and validation 
-- null check   : if there are any null it returns 1 , if not there then returns 0 
select 
	sum(case when State IS NULL THEN 1 ELSE 0 END) AS null_state,
	sum(case when City IS NULL THEN 1 ELSE 0 END) AS null_city,
	sum(case when Order_Date IS NULL THEN 1 ELSE 0 END) AS null_order_date,
	sum(case when Restaurant_Name IS NULL THEN 1 ELSE 0 END) AS null_restaurant,
	sum(case when Location IS NULL THEN 1 ELSE 0 END) AS null_location,
	sum(case when Category IS NULL THEN 1 ELSE 0 END) AS null_category,
	sum(case when Dish_Name IS NULL THEN 1 ELSE 0 END) AS null_dhis,
	sum(case when Price_INR IS NULL THEN 1 ELSE 0 END) AS null_price,
	sum(case when Rating IS NULL THEN 1 ELSE 0 END) AS null_rating,
	sum(case when Rating_Count IS NULL THEN 1 ELSE 0 END) AS null_rating_count
from swiggy_data   -- this returns 0 then no null values are there in any columns 

-- checking blank string or empty strings
	select * 
	from swiggy_data 
	where 
	State = '' OR city = '' OR Restaurant_Name = '' OR Category = '' OR Dish_Name = ''

-- CHECK for duplicates values 
select 
state,city,order_date,Restaurant_name,location,category,
dish_name,price_INR,rating,rating_count,count(*) as CNT
FROM swiggy_data
group by 
state,city,order_date,Restaurant_name,location,category,
dish_name,price_INR,rating,rating_count
having count(*) > 1 

-- deletion of duplicate values
	with CTE AS (
	select * ,
	ROW_NUMBER() over(
	 partition by state,city,order_date,Restaurant_name,location,category,
	dish_name,price_INR,rating,rating_count 
	order by (select null)
	) as rn
	from swiggy_data
	)

	DELETE FROM CTE WHERE rn>1

-- creating star schema 
--  creating dimension table 
-- date table
create table dim_date(
	date_id int identity(1,1) primary key,  -- identity() is used to assign uniqu numbers 
	Full_Date DATE,
	Year INT,
	Month INT,
	Month_Name VARCHAR(20),
	Quarter int,
	Day int,
	Week int
)

-- dim_location
CREATE TABLE dim_location (
    location_id INT IDENTITY(1,1) PRIMARY KEY,
    State VARCHAR(100),
    City VARCHAR(100),
    Location VARCHAR(200)
);

-- dim_restaurant
CREATE TABLE dim_restaurant (
    restaurant_id INT IDENTITY(1,1) PRIMARY KEY,
    Restaurant_Name VARCHAR(200)
);

-- dim_category
CREATE TABLE dim_category (
    category_id INT IDENTITY(1,1) PRIMARY KEY,
    Category VARCHAR(200)
);

-- dim_dish
CREATE TABLE dim_dish (
    dish_id INT IDENTITY(1,1) PRIMARY KEY,
    Dish_Name VARCHAR(200)
);

-- creating Fact table 
CREATE TABLE fact_swiggy_orders (

    Order_id INT IDENTITY(1,1) PRIMARY KEY,

    Date_id INT,
    Price_INR DECIMAL(10,2),
    Rating DECIMAL(4,2),
    Rating_Count INT,

    location_id INT,
    restaurant_id INT,
    category_id INT,
    dish_id INT,

    FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY (location_id) REFERENCES dim_location(location_id),
    FOREIGN KEY (restaurant_id) REFERENCES dim_restaurant(restaurant_id),
    FOREIGN KEY (category_id) REFERENCES dim_category(category_id),
    FOREIGN KEY (dish_id) REFERENCES dim_dish(dish_id)
);

select * from fact_swiggy_orders

-- insert data in created tables 
-- dim_date table 
INSERT INTO dim_date (Full_Date, Year, Month, Month_Name, Quarter, Day, Week)
SELECT DISTINCT
    Order_Date,
    YEAR(Order_Date),
    MONTH(Order_Date),
    DATENAME(MONTH, Order_Date),
    DATEPART(QUARTER, Order_Date),
    DAY(Order_Date),
    DATEPART(WEEK, Order_Date)
FROM swiggy_data
WHERE Order_Date IS NOT NULL;

select * from dim_date

-- dim_locations 
insert into dim_location (State,City,Location)
select distinct
	State,
	City,
	Location
from swiggy_data

-- insert dim_restaurant
insert into dim_restaurant(Restaurant_Name)
SELECT DISTINCT
    Restaurant_Name
FROM swiggy_data;

-- insert dim_category
INSERT INTO dim_category (Category)
SELECT DISTINCT
    Category
FROM swiggy_data;

-- insert dim_dish
INSERT INTO dim_dish (Dish_Name)
SELECT DISTINCT
    Dish_Name
FROM swiggy_data;

-- insert values into Fact table 
INSERT INTO fact_swiggy_orders
(
    date_id,
    Price_INR,
    Rating,
    Rating_Count,
    location_id,
    restaurant_id,
    category_id,
    dish_id
)
SELECT
    dd.date_id,
    s.Price_INR,
    s.Rating,
    s.Rating_Count,
    dl.location_id,
    dr.restaurant_id,
    dc.category_id,
    dsh.dish_id
FROM swiggy_data s
JOIN dim_date dd
    ON dd.Full_Date = s.Order_Date

JOIN dim_location dl
    ON dl.State = s.State
    AND dl.City = s.City
    AND dl.Location = s.Location

JOIN dim_restaurant dr
    ON dr.Restaurant_Name = s.Restaurant_Name

JOIN dim_category dc
    ON dc.Category = s.Category

JOIN dim_dish dsh
    ON dsh.Dish_Name = s.Dish_Name;


select * from fact_swiggy_orders f
JOIN dim_date d on f.date_id = d.date_id
JOIN dim_location l on f.location_id = l.location_id
JOIN dim_restaurant r on f.restaurant_id = r.restaurant_id
JOIN dim_category c on f.category_id = c.category_id
JOIN dim_dish di on f.dish_id = di.dish_id

-- Requirements 
-- kpi's
-- TOTAL ORDERS
SELECT COUNT(*) AS totalorders 
from fact_swiggy_orders

-- total revenue 
select 
format(sum(convert(float,price_INR))/1000000,'N2')  +  ' INR_MILLION'  as total_revenue
from fact_swiggy_orders

-- AVG Dish price
select 
format(avg(convert(float,price_INR)),'N2')  +  ' INR'  as avg_revenue
from fact_swiggy_orders

-- AVG Rating 
select 
avg(rating) as avg_rating
from fact_swiggy_orders

-- Deep Drive business analysis
-- monthly analysis 
select 
d.year,
d.month,
d.month_name,
sum(price_INR) as total_revenue
from fact_swiggy_orders f
JOIN dim_date d 
on f.Date_id = d.date_id
group by 
d.year,
d.month,
d.month_name
order by total_revenue desc


-- Quarterly analysis

select 
d.year,
d.Quarter,
sum(price_INR) as total_revenue
from fact_swiggy_orders f
JOIN dim_date d 
on f.Date_id = d.date_id
group by 
d.year,
d.Quarter
order by total_revenue desc

-- yearly trend
select 
d.year,
count(*) as totalorders
from fact_swiggy_orders f
JOIN dim_date d 
on f.Date_id = d.date_id
group by 
d.year
order by totalorders desc

-- orders by day and week 
select 
DATENAME(WEEKDAY,d.Full_date) as day_name,
count(*) as totalorders
from fact_swiggy_orders f
JOIN dim_date d 
on f.Date_id = d.date_id
group by 
DATENAME(WEEKDAY,d.Full_date), Datepart(WEEKDAY,d.Full_Date)
order by DATEPART(WEEKDAY,d.Full_date)

-- LOCATION BASED ANALYSIS
-- Top 10 cities  by order vlaue
select top 10  -- for bottom 10 , need not write bottom 10 , just change DESC to ASC 
l.city ,
sum(f.price_INR)  as total_revenue
from fact_swiggy_orders f
JOIN dim_location l
on f.location_id = l.location_id
group by l.City 
order by sum(f.price_INR) desc

-- Revenue contribution by state wise
select top 10  -- for bottom 10 , need not write bottom 10 , just change DESC to ASC 
l.State ,
sum(f.price_INR)  as total_revenue
from fact_swiggy_orders f
JOIN dim_location l
on f.location_id = l.location_id
group by l.State 
order by sum(f.price_INR) desc

-- top 10 restaurants orders
select top 10  -- for bottom 10 , need not write bottom 10 , just change DESC to ASC 
r.restaurant_name ,
sum(f.price_INR)  as total_revenue
from fact_swiggy_orders f
JOIN dim_restaurant r
on f.restaurant_id = r.restaurant_id
group by r.Restaurant_Name
order by sum(f.price_INR) desc

-- top category by order volume
select top 10  
c.category ,
sum(f.price_INR)  as total_revenue
from fact_swiggy_orders f
JOIN dim_category c
on f.category_id = c.category_id
group by c.category
order by sum(f.price_INR) desc

-- most order dish 
select top 10  
dd.dish_name,
sum(f.price_INR)  as total_revenue
from fact_swiggy_orders f
JOIN dim_dish dd
on f.dish_id = dd.dish_id
group by dd.Dish_Name
order by sum(f.price_INR) desc

-- cuisine performance (order + avg rating)
select top 10  
c.category,
count(*)  as total_orders,
avg(f.rating) as avg_rating
from fact_swiggy_orders f
JOIN dim_category c
on f.category_id = c.category_id
group by c.Category
order by count(*) desc

-- total orders by range 
SELECT
    CASE
        WHEN CONVERT(FLOAT, Price_INR) < 100 THEN 'Under 100'
        WHEN CONVERT(FLOAT, Price_INR) BETWEEN 100 AND 199 THEN '100 - 199'
        WHEN CONVERT(FLOAT, Price_INR) BETWEEN 200 AND 299 THEN '200 - 299'
        WHEN CONVERT(FLOAT, Price_INR) BETWEEN 300 AND 499 THEN '300 - 499'
        ELSE '500+'
    END AS price_range,
    COUNT(*) AS total_orders
FROM fact_swiggy_orders
GROUP BY
    CASE
        WHEN CONVERT(FLOAT, Price_INR) < 100 THEN 'Under 100'
        WHEN CONVERT(FLOAT, Price_INR) BETWEEN 100 AND 199 THEN '100 - 199'
        WHEN CONVERT(FLOAT, Price_INR) BETWEEN 200 AND 299 THEN '200 - 299'
        WHEN CONVERT(FLOAT, Price_INR) BETWEEN 300 AND 499 THEN '300 - 499'
        ELSE '500+'
    END
ORDER BY total_orders DESC;

-- ranting analysis
select 
rating,
count(*) as totalorders
from fact_swiggy_orders
group by rating
order by rating desc
------------------------------------------------------------------
                                   -- my queries 
-- avg_rating >=3 per locationid
select top 10 location_id,avg(rating) as avg_rating
from fact_swiggy_orders
group by location_id 
having avg(rating) >= 3
order by avg(rating) desc

-- running total per month 
select d.Month_Name,f.Price_INR,
sum(f.price_inr) over(order by f.price_inr
rows between unbounded preceding and current row ) as running_total
from fact_swiggy_orders f
JOIN dim_date d
on f.Date_id = d.date_id
order by Price_INR

select r.restaurant_name,count(d.dish_id) as total_dish
from dim_restaurant r
Join dim_dish d
on r.restaurant_id = d.dish_id
group by r.Restaurant_Name
having count(d.dish_id) >1

select * from dim_dish
select * from dim_restaurant