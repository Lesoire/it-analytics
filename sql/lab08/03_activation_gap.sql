-- Завдання 3.1: Activation gap — нові користувачі без view_item за 24 год

WITH нові_січня AS (
  SELECT user_pseudo_id, MIN(event_timestamp) AS перша_подія
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', event_date)) = '202101'
  GROUP BY 1
),

тільки_нові AS (
  SELECT user_pseudo_id, перша_подія FROM нові_січня н
  WHERE NOT EXISTS (
    SELECT 1
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` е
    WHERE е._TABLE_SUFFIX BETWEEN '20201101' AND '20201231'
      AND е.user_pseudo_id = н.user_pseudo_id
  )
),

перевірка AS (
  SELECT
    н.user_pseudo_id,
    COUNTIF(е.event_name = 'view_item'
      AND е.event_timestamp <= н.перша_подія + 24 * 3600 * 1000000) AS переглядів_24год
  FROM тільки_нові н
  LEFT JOIN `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` е
    ON е.user_pseudo_id = н.user_pseudo_id
    AND е._TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
  GROUP BY 1
)

SELECT
  COUNT(*)                                                       AS нових_користувачів,
  COUNTIF(переглядів_24год = 0)                                 AS без_перегляду_24год,
  ROUND(100 * AVG(IF(переглядів_24год = 0, 1, 0)), 2)          AS відсоток_без_перегляду
FROM перевірка;
