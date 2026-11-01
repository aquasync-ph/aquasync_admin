# Walk-In POS Transaction Fix (Cashier & Admin Side)

## Root Cause Analysis

Kapag pinili ang **Walk-In** sa cashier side (`aquasync_cashier_app`), hindi ito nagre-record o nag-i-save sa database (kaya wala rin sa admin side) dahil sa mga sumusunod:

1. **Row Level Security (RLS) & Profile Insertion Failure**:
   - Ang Walk-in customer ay may temporary ID na `'walk-in'`. Sinusubukan ng cashier app na i-insert ito sa `public.profiles` table bago i-save ang transaksyon.
   - Dahil ang naka-login ay **Cashier** (at hindi Admin), hinaharangan ng Supabase RLS policies ang pag-insert ng bagong profile para sa customer kung walang tamang permission o RPC function.
2. **Null Customer ID / Database Constraint Error**:
   - Dahil nag-fail ang pag-insert sa `profiles`, ang `customerId` ay nagiging `null`.
   - Kapag sinubukan nitong mag-insert sa `sales` at `orders` tables gamit ang `customer_id: null`, nire-reject ito ng database (dahil sa NOT NULL constraint o foreign key check).
3. **Swallowed Exceptions**:
   - Ang mga direktang SQL inserts ay nakabalot sa `try { ... } catch (e) {}`, kaya silent failure ito — walang error sa UI ng cashier, ngunit walang data na pumapasok sa Supabase kaya blangko rin sa Admin Side.

---

## Solution / Fix

Upang maayos ito nang tuluyan at masigurong tuwing pipili ng **Walk-In** ang cashier ay awtomatikong mase-save at magre-record ito sa parehong cashier at admin side, sundin ang mga hakbang na ito:

### Step 1: I-run ang SQL Script sa Supabase SQL Editor

I-copy at i-paste ang SQL script na ito sa **Supabase SQL Editor** ng inyong project para i-setup ang `cashier_complete_sale` RPC function na may `SECURITY DEFINER` (para ma-bypass ang RLS restrictions ng cashier kapag nagre-record ng walk-in at sales) pati na rin ang tamang RLS policies:

