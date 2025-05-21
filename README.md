# FitUp Data Analysis
**Analysis of key metrics and user behavior in the fitness app**
---
![FitUp Logo](https://github.com/Andrii-Klipailo/FitUp_Data_Analysis/blob/main/images/FitUp_logo.png)
---

## Overview  
**FitUp** is a mobile fitness app that helps users track workouts and monitor progress.  
It offers personalized training plans, real-time performance tracking, and a subscription-based model for premium features.

Users can access a limited set of workouts for free, or unlock full access to all training programs through one of two premium subscription plans: **monthly ($9.99)** or **yearly ($99.99)**.

This project analyzes user activity during the **first 3 months** after the app’s launch.  
The focus is on evaluating user behavior, engagement, and monetization through product metrics such as **LTV, retention**, and **conversion rates** using **SQL**.


## Objective  
To demonstrate data analysis skills using SQL by calculating core product metrics, identifying behavior patterns, and drawing actionable insights from user and event data.


## Goals  
- Calculate key metrics such as DAU, MAU, and LTV.
- Analyze user behavior and retention rates.
- Assess subscription conversion rates and identify areas for improvement.
- Provide recommendations based on the analysis.


## Methodology  
- SQL queries written in **Google BigQuery**  
- Data was retrieved from the app’s **users, events**, and **subscriptions** tables  
- Visualizations were built using **BigQuery’s UI**

## Main Analysis

### 1. MAU (Monthly Active Users)  
The number of unique users active per month.  
```SQL
--MAU
SELECT EXTRACT(MONTH FROM event_time) AS month_number
,COUNT(DISTINCT user_id) as MAU
FROM `FitUp.events`
GROUP BY 1
ORDER BY 1
;
```
![MAU](https://github.com/Andrii-Klipailo/FitUp_Data_Analysis/blob/main/images/MAU.png)

---

### 2. WAU (Weekly Active Users)  
Unique users per week.  
```SQL
--WAU
SELECT EXTRACT(WEEK FROM event_time)+1 AS week_number
,COUNT(DISTINCT user_id) as WAU
FROM `FitUp.events`
GROUP BY 1
ORDER BY 1
;
```  
![WAU](https://github.com/Andrii-Klipailo/FitUp_Data_Analysis/blob/main/images/WAU.png)

---

### 3. DAU (Daily Active Users)  
Daily unique active users.  
```SQL
--DAU
SELECT DATE(event_time) AS date
,COUNT(DISTINCT user_id) as DAU
FROM `FitUp.events`
GROUP BY 1
ORDER BY 1
;
```  
![DAU](https://github.com/Andrii-Klipailo/FitUp_Data_Analysis/blob/main/images/DAU.png)

---

### 4. Subscription Conversion Rate  
Percentage of users who purchased a subscription.  
```SQL
--Conversion to subscription
SELECT
  ROUND(
    (SELECT COUNT(DISTINCT user_id) FROM `FitUp.events`
    WHERE event_type = "buy_subscription")*100.0/
    (SELECT COUNT(DISTINCT user_id) FROM `FitUp.users`)
  ,2) as Conversion_rate
;
```
![Conversion_rate](https://github.com/Andrii-Klipailo/FitUp_Data_Analysis/blob/main/images/Conversion_rate.png)

---

### 5. 7-Day Retention Rate  
Percentage of users who returned to the app 7 days after registration.  
```SQL
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
```
![Retention_rate](https://github.com/Andrii-Klipailo/FitUp_Data_Analysis/blob/main/images/Retention_rate.png)

---

### 6. ARPU (Average Revenue Per User)  
Revenue per user per month.  
```SQL
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
```
![ARPU](https://github.com/Andrii-Klipailo/FitUp_Data_Analysis/blob/main/images/ARPU.png)

---

### 7. ARPPU (Average Revenue Per Paying User)  
Revenue per paying user per month.  
```SQL
--ARPPU by month
WITH main_table AS(
SELECT EXTRACT(MONTH FROM DATE(subscription_date)) as month
  ,COUNT(DISTINCT user_id) as active_users
  ,SUM(price) AS amount
FROM `FitUp.subscriptions`
GROUP BY 1
)
SELECT month 
  ,ROUND(amount/active_users, 2) AS ARPPU
FROM main_table
ORDER BY month
;

```
![ARPPU](https://github.com/Andrii-Klipailo/FitUp_Data_Analysis/blob/main/images/ARPPU.png)

---

### 8. Average Customer Lifetime  
Average number of days users remain active in the app.  
```SQL
-- Average Customer Lifetime
WITH living_time_table AS(
SELECT DISTINCT user_id
  ,DATE_DIFF(MAX(DATE(event_time)),MIN(DATE(event_time)), DAY) living_time
FROM `FitUp.events`
GROUP BY 1
)
SELECT ROUND(AVG(living_time),0) AS user_livetime
FROM living_time_table
;
```
![Lifetime](https://github.com/Andrii-Klipailo/FitUp_Data_Analysis/blob/main/images/Lifetime.png)

---

### 9. LTV (Customer Lifetime Value)  
Revenue per user across their lifetime in date cohort
```SQL
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
SELECT created_at as cohort_date
  ,COUNT(DISTINCT user_id) users
  ,ROUND(SUM(price),2) AS amount
  ,ROUND(SUM(price)/COUNT(DISTINCT user_id), 2) AS LTV
FROM main_table
GROUP BY 1
;

```
![LTV_table](https://github.com/Andrii-Klipailo/FitUp_Data_Analysis/blob/main/images/LTV_table.png)
![LTV_chart](https://github.com/Andrii-Klipailo/FitUp_Data_Analysis/blob/main/images/LTV_chart.png)

---

### 10. Event Distribution by Type  
Total number of actions by event type.  
```SQL
--Number of events by type 
SELECT event_type 
  ,COUNT(*) AS quantity
FROM `FitUp.events`
GROUP BY event_type
ORDER BY quantity DESC
;
```
![Quantity_events](https://github.com/Andrii-Klipailo/FitUp_Data_Analysis/blob/main/images/Quantity_events.png)

---

### 11. User Distribution by Country  
```SQL
-- Distribution users by Country
SELECT country
  ,COUNT(DISTINCT user_id) AS users
FROM `FitUp.users`
GROUP BY country
ORDER BY users DESC
;
```
![Country](https://github.com/Andrii-Klipailo/FitUp_Data_Analysis/blob/main/images/Country.png)

---

### 12. User Distribution by Platform  
```SQL
-- Distribution users by platform
SELECT platform
  ,COUNT(DISTINCT user_id) AS users
FROM `FitUp.users`
GROUP BY platform
ORDER BY users
;
```
![Platforms](https://github.com/Andrii-Klipailo/FitUp_Data_Analysis/blob/main/images/Platforms.png)

---

### 13. Training Completion Conversion  
Percentage of users who finished a workout after starting it.  
```SQL
-- Conversion to training completion
SELECT 
ROUND(
  (SELECT COUNT(user_id) FROM `FitUp.events`
  WHERE event_type = "workout_end")*100.0/
  (SELECT COUNT(user_id) FROM `FitUp.events`
  WHERE event_type = "workout_start") 
,2) AS finished_training
;
```
![finished_training](https://github.com/Andrii-Klipailo/FitUp_Data_Analysis/blob/main/images/finished_training.png)

---

### 14. First Workout Before Subscription  
Percentage of users who completed their first workout before buying a subscription.  
```SQL
-- Percentage of people who completed their first training before purchasing a subscription
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
,2) AS workout_before_buy
;
```
![workout_before_buy](https://github.com/Andrii-Klipailo/FitUp_Data_Analysis/blob/main/images/workout_before_buy.png)
---
## Findings and Conclusion

This analysis covers the first three months after the app's launch and highlights key results:

- The app gained **30,000+ users** from **5 countries**, mostly from **France** and **Germany**.
- In the most recent week, there were nearly **20,000 unique active users**.
- **13.3%** of users purchased a **premium subscription**.
- The **average revenue per paying user (ARPPU)** is approximately **$27**.
- The **average user lifetime** is **38 days**, which is relatively short for a fitness app and shows room for improvement in user retention.
- **95.6%** of workouts are completed, it means ~1 of 20 sessions is interrupted. This may be caused by user behavior or app issues and requires further investigation.
- **82.5%** of subscriptions happen **after users complete their first workout**, proving the importance of the early user experience.
- The remaining **17.5%** subscribe **before their first workout**, showing strong early interest and trust in the product.

**In summary**, the app shows strong growth and solid monetization potential. Focusing on retention and improving the first-time user experience can help unlock even more value.

---

#### Thank you for taking the time to explore my project!
If you have any feedback, questions, or would like to connect — feel free to reach out.







