use blinkit;


select count(*) from blinkit_orders;

-- 1 sales Analysis

-- 1)  total revenue of blinkit

select 
	ROUND(sum(grand_total)) as total_revenue
from blinkit_orders;

-- 2) Total blinkit orders

select count(order_id) from blinkit_orders;


-- 3) find Average order value each order 

select 
	ROUND(AVG(grand_total)) AS avg_order_value 
from 
	blinkit_orders;
    
-- 4)  total quantity sold 

select 
	sum(total_qty) as total_quantity
from blinkit_orders;



-- 5) total discount given 

select 
	ROUND(sum(product_discount+promo_discount)) as total_discount
from 
	blinkit_orders;


