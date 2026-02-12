					
					----- PROMOTION EFFECTIVENESS -----
-- TASK: Understand which discounts work and which only lose money.


-- Analyzing promotions, which lasted for 2 weeks

CREATE MATERIALIZED VIEW dm_promotion_efficiency AS
-- Finding the sales BEFORE, DURING and AFTER promotion
WITH before_promo_sales AS (
	SELECT 
		p.product_id,
		COALESCE(SUM(s.quantity), 0) AS sales_before
     FROM product AS p
     JOIN sales AS s
     	ON p.product_id = s.product_id
     JOIN promotions AS pr
     	ON p.product_id = pr.product_id
     WHERE s.sale_date BETWEEN pr.start_date - INTERVAL '14 days'
     						AND pr.start_date - INTERVAL '1 day'
     GROUP BY 1
),
during_promo_sales AS (
	SELECT 
		p.product_id,
		COALESCE(SUM(quantity), 0) AS sales_during
    FROM product AS p
    JOIN sales AS s
     	ON p.product_id = s.product_id
    JOIN promotions AS pr
     	ON p.product_id = pr.product_id
    WHERE s.sale_date BETWEEN pr.start_date AND pr.end_date
    GROUP BY 1
),
after_promo_sales AS (
	SELECT 
		p.product_id,
		COALESCE(SUM(quantity), 0) AS sales_after
    FROM product AS p
    JOIN sales AS s
     	ON p.product_id = s.product_id
    JOIN promotions AS pr
     	ON p.product_id = pr.product_id
    WHERE s.sale_date BETWEEN pr.end_date + INTERVAL '1 day' 
                           AND pr.end_date + INTERVAL '14 days'
    GROUP BY 1
),
-- Promotion cost (lost margin)
promo_costs AS (
	SELECT
		pr.promo_id,
		SUM(s.quantity * p.price * pr.discount_percent / 100.0) AS promo_cost
    FROM sales AS s
    JOIN products AS p
    	ON s.product_id = p.product_id
    JOIN promotions AS pr
    	ON s.product_id = p.product_id
    WHERE s.sale_date BETWEEN p.start_date AND p.end_date
    GROUP BY 1
),
-- Comparing sales BEFORE, DURING and AFTER promotion
promo_analysis AS (
	SELECT 
    	pr.promo_name,
    	pr.product_id,
    	p.product_name,
    	pr.discount_percent,
    	pr.start_date,
    	pr.end_date,   
    	bps.sales_before,
    	dps.sales_during,
    	aps.sales_after,
    	pc.promo_cost
    FROM promotions AS pr
    JOIN products AS p
  		ON p.product_id = pr.product_id
  	JOIN before_promo_sales AS bps
  		ON p.product_id = bps.product_id
  	JOIN during_promo_sales AS dps
  		ON p.product_id = dps.product_id
  	JOIN after_promo_sales AS aps
  		ON p.product_id = aps.product_id
  	JOIN promo_costs AS pc
  		ON pr.promo_id = pc.promo_id
  	WHERE pr.end_date >= CURRENT_DATE - INTERVAL '6 months'
)
SELECT 
	promo_name,
	product_name,
  	discount_percent,
  	sales_before,
  	sales_during,
  	sales_after,
  	sales_during - sales_before AS units_growth,   -- Sales increase during promotion
  	ROUND((sales_during - sales_before) * 100.0 / NULLIF(sales_before, 0), 2) AS growth_percent,   -- Percentage increase
  	ROUND((sales_after - sales_before) * 100.0 / NULLIF(sales_before, 0), 2) AS post_promo_change_percent,   -- Percentage increase
  	ROUND(promo_cost, 2) AS promo_cost_dollars
FROM promo_analysis
ORDER BY growth_percent DESC;

/*
Possible result:
| promo      | product | discount | before | during | after |  change  | growth%   | cost$  |
|------------|---------|----------|--------|--------|-------|----------|-----------|--------|
| Mega Sale  | Chips   | 40%      | 650    | 2400   | 200   | -69.23%  | +369.23%  | 1600   |
| Smart Deal | Yoghurt | 20%      | 300    | 500    | 320   |  6.66%   | +66.67%   | 550    |
*/

-- CONCLUSION: 1. 40% discount on chips attracted buyers, but after promotion sales dropped (they stocked up).
-- 			   2. 20% discount on yoghurt gave good results without dip!
