--jak zmienia się sprzedaż w czasie dla każdej kategorii

SELECT
    YEAR(f.order_date)  AS sales_year,
    MONTH(f.order_date) AS sales_month,
    p.category,
    SUM(f.sales_amount) AS total_sales,
    SUM(f.quantity)     AS total_quantity
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON f.product_key = p.product_key
GROUP BY
    YEAR(f.order_date),
    MONTH(f.order_date),
    p.category
ORDER BY
    sales_year,
    sales_month,
    total_sales DESC;

--Top 10 klientów według wartości zakupów
SELECT TOP 10
    c.customer_key,
    c.first_name,
    c.last_name,
    c.country,
    SUM(f.sales_amount) AS total_sales,
    COUNT(*)            AS number_of_orders
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON f.customer_key = c.customer_key
GROUP BY
    c.customer_key,
    c.first_name,
    c.last_name,
    c.country
ORDER BY
    total_sales DESC;


--Sprzedaż według kraju i płci klienta
SELECT
    c.country,
    c.gender,
    SUM(f.sales_amount) AS total_sales,
    SUM(f.quantity)     AS total_quantity,
    COUNT(*)            AS number_of_orders
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON f.customer_key = c.customer_key
GROUP BY
    c.country,
    c.gender
ORDER BY
    total_sales DESC;
