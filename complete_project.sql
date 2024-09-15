create database fasoos;
use fasoos;
drop table if exists driver;
CREATE TABLE driver(driver_id integer,reg_date date); 

INSERT INTO driver(driver_id,reg_date) 
 VALUES (1,'2021-01-01'),
(2,'2021-03-01'),
(3,'2021-08-01'),
(4,'2021-01-15');


drop table if exists ingredients;
CREATE TABLE ingredients(ingredients_id integer,ingredients_name varchar(60)); 

INSERT INTO ingredients(ingredients_id ,ingredients_name) 
 VALUES (1,'BBQ Chicken'),
(2,'Chilli Sauce'),
(3,'Chicken'),
(4,'Cheese'),
(5,'Kebab'),
(6,'Mushrooms'),
(7,'Onions'),
(8,'Egg'),
(9,'Peppers'),
(10,'schezwan sauce'),
(11,'Tomatoes'),
(12,'Tomato Sauce');

drop table if exists rolls;
CREATE TABLE rolls(roll_id integer,roll_name varchar(30)); 

INSERT INTO rolls(roll_id ,roll_name) 
 VALUES (1	,'Non Veg Roll'),
(2	,'Veg Roll');

drop table if exists rolls_recipes;
CREATE TABLE rolls_recipes(roll_id integer,ingredients varchar(24)); 

INSERT INTO rolls_recipes(roll_id ,ingredients) 
 VALUES (1,'1,2,3,4,5,6,8,10'),
(2,'4,6,7,9,11,12');

drop table if exists driver_order;
CREATE TABLE driver_order(order_id integer,driver_id integer,pickup_time datetime,distance VARCHAR(7),duration VARCHAR(10),cancellation VARCHAR(23));
INSERT INTO driver_order(order_id,driver_id,pickup_time,distance,duration,cancellation) 
 VALUES(1,1,'2021-01-01 18:15:34','20km','32 minutes',''),
(2,1,'2021-01-01 19:10:54','20km','27 minutes',''),
(3,1,'2021-02-02 00:12:37','13.4km','20 mins','NaN'),
(4,2,'2021-04-01 13:53:03','23.4','40','NaN'),
(5,3,'2021-08-01 21:10:57','10','15','NaN'),
(6,3,null,null,null,'Cancellation'),
(7,2,'2021-08-01 21:30:45','25km','25mins',null),
(8,2,'2021-09-02 00:15:02','23.4 km','15 minute',null),
(9,2,null,null,null,'Customer Cancellation'),
(10,1,'2021-11-01 18:50:20','10km','10minutes',null);


drop table if exists customer_orders;
CREATE TABLE customer_orders(order_id integer,customer_id integer,roll_id integer,not_include_items VARCHAR(4),extra_items_included VARCHAR(4),order_date datetime);
INSERT INTO customer_orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date)
values (1,101,1,'','','2021-01-01 18:05:02'),
(2,101,1,'','','2021-01-01 19:00:52'),
(3,102,1,'','','2021-02-01 23:51:23'),
(3,102,2,'','NaN','2021-02-01 23:51:23'),
(4,103,1,'4','','2021-04-01 13:23:46'),
(4,103,1,'4','','2021-04-01 13:23:46'),
(4,103,2,'4','','2021-04-01 13:23:46'),
(5,104,1,null,'1','2021-08-01 21:00:29'),
(6,101,2,null,null,'2021-08-01 21:03:13'),
(7,105,2,null,'1','2021-08-01 21:20:29'),
(8,102,1,null,null,'2021-09-01 23:54:33'),
(9,103,1,'4','1,5','2021-10-01 11:22:59'),
(10,104,1,null,null,'2021-11-01 18:34:49'),
(10,104,1,'2,6','1,4','2021-11-01 18:34:49');

select * from customer_orders;
select * from driver_order;
select * from ingredients;
select * from driver;
select * from rolls;
select * from rolls_recipes;

-- A. Role Metrics

