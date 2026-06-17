-- Завдання 3.1: Lifecycle State Machine — стани станом на 31 січня 2021

WITH прапорці AS (
  SELECT
    user_pseudo_id,
    MAX(IF(FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', event_date)) = '202011', 1, 0)) AS листопад,
    MAX(IF(FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', event_date)) = '202012', 1, 0)) AS грудень,
    MAX(IF(FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', event_date)) = '202101', 1, 0)) AS січень,
    DATE_TRUNC(MIN(PARSE_DATE('%Y%m%d', event_date)), MONTH)                        AS перший_місяць
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
  GROUP BY 1
),

стани AS (
  SELECT
    user_pseudo_id,
    CASE
      WHEN перший_місяць = DATE '2021-01-01' AND січень = 1        THEN 'New'
      WHEN грудень = 1 AND січень = 1                               THEN 'Retained'
      WHEN грудень = 0 AND січень = 1
        AND (листопад = 1 OR перший_місяць < DATE '2020-12-01')    THEN 'Resurrected'
      WHEN грудень = 1 AND січень = 0                               THEN 'Churned'
      ELSE NULL
    END AS стан
  FROM прапорці
  WHERE грудень = 1 OR січень = 1
)

SELECT
  стан,
  COUNT(*)                                                       AS користувачів,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)              AS відсоток
FROM стани
WHERE стан IS NOT NULL
GROUP BY 1
ORDER BY користувачів DESC;
