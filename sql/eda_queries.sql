-- EDA --

--  Delivery Delay Summary
SELECT 
    delivery_status,
    COUNT(*) AS num_deliveries,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM delivery_logs) * 100, 2) AS pct_deliveries,
    ROUND(AVG(DATEDIFF(actual_delivery_date, expected_delivery_date)), 2) AS avg_delay_days
FROM delivery_logs
GROUP BY delivery_status
ORDER BY num_deliveries DESC;
-- ====================================================================================================

-- Average Lead Time per Supplier
SELECT 
    s.supplier_name,
    s.country,
    ROUND(AVG(DATEDIFF(actual_delivery_date, order_date)), 2) AS avg_lead_time_days,
    COUNT(*) AS num_orders
FROM delivery_logs d
JOIN suppliers s ON d.supplier_id = s.supplier_id
WHERE actual_delivery_date IS NOT NULL
GROUP BY s.supplier_name, s.country
ORDER BY avg_lead_time_days DESC
LIMIT 10;
-- ====================================================================================================

-- Stock-Out Frequency by Category
SELECT 
    c.category,
    COUNT(*) AS stockout_days
FROM inventory_levels i
JOIN components c ON i.component_id = c.component_id
WHERE i.closing_stock = 0
GROUP BY c.category
ORDER BY stockout_days DESC;
-- ====================================================================================================

-- Overstock Frequency vs. Safety Stock
SELECT 
    c.category,
    COUNT(*) AS overstock_days,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM inventory_levels) * 100, 2) AS pct_overstock_days
FROM inventory_levels i
JOIN components c 
    ON i.component_id = c.component_id
WHERE i.closing_stock > c.safety_stock_units
GROUP BY c.category
ORDER BY overstock_days DESC;
-- =========================================================================================================

-- Forecast Accuracy (MAPE) by Category
SELECT 
    c.category,
    ROUND(AVG(ABS(f.forecast_units - po.actual_units) / f.forecast_units) * 100, 2) AS avg_forecast_error_pct
FROM forecasts f
JOIN (
    SELECT 
        DATE_FORMAT(date, '%Y-%m') AS month,
        component_id,
        SUM(units_required) AS actual_units
    FROM production_orders
    GROUP BY month, component_id
) po 
  ON f.month = po.month AND f.component_id = po.component_id
JOIN components c ON f.component_id = c.component_id
GROUP BY c.category
ORDER BY avg_forecast_error_pct DESC; 