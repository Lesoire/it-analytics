-- Завдання 2.1-2.2: NRR, Expansion Revenue, Revenue Churn

WITH місячний_дохід AS (
  SELECT
    user_pseudo_id,
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', event_date))       AS місяць,
    SUM(IFNULL(ecommerce.purchase_revenue_in_usd, 0))           AS дохід
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name = 'purchase'
  GROUP BY 1, 2
),

прапорці_активності AS (
  SELECT
    user_pseudo_id,
    MAX(IF(FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', event_date)) = '202012', 1, 0)) AS грудень,
    MAX(IF(FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', event_date)) = '202101', 1, 0)) AS січень
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
  GROUP BY 1
),

утримані AS (
  SELECT user_pseudo_id FROM прапорці_активності
  WHERE грудень = 1 AND січень = 1
),

порівняння AS (
  SELECT
    у.user_pseudo_id,
    IFNULL(г.дохід, 0)                                          AS дохід_грудень,
    IFNULL(с.дохід, 0)                                          AS дохід_січень
  FROM утримані у
  LEFT JOIN місячний_дохід г ON у.user_pseudo_id = г.user_pseudo_id AND г.місяць = '202012'
  LEFT JOIN місячний_дохід с ON у.user_pseudo_id = с.user_pseudo_id AND с.місяць = '202101'
),

фінанси AS (
  SELECT
    SUM(дохід_грудень)                                          AS база_грудень,
    SUM(дохід_січень)                                           AS утримані_січень,
    SUM(GREATEST(дохід_січень - дохід_грудень, 0))              AS expansion,
    SUM(GREATEST(дохід_грудень - дохід_січень, 0))              AS contraction
  FROM порівняння
),

весь_грудень AS (
  SELECT SUM(дохід) AS загальний_грудень FROM місячний_дохід WHERE місяць = '202012'
)

SELECT
  ф.база_грудень,
  ф.утримані_січень,
  ф.expansion,
  ф.contraction,
  ROUND(ф.утримані_січень - ф.база_грудень, 2)                 AS net_expansion,
  ROUND(100 * SAFE_DIVIDE(ф.утримані_січень, ф.база_грудень), 2) AS nrr_відсоток,
  ROUND(100 * SAFE_DIVIDE(
    (SELECT загальний_грудень FROM весь_грудень) - ф.утримані_січень,
    (SELECT загальний_грудень FROM весь_грудень)), 2)           AS revenue_churn_pct
FROM фінанси ф;
