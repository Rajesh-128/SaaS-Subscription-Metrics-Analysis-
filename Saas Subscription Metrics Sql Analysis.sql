 -- create database SaaS_Subscription_Metrics;
 -- USE SaaS_Subscription_Metrics;
 -- alter table customers
 -- rename column ï»¿customer_id TO customer_Id;
 -- alter table subscription 
 -- rename column ï»¿subscription_id to subscription_Id;
 -- alter table metrics
 -- rename column ï»¿customer_id to customer_Id;
 -- alter table payment 
 -- rename column ï»¿payment_id to payment_Id;
 -- alter table tickets
 -- rename column ï»¿ticket_id to ticket_Id;
 
 
-- 1. Total Customers 
select count(distinct customer_id)
as total_customers
from customers;
 
-- 2. Total Active customers
select count(distinct customer_Id) 
AS Active_customers
from subscription
where status = 'Active';
 
-- 3. Total churned customers
select count(distinct customer_Id)
AS churned_customers
from subscription
where status = 'churned';

-- 4. Total Customers by Plan 
select count(distinct customer_Id)
AS Customers
from subscription
group by plan_name
order by customers desc;

-- 5. Total Revenue by Plan 
select 
		plan_name,
		sum(monthly_price) as revenue
from subscription
where status = 'Active'
group by plan_name
order by revenue desc;
 
 -- 6. Total MRR (Monthly Recurring Revenue).
 select
		sum(monthly_price) as MRR 
from subscription
where status = 'Active';
 
 -- 7. Total ARR (Annual recurring Revenue). 
 select 
 sum(monthly_price) * 12 AS ARR
 from subscription
 where status = 'Active';
 
-- 8.  Total churned customers 
select
	count(distinct case
		when status = 'churned'
		then customer_id
	end) as churned_customers,
	count(distinct customer_id) as total_customer
	from subscription;

-- 9. what was the Subscription Movement
SELECT
    subscription_id,
    customer_id,
    plan_name,
    monthly_price,
    'status',
    upgrade_flag,
    downgrade_flag,

    CASE
        WHEN upgrade_flag = 1 THEN 'Upgrade'
        WHEN downgrade_flag = 1 THEN 'Downgrade'
        ELSE 'No Change'
    END AS subscription_movement
    
FROM subscription;

-- 10. what is a Total customers are Upgrade, downgrade and Nochange to the Plane 
select
	case
		when upgrade_flag = 1 then 'upgrade'
        when downgrade_flag = 1 then 'downgrade'
        else 'no change'
	END as subscription_movement,
    
    count(*) AS customers
    
from subscription

group by
	case
		when upgrade_flag = 1 then 'upgrade'
        when downgrade_flag = 1 then 'downgrade'
        else 'no change'
END;

-- 11. what is Total percent Rate of upgrade Plan 
SELECT
    COUNT(*) AS total_customers,

    SUM(CASE
        WHEN upgrade_flag = 1 THEN 1
        ELSE 0
    END) AS upgraded_customers,

    ROUND(
        100.0 *
        SUM(CASE
            WHEN upgrade_flag = 1 THEN 1
            ELSE 0
        END)
        / COUNT(*),
        2
    ) AS upgrade_rate_percent

FROM subscription;

-- 12. Total upgrade percent rate by plan Name 

SELECT
    plan_name,

    COUNT(*) AS total_customers,

    SUM(CASE
        WHEN upgrade_flag = 1 THEN 1
        ELSE 0
    END) AS upgraded_customers,

    ROUND(
        100.0 *
        SUM(CASE
            WHEN upgrade_flag = 1 THEN 1
            ELSE 0
        END)
        / NULLIF(COUNT(*), 0),
        2
    ) AS upgrade_rate_percent

FROM subscription

GROUP BY plan_name

ORDER BY upgrade_rate_percent DESC;  

-- 13. what is Total percent Rate of upgrade Plan
SELECT
    COUNT(*) AS total_customers,

    SUM(CASE
        WHEN downgrade_flag = 1 THEN 1
        ELSE 0
    END) AS downgraded_customers,

    ROUND(
        100.0 *
        SUM(CASE
            WHEN downgrade_flag = 1 THEN 1
            ELSE 0
        END)
        / COUNT(*),
        2
    ) AS downgrade_rate_percent

FROM subscription;
      
-- 14. Total downgrade percent rate by plan Name    
SELECT
    plan_name,

    COUNT(*) AS total_customers,

    SUM(CASE
        WHEN downgrade_flag = 1 THEN 1
        ELSE 0
    END) AS downgraded_customers,

    ROUND(
        100.0 *
        SUM(CASE
            WHEN downgrade_flag = 1 THEN 1
            ELSE 0
        END)
        / NULLIF(COUNT(*), 0),
        2
    ) AS downgrade_rate_percent

FROM subscription

GROUP BY plan_name

ORDER BY downgrade_rate_percent DESC;
      
-- 15. Total customers churn percent rate by Plan

select
	plan_name,
    
    count(distinct customer_id) as total_customers,
    
    count(distinct case
		when status = 'churnes'
        then customer_id
        end) as churned_customers,
        
	round(
		100.0 * 
        count(distinct case 
			when status = 'churned'
			then customer_id
		END)
		/ NULLIF(COUNT(DISTINCT customer_id), 0),
		2
	) as churn_rate_percent

from subscription

group by plan_name

