-- Завдання 3.2 (частина 2): JSON-контракт для Resurrection Loop (5 dormant users)

WITH активність AS (
  SELECT
    user_pseudo_id,
    MAX(IF(FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', event_date)) = '202012', 1, 0)) AS грудень,
    MAX(IF(FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', event_date)) = '202101', 1, 0)) AS січень
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
  GROUP BY 1
),

сплячі AS (
  SELECT user_pseudo_id FROM активність
  WHERE грудень = 1 AND січень = 0
  LIMIT 5
),

остання_категорія AS (
  SELECT
    с.user_pseudo_id,
    ARRAY_AGG(товар.item_category ORDER BY е.event_timestamp DESC LIMIT 1)[OFFSET(0)] AS категорія
  FROM сплячі с
  INNER JOIN `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` е
    ON е.user_pseudo_id = с.user_pseudo_id
    AND е._TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND е.event_name = 'view_item'
  CROSS JOIN UNNEST(е.items) AS товар
  GROUP BY 1
)

SELECT
  TO_JSON_STRING(STRUCT(
    user_pseudo_id   AS user_id,
    'resurrection'   AS segment_type,
    категорія        AS last_category_name,
    CONCAT('Ми сумуємо за вами! Перегляньте нові надходження у категорії ',
           IFNULL(категорія, 'Apparel')) AS personalized_message
  )) AS payload
FROM остання_категорія;
