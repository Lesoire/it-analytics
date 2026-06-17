-- Завдання 2.1: Кореляція між кількістю переглядів товарів та доходом

WITH метрики_користувача AS (
  SELECT
    user_pseudo_id,
    COUNTIF(event_name = 'view_item')                            AS перегляди,
    SUM(IF(event_name = 'purchase',
           IFNULL(ecommerce.purchase_revenue_in_usd, 0), 0))    AS дохід
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
  GROUP BY 1
  HAVING перегляди > 5
)

SELECT
  COUNT(*)                                AS вибірка_користувачів,
  ROUND(AVG(перегляди), 2)               AS середні_перегляди,
  ROUND(AVG(дохід), 2)                   AS середній_дохід,
  ROUND(CORR(перегляди, дохід), 4)       AS кореляція_пірсона
FROM метрики_користувача
WHERE перегляди > 0;
