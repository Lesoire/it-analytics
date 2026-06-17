-- Завдання 1.2: SLA-аудит — затримка між session_start та наступною подією

WITH сирі_події AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value
     FROM UNNEST(event_params)
     WHERE key = 'ga_session_id')     AS sid,
    event_name,
    event_timestamp
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') IS NOT NULL
),

з_наступною_подією AS (
  SELECT
    *,
    LEAD(event_timestamp) OVER (
      PARTITION BY user_pseudo_id, sid
      ORDER BY event_timestamp
    ) AS ts_наступної
  FROM сирі_події
),

затримки AS (
  SELECT
    SAFE_DIVIDE(ts_наступної - event_timestamp, 1000000) AS затримка_сек
  FROM з_наступною_подією
  WHERE event_name = 'session_start'
    AND ts_наступної IS NOT NULL
)

SELECT
  COUNT(*)                                                      AS сесій_виміряно,
  ROUND(APPROX_QUANTILES(затримка_сек, 100)[OFFSET(50)], 2)   AS p50_сек,
  ROUND(APPROX_QUANTILES(затримка_сек, 100)[OFFSET(95)], 2)   AS p95_сек,
  ROUND(APPROX_QUANTILES(затримка_сек, 100)[OFFSET(99)], 2)   AS p99_сек,
  ROUND(AVG(затримка_сек), 2)                                  AS середня_сек,
  ROUND(100 * AVG(IF(затримка_сек > 3, 1, 0)), 2)             AS відсоток_понад_3сек
FROM затримки
WHERE затримка_сек > 0
  AND затримка_сек <= 60;
