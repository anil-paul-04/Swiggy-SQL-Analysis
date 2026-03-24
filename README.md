# Swiggy Data Analysis Using SQL

## Introduction

This project analyzes Swiggy food delivery data using SQL to extract meaningful insights such as top-performing restaurants, most ordered dishes, and revenue trends.

## Tools Used

* SQL Server
* T-SQL
* Data Modeling (Star Schema)

## Data Cleaning & Validation

### Null Check

```sql
SELECT 
    SUM(CASE WHEN State IS NULL THEN 1 ELSE 0 END) AS null_state,
    SUM(CASE WHEN City IS NULL THEN 1 ELSE 0 END) AS null_city
FROM swiggy_data;
```

✔ No null values found

---

## Key Performance Indicators (KPIs)

### Total Orders

```sql
SELECT COUNT(*) AS total_orders
FROM fact_swiggy_orders;
```

---

### Total Revenue

```sql
SELECT SUM(price_INR) AS total_revenue
FROM fact_swiggy_orders;
```

---

## Business Analysis

### Monthly Revenue

```sql
SELECT d.year, d.month, SUM(price_INR) AS total_revenue
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.year, d.month;
```

---

## Insights

* No missing or duplicate data
* Certain cities generate higher revenue
* Popular dishes contribute significantly to sales

---

## Conclusion

This project demonstrates how SQL can be used to transform raw data into meaningful business insights and support data-driven decision-making.

