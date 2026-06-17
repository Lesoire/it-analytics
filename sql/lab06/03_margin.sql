-- Завдання 2.1: Валова маржа = дохід - (кількість_подій * $0.005)

WITH економіка AS (
  SELECT
    user_pseudo_id,
    COUNT(*)                                                     AS подій,
    SUM(IF(event_name = 'purchase',
           IFNULL(ecommerce.purchase_revenue_in_usd, 0), 0))    AS дохід
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
  GROUP BY 1
),

маржа AS (
  SELECT
    user_pseudo_id,
    подій,
    дохід,
    дохід - подій * 0.005                                       AS валова_маржа,
    IF(дохід - подій * 0.005 < 0, 1, 0)                        AS збитковий
  FROM економіка
)

SELECT
  COUNT(*)                              AS всього_користувачів,
  COUNTIF(збитковий = 1)               AS збиткових,
  ROUND(100 * AVG(збитковий), 2)       AS відсоток_збиткових,
  ROUND(AVG(валова_маржа), 4)          AS середня_маржа,
  ROUND(MIN(валова_маржа), 4)          AS найгірша_маржа,
  ROUND(MAX(валова_маржа), 4)          AS найкраща_маржа
FROM маржа;
