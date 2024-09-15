-- B.  Driver and delivery analysis
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