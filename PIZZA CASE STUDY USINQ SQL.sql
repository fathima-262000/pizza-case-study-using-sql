CREATE DATABASE pizza_db;
select * from order_details;  -- order_details_id	order_id	pizza_id	quantity

select * from pizzas -- pizza_id, pizza_type_id, size, price

select * from orders  -- order_id, date, time

select * from pizza_types;  -- pizza_type_id, name, category, ingredients
-- questions
  -- Basic:
  
-- Retrieve the total number of orders placed.

SELECT COUNT(DISTINCT(order_id)) AS total_no_of_orders FROM orders;

-- Calculate the total revenue generated from pizza sales.
-- method 1
select cast(sum(order_details.quantity * pizzas.price) as decimal(10,2)) as 'Total Revenue'
from order_details 
join pizzas on pizzas.pizza_id = order_details.pizza_id

-- method2

CREATE VIEW revenue AS
WITH CTE AS 
(SELECT * FROM pizzas p JOIN order_details o USING(pizza_id)
)
SELECT order_details_id,SUM(quantity*price) AS total_revenue FROM CTE GROUP BY order_details_id;
SELECT ROUND(SUM(total_revenue),2) AS total_revenue FROM revenue;

-- Identify the highest-priced pizza.
-- method 1
SELECT p.pizza_id , pt.name FROM pizzas p JOIN pizza_types pt USING(pizza_type_id) WHERE p.price =
(SELECT MAX(Price) FROM pizzas);

-- method2
select top 1 pizza_types.name as 'Pizza Name', cast(pizzas.price as decimal(10,2)) as 'Price'
from pizzas 
join pizza_types on pizza_types.pizza_type_id = pizzas.pizza_type_id
order by price desc

-- method3
with cte as (
select pizza_types.name as Pizza_Name, cast(pizzas.price as decimal(10,2)) as Price,
rank() over (order by price desc) as rnk
from pizzas
join pizza_types on pizza_types.pizza_type_id = pizzas.pizza_type_id
)
select Pizza_Name, Price from cte where rnk = 1 

-- Identify the most common pizza size ordered.
-- method 1
with cte AS
(SELECT * FROM pizzas JOIN order_details USING(pizza_id))
,cte2 AS
(SELECT size,COUNT(DISTINCT(order_id)) AS total_orders FROM cte GROUP BY(size))
SELECT size,total_orders FROM cte2
ORDER BY total_orders DESC LIMIT 1;

-- method 2
select pizzas.size, count(distinct order_id) as 'No of Orders', sum(quantity) as 'Total Quantity Ordered' 
from order_details
join pizzas on pizzas.pizza_id = order_details.pizza_id
-- join pizza_types on pizza_types.pizza_type_id = pizzas.pizza_type_id
group by pizzas.size
order by count(distinct order_id) desc

-- List the top 5 most ordered pizza types along with their quantities.
-- method 1
WITH CTE AS
(SELECT * FROM pizzas JOIN order_details USING(pizza_id)),
cte2 AS 
(SELECT * FROM CTE JOIN pizza_types USING(pizza_type_id))
SELECT pizza_type_id,name,COUNT(DISTINCT(order_id)) AS total_orders,SUM(quantity) AS total_quantity FROM cte2 GROUP BY pizza_type_id,name ORDER BY total_orders DESC LIMIT 5

-- method2
select  pizza_types.name as Pizza, sum(order_details.quantity) as Total_Ordered
from order_details
join pizzas on pizzas.pizza_id = order_details.pizza_id
join pizza_types on pizza_types.pizza_type_id = pizzas.pizza_type_id
group by pizza_types.name 
order by Total_Ordered desc LIMIT 5

-- Intermediate:
-- Find the total quantity of each pizza category ordered (this will help us to understand the category which customers prefer the most).
-- METHOD 1
WITH cte AS 
(SELECT * FROM pizzas JOIN pizza_types USING(pizza_type_id))
,cte2 AS 
(SELECT * FROM cte c JOIN order_details o USING(pizza_id))
SELECT category ,SUM(quantity) AS total_orders FROM cte2 GROUP BY category ORDER BY total_orders DESC;

