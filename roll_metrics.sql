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