-- Завдання 1.1: Розподіл LTV по користувачах + квантильний аналіз
-- Датасет: ga4_obfuscated_sample_ecommerce (листопад 2020 – січень 2021)

WITH покупці AS (
  SELECT
    user_pseudo_id                                          AS uid,
    ROUND(SUM(IFNULL(ecommerce.purchase_revenue_in_usd, 0)), 2) AS total_spent
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name = 'purchase'
  GROUP BY uid
),

розподіл AS (
  SELECT
    COUNT(*)                                                     AS кількість_покупців,
    ROUND(AVG(total_spent), 2)                                   AS середнє,
    ROUND(APPROX_QUANTILES(total_spent, 100)[OFFSET(50)], 2)    AS медіана_p50,
    ROUND(APPROX_QUANTILES(total_spent, 100)[OFFSET(90)], 2)    AS p90,
    ROUND(APPROX_QUANTILES(total_spent, 100)[OFFSET(99)], 2)    AS p99,
    ROUND(MAX(total_spent), 2)                                   AS максимум,
    ROUND(SUM(total_spent), 2)                                   AS загальний_дохід
  FROM покупці
)

SELECT
  *,
  ROUND(SAFE_DIVIDE(середнє, медіана_p50), 2)  AS коеф_асиметрії,
  ROUND(
    100 * (SELECT SUM(total_spent) FROM покупці
           WHERE total_spent >= (SELECT p99 FROM розподіл))
    / загальний_дохід,
    2
  ) AS частка_доходу_від_p99
FROM розподіл;
