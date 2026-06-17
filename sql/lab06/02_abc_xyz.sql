-- Завдання 1.2: ABC/XYZ аналіз + перетин Champions (555) з класом A

WITH транзакції AS (
  SELECT
    user_pseudo_id,
    PARSE_DATE('%Y%m%d', event_date)                             AS дата,
    IFNULL(ecommerce.purchase_revenue_in_usd, 0)                AS дохід
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name = 'purchase'
),

по_користувачу AS (
  SELECT
    user_pseudo_id,
    SUM(дохід)                                                   AS дохід,
    COUNT(DISTINCT DATE_TRUNC(дата, MONTH))                     AS місяців_активності
  FROM транзакції
  GROUP BY 1
),

накопичувальний AS (
  SELECT
    user_pseudo_id,
    дохід,
    місяців_активності,
    SUM(дохід) OVER (ORDER BY дохід DESC)                       AS накопич_дохід,
    SUM(дохід) OVER ()                                          AS загальний_дохід
  FROM по_користувачу
),

класи AS (
  SELECT
    user_pseudo_id,
    дохід,
    місяців_активності,
    CASE
      WHEN SAFE_DIVIDE(накопич_дохід, загальний_дохід) <= 0.80 THEN 'A'
      WHEN SAFE_DIVIDE(накопич_дохід, загальний_дохід) <= 0.95 THEN 'B'
      ELSE 'C'
    END AS abc,
    CASE
      WHEN місяців_активності = 3 THEN 'X'
      WHEN місяців_активності = 2 THEN 'Y'
      ELSE 'Z'
    END AS xyz
  FROM накопичувальний
),

чемпіони_555 AS (
  SELECT user_pseudo_id FROM (
    SELECT
      user_pseudo_id,
      6 - NTILE(5) OVER (ORDER BY DATE_DIFF(DATE '2021-01-31', MAX(PARSE_DATE('%Y%m%d', event_date)), DAY) ASC) AS r,
      NTILE(5) OVER (ORDER BY COUNT(*) ASC)                     AS f,
      NTILE(5) OVER (ORDER BY SUM(IFNULL(ecommerce.purchase_revenue_in_usd,0)) ASC) AS m
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
    WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
      AND event_name = 'purchase'
    GROUP BY 1
  ) WHERE r = 5 AND f = 5 AND m = 5
),

матриця AS (
  SELECT abc, xyz, COUNT(*) AS користувачів, ROUND(SUM(дохід), 2) AS дохід
  FROM класи GROUP BY 1, 2
),

перетин AS (
  SELECT COUNT(*) AS champions_клас_a
  FROM класи k INNER JOIN чемпіони_555 c USING (user_pseudo_id)
  WHERE k.abc = 'A'
)

SELECT abc, xyz, користувачів, дохід, NULL AS champions_клас_a FROM матриця
UNION ALL
SELECT 'ПЕРЕТИН', '555+A', champions_клас_a, NULL, champions_клас_a FROM перетин
ORDER BY abc, xyz;
