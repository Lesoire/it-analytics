-- Завдання 1.1: RFM-скоринг через NTILE(5) + виділення ключових сегментів

WITH базові_метрики AS (
  SELECT
    user_pseudo_id,
    MAX(PARSE_DATE('%Y%m%d', event_date))                        AS остання_покупка,
    COUNT(*)                                                     AS частота,
    SUM(IFNULL(ecommerce.purchase_revenue_in_usd, 0))           AS сума
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name = 'purchase'
  GROUP BY 1
),

давність AS (
  SELECT
    user_pseudo_id,
    DATE_DIFF(DATE '2021-01-31', остання_покупка, DAY)          AS днів_тому,
    частота,
    сума
  FROM базові_метрики
),

бали AS (
  SELECT
    *,
    6 - NTILE(5) OVER (ORDER BY днів_тому ASC)                  AS r,
    NTILE(5) OVER (ORDER BY частота ASC)                        AS f,
    NTILE(5) OVER (ORDER BY сума ASC)                           AS m
  FROM давність
),

сегменти AS (
  SELECT
    *,
    CONCAT(CAST(r AS STRING), CAST(f AS STRING), CAST(m AS STRING)) AS rfm_код,
    CASE
      WHEN r = 5 AND f = 5 AND m = 5 THEN 'Champions'
      WHEN r = 2 AND f = 1 AND m BETWEEN 1 AND 5 THEN 'At Risk'
      WHEN r = 1 AND f = 1 AND m = 1 THEN 'Hibernating'
      ELSE 'Інші'
    END AS сегмент
  FROM бали
),

підсумок AS (
  SELECT SUM(сума) AS весь_дохід FROM сегменти
)

SELECT
  сегмент,
  COUNT(*)                                                       AS користувачів,
  ROUND(SUM(сума), 2)                                           AS дохід_сегменту,
  ROUND(100 * SAFE_DIVIDE(SUM(сума), (SELECT весь_дохід FROM підсумок)), 2) AS частка_доходу
FROM сегменти
WHERE сегмент IN ('Champions', 'At Risk', 'Hibernating')
GROUP BY 1
ORDER BY дохід_сегменту DESC;
