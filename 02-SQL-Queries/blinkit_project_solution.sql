use blinkit;

CREATE INDEX idex_user_id ON blinkit_orders(user_id);
CREATE INDEX idx_order_date ON blinkit_orders(order_date);
CREATE INDEX idx_order_year ON blinkit_orders(order_year);
CREATE INDEX idx_store_city ON blinkit_orders(store_city);
CREATE INDEX idx_user_tier ON blinkit_orders(user_tier);
CREATE INDEX idx_status ON blinkit_orders(order_status);
CREATE INDEX idx_payment ON blinkit_orders(payment_method);

-------------------------------- BLINKIT PROJECT KPI ---------------------------------------------------------
select * from blinkit_orders;

-- total revenue
select concat(Round(sum(grand_total)/10000000,2),"Cr") as total_revenue from blinkit_orders;

-- 1)TOTAL GMV (TOTAL REVENUE)(Gross Merchandise Volume)
-- GMV (Gross Merchandise Value) is the total value of all products sold through the platform before any discounts, returns, cancellations, taxes, or additional charges are considered.

select 
	CONCAT("₹",
    ROUND(sum(mrp_total)/10000000),
    " Cr") as TOTAL_GMV 
from blinkit_orders;	

-- toal gmv = 469Cr

-- TOTAL NO OF ORDER

select 
	count(*) as total_order 
	from blinkit_orders;
    
-- output - 3.8 million order


--  2)  TOTAL UNIQUE CUSTOMER

select 
	count(distinct user_id) as unique_customer
from 
	blinkit_orders;
    
-- output total active customer - 7,43,772
    

-- 3) Average order values

select 
	concat("₹ ",ROUND(AVG(grand_total),2)) AS avg_order_value 
from 
	blinkit_orders;
    
-- Average_order_value - ₹ 1016.70

    
    
-- 4) Average Rating

SELECT 
	AVG(order_rating) as Average_rating
FROM 
	blinkit_orders;
    
-- Average rating - 4.25
    
-- 5)Average delivery time 

select 
	concat(ROUND(AVG(delivery_time_mins),2)," min") as avg_delivery_time
from 
	blinkit_orders;
    
-- Average delivery time - 18.99 min
    
    
-- 6) Cancellation rate

select 
	order_status,
    count(*)  as count,
    concat(ROUND(count(*)*100/(select count(*) from blinkit_orders),2)," %") AS Percantage
from 
	blinkit_orders
where order_status in ("Cancelled","Returen")
group by order_status;

-- Cancellation rate - 1.87 %



-- 7) cancellation reason 

select 
	cancellation_return_reason,
    count(*) as count
from 
	blinkit_orders
group by cancellation_return_reason
order by count desc;


select 
	distinct order_status,
    cancellation_return_reason,
    count(*) as count
from 
	blinkit_orders
where NOT order_status in ("Delivered","Partially Delivered")
group by order_status,cancellation_return_reason
order by count desc;





    
    
    
    

-- Section 1: Data Sanity & Overview (Warm-up)
select count(*) from blinkit_orders;

-- 1) Q1. How many total orders are in our dataset, and what is the date range covered? 

create index idex_order_id
on blinkit_orders(order_id);

select 
	count(*) as order_count,
	min(order_date) start_date,
    max(order_date) end_date
from blinkit_orders;


-- 2) Q2. What is the total GMV (revenue) year-wise, and how has it grown each year? 	
create view total_gmv as
WITH yearly_gmv AS (
    SELECT
        order_year,
        ROUND(SUM(mrp_total)/10000000,2) AS gmv
    FROM blinkit_orders
    GROUP BY order_year
)
SELECT
    order_year,
    concat("₹",gmv,"Cr"),
    concat("₹",LAG(gmv) OVER (ORDER BY order_year),"Cr") AS previous_year_gmv,
    concat(ROUND(
        ((gmv - LAG(gmv) OVER (ORDER BY order_year))
        / LAG(gmv) OVER (ORDER BY order_year)) * 100,
        2
    ),"%") AS yoy_growth_percent
FROM yearly_gmv
ORDER BY order_year;
    


-- 3) Q3. What is the overall order status split (Delivered, Cancelled, Returned, Partial), and how is our delivery success rate trending each year? 

-- query 1
create view order_status as
select 
	order_status,
    count(*) as orders,
    concat(ROUND(count(*)*100/sum(count(*)) over(),2),"%") AS Percantage
