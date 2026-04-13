--jak zmienia się sprzedaż w czasie dla każdej kategorii

select
    year(f.order_date)  as sales_year,
    month(f.order_date) as sales_month,
    p.category,
    sum(f.sales_amount) as total_sales,
    sum(f.quantity)     as total_quantity
from gold.fact_sales f
left join gold.dim_products p
on f.product_key = p.product_key
group by
    year(f.order_date),
    month(f.order_date),
    p.category
order by
    sales_year,
    sales_month,
    total_sales desc;

--top 10 klientów według wartości zakupów
select top 10
    c.customer_key,
    c.first_name,
    c.last_name,
    c.country,
    sum(f.sales_amount) as total_sales,
    count(*)            as number_of_orders
from gold.fact_sales f
left join gold.dim_customers c
on f.customer_key = c.customer_key
group by
    c.customer_key,
    c.first_name,
    c.last_name,
    c.country
order by
    total_sales desc;


--sprzedaż według kraju i płci klienta
select
    c.country,
    c.gender,
    sum(f.sales_amount) as total_sales,
    sum(f.quantity)     as total_quantity,
    count(*)            as number_of_orders
from gold.fact_sales f
left join gold.dim_customers c
    on f.customer_key = c.customer_key
group by
    c.country,
    c.gender
order by
    total_sales desc;
