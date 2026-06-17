-- Завдання 2.2: Кореляція сесії vs LTV по типу пристрою (пошук хибної кореляції)

WITH події AS (
  SELECT
    user_pseudo_id,
    device.category                                              AS тип_пристрою,
    (SELECT value.int_value
     FROM UNNEST(event_params) WHERE key = 'ga_session_id')     AS sid,
    event_name,
    IFNULL(ecommerce.purchase_revenue_in_usd, 0)                AS дохід_події
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
),

агрегація AS (
  SELECT
    user_pseudo_id,
    тип_пристрою,
    COUNT(DISTINCT sid)                                          AS кількість_сесій,
    SUM(IF(event_name = 'purchase', дохід_події, 0))            AS ltv
  FROM події
  WHERE sid IS NOT NULL
  GROUP BY 1, 2
)

SELECT
  тип_пристрою,
  COUNT(*)                                AS користувачів,
  ROUND(AVG(кількість_сесій), 2)          AS середньо_сесій,
  ROUND(AVG(ltv), 2)                      AS середній_ltv,
  ROUND(CORR(кількість_сесій, ltv), 4)   AS кореляція
FROM агрегація
WHERE кількість_сесій > 0
GROUP BY 1
HAVING COUNT(*) > 30
ORDER BY кореляція DESC;
