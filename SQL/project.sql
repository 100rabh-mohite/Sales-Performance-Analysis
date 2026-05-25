create database project;
use project;

select * from sales_dataset;

-- Retrieve total sales per region.
SELECT
    Region,
    SUM(Sales) AS Total_Sales
FROM sales_dataset
GROUP BY Region;


-- Find the top 5 best-selling products.

select Product,sum(sales)as total_sales
from sales_dataset
group by Product
order by total_sales desc
limit 5;


-- Calculate monthly revenue.
select month(OrderDate)as MONTH,
sum(sales)as revenue
from sales_dataset
group by MONTH
order by MONTh;

--  Identify repeat customers.
select CustomerID ,count(OrderID)as total_orders
from sales_dataset
group by CustomerID
having total_orders>1;


-- Find average order value per region.
select Region,avg(sales)as avg_order_value
from sales_dataset 
group by Region;

-- Determine peak sales hour in a day.
select
    HOUR,
    SUM(sales)as total_sales
from sales_dataset
group by HOUR
order by total_sales desc;



-- Rank products by sales within each category.
select Category ,Product
,sum(sales)as total_sales,
rank() over(
            partition by Category
            order by sum(sales) desc
            ) as ranking
from sales_dataset
group by Category,Product;


