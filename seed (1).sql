USE Trash2Cash;
GO

MERGE Plans AS target
USING (VALUES
  ('Starter', 6, 6.00, 0.00, 0.00, 'Flexible pickups, standard rewards, app tracking', 1),
  ('Plus', 14, 10.00, 149.00, 8.00, 'More bags, higher weight limits, bonus points, priority slots', 1),
  ('Impact Pro', 30, 18.00, 299.00, 15.00, 'High-volume recycling, best point multiplier, priority routing', 1)
) AS source (name, monthly_bag_limit, max_weight_per_bag, price, bonus_percentage, benefits, is_active)
ON target.name = source.name
WHEN MATCHED THEN UPDATE SET
  monthly_bag_limit = source.monthly_bag_limit,
  max_weight_per_bag = source.max_weight_per_bag,
  price = source.price,
  bonus_percentage = source.bonus_percentage,
  benefits = source.benefits,
  is_active = source.is_active,
  updated_at = SYSUTCDATETIME()
WHEN NOT MATCHED THEN
  INSERT (name, monthly_bag_limit, max_weight_per_bag, price, bonus_percentage, benefits, is_active)
  VALUES (source.name, source.monthly_bag_limit, source.max_weight_per_bag, source.price, source.bonus_percentage, source.benefits, source.is_active);
GO

MERGE Categories AS target
USING (VALUES
  ('Plastic', 12.00, 1),
  ('Paper', 8.00, 1),
  ('Metal', 22.00, 1),
  ('Glass', 10.00, 1),
  ('Electronics', 35.00, 1),
  ('Organic Compost', 6.00, 1)
) AS source (name, points_per_kg, is_active)
ON target.name = source.name
WHEN MATCHED THEN UPDATE SET points_per_kg = source.points_per_kg, is_active = source.is_active, updated_at = SYSUTCDATETIME()
WHEN NOT MATCHED THEN INSERT (name, points_per_kg, is_active) VALUES (source.name, source.points_per_kg, source.is_active);
GO

MERGE Service_Areas AS target
USING (VALUES
  ('New Cairo', 'Cairo', 1, 20.00),
  ('Nasr City', 'Cairo', 1, 15.00),
  ('Dokki', 'Giza', 1, 18.00),
  ('Smouha', 'Alexandria', 1, 22.00),
  ('Maadi', 'Cairo', 1, 16.00)
) AS source (area_name, city, is_active, delivery_fee)
ON target.area_name = source.area_name AND target.city = source.city
WHEN MATCHED THEN UPDATE SET is_active = source.is_active, delivery_fee = source.delivery_fee, updated_at = SYSUTCDATETIME()
WHEN NOT MATCHED THEN INSERT (area_name, city, is_active, delivery_fee) VALUES (source.area_name, source.city, source.is_active, source.delivery_fee);
GO

MERGE Trucks AS target
USING (VALUES
  ('T2C-1842', 'Omar Hassan', 'available', 'New Cairo'),
  ('T2C-7721', 'Nour Adel', 'available', 'Nasr City'),
  ('T2C-4420', 'Salma Fathy', 'maintenance', 'Smouha')
) AS source (plate_number, driver_name, current_status, current_area)
ON target.plate_number = source.plate_number
WHEN MATCHED THEN UPDATE SET driver_name = source.driver_name, current_status = source.current_status, current_area = source.current_area, updated_at = SYSUTCDATETIME()
WHEN NOT MATCHED THEN INSERT (plate_number, driver_name, current_status, current_area) VALUES (source.plate_number, source.driver_name, source.current_status, source.current_area);
GO

INSERT INTO Truck_Areas (truck_id, area_id)
SELECT t.truck_id, a.area_id
FROM Trucks t
JOIN Service_Areas a ON
  (t.plate_number = 'T2C-1842' AND a.area_name IN ('New Cairo', 'Maadi')) OR
  (t.plate_number = 'T2C-7721' AND a.area_name IN ('Nasr City', 'Dokki')) OR
  (t.plate_number = 'T2C-4420' AND a.area_name IN ('Smouha'))
WHERE NOT EXISTS (
  SELECT 1 FROM Truck_Areas ta WHERE ta.truck_id = t.truck_id AND ta.area_id = a.area_id
);
GO

MERGE System_Settings AS target
USING (VALUES
  ('minimum_bag_weight_kg', '1'),
  ('bonus_multiple_categories_points', '10'),
  ('bonus_weekly_consistency_points', '20'),
  ('bonus_ideal_weight_points', '5'),
  ('ideal_weight_kg', '5'),
  ('ideal_weight_tolerance_kg', '1'),
  ('co2_saved_kg_per_kg_recycled', '1.8'),
  ('water_saved_liters_per_kg_recycled', '28')
) AS source (setting_key, setting_value)
ON target.setting_key = source.setting_key
WHEN MATCHED THEN UPDATE SET setting_value = source.setting_value, updated_at = SYSUTCDATETIME()
WHEN NOT MATCHED THEN INSERT (setting_key, setting_value) VALUES (source.setting_key, source.setting_value);
GO

MERGE Achievements AS target
USING (VALUES
  ('First Bag', 'Submitted your first recyclable bag.'),
  ('Weekly Hero', 'Recycled consistently within a week.'),
  ('Category Explorer', 'Sorted multiple waste types in one bag.'),
  ('Impact Maker', 'Crossed a meaningful recycled-weight milestone.')
) AS source (title, description)
ON target.title = source.title
WHEN MATCHED THEN UPDATE SET description = source.description
WHEN NOT MATCHED THEN INSERT (title, description) VALUES (source.title, source.description);
GO

