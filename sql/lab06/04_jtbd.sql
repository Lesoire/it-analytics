-- Завдання 2.2: JTBD сегментація — Price Comparison та Window Shopping

WITH поведінка AS (
  SELECT
    user_pseudo_id,
    COUNT(*)                                                     AS всього_подій,
    COUNTIF(event_name = 'view_item')                           AS переглядів,
    COUNTIF(event_name = 'add_to_cart')                         AS в_кошик,
    COUNTIF(event_name = 'purchase')                            AS покупок
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
  GROUP BY 1
),

теги AS (
  SELECT
    user_pseudo_id,
    CASE
      WHEN переглядів > 10 AND в_кошик = 0 THEN 'Price Comparison'
      WHEN покупок = 0 AND всього_подій >= 50 THEN 'Window Shopping'
      ELSE 'Інші'
    END AS jtbd
  FROM поведінка
)

SELECT
  jtbd,
  COUNT(*)                                                       AS користувачів,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)              AS відсоток
FROM теги
WHERE jtbd != 'Інші'
GROUP BY 1
ORDER BY користувачів DESC;
