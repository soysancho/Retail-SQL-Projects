					
					----- MARKET BASKET ANALYSIS (What People Buy Together) -----
-- TASK: Find out which products are bought in one transaction to place them nearby.


-- Finding product pairs

CREATE MATERIALIZED VIEW dm_purchase_pairs AS
-- Take all receipts where 2+ products were bought
WITH transactions AS (
  SELECT
  	product_id,
    transaction_id,
    product_name
  FROM sales
  WHERE transaction_date >= CURRENT_DATE - INTERVAL '3 months'
),
-- How many times a product was bought in general
product_purchase_count AS (
	SELECT
		product_id,
		product_name,
		COUNT(DISTINCT transaction_id) AS product_purchases
   	FROM transactions
   	GROUP BY 1,2
),
-- Create all possible pairs of products from one receipt
product_pairs AS (
  SELECT
  	t1.product_id AS product1_id,
    t1.product_name AS product1_name,
    t2.product_name AS product2_name,
    COUNT(DISTINCT t1.transaction_id) AS bought_together_count
  FROM transactions AS t1
  JOIN transactions AS t2 -- Using SELF JOIN
    ON t1.transaction_id = t2.transaction_id
    AND t1.product_name < t2.product_name  -- To avoid duplicates (A+B = B+A)
  GROUP BY 1, 2
  HAVING COUNT(DISTINCT t1.transaction_id) >= 50  -- Minimum 50 times together
)
-- Calculate how often bought together
SELECT 
  pp.product1_name,
  pp.product2_name,
  pp.bought_together_count,
  -- How many times product1 was bought in general
  ppc.product_purchases AS product1_purchases,
  -- Probability of buying product2 if already took product1
  ROUND(pp.bought_together_count * 100.0 / ppc.product_purchases, 2) AS probability_percent
FROM product_pairs AS pp
JOIN product_purchase_count AS ppc
	ON pp.product1_id = ppc.product_id
ORDER BY 3 DESC
LIMIT 20;

/*
Possible result:
| product_1    | product_2     | together | probability |
|--------------|---------------|----------|-------------|
| Beer         | Chips         |   3452   | 65.34%         |
| Spaghetti    | Tomato sauce  |   2895   | 58.73%         |
| Coffee       | Milk          |   2653   | 52.81%         |
| Bread        | Butter        |   2347   | 48.12%         |
*/

-- CONCLUSION: If a customer took beer, in 65.34% of cases they'll take chips — place them nearby!