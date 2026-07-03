CREATE TABLE departments (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    features TEXT NOT NULL,
    description TEXT DEFAULT '',
    department_id INTEGER NOT NULL REFERENCES departments(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
INSERT INTO departments (name) VALUES
    ('Stickers'),('Apparel'),('Drinkware'),('Home & Living'),('Accessories')
ON CONFLICT DO NOTHING;
INSERT INTO products (name,features,description,department_id) VALUES
    ('Sticker Pack','Waterproof, UV-resistant','High-quality stickers',1),
    ('Custom T-Shirt','100% cotton','Comfortable and stylish',2),
    ('Mug 11oz','Ceramic, dishwasher safe','Custom mugs',3),
    ('Tote Bag','Eco-friendly canvas','Eco-friendly tote bags',4),
    ('Phone Case','Shock-absorbent','Protect your phone',5),
    ('Hoodie','Fleece lining','Stay warm',2)
ON CONFLICT DO NOTHING;
