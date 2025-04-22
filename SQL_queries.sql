--DAU
SELECT DATE(event_time) AS date
,COUNT(DISTINCT user_id) as DAU
FROM `FitUp.events`
GROUP BY 1
ORDER BY 1
;


--WAU
SELECT EXTRACT(WEEK FROM event_time)+1 AS week_number
,COUNT(DISTINCT user_id) as WAU
FROM `FitUp.events`
GROUP BY 1
ORDER BY 1
;


--MAU
SELECT EXTRACT(MONTH FROM event_time) AS month_number
,COUNT(DISTINCT user_id) as MAU
FROM `FitUp.events`
GROUP BY 1
ORDER BY 1
;


--Conversion to subscription
SELECT
  ROUND(
    (SELECT COUNT(DISTINCT user_id) FROM `FitUp.events`
    WHERE event_type = "buy_subscription")*100.0/
    (SELECT COUNT(DISTINCT user_id) FROM `FitUp.users`)
  ,2) as Conversion_rate
;


--Retention 7 day
WITH
return_on_xday AS(
SELECT us.user_id
  ,created_at
  ,DATE(event_time) as event_date
  ,event_type
FROM `FitUp.users` as us
LEFT JOIN `FitUp.events` as ev
USING(user_id)
WHERE DATE(event_time) = created_at + 7
),
count_returns AS(
SELECT created_at
  ,COUNT( DISTINCT user_id) as numb_of_returns
FROM return_on_xday
GROUP BY 1
ORDER BY 1
),
count_registrations AS(
SELECT created_at
  ,COUNT(DISTINCT user_id) as numb_of_regs
FROM `FitUp.users`
GROUP BY 1
),
main_table AS(
SELECT rt.created_at
  ,numb_of_returns
  ,numb_of_regs
FROM count_returns as rt
JOIN count_registrations as rg
USING(created_at)
)
SELECT created_at as date
  ,numb_of_returns
  ,numb_of_regs
  ,ROUND(numb_of_returns*100.0/numb_of_regs, 2) AS retention_rate
FROM main_table
ORDER BY 1
;


--ARPU by month
WITH active_users_table AS(
SELECT EXTRACT(MONTH FROM DATE(event_time)) as month
  ,COUNT(DISTINCT user_id) as active_users
FROM `FitUp.events`
GROUP BY 1
),
revenue_table AS(
SELECT EXTRACT(MONTH FROM subscription_date) AS month
  ,SUM(price) AS amount
FROM `FitUp.subscriptions`
GROUP BY 1
),
main_table AS(
SELECT month
  ,active_users 
  ,amount
FROM active_users_table
JOIN revenue_table
USING(month)
)
SELECT month 
  ,ROUND(amount/active_users, 2) AS ARPU
FROM main_table
ORDER BY month
;


--ARPPU by month
WITH main_table AS(
SELECT EXTRACT(MONTH FROM DATE(subscription_date)) as month
  ,COUNT(user_id) as active_users
  ,SUM(price) AS amount
FROM `FitUp.subscriptions`
GROUP BY 1
)
SELECT month 
  ,ROUND(amount/active_users, 2) AS ARPPU
FROM main_table
ORDER BY month
;


-- Average Customer Lifetime
WITH living_time_table AS(
SELECT DISTINCT user_id
  ,DATE_DIFF(MAX(DATE(event_time)),MIN(DATE(event_time)), DAY) living_time
FROM `FitUp.events`
GROUP BY 1
)
SELECT ROUND(AVG(living_time),0) AS user_livetime
FROM living_time_table



--LTV 
WITH
main_table AS(
SELECT us.user_id
  ,created_at
  ,subscription_date
  ,price
FROM `FitUp.users` as us
LEFT JOIN `FitUp.subscriptions` as sub
USING(user_id)
)
SELECT created_at
  ,COUNT(user_id) users
  ,ROUND(SUM(price),2) AS amount
  ,ROUND(SUM(price)/COUNT(user_id), 2) AS LTV
FROM main_table
GROUP BY 1
;


--Number of events by type 
SELECT event_type 
  ,COUNT(*) AS quantity
FROM `FitUp.events`
GROUP BY event_type
ORDER BY quantity DESC
;


-- Distribution users by Country
SELECT country
  ,COUNT(DISTINCT user_id) AS users
FROM `FitUp.users`
GROUP BY country
ORDER BY users DESC
;


-- Distribution users by platform
SELECT platform
  ,COUNT(DISTINCT user_id) AS users
FROM `FitUp.users`
GROUP BY platform
ORDER BY users
;


-- Convertion to finishing training
SELECT 
ROUND(
  (SELECT COUNT(user_id) FROM `FitUp.events`
  WHERE event_type = "workout_end")*100.0/
  (SELECT COUNT(user_id) FROM `FitUp.events`
  WHERE event_type = "workout_start") 
,2) AS finished_training



-- Percentage of  people that did first training before buying subscription
WITH first_subscription_date AS(
SELECT DISTINCT user_id
  ,MIN(event_time) subscription_date
FROM `FitUp.events`
WHERE event_type = "buy_subscription"
GROUP BY 1
),
first_training_date AS (
SELECT DISTINCT user_id
  ,MIN(event_time) as workout_date
FROM `FitUp.events`
WHERE event_type = "workout_start"
GROUP BY 1
),
main_table AS(
SELECT fs.user_id
  ,subscription_date
  ,workout_date
FROM first_subscription_date as fs
LEFT JOIN first_training_date as ft
ON fs.user_id = ft.user_id
)
SELECT
ROUND(
  (SELECT COUNT(user_id) FROM main_table
  WHERE workout_date < subscription_date)*100.0/
  (SELECT COUNT(user_id) FROM main_table)
,2) AS workout_start_before_buy
;


























