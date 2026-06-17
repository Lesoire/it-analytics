-- Завдання 1.1-1.2: Quick Ratio, Net MAU Change, What-if аналіз

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
),

підрахунок AS (
  SELECT
    COUNTIF(стан = 'New')          AS нових,
    COUNTIF(стан = 'Resurrected')  AS воскреслих,
    COUNTIF(стан = 'Churned')      AS відтік,
    COUNTIF(стан = 'Retained')     AS утриманих
  FROM стани
)

SELECT
  нових,
  воскреслих,
  відтік,
  утриманих,
  нових + воскреслих                                            AS приплив,
  відтік                                                        AS відплив,
  (нових + воскреслих) - відтік                                 AS чистий_приріст_mau,
  ROUND(SAFE_DIVIDE(нових + воскреслих, відтік), 4)             AS quick_ratio,
  ROUND(SAFE_DIVIDE(нових + воскреслих, 1.5), 0)                AS цільовий_відтік_qr15,
  ROUND(100 * SAFE_DIVIDE(
    відтік - SAFE_DIVIDE(нових + воскреслих, 1.5), відтік), 2) AS потрібне_зниження_відтоку_pct,
  CASE
    WHEN SAFE_DIVIDE(нових + воскреслих, відтік) > 1.5 THEN 'Healthy'
    WHEN SAFE_DIVIDE(нових + воскреслих, відтік) < 1.0 THEN 'Critical'
    ELSE 'Warning'
  END AS вердикт
FROM підрахунок;
