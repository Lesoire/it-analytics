-- Завдання 2.1: Тижневі криві retention (W0–W12, перші 3 когорти)

WITH перший_тиждень AS (
  SELECT
    user_pseudo_id,
    DATE_TRUNC(MIN(PARSE_DATE('%Y%m%d', event_date)), WEEK(MONDAY)) AS когорта_тиждень
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
  GROUP BY 1
),

три_когорти AS (
  SELECT когорта_тиждень FROM перший_тиждень
  GROUP BY 1 ORDER BY 1 LIMIT 3
),

тижнева_активність AS (
  SELECT DISTINCT
    user_pseudo_id,
    DATE_TRUNC(PARSE_DATE('%Y%m%d', event_date), WEEK(MONDAY))  AS тиждень
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
),

з_номерами AS (
  SELECT
    п.когорта_тиждень,
    п.user_pseudo_id,
    DATE_DIFF(а.тиждень, п.когорта_тиждень, WEEK)              AS номер_тижня
  FROM перший_тиждень п
  INNER JOIN три_когорти т USING (когорта_тиждень)
  INNER JOIN тижнева_активність а USING (user_pseudo_id)
  WHERE DATE_DIFF(а.тиждень, п.когорта_тиждень, WEEK) BETWEEN 0 AND 12
),

розміри AS (
  SELECT когорта_тиждень, COUNT(DISTINCT user_pseudo_id) AS розмір_w0
  FROM з_номерами WHERE номер_тижня = 0 GROUP BY 1
),

повернення AS (
  SELECT когорта_тиждень, номер_тижня, COUNT(DISTINCT user_pseudo_id) AS активних
  FROM з_номерами GROUP BY 1, 2
)

SELECT
  FORMAT_DATE('%Y-%m-%d', п.когорта_тиждень)                   AS когорта,
  п.номер_тижня,
  п.активних,
  р.розмір_w0,
  ROUND(100 * SAFE_DIVIDE(п.активних, р.розмір_w0), 2)         AS retention_pct
FROM повернення п
INNER JOIN розміри р USING (когорта_тиждень)
ORDER BY когорта, номер_тижня;