-- 1.how many rolls were ordered
select count(roll_id) FROM customer_orders;

-- 2. how many unique customers
SELECT count(DISTINCT customer_id) from customer_orders;

-- 3. how many successful orders were delivered by each driver
 SELECT driver_id, count(distinct order_id) from driver_order where cancellation not in ('cancellation', 'customer cancellation')  group by driver_id;

-- 4. how many each type of roll was delivered
SELECT roll_id,count(roll_id) from customer_orders where order_id in(

SELECT order_id from
(select * , case when cancellation in('cancellation', 'customer cancellation') then 'c' else'nc' end as order_cancel_details from driver_order) a
where order_cancel_details='nc')
group by roll_id;

-- 5. how many veg and non veg rolls were ordered by customers
select a.*, b.roll_name from
(select customer_id, roll_id,count(roll_id) count from customer_orders
GROUP BY customer_id, roll_id) a inner join rolls b on a.roll_id=b.roll_id;
 
 
 -- 6. What was the maximum number of rolls delivered in single order
 select order_id,(count(roll_id))from (
 select * from customer_orders where order_id in(
 
 SELECT order_id from
(select * , case when cancellation in('cancellation', 'customer cancellation') then 'c' else'nc' end as order_cancel_details from driver_order) a
where order_cancel_details='nc') )b
GROUP BY order_id;

-- 7. For each customer, how many delivered roll has at least one change and how many had no changes

with temp_customer_orders(order_id ,customer_id ,roll_id ,not_include_items ,extra_items_included ,order_date ) as
(
	select order_id ,customer_id ,roll_id,
    case when not_include_items is null or not_include_items=''then '0' 
    else not_include_items end
    new_not_include_items,case when extra_items_included is null or extra_items_included='' or
    extra_items_included='NaN' then '0' else extra_items_included end extra_items_included,
    order_date from customer_orders
)
,
 temp_driver_orders(order_id,driver_id,pickup_time,distance,duration,new_cancellation) as
(
select order_id,driver_id,pickup_time,distance,duration,
case when cancellation in ('Cancellation', 'Customer Cancellation') then 0 else 1 end as new_cancellation
from driver_order
)
select customer_id, change_no_change, count(order_id) as number_of_orders from(
select * ,case when not_include_items='0' and extra_items_included='0' then 'no change' else 'change' end change_no_change 
from temp_customer_orders WHERE order_id
 in(SELECT order_id from temp_driver_orders where new_cancellation !=0)
 ) t
 GROUP BY customer_id, change_no_change
 ORDER BY customer_id;
 
 -- 8. How many rolls were delivered that both exclusions and extras
 
 with temp_customer_orders(order_id ,customer_id ,roll_id ,not_include_items ,extra_items_included ,order_date ) as
 (
	SELECT order_id ,customer_id ,roll_id,
    case when not_include_items is null or not_include_items=''then '0' 
    else not_include_items end new_not_include_items,
    case when extra_items_included is null or extra_items_included='' or extra_items_included='NaN' then '0' 
    else extra_items_included end new_extra_items_included,
      order_date from customer_orders
)
,
 temp_driver_orders(order_id,driver_id,pickup_time,distance,duration,new_cancellation) as
(SELECT order_id,driver_id,pickup_time,distance,duration,
 case when cancellation in ('Cancellation', 'Customer Cancellation') then 0 else 1 end as new_cancellation
from driver_order
) 
SELECT * from temp_customer_orders WHERE not_include_items !=0 and extra_items_included !=0 and order_id
IN
(SELECT order_id from temp_driver_orders where new_cancellation !=0);


-- 9 total number of orders ordered for each hour of day
SELECT concat(cast(hour(ORDER_DATE)AS CHAR),"-",cast(hour(ORDER_DATE)+1 AS CHAR)) hours, count(roll_id) AS Roll_Ordered
FROM customer_orders
GROUP BY hours 
ORDER BY hours ;

