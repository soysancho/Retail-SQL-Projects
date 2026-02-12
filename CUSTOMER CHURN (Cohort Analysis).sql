					
					----- CUSTOMER CHURN (Cohort Analysis) -----
-- TASK: Understand how many customers return for purchases.

-- Cohort analysis

CREATE MATERIALIZED VIEW dm_churn_cohort_month AS
-- Finding first purchase date of each customer
WITH first_purchases AS (
  SELECT 
    customer_id,
    MIN(purchase_date) AS first_purchase_date,
    DATE_TRUNC('month', MIN(purchase_date)) AS cohort_month  -- First purchase month
  FROM sales
  WHERE customer_id IS NOT NULL
  GROUP BY customer_id
),
-- Calculating in which month after first purchase customer returned
customer_returns AS (
  SELECT 
    fp.customer_id,
    fp.cohort_month,
    DATE_TRUNC('month', s.purchase_date) AS purchase_month,
    -- Difference in months between first and current purchase
    EXTRACT(YEAR FROM AGE(s.purchase_date, fp.first_purchase_date)) * 12 +
    EXTRACT(MONTH FROM AGE(s.purchase_date, fp.first_purchase_date)) AS months_since_first
  FROM first_purchases AS fp
  JOIN sales AS s
  	ON fp.customer_id = s.customer_id
)
-- Calculating retention by cohorts
SELECT 
  cohort_month,
  COUNT(DISTINCT CASE WHEN months_since_first = 0 THEN customer_id END) AS returned_same_month,
  COUNT(DISTINCT CASE WHEN months_since_first = 1 THEN customer_id END) AS month_1_returned, -- Returned after 1 month
  COUNT(DISTINCT CASE WHEN months_since_first = 2 THEN customer_id END) AS month_2_returned, -- Returned after 2 months
  COUNT(DISTINCT CASE WHEN months_since_first = 3 THEN customer_id END) AS month_3_returned, -- Returned after 3 months
  -- Retention percentage = how many customers returned next month / how many customers returned the same month
  ROUND(COUNT(DISTINCT CASE WHEN months_since_first = 1 THEN customer_id END) * 100.0 /
        NULLIF(COUNT(DISTINCT CASE WHEN months_since_first = 0 THEN customer_id END), 0), 2) 
        AS retention_month_1_percent
FROM customer_returns
GROUP BY 1
ORDER BY 1;

/*
Possible result:
| cohort    | same_month | month_1 | month_2 | retention_1 |
|-----------|------------|---------|---------|-------------|
| 2024-01   |   1,000    | 450     | 320     | 45%         |
| 2024-02   |   1,200    | 600     | 480     | 50%         |
| 2024-03   |   950      | 570     | 456     | 60%         |
*/

-- CONCLUSION: In March retention increased to 60% (570 out of 950 returned) — perhaps a loyalty program was launched!