order by churn_rate_percent desc;

 -- 16. Total customers churn percent rate by country 
 
 SELECT
    c.country,

    COUNT(DISTINCT s.customer_id) AS total_customers,

    COUNT(DISTINCT CASE
        WHEN s.status = 'Churned'
        THEN s.customer_id
    END) AS churned_customers,

    ROUND(
        100.0 *
        COUNT(DISTINCT CASE
            WHEN s.status = 'Churned'
            THEN s.customer_id
        END)
        / NULLIF(COUNT(DISTINCT s.customer_id), 0),
        2
    ) AS churn_rate_percent

FROM customers c

INNER JOIN subscription s
    ON c.customer_id = s.customer_id

GROUP BY c.country

ORDER BY churn_rate_percent DESC;

-- 17. WHAT IS THE CHURNED CUSTOMERS CANCEL THE PLAN 

SELECT
    cancellation_reason,

    COUNT(DISTINCT customer_id) AS churned_customers,

    ROUND(
        100.0 * COUNT(DISTINCT customer_id)
        /
        NULLIF(
            (
                SELECT COUNT(DISTINCT customer_id)
                FROM subscription
                WHERE status = 'Churned'
            ),
            0
        ),
        2
    ) AS percentage_of_churn

FROM subscription

WHERE status = 'Churned'

GROUP BY cancellation_reason

ORDER BY churned_customers DESC;

-- 18. WHAT IS THE TOTAL MONTHLY MRR (Monthly Recurring Revenue)

WITH RECURSIVE months AS (

    SELECT DATE('2024-01-01') AS month_start

    UNION ALL

    SELECT DATE_ADD(month_start, INTERVAL 1 MONTH)

    FROM months

    WHERE month_start < '2025-12-01'
),

monthly_mrr AS (

    SELECT
        m.month_start,

        COALESCE(
            SUM(
                CASE
                    WHEN s.start_date <= LAST_DAY(m.month_start)
                     AND (
                            s.end_date IS NULL
                            OR s.end_date > LAST_DAY(m.month_start)
                         )
                    THEN s.monthly_price
                    ELSE 0
                END
            ),
            0
        ) AS MRR

    FROM months m

    CROSS JOIN subscription s

    GROUP BY m.month_start
)

SELECT
    month_start,
    MRR

FROM monthly_mrr

ORDER BY month_start;

-- 20. Monthly MRR Growth

WITH RECURSIVE months AS (

    SELECT DATE('2024-01-01') AS month_start

    UNION ALL

    SELECT DATE_ADD(month_start, INTERVAL 1 MONTH)

    FROM months

    WHERE month_start < '2025-12-01'
),

monthly_mrr AS (

    SELECT
        m.month_start,

        COALESCE(
            SUM(
                CASE
                    WHEN s.start_date <= LAST_DAY(m.month_start)
                     AND (
                            s.end_date IS NULL
                            OR s.end_date > LAST_DAY(m.month_start)
                         )
                    THEN s.monthly_price
                    ELSE 0
                END
            ),
            0
        ) AS MRR

    FROM months m

    CROSS JOIN subscription s

    GROUP BY m.month_start
),

mrr_with_previous AS (

    SELECT
        month_start,
        MRR,

        LAG(MRR) OVER (
            ORDER BY month_start
        ) AS previous_MRR

    FROM monthly_mrr
)

SELECT
    month_start,
    MRR,
    previous_MRR,

    MRR - previous_MRR AS MRR_change,

    ROUND(
        100.0 *
        (MRR - previous_MRR)
        / NULLIF(previous_MRR, 0),
        2
    ) AS MRR_growth_percent

FROM mrr_with_previous

ORDER BY month_start; 

-- 21. Revenue Ranking 

SELECT
    s.customer_id,
    c.country,
    c.industry,
    s.plan_name,
    s.monthly_price AS MRR,

    RANK() OVER (
        ORDER BY s.monthly_price DESC
    ) AS revenue_rank

FROM subscription s

INNER JOIN customers c
    ON s.customer_id = c.customer_id

WHERE s.status = 'Active'

ORDER BY revenue_rank;

-- 22. Top 10 Customers

WITH ranked_customers AS (

    SELECT
        s.customer_id,
        c.country,
        c.industry,
        c.company_size,
        s.plan_name,
        s.monthly_price AS MRR,

        ROW_NUMBER() OVER (
            ORDER BY s.monthly_price DESC
        ) AS customer_rank

    FROM subscription s

    INNER JOIN customers c
        ON s.customer_id = c.customer_id

    WHERE s.status = 'Active'
)

SELECT
    customer_rank,
    customer_id,
    country,
    industry,
    company_size,
    plan_name,
    MRR

FROM ranked_customers

WHERE customer_rank <= 10

ORDER BY customer_rank;

-- 23. Top Customers by Country

WITH ranked_customers AS (

    SELECT
        c.country,
        s.customer_id,
        s.plan_name,
        s.monthly_price AS MRR,

        ROW_NUMBER() OVER (
            PARTITION BY c.country
            ORDER BY s.monthly_price DESC
        ) AS country_customer_rank

    FROM customers c

    INNER JOIN subscription s
        ON c.customer_id = s.customer_id

    WHERE s.status = 'Active'
)

SELECT *
FROM ranked_customers
WHERE country_customer_rank <= 3
ORDER BY country, country_customer_rank;



select * from customers;
select * from payment;
select * from subscription;
select * from metrics;
select * from tickets;
