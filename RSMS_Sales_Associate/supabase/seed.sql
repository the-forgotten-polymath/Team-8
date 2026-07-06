INSERT INTO health_scores (
    id,
    store_id,
    sales_score,
    inventory_score,
    customer_score,
    overall_score,
    generated_at
)
SELECT
    gen_random_uuid(),
    id,
    sales_score,
    inventory_score,
    customer_score,
    ROUND(
        (
            0.50 * sales_score +
            0.30 * inventory_score +
            0.20 * customer_score
        )::numeric,
        2
    ),
    NOW()
FROM (
    SELECT
        id,
        FLOOR(random() * 41 + 60) AS sales_score,      -- 60-100
        FLOOR(random() * 41 + 60) AS inventory_score,  -- 60-100
        FLOOR(random() * 41 + 60) AS customer_score    -- 60-100
    FROM stores
) s;
