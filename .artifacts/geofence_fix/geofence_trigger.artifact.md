# Supabase SQL Fix: Geofence Validation Trigger

Para masigurong hindi makaka-order ang mga user na wala sa proximity ng store (base sa na-configure na geofence radius sa Admin Dashboard), kailangan natin ng **Database Trigger**.

Ang trigger na ito ay tatakbo tuwing may papasok na bagong order sa `public.orders`. Iche-check nito ang layo ng customer (mula sa `public.profiles`) at ang lokasyon ng station (mula sa `public.station_settings`). Kapag lagpas sa `geofence_radius_km` ang distance at naka-ON ang `enforce_geofence_radius`, awtomatikong ire-reject ng database ang order.

### Mga Hakbang:

1. Buksan ang inyong **Supabase Dashboard**.
2. Pumunta sa **SQL Editor**.
3. Gumawa ng **New Query** at i-paste ang code sa ibaba.
4. I-click ang **Run**.

```sql
-- 1. I-enable ang extensions para sa distance calculation
CREATE EXTENSION IF NOT EXISTS cube;
CREATE EXTENSION IF NOT EXISTS earthdistance;

-- 2. Gumawa ng function na mag-checheck ng distance
CREATE OR REPLACE FUNCTION public.check_order_geofence()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_enforce_geofence boolean;
    v_geofence_radius numeric;
    v_station_lat numeric;
    v_station_lng numeric;
    v_customer_lat numeric;
    v_customer_lng numeric;
    v_distance_km numeric;
BEGIN
    -- I-apply lang ang geofence check sa mga Delivery orders
    IF NEW.fulfillment_type ILIKE '%delivery%' OR NEW.order_type ILIKE '%delivery%' THEN

        -- Kunin ang settings ng station mula sa Admin dashboard
        SELECT enforce_geofence_radius, geofence_radius_km, latitude, longitude
        INTO v_enforce_geofence, v_geofence_radius, v_station_lat, v_station_lng
        FROM public.station_settings
        LIMIT 1;

        -- Kung naka-ON ang enforce geofence, gawin ang validation
        IF v_enforce_geofence = true THEN
            -- Kunin ang coordinates ng customer
            SELECT latitude, longitude
            INTO v_customer_lat, v_customer_lng
            FROM public.profiles
            WHERE id = NEW.customer_id;

            -- Siguraduhing may valid coordinates
            IF v_customer_lat IS NOT NULL AND v_customer_lng IS NOT NULL AND v_station_lat IS NOT NULL AND v_station_lng IS NOT NULL THEN

                -- Kalkulahin ang layo (in kilometers)
                v_distance_km := earth_distance(
                    ll_to_earth(v_station_lat::float8, v_station_lng::float8),
                    ll_to_earth(v_customer_lat::float8, v_customer_lng::float8)
                ) / 1000.0;

                -- Kapag lagpas sa geofence, i-reject ang insert
                IF v_distance_km > v_geofence_radius THEN
                    RAISE EXCEPTION 'OUT_OF_GEOFENCE: Customer is % km away. Maximum allowed is % km.',
                        ROUND(v_distance_km, 2), v_geofence_radius;
                END IF;
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

-- 3. I-attach ang function bilang trigger sa orders table
DROP TRIGGER IF EXISTS trg_check_order_geofence ON public.orders;
CREATE TRIGGER trg_check_order_geofence
BEFORE INSERT ON public.orders
FOR EACH ROW
EXECUTE FUNCTION public.check_order_geofence();
```

### Paano Ito Gumagana?
- **Admin Control**: Kung i-turn OFF ninyo ang "Proximity Geofence" o baguhin ang radius sa **Live Map Tracking & Geofence Control** sa inyong Admin Dashboard, awtomatiko itong susundin ng database nang walang kailangang baguhin sa app.
- **Fail-Safe**: Dahil nasa database level ito (Supabase Trigger), hindi ito mababypass kahit anong app pa ang gamitin ng customer para mag-order. Lalabas na error ay `OUT_OF_GEOFENCE` na madaling ma-catch at ma-display sa Customer App.