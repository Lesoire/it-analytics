-- Завдання 3.2 (частина 1): Кількість dormant користувачів (грудень є, січня немає)

WITH активність AS (
  SELECT
    user_pseudo_id,
    MAX(IF(FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', event_date)) = '202012', 1, 0)) AS грудень,
    MAX(IF(FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', event_date)) = '202101', 1, 0)) AS січень
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
  GROUP BY 1
)

SELECT COUNT(*) AS dormant_користувачів
FROM активність
WHERE грудень = 1 AND січень = 0;
