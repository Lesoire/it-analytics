# ЛР8 — Висновки

> Експорт: `lab08_quick_ratio.csv`, `lab08_nrr.csv` → `python python/lab08_charts.py`

> **Термінологія:**  
> **QR** (Quick Ratio) — співвідношення (Нові + Воскреслі) до Відтоку · **MAU** — активні за місяць · **NRR** (Net Revenue Retention) — збереження доходу від наявної бази · **LCP** — час до відображення основного контенту · **FCM** — push-нотифікації Firebase · **JSON** — формат даних для міжсервісної передачі · **BQ** (BigQuery) — аналітична база даних Google

## 1.1 Quick Ratio (QR)

| Метрика | Значення |
|---------|----------|
| New | 91 069 |
| Resurrected | 512 |
| Churned | 101 106 |
| Retained | 3 209 |
| Inflow | 91 581 |
| Outflow | 101 106 |
| Чистий приріст MAU | -9 525 |
| Quick Ratio | 0.9058 |
| Вердикт | Critical |

**Висновок (1.3):** На графіку стовпчик Outflow перевищує Inflow. Quick Ratio = **0.9058** < 1: за кожен новий залучений контакт продукт втрачає більше одного існуючого. Чиста втрата активної бази за січень — 9 525 користувачів. Поточний стан не дозволяє масштабувати acquisition — будь-яке нарощення залучення лише маскуватиме глибинну проблему відтоку. Пріоритет — **retention**.

---

## 1.2 What-if: досягнення QR = 1.5

- Цільовий Churned при QR=1.5: **61 054** users
- Поточний Churned: **101 106**
- Необхідне зниження відтоку: **39.61%**

**Інженерні причини надмірного відтоку:** затримка > 3 с (LCP) на першому екрані, збої в авторизації, broken deep links після email-пушу, некоректна обробка помилок при повторному вході.

---

## 2.1–2.3 NRR (Net Revenue Retention)

| Метрика | Значення |
|---------|----------|
| Дохід Retained (грудень) | 26 782 |
| Дохід Retained (січень) | 11 872 |
| Expansion Revenue | 10 289 |
| Contraction Revenue | 25 199 |
| Net Expansion | -14 910 |
| NRR | 44.33% |
| Revenue Churn proxy | 92.61% |
| Upsell users | 161 |
| Upsell delta | 10 289 |

**Negative Churn (NRR > 100%):** найпростіше досягається в **підписочній** моделі (auto-renew + tier upsell) або usage-based монетизації з volume discounts — обидва варіанти дозволяють автоматично нарощувати дохід від наявних клієнтів без їхнього активного рішення.

**Фіча для upsell:** блок «Разом з цим купують» на сторінці оформлення + bundle-знижка для Retained-сегменту.

---

## 3.1–3.3 Activation & Resurrection Loops

| Метрика | Значення |
|---------|----------|
| Нових users (січень) | 91 069 |
| Без view_item за 24 год | 73 623 (80.84%) |
| Dormant (Churned) | 101 106 |

**Activation Loop:** тригер на `session_start` без `view_item` за 24 год → push із персональним каталогом бестселерів або купон на першу покупку.

**JSON-контракт (приклад для BQ → FCM):**
```json
{
  "user_id": "1242944.3150378184",
  "segment_type": "resurrection",
  "last_category_name": "Lifestyle/Bags/",
  "personalized_message": "Ми сумуємо за вами! Перегляньте нові надходження у категорії Lifestyle/Bags/"
}
```

**Архітектура:** Cloud Function підписана на Pub/Sub (daily lifecycle job) → оновлює колекцію `user_segments` у Firestore → FCM відправляє personalized payload на основі `last_category_name`.