from 
	blinkit_orders
group by order_status;

-- query 2

select 
	order_year,
    sum(case
		when order_status="Delivered" then 1
        else 0
	end) as delivered_rate,
    Round(sum(
		case  
			when order_status="Delivered" then 1
            else 0
		end)*100/count(*)
        ) as delivered_sucess_rate
from 
	blinkit_orders
group by order_year
order by order_year;


-- 4) . Which top 5 cities contribute the most to our total GMV, and what is their share in percentage?

CREATE INDEX idx_store_city_gmv ON blinkit_orders(store_city,mrp_total);

with city_gmv as
(
select 
	store_city,
    round(SUM(mrp_total),2) as revenue
from 
	blinkit_orders
group by store_city
)
select 
	store_city,
    revenue,
    CONCAT(ROUND(revenue*100/sum(revenue) over(),2)," %") as Percantage
from 
	city_gmv
order by revenue desc
limit 5;
 


-- 5) Which dark stores are the top 10 performers by revenue, and which are the bottom 10 (underperformers)? 

CREATE INDEX idx_store_id_revenue ON blinkit_orders(store_id,grand_total);
 -- top performers dark store id
 (
select 
	'Top 10' as category_1,
	store_city,
    concat("₹",sum(grand_total)/10000000,2) as total_revenue
from 
	blinkit_orders
group by store_city
order by sum(grand_total) desc
limit 10
)
union
(
select 
	'Bottom 10' as category_2,
	store_city,
    concat("₹",ROUND(sum(grand_total)/10000000,2),"Cr")as total_revenue
from 
	blinkit_orders
group by store_city
order by sum(grand_total) asc
limit 10
);


-- Q6. Which pincode areas have the highest order volume, and what is the average order value there?

CREATE INDEX idx_pincode on blinkit_orders(customer_pincode,order_id,grand_total);
select
	customer_pincode,
    count(order_id) as highest_order_volume,
    ROUND(avg(grand_total),2) as avg_order_value
from 
	blinkit_orders
group by customer_pincode
order by count(order_id) desc;


-- Q7. What are the peak hours of the day for orders, and how does the pattern differ on weekdays vs weekends? 


select 
	order_hour as hours,
    COUNT(order_id) as total_order
from 
	blinkit_orders
group by order_hour
order by total_order desc
limit 5;

-- query 2

select 
	case 
		when order_day_of_week  in ('Saturday','Sunday')
        then 'Weekend'
        ELSE 'Weekdays'
	end AS day_type,
    order_hour,
    count(*)  as total_hour
from 
	blinkit_orders
group by day_type,order_hour
order by day_type,order_hour;


-- 8) Which month of the year gives us the highest GMV, and which festive months show clear spikes?

SELECT
	order_year,
    order_month_name,
    concat("₹",ROUND(SUM(grand_total)/10000000, 2),"Cr") AS total_gmv
FROM blinkit_orders
GROUP BY order_year,order_month_name
ORDER BY order_year,order_month_name asc;

-- Q9. What is the weekend effect — how much more do we sell on Fri-Sat-Sun compared to Mon-Thu?
with weekend_effect as
(
select 
	case
		when order_day_of_week in ('Friday','Saturday','Sunday')
             then 'Weekend'
        else 'Weekday'
        end as day_group,
        sum(mrp_total) as revenue
from 
	blinkit_orders
group by day_group
)
select 
	day_group,
    concat("₹",ROUND(round(revenue)/10000000),"Cr") as total_revenue,
    ROUND(revenue*100/sum(revenue) over (),2) as revenue_percantage
from 
	weekend_effect;
    
-- 10) What is the payment method mix (UPI, COD, Card, etc.), and how has UPI adoption grown over the years? 
-- query 1
select 
	payment_method,
    concat("₹",ROUND(sum(grand_total)/10000000),"Cr") as total_revenue
from 
	blinkit_orders
group by payment_method
order by total_revenue desc;

-- query 2
with yoy_upi_adoption as
(
select 
	order_year,
    count(*) as total_order,
    sum(case 
		when payment_method="UPI"
        then 1
        else 0
	end) as total_upi_transaction
from 
	blinkit_orders
group by order_year
order by order_year
)
select 
	order_year,
    total_upi_transaction,
    lag(total_upi_transaction) over (order by order_year) as previous_upi,
    concat(ROUND(
        total_upi_transaction -
        LAG(total_upi_transaction) OVER (ORDER BY order_year),
        2
    )) AS growth_upi
    