-- METHOD2
select pizza_types.category, sum(quantity) as 'Total Quantity Ordered'
from order_details
join pizzas on pizzas.pizza_id = order_details.pizza_id
join pizza_types on pizza_types.pizza_type_id = pizzas.pizza_type_id
group by pizza_types.category 
order by sum(quantity)  desc LIMIT 5

-- Determine the distribution of orders by hour of the day (at which time the orders are maximum (for inventory management and resource allocation).

SELECT HOUR(time) AS hour_of_day ,COUNT(DISTINCT(order_id)) AS total_orders FROM orders GROUP BY hour_of_day ORDER BY total_orders DESC ;


-- Find the category-wise distribution of pizzas (to understand customer behaviour).

SELECT category,COUNT(DISTINCT(pizza_type_id)) AS no_of_types FROM pizza_types GROUP BY category;

-- Group the orders by date and calculate the average number of pizzas ordered per day.


WITH cte AS 
(SELECT * FROM orders o JOIN order_details r USING(order_id))
,cte2 AS 
(SELECT date,SUM(quantity) AS total_no_of_pizzas_ordered FROM cte GROUP BY date)
SELECT AVG(total_no_of_pizzas_ordered) AS avg_no_of_pizzas_ordered_per_day FROM cte2


-- Determine the top 3 most ordered pizza types based on revenue (let's see the revenue wise pizza orders to understand from sales perspective which pizza is the best selling)

WITH cte AS
(SELECT * FROM pizzas JOIN pizza_types USING(pizza_type_id)
JOIN order_details USING(pizza_id)),
cte2 AS
(SELECT pizza_type_id,name,(price*quantity) AS revenue FROM cte)
SELECT pizza_type_id,name,SUM(revenue) AS total_revenue FROM cte2 GROUP BY pizza_type_id,name ORDER BY total_revenue DESC LIMIT 3

Advanced:
-- Calculate the percentage contribution of each pizza type to total revenue (to understand % of contribution of each pizza in the total revenue)

CREATE VIEW pizza_types_revenue AS 
(
WITH cte AS
(SELECT * FROM pizzas JOIN pizza_types USING(pizza_type_id)
JOIN order_details USING(pizza_id)),
cte2 AS
(SELECT pizza_type_id,name,(price*quantity) AS revenue FROM cte)
SELECT pizza_type_id,name,SUM(revenue) AS total_revenue FROM cte2 GROUP BY pizza_type_id,name ORDER BY total_revenue
);

SELECT name,CONCAT(CAST((total_revenue/(SELECT SUM(total_revenue)AS grand_total FROM pizza_types_revenue)*100) AS DECIMAL(10,2)),'%') AS percentage_revenue 
FROM pizza_types_revenue ORDER BY percentage_revenue DESC



-- Analyze the cumulative revenue generated over time.


WITH cte AS
(SELECT o.date,CAST(SUM(p.price*ol.quantity)AS DECIMAL(10,2)) AS revenue FROM 
pizzas p JOIN
pizza_types pt USING(pizza_type_id) JOIN
order_details ol USING(pizza_id) JOIN
orders o USING(order_id) GROUP BY date)

SELECT date,revenue,SUM(revenue) OVER(ORDER BY date )AS cum_revenue FROM cte 


/*select * from order_details;  -- order_details_id	order_id	pizza_id	quantity

select * from pizzas -- pizza_id, pizza_type_id, size, price

select * from orders  -- order_id, date, time

select * from pizza_types;  -- pizza_type_id, name, category, ingredients*/


Determine the top 3 most ordered pizza types based on revenue for each pizza category (In each category which pizza is the most selling)*/


with cte AS
(SELECT pt.category,pt.name,CAST((ot.quantity*p.price) AS DECIMAL(10,2)) AS revenue FROM pizzas p JOIN
 pizza_types pt USING(pizza_type_id) JOIN
 order_details ot USING(pizza_id)   JOIN
 orders o USING(order_id))
 ,cte2 AS 
(SELECT category,name, revenue,DENSE_RANK() OVER(PARTITION BY category ORDER BY revenue DESC) AS revenue_rank FROM cte)

SELECT category,name,revenue,revenue_rank FROM cte2 WHERE revenue_rank in (1,2,3) ORDER BY category,revenue_rank



