-- Request 1

SELECT 
	market, sub_zone 
FROM gdb023.dim_customer
WHERE customer="Atliq Exclusive" AND  region = "APAC"
ORDER BY market;



-- Request 2


WITH unique_product_2020
AS
(
SELECT 
	COUNT(DISTINCT (product_code)) AS unique_product_2020
FROM gdb023.fact_sales_monthly 
WHERE fiscal_year = 2020  
),

unique_product_2021
AS
(
SELECT 
	COUNT(DISTINCT (product_code)) AS unique_product_2021
FROM gdb023.fact_sales_monthly 
WHERE fiscal_year = 2021 
)

SELECT 
	*, ROUND(unique_product_2020/unique_product_2021 * 100, 1) AS percentage_chg
FROM unique_product_2020
CROSS JOIN unique_product_2021;   



-- Request 3


SELECT 
	segment, 
    COUNT(DISTINCT (product_code)) AS product_count
FROM gdb023.dim_product
GROUP BY segment
ORDER BY product_count DESC;



-- Request 4


WITH product_count_2020_cte
AS
(
SELECT 
	p.segment, 
    COUNT(DISTINCT (p.product_code)) AS product_count_2020
FROM gdb023.dim_product p
INNER JOIN gdb023.fact_sales_monthly s
	ON p.product_code = s.product_code
WHERE s.fiscal_year = 2020
GROUP BY segment
 ),
 
 product_count_2021_cte
 AS
 (
SELECT 
	p.segment, 
    COUNT(DISTINCT (p.product_code)) AS product_count_2021
FROM gdb023.dim_product p
INNER JOIN gdb023.fact_sales_monthly s
	ON p.product_code = s.product_code
WHERE s.fiscal_year = 2021
GROUP BY segment
)

SELECT 
	a.segment, 
    a.product_count_2020, 
    b.product_count_2021,
    product_count_2021 - product_count_2020 AS difference
FROM product_count_2020_cte a
INNER JOIN product_count_2021_cte b
	ON a.segment = b.segment
ORDER BY difference DESC;



-- Request 5


SELECT 
	m.product_code, p.product, m.manufacturing_cost
FROM gdb023.fact_manufacturing_cost m
INNER JOIN gdb023.dim_product p
	ON p.product_code = m.product_code
Where manufacturing_cost = (Select max(manufacturing_cost) from fact_manufacturing_cost WHERE cost_year = 2021);


SELECT 
	m.product_code, p.product, m.manufacturing_cost
FROM gdb023.fact_manufacturing_cost m
INNER JOIN gdb023.dim_product p
	ON p.product_code = m.product_code
Where manufacturing_cost = (Select min(manufacturing_cost) from fact_manufacturing_cost WHERE cost_year = 2021);



-- Request 6


SELECT 
	d.customer_code, c.customer, d.fiscal_year, avg(d.pre_invoice_discount_pct) AS average_discount_percentage 
FROM gdb023.fact_pre_invoice_deductions d
INNER JOIN gdb023.dim_customer c
	ON d.customer_code = c.customer_code
WHERE fiscal_year = 2021 AND market = 'India'
GROUP BY d.customer_code, c.customer
ORDER BY average_discount_percentage DESC
LIMIT 5;



-- Request 7


SELECT 
	MONTHNAME(s.date) AS Month, s.fiscal_year AS Year, 
    ROUND(SUM((s.sold_quantity * g.gross_price) / 1000000), 2) AS Gross_sales_Amount
FROM gdb023.fact_sales_monthly s
INNER JOIN gdb023.fact_gross_price g
	ON s.product_code = g.product_code 
	AND s.fiscal_year = g.fiscal_year
INNER JOIN gdb023.dim_customer c
	ON s.customer_code = c.customer_code
WHERE c.customer LIKE '%Atliq Exclusive%'
GROUP BY s.date, s.fiscal_year;



-- Request 8


SELECT 
	QUARTER(date_add(date,  INTERVAL -8 MONTH)) AS Quarter, 
    SUM(sold_quantity) AS total_sold_quantity
FROM gdb023.fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY Quarter 
ORDER BY total_sold_quantity DESC; 



-- Request 9


WITH gross_sales_mln
AS
(
SELECT 
	 c.channel, ROUND(SUM(g.gross_price * s.sold_quantity)/1000000, 2) AS gross_sales_mln
FROM gdb023.fact_gross_price g
INNER JOIN gdb023.fact_sales_monthly s
	ON g.product_code = s.product_code AND g.fiscal_year = s.fiscal_year
INNER JOIN gdb023.dim_customer c
	ON c.customer_code = s.customer_code
WHERE s.fiscal_year = 2021
GROUP BY c.channel
ORDER BY gross_sales_mln DESC
)

SELECT 
	*, 
    gross_sales_mln*100/SUM(gross_sales_mln) OVER () AS percentage
FROM gross_sales_mln
LIMIT 1;



-- Request 10


WITH total_sold_quantity_cte
AS
(
SELECT 
	p.division, p.product_code, p.product, 
    SUM(s.sold_quantity) AS total_sold_quantity  
FROM gdb023.dim_product p
INNER JOIN gdb023.fact_sales_monthly s
	ON p.product_code = s.product_code
WHERE s.fiscal_year = 2021
GROUP BY p.division, p.product_code, p.product
ORDER BY total_sold_quantity DESC
),

rank_order_cte
AS
(
SELECT 
	*,
    DENSE_RANK() over(partition by division order by total_sold_quantity DESC) AS rank_order
FROM total_sold_quantity_cte
)    

SELECT 
	*
FROM rank_order_cte
WHERE rank_order <= 3    

 