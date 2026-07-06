-- Generate dummy customers
INSERT INTO customers (
    id,
    name,
    phone,
    email,
    created_at,
    gender,
    date_of_birth,
    customer_tier,
    customer_status,
    loyalty_points
)
SELECT 
    gen_random_uuid(),
    'Customer ' || gs,
    '+9198765' || lpad((floor(random() * 100000))::text, 5, '0'),
    'customer' || gs || '@example.com',
    NOW() - (random() * interval '365 days'),
    CASE WHEN random() > 0.5 THEN 'Male' ELSE 'Female' END,
    (NOW() - (random() * interval '365 days' * 40) - interval '18 years')::date,
    CASE WHEN random() > 0.8 THEN 'VIP' ELSE 'Regular' END,
    'Active',
    floor(random() * 5000)
FROM generate_series(1, 20) AS gs;

-- Generate dummy sales using the customers we just inserted (requires stores and users/staff)
-- Note: Make sure you have records in `stores` and `users` before running this,
-- otherwise the foreign keys may fail if you uncomment the store_id and user_id fields.
INSERT INTO sales (
    id,
    customer_id,
    -- store_id,  -- Uncomment and provide a valid UUID if store_id is required by your constraints
    -- user_id,   -- Uncomment and provide a valid UUID if user_id is required
    total_amount,
    payment_method,
    sale_status,
    sale_date,
    created_at,
    invoice_number
)
SELECT
    gen_random_uuid(),
    id,
    ROUND((random() * 9900 + 100)::numeric, 2),
    CASE floor(random() * 3) 
        WHEN 0 THEN 'Credit Card'
        WHEN 1 THEN 'Cash'
        ELSE 'UPI'
    END,
    'Completed',
    NOW() - (random() * interval '30 days'),
    NOW(),
    'INV-' || lpad((floor(random() * 1000000))::text, 6, '0')
FROM customers
LIMIT 50; -- Creates up to 50 sales (will loop over your customers)
