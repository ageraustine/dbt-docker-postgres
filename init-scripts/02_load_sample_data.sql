-- Load sample data into raw tables

-- Insert customers
INSERT INTO raw_customers (id, first_name, last_name, email, phone, address, city, state, zip_code, country, created_at, updated_at) VALUES
(1, 'John', 'Doe', 'john.doe@example.com', '555-0101', '123 Main St', 'New York', 'NY', '10001', 'USA', '2024-01-15 10:00:00', '2024-01-15 10:00:00'),
(2, 'Jane', 'Smith', 'jane.smith@example.com', '555-0102', '456 Oak Ave', 'Los Angeles', 'CA', '90001', 'USA', '2024-01-16 11:00:00', '2024-01-16 11:00:00'),
(3, 'Bob', 'Johnson', 'bob.johnson@example.com', '555-0103', '789 Pine Rd', 'Chicago', 'IL', '60601', 'USA', '2024-01-17 12:00:00', '2024-01-17 12:00:00'),
(4, 'Alice', 'Williams', 'alice.williams@example.com', '555-0104', '321 Elm St', 'Houston', 'TX', '77001', 'USA', '2024-01-18 13:00:00', '2024-01-18 13:00:00'),
(5, 'Charlie', 'Brown', 'charlie.brown@example.com', '555-0105', '654 Maple Dr', 'Phoenix', 'AZ', '85001', 'USA', '2024-01-19 14:00:00', '2024-01-19 14:00:00')
ON CONFLICT (id) DO NOTHING;

-- Insert products
INSERT INTO raw_products (id, name, category, subcategory, brand, price, cost, stock_quantity, created_at, updated_at) VALUES
(1, 'Laptop Pro 15', 'Electronics', 'Computers', 'TechBrand', 1299.99, 800.00, 50, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(2, 'Wireless Mouse', 'Electronics', 'Accessories', 'TechBrand', 29.99, 15.00, 200, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(3, 'Office Chair', 'Furniture', 'Seating', 'ComfortCo', 249.99, 150.00, 75, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(4, 'Standing Desk', 'Furniture', 'Desks', 'ComfortCo', 599.99, 350.00, 30, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(5, 'USB-C Cable', 'Electronics', 'Accessories', 'TechBrand', 19.99, 8.00, 500, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(6, 'Notebook Pack', 'Office Supplies', 'Stationery', 'PaperPlus', 12.99, 6.00, 300, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(7, 'Desk Lamp', 'Furniture', 'Lighting', 'ComfortCo', 79.99, 40.00, 100, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(8, 'Mechanical Keyboard', 'Electronics', 'Accessories', 'TechBrand', 149.99, 80.00, 120, '2024-01-01 00:00:00', '2024-01-01 00:00:00')
ON CONFLICT (id) DO NOTHING;

-- Insert orders
INSERT INTO raw_orders (id, customer_id, order_date, status, total_amount, shipping_address, shipping_city, shipping_state, shipping_zip_code, shipping_country, created_at, updated_at) VALUES
(1, 1, '2024-02-01 10:30:00', 'completed', 1329.98, '123 Main St', 'New York', 'NY', '10001', 'USA', '2024-02-01 10:30:00', '2024-02-01 15:00:00'),
(2, 2, '2024-02-02 11:15:00', 'completed', 279.98, '456 Oak Ave', 'Los Angeles', 'CA', '90001', 'USA', '2024-02-02 11:15:00', '2024-02-02 16:00:00'),
(3, 1, '2024-02-05 14:20:00', 'completed', 599.99, '123 Main St', 'New York', 'NY', '10001', 'USA', '2024-02-05 14:20:00', '2024-02-05 18:00:00'),
(4, 3, '2024-02-07 09:45:00', 'completed', 1479.97, '789 Pine Rd', 'Chicago', 'IL', '60601', 'USA', '2024-02-07 09:45:00', '2024-02-07 14:30:00'),
(5, 4, '2024-02-10 16:00:00', 'shipped', 249.99, '321 Elm St', 'Houston', 'TX', '77001', 'USA', '2024-02-10 16:00:00', '2024-02-10 16:30:00'),
(6, 2, '2024-02-12 13:30:00', 'completed', 92.98, '456 Oak Ave', 'Los Angeles', 'CA', '90001', 'USA', '2024-02-12 13:30:00', '2024-02-12 17:00:00'),
(7, 5, '2024-02-15 10:00:00', 'processing', 1349.98, '654 Maple Dr', 'Phoenix', 'AZ', '85001', 'USA', '2024-02-15 10:00:00', '2024-02-15 10:00:00')
ON CONFLICT (id) DO NOTHING;

-- Insert order items
INSERT INTO raw_order_items (id, order_id, product_id, quantity, unit_price, discount_amount, line_total, created_at) VALUES
(1, 1, 1, 1, 1299.99, 0.00, 1299.99, '2024-02-01 10:30:00'),
(2, 1, 2, 1, 29.99, 0.00, 29.99, '2024-02-01 10:30:00'),
(3, 2, 3, 1, 249.99, 0.00, 249.99, '2024-02-02 11:15:00'),
(4, 2, 2, 1, 29.99, 0.00, 29.99, '2024-02-02 11:15:00'),
(5, 3, 4, 1, 599.99, 0.00, 599.99, '2024-02-05 14:20:00'),
(6, 4, 1, 1, 1299.99, 0.00, 1299.99, '2024-02-07 09:45:00'),
(7, 4, 8, 1, 149.99, 0.00, 149.99, '2024-02-07 09:45:00'),
(8, 4, 2, 1, 29.99, 0.00, 29.99, '2024-02-07 09:45:00'),
(9, 5, 3, 1, 249.99, 0.00, 249.99, '2024-02-10 16:00:00'),
(10, 6, 7, 1, 79.99, 0.00, 79.99, '2024-02-12 13:30:00'),
(11, 6, 6, 1, 12.99, 0.00, 12.99, '2024-02-12 13:30:00'),
(12, 7, 1, 1, 1299.99, 0.00, 1299.99, '2024-02-15 10:00:00'),
(13, 7, 5, 1, 19.99, 0.00, 19.99, '2024-02-15 10:00:00'),
(14, 7, 2, 1, 29.99, 0.00, 29.99, '2024-02-15 10:00:00')
ON CONFLICT (id) DO NOTHING;
