-- Creating Database or Blinkit
CREATE DATABASE IF NOT EXISTS blinkit;


-- Using Blinkit 
USE blinkit;


-- Enable local_infile on the Server
SHOW VARIABLES LIKE 'local_infile'; -- ON right now
SET GLOBAL local_infile = 1;


--  Verify it is now ON
SHOW VARIABLES LIKE 'local_infile';

-- Creating Table
CREATE TABLE blinkit_orders (
    order_id                   VARCHAR(20),
    order_timestamp            DATETIME,
    order_date                 DATE,
    order_year                 INT,
    order_month                INT,
    order_month_name           VARCHAR(15),
    order_day_of_week          VARCHAR(15),
    order_hour                 INT,
    user_id                    VARCHAR(15),
    user_tier                  VARCHAR(15),
    store_id                   VARCHAR(10),
    store_city                 VARCHAR(30),
    store_zone                 VARCHAR(15),
    customer_pincode           VARCHAR(10),
    delivery_slot              VARCHAR(20),
    platform                   VARCHAR(15),
    payment_method             VARCHAR(25),
    order_status               VARCHAR(25),
    cancellation_return_reason VARCHAR(50),
    num_items_ordered          INT,
    total_qty                  INT,
    item_names_sample          VARCHAR(255),
    mrp_total                  DECIMAL(10,2),
    product_discount           DECIMAL(10,2),
    subtotal                   DECIMAL(10,2),
    promo_code                 VARCHAR(20),
    promo_discount             DECIMAL(10,2),
    delivery_fee               DECIMAL(6,2),
    tip                        DECIMAL(6,2),
    cashback_earned            DECIMAL(8,2),
    grand_total                DECIMAL(10,2),
    delivery_time_mins         INT NULL,
    order_rating               INT,
    is_first_order             INT,
    is_reorder                 INT,
    is_express_eligible        INT,
    gstn_applied               INT
);


-- Importing blinkit_orders_2022 table

LOAD DATA LOCAL INFILE 'D:/EXCEL PRACTICE/blinkit_sql_project/dataset/blinkit_orders_2026.csv'
INTO TABLE blinkit_orders
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, order_timestamp, order_date, order_year, order_month, order_month_name,
order_day_of_week, order_hour, user_id, user_tier, store_id, store_city, store_zone,
customer_pincode, delivery_slot, platform, payment_method, order_status,
cancellation_return_reason, num_items_ordered, total_qty, item_names_sample,
mrp_total, product_discount, subtotal, promo_code, promo_discount, delivery_fee,
tip, cashback_earned, grand_total, @delivery_time_mins, order_rating,
is_first_order, is_reorder, is_express_eligible, gstn_applied)
SET delivery_time_mins = NULLIF(@delivery_time_mins, '');


-- Validating import of blinkit_orders_2022 table
select count(*) From blinkit_orders;