```sql
-- 1. Siguraduhing pwede ang null customer_id o kaya ay handled ang walk-in
ALTER TABLE public.sales ALTER COLUMN customer_id DROP NOT NULL;
ALTER TABLE public.orders ALTER COLUMN customer_id DROP NOT NULL;

-- 2. Lumikha ng cashier_complete_sale RPC function na may SECURITY DEFINER
CREATE OR REPLACE FUNCTION public.cashier_complete_sale(
    p_receipt_number text,
    p_customer_id text DEFAULT NULL,
    p_payment_method text DEFAULT 'cash',
    p_cash_received numeric DEFAULT 0,
    p_items jsonb DEFAULT '[]'::jsonb,
    p_fulfillment_type text DEFAULT 'Pick-up at Store',
    p_cashier_id uuid DEFAULT NULL,
    p_cashier_name text DEFAULT 'Cashier',
    p_gcash_ref_no text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_sale_id uuid;
    v_customer_uuid uuid;
    v_item jsonb;
    v_product_id uuid;
    v_qty int;
    v_unit_price numeric;
    v_subtotal numeric;
    v_total_amount numeric := 0;
    v_is_walk_in boolean := false;
    v_order_type text := 'pos';
BEGIN
    -- Handle walk-in customer profile automatically
    IF p_customer_id IS NULL OR p_customer_id = 'walk-in' OR p_customer_id = '' THEN
        v_is_walk_in := true;
        v_order_type := 'walk_in';

        -- Hanapin o gawa ng default Walk-in Customer sa profiles
        SELECT id INTO v_customer_uuid FROM public.profiles WHERE full_name ILIKE 'Walk-in Customer' LIMIT 1;
        IF v_customer_uuid IS NULL THEN
            v_customer_uuid := gen_random_uuid();
            INSERT INTO public.profiles (id, full_name, phone, address, role, created_at, updated_at)
            VALUES (v_customer_uuid, 'Walk-in Customer', 'N/A', 'Station Walk-in / Store Pickup', 'customer', now(), now());
        END IF;
    ELSE
        BEGIN
            v_customer_uuid := p_customer_id::uuid;
        EXCEPTION WHEN OTHERS THEN
            v_customer_uuid := NULL;
        END;
    END IF;

    -- Compute total amount
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_product_id := (v_item->>'product_id')::uuid;
        v_qty := COALESCE((v_item->>'quantity')::int, 1);

        SELECT price INTO v_unit_price FROM public.products WHERE id = v_product_id;
        IF v_unit_price IS NULL THEN
            v_unit_price := COALESCE((v_item->>'unit_price')::numeric, 0.0);
        END IF;

        v_subtotal := v_unit_price * v_qty;
        v_total_amount := v_total_amount + v_subtotal;
    END LOOP;

    IF v_total_amount <= 0 THEN
        v_total_amount := COALESCE(p_cash_received, 0);
    END IF;

    -- Insert sa public.sales
    INSERT INTO public.sales (
        id,
        receipt_number,
        customer_id,
        cashier_id,
        cashier_name,
        total_amount,
        cash_received,
        payment_method,
        fulfillment_type,
        status,
        is_walk_in,
        order_type,
        gcash_ref_no,
        created_at
    ) VALUES (
        gen_random_uuid(),
        p_receipt_number,
        v_customer_uuid,
        p_cashier_id,
        p_cashier_name,
        v_total_amount,
        CASE WHEN lower(p_payment_method) = 'gcash' THEN v_total_amount ELSE p_cash_received END,
        lower(p_payment_method),
        p_fulfillment_type,
        'Completed',
        v_is_walk_in,
        v_order_type,
        p_gcash_ref_no,
        now()
    )
    RETURNING id INTO v_sale_id;

    -- Insert sale items at bawas stock
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_product_id := (v_item->>'product_id')::uuid;
        v_qty := COALESCE((v_item->>'quantity')::int, 1);

        SELECT price INTO v_unit_price FROM public.products WHERE id = v_product_id;
        IF v_unit_price IS NULL THEN v_unit_price := 0.0; END IF;
        v_subtotal := v_unit_price * v_qty;

        INSERT INTO public.sale_items (
            sale_id,
            product_id,
            product_name,
            unit_price,
            quantity,
            subtotal
        ) VALUES (
            v_sale_id,
            v_product_id,
            (SELECT name FROM public.products WHERE id = v_product_id),
            v_unit_price,
            v_qty,
            v_subtotal
        );

        UPDATE public.products
        SET stock = GREATEST(0, stock - v_qty),
            updated_at = now()
        WHERE id = v_product_id;
    END LOOP;

    -- Insert din sa public.orders para makita sa Admin Side (Orders / Deliveries)
    INSERT INTO public.orders (
        id,
        order_number,
        customer_id,
        total_amount,
        payment_method,
        fulfillment_type,
        order_status,
        is_walk_in,
        order_type,
        created_at
    ) VALUES (
        gen_random_uuid(),
        p_receipt_number,
        v_customer_uuid,
        v_total_amount,
        lower(p_payment_method),
        p_fulfillment_type,
        'Completed',
        v_is_walk_in,
        v_order_type,
        now()
    );

    RETURN v_sale_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.cashier_complete_sale TO authenticated, anon, service_role;

-- 3. RLS Policies para sa Cashiers
ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sale_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow cashiers insert sales" ON public.sales;
CREATE POLICY "Allow cashiers insert sales" ON public.sales FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Allow cashiers insert sale_items" ON public.sale_items;
CREATE POLICY "Allow cashiers insert sale_items" ON public.sale_items FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Allow cashiers insert orders" ON public.orders;
CREATE POLICY "Allow cashiers insert orders" ON public.orders FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public read sales" ON public.sales;
CREATE POLICY "Allow public read sales" ON public.sales FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow public read sale_items" ON public.sale_items;
CREATE POLICY "Allow public read sale_items" ON public.sale_items FOR SELECT USING (true);
```

---

### Step 2: I-update ang `completeTransaction` sa Cashier App (`app_state.dart`)

Sa `aquasync_cashier_app/lib/providers/app_state.dart`, siguraduhing ipinapasa ang `p_customer_id`, `p_cashier_id`, at `p_cashier_name` nang tama sa RPC call:

```dart
      await _supabase.rpc('cashier_complete_sale', params: {
        'p_receipt_number': receiptNumber,
        'p_customer_id': customerId == 'walk-in' ? null : customerId,
        'p_payment_method': paymentMethod.toLowerCase(),
        'p_cash_received': paymentMethod.toLowerCase() == 'gcash' ? null : cashReceived,
        'p_items': itemsPayload,
        'p_fulfillment_type': _fulfillmentType,
        'p_cashier_id': _cashierId,
        'p_cashier_name': _cashierName ?? 'Cashier',
        'p_gcash_ref_no': gcashRefNo?.replaceAll(' ', '').trim(),
      });
```