MERGE Partners AS target
USING (VALUES
  ('Brew Haven', 'Neighborhood cafe rewards for eco-conscious members.', 'Cafe', 'https://images.unsplash.com/photo-1445116572660-236099ec97a0?auto=format&fit=crop&w=600&q=80', 'hello@brewhaven.eco', '+201155000001', 1),
  ('Green Basket', 'Organic store perks, reusable essentials, and refill discounts.', 'Eco Store', 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=600&q=80', 'care@greenbasket.eco', '+201155000002', 1),
  ('Cycle Care', 'City bike servicing and sustainable commuting benefits.', 'Service', 'https://images.unsplash.com/photo-1485965120184-e220f721d03e?auto=format&fit=crop&w=600&q=80', 'support@cyclecare.eco', '+201155000003', 1),
  ('Harvest Table', 'Farm-to-table restaurant rewards and seasonal offers.', 'Restaurant', 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=600&q=80', 'welcome@harvesttable.eco', '+201155000004', 1)
) AS source (name, description, category, logo_url, contact_email, phone, is_active)
ON target.name = source.name
WHEN MATCHED THEN UPDATE SET
  description = source.description,
  category = source.category,
  logo_url = source.logo_url,
  contact_email = source.contact_email,
  phone = source.phone,
  is_active = source.is_active
WHEN NOT MATCHED THEN
  INSERT (name, description, category, logo_url, contact_email, phone, is_active)
  VALUES (source.name, source.description, source.category, source.logo_url, source.contact_email, source.phone, source.is_active);
GO

MERGE Partner_Offers AS target
USING (
  SELECT p.partner_id, v.title, v.description, v.points_required, v.discount_type, v.discount_value, v.coupon_code, v.expiry_date, v.is_active
  FROM Partners p
  JOIN (VALUES
    ('Brew Haven', 'Free oat milk upgrade', 'Unlock a free oat milk or reusable cup size upgrade on your next order.', 120, 'benefit', 1.00, 'BREW-GREEN', '2026-12-31', 1),
    ('Brew Haven', '20% off signature drinks', 'Enjoy a premium drink discount for one eco rewards visit.', 220, 'percentage', 20.00, 'BREW20', '2026-12-31', 1),
    ('Green Basket', 'EGP 75 store voucher', 'Use points for a voucher on refill goods and low-waste essentials.', 320, 'fixed', 75.00, 'GBASKET75', '2026-11-30', 1),
    ('Green Basket', '15% off refill station', 'Reduce your refill basket total with a reusable-first partner perk.', 180, 'percentage', 15.00, 'REFILL15', '2026-10-31', 1),
    ('Cycle Care', 'Free bike safety tune-up', 'Redeem a full brake and tire check with a sustainability service partner.', 450, 'service', 1.00, 'CYCLESAFE', '2026-12-31', 1),
    ('Harvest Table', 'Two-for-one dessert', 'Celebrate your impact with a complimentary dessert pairing.', 250, 'coupon', 2.00, 'HARVEST2', '2026-09-30', 1)
  ) AS v (partner_name, title, description, points_required, discount_type, discount_value, coupon_code, expiry_date, is_active)
    ON p.name = v.partner_name
) AS source
ON target.partner_id = source.partner_id AND target.title = source.title
WHEN MATCHED THEN UPDATE SET
  description = source.description,
  points_required = source.points_required,
  discount_type = source.discount_type,
  discount_value = source.discount_value,
  coupon_code = source.coupon_code,
  expiry_date = source.expiry_date,
  is_active = source.is_active
WHEN NOT MATCHED THEN
  INSERT (partner_id, title, description, points_required, discount_type, discount_value, coupon_code, expiry_date, is_active)
  VALUES (source.partner_id, source.title, source.description, source.points_required, source.discount_type, source.discount_value, source.coupon_code, source.expiry_date, source.is_active);
GO

DECLARE @starterPlan INT = (SELECT plan_id FROM Plans WHERE name = 'Starter');
DECLARE @plusPlan INT = (SELECT plan_id FROM Plans WHERE name = 'Plus');

MERGE Users AS target
USING (VALUES
  ('Trash2Cash Admin', 'admin@trash2cash.local', '+201000000001', 'Trash2Cash HQ', '$2a$12$LxKXtpKHzm4VJf6nkGqeB.A9lRxH5m7I9K8/QcB3bpLUsz7hCv2v2', 'admin', @plusPlan, 0, 'active'),
  ('Maya Green', 'maya@trash2cash.local', '+201000000002', 'New Cairo, Cairo', '$2a$12$HrvfqCvJCmZUqeAd38z4XejaECgzL9CwHkGSPVr7wR301S74zDm26', 'user', @starterPlan, 0, 'active')
) AS source (full_name, email, phone, address, password_hash, role, plan_id, total_points, status)
ON target.email = source.email
WHEN MATCHED THEN UPDATE SET
  full_name = source.full_name,
  phone = source.phone,
  address = source.address,
  password_hash = source.password_hash,
  role = source.role,
  plan_id = source.plan_id,
  status = source.status
WHEN NOT MATCHED THEN
  INSERT (full_name, email, phone, address, password_hash, role, plan_id, total_points, status)
  VALUES (source.full_name, source.email, source.phone, source.address, source.password_hash, source.role, source.plan_id, source.total_points, source.status);
GO

INSERT INTO Subscriptions (user_id, plan_id, payment_id, status, started_at)
SELECT u.user_id, u.plan_id, NULL, 'active', u.created_at
FROM Users u
WHERE u.plan_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1
    FROM Subscriptions s
    WHERE s.user_id = u.user_id
      AND s.plan_id = u.plan_id
      AND s.status = 'active'
  );
GO