from 
	yoy_upi_adoption;
    


-- 11)  Which delivery slot is most popular (10-min Express, Turbo, Scheduled), and what is the average delivery time per slot?
		
select 
	delivery_slot,
    count(*) as delivery_count,
    avg(delivery_time_mins) as avg_delivery_time
from 
	blinkit_orders
group by delivery_slot
order by avg(delivery_time_mins) desc;

-- 12) What is the platform split between Android, iOS, and Web, and which platform users spend more per order?
select 
	platform,
    count(*) as orders,
    CONCAT("₹",round(sum(grand_total)/10000000,2),"Cr") as total_revenue,
    ROUND(avg(grand_total),2) as avg_order_value
from blinkit_orders
group by platform
order by total_revenue desc;


-- 13) How do the four user tiers (Bronze, Silver, Gold, Platinum) compare in terms of average order value, order frequency, and cancellation rate?

select 
	user_tier,
    count(*) as total_order,
    ROUND(count(*)/count(distinct user_id),2)as order_frequency,
    ROUND(avg(grand_total),2) as avg_order_value,
   concat(ROUND(
        SUM(CASE
                WHEN order_status = 'Cancelled' THEN 1
                ELSE 0
            END) * 100.0 / COUNT(*),
        2)," %") AS cancellation_rate
from
	blinkit_orders
group by user_tier
order by avg_order_value desc;


-- 14)  What percentage of our orders are from repeat customers vs first-time customers, and how has this changed year-on-year?

select
	order_year,
    count(*) as orders,
	sum(case when is_first_order=1 then 1 else 0 end) as first_time_order,
    sum(case when is_reorder=1 then 1 else 0 end) as repeat_order,
    concat(round(sum(case when is_first_order=1 then 1 else 0 end)*100/count(*),2),"%") as first_time_order_percentage,
	concat(round(sum(case when is_reorder=1 then 1 else 0 end)*100/count(*),2),"%") as repeat_order_percentage
from 
	blinkit_orders
group by order_year;



-- 15) Who are our top 20 customers by lifetime GMV, and which cities/tiers do they belong to?
select 
	user_id,
    sum(mrp_total) as lifetime_gmv
from 
	blinkit_orders
group by user_id
order by sum(mrp_total) desc
limit 20;

SELECT 
    user_id,
    MAX(user_tier) AS user_tier,
    MAX(store_city) AS customer_city,
    SUM(grand_total) AS lifetime_gmv,
    COUNT(order_id) AS total_orders
FROM 
    blinkit_orders 
GROUP BY 
    user_id
ORDER BY 
    lifetime_gmv DESC
LIMIT 20;



-- 16) Which promo codes are used most, and what is the average discount given per code? 

select 
	promo_code,
    count(*) as count,
    ROUND(avg(promo_discount),2) as avg_discount
from 
	blinkit_orders
where promo_code is not null
group by promo_code
order by count desc
limit 22 offset 1;


-- 17) What percentage of our GMV is being lost to promo discounts and cashback, broken down by user tier? 
select * from blinkit_orders;

SELECT
    user_tier,
    concat("₹",ROUND(SUM(mrp_total)/10000000, 2),"Cr")AS total_gmv,
    concat("₹",ROUND(SUM(promo_discount + cashback_earned)/10000000, 2),"Cr") AS Promo_cashback,
    concat("₹",ROUND(
        (SUM(promo_discount + cashback_earned) * 100.0) /
        SUM(mrp_total),
        2
    ),"%") AS loss_percentage
FROM blinkit_orders
GROUP BY user_tier
ORDER BY loss_percentage DESC;




-- 18) What are the top 5 reasons for cancellation and return, and which cities have the highest cancellation rates?

-- query 1

SELECT
    cancellation_return_reason,
    COUNT(order_status) AS total_orders,
    concat(ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2)," %") AS percentage
FROM blinkit_orders
WHERE order_status IN ('Cancelled', 'Returned')
  AND cancellation_return_reason IS NOT NULL
GROUP BY cancellation_return_reason
ORDER BY percentage DESC
LIMIT 5;

-- query 2

select * from blinkit_orders;

