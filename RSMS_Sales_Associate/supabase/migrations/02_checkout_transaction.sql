-- Migration: Complete Checkout Transaction Function
-- Objective: Atomic transaction to insert sale, insert sale_items, and update inventory with stock validation.

CREATE OR REPLACE FUNCTION public.complete_checkout_transaction(
  p_customer_id UUID,
  p_user_id UUID,
  p_payment_method TEXT,
  p_discount_amount NUMERIC,
  p_tax_amount NUMERIC,
  p_invoice_number TEXT,
  p_items JSONB -- Array of {product_id: UUID, quantity: INT, unit_price: NUMERIC}
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_store_id UUID;
  v_sale_id UUID;
  v_item RECORD;
  v_current_qty INT;
  v_total_amount NUMERIC := 0;
BEGIN
  RAISE NOTICE 'Checkout transaction started for user %', p_user_id;

  -- 1. Fetch store_id for the user
  SELECT store_id INTO v_store_id
  FROM public.users
  WHERE id = p_user_id;

  IF v_store_id IS NULL THEN
    RAISE EXCEPTION 'User does not belong to any store';
  END IF;
  
  RAISE NOTICE 'Store ID resolved: %', v_store_id;

  -- 2. Validate inventory for all items before making any modifications
  FOR v_item IN SELECT * FROM jsonb_to_recordset(p_items) AS x(product_id UUID, quantity INT, unit_price NUMERIC)
  LOOP
    SELECT quantity INTO v_current_qty
    FROM public.inventory
    WHERE product_id = v_item.product_id AND store_id = v_store_id;

    RAISE NOTICE 'Validating product %: required %, current stock %', v_item.product_id, v_item.quantity, v_current_qty;

    IF v_current_qty IS NULL OR v_current_qty < v_item.quantity THEN
      RAISE EXCEPTION 'Insufficient stock';
    END IF;
  END LOOP;

  -- 3. Calculate total amount
  SELECT COALESCE(SUM(quantity * unit_price), 0) INTO v_total_amount
  FROM jsonb_to_recordset(p_items) AS x(product_id UUID, quantity INT, unit_price NUMERIC);
  
  v_total_amount := v_total_amount - p_discount_amount + p_tax_amount;

  RAISE NOTICE 'Calculated total amount: %', v_total_amount;

  -- 4. Insert into sales
  INSERT INTO public.sales (
    customer_id,
    user_id,
    store_id,
    total_amount,
    payment_method,
    invoice_number,
    discount_amount,
    tax_amount,
    sale_status,
    sale_date
  ) VALUES (
    p_customer_id,
    p_user_id,
    v_store_id,
    v_total_amount,
    p_payment_method,
    p_invoice_number,
    p_discount_amount,
    p_tax_amount,
    'Completed',
    NOW()
  ) RETURNING id INTO v_sale_id;

  RAISE NOTICE 'Inserted sale record with ID: %', v_sale_id;

  -- 5. Insert into sale_items and 6. Update inventory
  FOR v_item IN SELECT * FROM jsonb_to_recordset(p_items) AS x(product_id UUID, quantity INT, unit_price NUMERIC)
  LOOP
    INSERT INTO public.sale_items (
      sale_id,
      product_id,
      quantity,
      unit_price
    ) VALUES (
      v_sale_id,
      v_item.product_id,
      v_item.quantity,
      v_item.unit_price
    );

    UPDATE public.inventory
    SET quantity = quantity - v_item.quantity
    WHERE product_id = v_item.product_id AND store_id = v_store_id;
    
    RAISE NOTICE 'Updated inventory for product %: reduced by %', v_item.product_id, v_item.quantity;
  END LOOP;

  RAISE NOTICE 'Checkout transaction committed successfully';
  RETURN v_sale_id;
END;
$$;
