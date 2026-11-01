# Supabase SQL Fix: Clean Cascade Delete (Including order_messages)

Idinagdag ang pagbura sa **`order_messages`** (order chat messages) na nakatali sa customer/sender bago i-delete ang profile.

### I-paste at i-run ito sa Supabase SQL Editor:

```sql
-- Drop old function signature first
DROP FUNCTION IF EXISTS public.delete_user_cascade(uuid);
DROP FUNCTION IF EXISTS public.delete_user_cascade;

CREATE OR REPLACE FUNCTION public.delete_user_cascade(p_target_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Security Check: Only admin allowed to delete users
    IF NOT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'admin'
    ) THEN
        RAISE EXCEPTION 'Access denied. Only administrators can delete users.';
    END IF;

    -- 0. Clean up order messages (chat) linked to orders or sent by user
    BEGIN
        DELETE FROM public.order_messages
        WHERE sender_id = p_target_user_id
           OR order_id IN (SELECT id FROM public.orders WHERE customer_id = p_target_user_id);
    EXCEPTION WHEN OTHERS THEN NULL; END;

    -- 1. Clean up ALL child records of ORDERS linked to this customer_id
    BEGIN
        DELETE FROM public.deliveries
        WHERE order_id IN (SELECT id FROM public.orders WHERE customer_id = p_target_user_id)
           OR driver_id = p_target_user_id;
    EXCEPTION WHEN OTHERS THEN NULL; END;

    BEGIN
        DELETE FROM public.order_items
        WHERE order_id IN (SELECT id FROM public.orders WHERE customer_id = p_target_user_id);
    EXCEPTION WHEN OTHERS THEN NULL; END;

    BEGIN
        DELETE FROM public.order_status_history
        WHERE order_id IN (SELECT id FROM public.orders WHERE customer_id = p_target_user_id);
    EXCEPTION WHEN OTHERS THEN NULL; END;

    BEGIN
        DELETE FROM public.debts
        WHERE order_id IN (SELECT id FROM public.orders WHERE customer_id = p_target_user_id)
           OR customer_id = p_target_user_id;
    EXCEPTION WHEN OTHERS THEN NULL; END;

    BEGIN
        DELETE FROM public.reviews
        WHERE order_id IN (SELECT id FROM public.orders WHERE customer_id = p_target_user_id)
           OR customer_id = p_target_user_id;
    EXCEPTION WHEN OTHERS THEN NULL; END;

    BEGIN
        DELETE FROM public.payments
        WHERE order_id IN (SELECT id FROM public.orders WHERE customer_id = p_target_user_id)
           OR customer_id = p_target_user_id;
    EXCEPTION WHEN OTHERS THEN NULL; END;

    -- Now delete the ORDERS
    BEGIN
        DELETE FROM public.orders WHERE customer_id = p_target_user_id;
    EXCEPTION WHEN OTHERS THEN NULL; END;

    -- 2. Clean up ALL child records of SALES linked to this customer_id
    BEGIN
        DELETE FROM public.sale_items
        WHERE sale_id IN (SELECT id FROM public.sales WHERE customer_id = p_target_user_id);
    EXCEPTION WHEN OTHERS THEN NULL; END;

    BEGIN
        DELETE FROM public.payments
        WHERE sale_id IN (SELECT id FROM public.sales WHERE customer_id = p_target_user_id);
    EXCEPTION WHEN OTHERS THEN NULL; END;

    -- Now delete the SALES
    BEGIN
        DELETE FROM public.sales WHERE customer_id = p_target_user_id;
    EXCEPTION WHEN OTHERS THEN NULL; END;

    -- 3. Clean up GALLONS, RFID & TRANSACTIONS
    BEGIN
        DELETE FROM public.rfid_qr_records
        WHERE gallon_id IN (SELECT id FROM public.gallons WHERE customer_id = p_target_user_id)
           OR customer_id = p_target_user_id;
    EXCEPTION WHEN OTHERS THEN NULL; END;

    BEGIN
        DELETE FROM public.gallon_transactions
        WHERE gallon_id IN (SELECT id FROM public.gallons WHERE customer_id = p_target_user_id)
           OR customer_id = p_target_user_id;
    EXCEPTION WHEN OTHERS THEN NULL; END;

    BEGIN
        DELETE FROM public.gallons WHERE customer_id = p_target_user_id;
    EXCEPTION WHEN OTHERS THEN NULL; END;

    -- 4. Clean up notifications
    BEGIN
        DELETE FROM public.notifications WHERE user_id = p_target_user_id;
    EXCEPTION WHEN OTHERS THEN NULL; END;

    -- 5. FINALLY delete profile and auth user
    DELETE FROM public.profiles WHERE id = p_target_user_id;
    BEGIN DELETE FROM auth.users WHERE id = p_target_user_id; EXCEPTION WHEN OTHERS THEN NULL; END;
END;
$$;

-- Secure access privileges: REVOKE from anon, GRANT to authenticated & service_role
REVOKE EXECUTE ON FUNCTION public.delete_user_cascade(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.delete_user_cascade(uuid) TO authenticated, service_role;
```
