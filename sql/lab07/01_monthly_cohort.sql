-- Завдання 1.1: Місячна матриця утримання (M0=100%, M1, M2)

WITH перший_місяць AS (
  SELECT
    user_pseudo_id,
    DATE_TRUNC(MIN(PARSE_DATE('%Y%m%d', event_date)), MONTH)    AS когорта
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
  GROUP BY 1
),

активність AS (
  SELECT DISTINCT
    user_pseudo_id,
    DATE_TRUNC(PARSE_DATE('%Y%m%d', event_date), MONTH)         AS місяць_активності
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
),

когортна_активність AS (
  SELECT
    п.когорта,
    п.user_pseudo_id,
    DATE_DIFF(а.місяць_активності, п.когорта, MONTH)            AS номер_місяця
  FROM перший_місяць п
  INNER JOIN активність а USING (user_pseudo_id)
  WHERE DATE_DIFF(а.місяць_активності, п.когорта, MONTH) BETWEEN 0 AND 2
),

розміри_когорт AS (
  SELECT когорта, COUNT(DISTINCT user_pseudo_id) AS розмір_m0
  FROM когортна_активність
  WHERE номер_місяця = 0
  GROUP BY 1
),

повернення AS (
  SELECT когорта, номер_місяця, COUNT(DISTINCT user_pseudo_id) AS активних
  FROM когортна_активність
  GROUP BY 1, 2
)

SELECT
  FORMAT_DATE('%Y-%m', п.когорта)                               AS когорта,
  п.номер_місяця,
  п.активних,
  р.розмір_m0,
  ROUND(100 * SAFE_DIVIDE(п.активних, р.розмір_m0), 2)         AS retention_pct
FROM повернення п
INNER JOIN розміри_когорт р USING (когорта)
ORDER BY когорта, номер_місяця;