select 
	store_city,
    count(*) as cancellation_count,
	concat(ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2)," %") AS Cancelled_rate
from 
	blinkit_orders
where order_status in ("Cancelled","Returned")
group by store_city
order by count(*) desc;



-- 19)   What is the average delivery time by city and delivery slot, and which stores consistently deliver faster or slower than average?
	
-- query 1 

SELECT
    store_city,
    delivery_slot,
    ROUND(AVG(delivery_time_mins),2) AS avg_delivery_time
FROM blinkit_orders
WHERE order_status = 'Delivered'
GROUP BY
    store_city,
    delivery_slot
ORDER BY
    avg_delivery_time;

-- query 2   which stores consistently deliver faster or slower than average?

--  Average_Delivery-Time = 18.98 sec

with delivery_fast_slow as
(
select 	
	store_city,
    AVG(delivery_time_mins) AS  Avg_delivery_time
from 
	blinkit_orders
where order_status="Delivered"
group by store_city
)
select 
	store_city,
	Avg_delivery_time,
    (case
		when Avg_delivery_time<(
			select avg(delivery_time_mins) from blinkit_orders
            where order_status="Delivered"
            )
		then 'Fast delivery'
        else 'Slow delivery'
        end) as Performation
from delivery_fast_slow
order by Avg_delivery_time asc;

    
    
-- 20) What is the month-over-month GMV growth, and can we identify any month where growth stalled or reversed — and why (linked to cancellations, low promos, or city issues)?

-- Calculate Monthly GMV and MoM Growth
WITH monthly_gmv AS (
    SELECT
        order_year,
        order_month,
        order_month_name,
        SUM(mrp_total) AS total_gmv
    FROM blinkit_orders
    GROUP BY order_year, order_month,order_month_name
)

SELECT
    order_year,
    order_month,order_month_name,
    ROUND(total_gmv,2) AS total_gmv,
    ROUND(
        (total_gmv - LAG(total_gmv) OVER(ORDER BY order_year, order_month))
        *100/
        LAG(total_gmv) OVER(ORDER BY order_year, order_month)
    ,2) AS mom_growth_percentage
FROM monthly_gmv
ORDER BY order_year, order_month;

-- check cancellation rate
SELECT
    order_year,
    order_month,
    COUNT(*) total_orders,
    SUM(CASE
            WHEN order_status='Cancelled'
            THEN 1
            ELSE 0
        END) cancelled_orders,
    ROUND(
        SUM(CASE
                WHEN order_status='Cancelled'
                THEN 1
                ELSE 0
            END)*100/COUNT(*)
    ,2) cancellation_rate
FROM blinkit_orders
GROUP BY order_year,order_month
ORDER BY order_year,order_month;

-- B. Promo Discounts

SELECT
    order_year,
    order_month,
    ROUND(SUM(promo_discount),2) AS total_promo_discount,
    ROUND(AVG(promo_discount),2) AS avg_promo_discount
FROM blinkit_orders
GROUP BY order_year,order_month
ORDER BY order_year,order_month;


-- Check Which City Dropped
SELECT
    order_year,
    order_month,
    store_city,
    ROUND(SUM(mrp_total),2) city_gmv
FROM blinkit_orders
GROUP BY
    order_year,
    order_month,
    store_city
ORDER BY
    order_year,
    order_month,
    city_gmv DESC;
    
    
    
-- differnt between total gmv and total revenue  by compare both
SELECT
    concat("₹",ROUND(SUM(mrp_total)/10000000,2),"Cr") AS total_gmv,
    concat("₹",ROUND(SUM(grand_total)/10000000,2),"Cr") AS total_revenue,
    concat("₹",ROUND(SUM(mrp_total)-SUM(grand_total),2)/10000000,"Cr") AS difference
FROM blinkit_orders;


-- cancellation rate

select 
	order_status,
    concat("₹",Round(sum(mrp_total)/10000000),"Cr") as total_gmv,
    concat("₹",Round(sum(grand_total)/10000000),"Cr") as total_revenue,
    concat("₹",ROUND(SUM(mrp_total)-SUM(grand_total)/10000000,2),"Cr") AS revenue_loss,
    concat(ROUND(count(*)*100/sum(count(*)) over(),2),"%") AS Percantage
from 
	blinkit_orders
group by order_status;



select * from blinkit_orders;
