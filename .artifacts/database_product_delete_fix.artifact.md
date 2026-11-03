# Supabase SQL Fix: Clean Cascade Delete for Products

Para maibalik ang kakayahang tuluyang ma-delete ang isang product na naka-link na sa mga historical orders (imbes na ma-archive lang), kailangan nating gumawa ng function na magbubura rin sa mga naka-link na `order_items` at `sale_items` bago burahin mismo ang product.

### I-paste at i-run ito sa iyong Supabase SQL Editor:

```sql
-- I-drop ang lumang function kung mayroon man
DROP FUNCTION IF EXISTS public.delete_product_cascade(uuid);
DROP FUNCTION IF EXISTS public.delete_product_cascade;

-- Gumawa ng bagong function na mag-cacascade delete sa mga produkto
CREATE OR REPLACE FUNCTION public.delete_product_cascade(p_target_product_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Security Check: Only admin allowed to delete products
    IF NOT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'admin'
    ) THEN
        RAISE EXCEPTION 'Access denied. Only administrators can delete products.';
    END IF;

    -- 1. I-delete ang mga items mula sa Customer Orders na may ganitong product
    BEGIN
        DELETE FROM public.order_items
        WHERE product_id = p_target_product_id;
    EXCEPTION WHEN OTHERS THEN NULL; END;

    -- 2. I-delete ang mga items mula sa Cashier Sales (POS) na may ganitong product
    BEGIN
        DELETE FROM public.sale_items
        WHERE product_id = p_target_product_id;
    EXCEPTION WHEN OTHERS THEN NULL; END;

    -- 3. Kapag malinis na ang mga naka-link na tables, i-delete na mismo ang product
    DELETE FROM public.products WHERE id = p_target_product_id;
END;
$$;

-- I-set ang tama at secure na access privileges
REVOKE EXECUTE ON FUNCTION public.delete_product_cascade(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.delete_product_cascade(uuid) TO authenticated, service_role;
```

Tandaan: Kapag ginamit ang function na ito, mabubura rin ang items sa mga lumang resibo ng customers na naglalaman ng product na ito.