-- 10. WHAT WAS THE NUMBER OF ORDER FOR EACH DAY OF THE WEEK 
select dayname(order_date) as day, count(roll_id) as rolls_ordered
from customer_orders
group by dayname(order_date);

-- B.  Driver and Customer Experience
-- 1. WHAT WAS THE AVERAGE TIME AVERAGE TIME IN MINUTE IT TOOK FOR EACH DRIVER TO ARRIVE AT THE FASSOS HEADQUATER TO PICK THE ORDER
SELECT 
     round( avg (timestampdiff(MINUTE, c.order_date, d.pickup_time)),2) AS avg_time, 
       d.driver_id
FROM customer_orders c
JOIN driver_order d ON c.order_id = d.order_id
WHERE d.pickup_time IS NOT NULL
GROUP BY d.driver_id;

-- 2 IS THERE ANY RELATIONSHIP BETWEEN THE NUMBER OF ROLLS AND HOW LONG THE ORDER TAKES TO PREPARE

SELECT 
     round( avg (timestampdiff(MINUTE, c.order_date, d.pickup_time)),2) AS avg_time, 
       c.roll_id
FROM customer_orders c
JOIN driver_order d ON c.order_id = d.order_id
WHERE d.pickup_time IS NOT NULL
GROUP BY  c.roll_id;

WITH TABLE1(MINUTE_DIFF,driver_id,roll_id,order_id,customer_id) AS
(SELECT TIMESTAMPDIFF(MINUTE,TIME(C.Order_Date) ,TIME(D.Pickup_time)) AS MINUTE_DIFF,driver_id,C.roll_id,C.order_id,C.customer_id
FROM customer_orders C
JOIN driver_order D
ON C.order_id=D.order_id
WHERE D.pickup_time IS NOT NULL)

SELECT  order_id, COUNT(roll_id) COUNT_ROLL ,round(SUM(MINUTE_DIFF)/COUNT(roll_id),0) AS TIME_TAKEN from
(SELECT roll_id,Order_id,customer_id,MINUTE_DIFF
FROM TABLE1) final 
GROUP BY  order_id;

-- 3. WHAT WAS THE AVERAGE DISTANCE TRAVEL FOR EACH CUSTOMER 
select * from customer_orders;
select * from driver_order;

select c.customer_id ,round(avg(d.distance),2) from customer_orders c
join driver_order d
on c.order_id=d.order_id
GROUP BY c.customer_id;

-- 4. What was the longest and shortest deilivery times for all orders?
select max(cleaned_duration),min(cleaned_duration) from
(select *, case when duration LIKE '%minutes%' OR duration LIKE '%mins%' or duration like '%minute%' then substring(duration,1,2) 
else duration end as cleaned_duration
 from driver_order
where duration is not null) d;

-- 5.WHAT WAS THE AVERAGE SPEED FOR EACH DRIVER FOR EACH DEILIVERY AND DO YOU NOTICE ANY TREND FOR THIS VALUES
select driver_id, roll_id, concat(round(avg((cleaned_distance/cleaned_duration)*60),2), ' km/hr') as speed from
(select *, case when duration LIKE '%minutes%' OR duration LIKE '%mins%' or duration like '%minute%' then substring(duration,1,2) 
else duration end as cleaned_duration,
case when distance LIKE '%km%' then substring(distance,1,2) else distance end as cleaned_distance
 from driver_order
 where duration is not null) d
 join customer_orders c
 on c.order_id=d.order_id
 GROUP BY driver_id, roll_id;
 
 -- 6. WHAT IS THE SUCCESSFUL PERCENTAGE FOR EACH DRIVER
 SELECT driver_id,(round(SUM(PERCEN)/COUNT(DRIVER_ID),2)*100) AS SUCCESSFUL_DELIVERY_PERCENTAGE
FROM 
(SELECT driver_id,
CASE WHEN Cancellation LIKE '%Cancel%' THEN 0
ELSE 1 END AS PERCEN
FROM driver_order) FINAL
GROUP BY driver_id;