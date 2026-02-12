					
					----- WASTE/SHRINKAGE LOSSES (Demand Forecasting) -----
-- TASK: Understand how much product to order so there is no excess. Otherwise, it is going spoil.


-- STEP 1: Analysis of average sales by day of week
-- Imagine Doughnut sells differently on different days of the week
CREATE MATERIALIZED VIEW dm_avg_sales_dow AS 
SELECT 
  CASE EXTRACT(DOW FROM sale_date)
    WHEN 0 THEN 'Sunday'
    WHEN 1 THEN 'Monday'
    WHEN 2 THEN 'Tuesday'
    WHEN 3 THEN 'Wednesday'
    WHEN 4 THEN 'Thursday'
    WHEN 5 THEN 'Friday'
    WHEN 6 THEN 'Saturday' END AS day_name,
  AVG(quantity) AS average_sales,
  MIN(quantity) AS minimum_sold,
  MAX(quantity) AS maximum_sold
FROM sales
WHERE product_name = 'Doughnut'
  AND sale_date >= CURRENT_DATE - INTERVAL '3 months'
GROUP BY day_of_week
ORDER BY day_of_week;


-- STEP 2: Find products with high waste

-- Finding sum of sales quantity and sum of waste quantity not to calculate them over and over
CREATE MATERIALIZED VIEW high_waste_products AS 
WITH sales_quantity_sum AS (
	SELECT p.product_id,
		SUM(s.quantity) AS sold  -- How much was sold
	FROM products AS p
	LEFT JOIN sales AS s
		ON p.product_id = s.product_id
	GROUP BY p.product_id
),
waste_quantity_sum AS (
	SELECT p.product_id,
		SUM(w.waste_quantity) AS wasted -- How much was wasted
	FROM products p
	LEFT JOIN waste w
		ON p.product_id = w.product_id
	GROUP BY p.product_id
)
-- Finding what spoils most often (top 20 products)
SELECT 
  p.product_name,
  p.category,
  p.shelf_life_days,  
  sqs.sold,   -- How much was sold
  wqs.wasted,   -- How much was wasted
  ROUND(wqs.wasted * 100.0 / (sqs.sold + wqs.wasted), 2) AS waste_percent,   -- Waste percentage
  SUM(w.waste_quantity * p.cost_price) AS loss_in_dollars   -- Money lost
FROM products p
LEFT JOIN sales_quantity_sum AS sqs
	ON p.product_id = sqs.product_id
LEFT JOIN waste_quantity_sum AS wqs
	ON p.product_id = wqs.product_id
LEFT JOIN waste AS w
	ON p.product_id = w.product_id
WHERE w.waste_date >= CURRENT_DATE - INTERVAL '1 month'
	AND wqs.wasted > 0
GROUP BY 1, 2, 3
ORDER BY loss_in_dollars DESC
LIMIT 20;

-- CONCLUSION: Need to order less top N products or discount them before expiration!