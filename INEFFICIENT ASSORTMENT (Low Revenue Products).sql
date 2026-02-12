					
					----- INEFFICIENT ASSORTMENT (Low Revenue Products) -----
-- TASK: Find "dead" products that take up shelf space but barely sell and bring no money.


-- There is a sales table with columns:
-- transaction_date DATE, product_name TEXT, quantity INT, price NUMERIC, revenue NUMERIC


-- ABC Analysis — dividing products into groups:
-- A — top products (75% of revenue)
-- B — medium (20% of revenue)
-- C — weak (5% of revenue)


-- SQL Query for ABC Analysis

CREATE MATERIALIZED VIEW dm_inefficient_assortment AS
-- Finding total revenue per product for the last 6 months
WITH sales_summary AS (
  SELECT 
    product_name,
    SUM(quantity) AS units_sold,
    SUM(revenue) AS total_revenue,
    COUNT(DISTINCT transaction_date) AS days_sold
  FROM sales
  WHERE transaction_date >= CURRENT_DATE - INTERVAL '6 months'
  GROUP BY product_name
),
-- Finding what percentage of total revenue each product brings
revenue_share AS (
  SELECT 
    product_name,
    units_sold,
    total_revenue,
    days_sold,
    -- Percentage of ALL sales
    total_revenue * 100.0 / SUM(total_revenue) OVER() AS revenue_percent,
    -- Cumulative percentage (running total)
    SUM(total_revenue * 100.0 / SUM(total_revenue) OVER()) 
      OVER(ORDER BY total_revenue DESC) AS cumulative_percent
  FROM sales_summary
)
-- Assigning categories: A, B, C
SELECT 
  product_name,
  units_sold,
  total_revenue,
  ROUND(revenue_percent, 2) AS revenue_percent,
  ROUND(cumulative_percent, 2) AS cumulative_percent,
  CASE 
    WHEN cumulative_percent <= 75 THEN 'A - TOP'
    WHEN cumulative_percent <= 95 THEN 'B - Medium'
    ELSE 'C - Remove from assortment'
  END AS category
FROM revenue_share
ORDER BY total_revenue DESC;

-- CONCLUSION: Category C products can be removed!