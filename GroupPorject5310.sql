CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL
);

CREATE TABLE addresses (
    address_id SERIAL PRIMARY KEY,
    street VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    zip_code VARCHAR(20) NOT NULL
);

CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    buyin_price DECIMAL(10, 2) NOT NULL,
    sell_price DECIMAL(10, 2) NOT NULL,
    category_id INT NOT NULL,
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
);

CREATE TABLE warehouses (
    warehouse_id SERIAL PRIMARY KEY,
    address_id INT NOT NULL,
    sqft INT NOT NULL,
    FOREIGN KEY (address_id) REFERENCES addresses(address_id)
);

CREATE TABLE product_warehouse (
    product_id INT NOT NULL,
    warehouse_id INT NOT NULL,
    storage_amount INT NOT NULL,
    PRIMARY KEY (product_id, warehouse_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id)
);

CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    user_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    address_id INT NOT NULL,
    FOREIGN KEY (address_id) REFERENCES addresses(address_id)
);

CREATE TABLE customer_order (
    order_id SERIAL PRIMARY KEY,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    date DATE,
    customer_id INT NOT NULL,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE discounts (
    discount_id SERIAL PRIMARY KEY,
    product_id INT NOT NULL,
    discount_percentage FLOAT NOT NULL,
    starting_time TIMESTAMP NOT NULL,
    ending_time TIMESTAMP NOT NULL,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE coupons (
    coupon_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL,
    coupon_amount DECIMAL(10, 2) NOT NULL,
    product_id INT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE suppliers (
    supplier_id SERIAL PRIMARY KEY,
    company_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20),
    address_id INT NOT NULL,
    FOREIGN KEY (address_id) REFERENCES addresses(address_id)
);

CREATE TABLE supplier_order (
    order_id SERIAL PRIMARY KEY,
    supplier_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    date DATE,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE ratings (
    customer_id INT NOT NULL,
    order_id INT NOT NULL,
    rating INT NOT NULL,
    feedback TEXT,
	PRIMARY KEY (order_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (order_id) REFERENCES customer_order(order_id)
);

CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    payment_method VARCHAR(50) NOT NULL
);

CREATE TABLE credit_cards (
    payment_id INT PRIMARY KEY,
    credit_card_number BIGINT NOT NULL,
    FOREIGN KEY (payment_id) REFERENCES payments(payment_id)
);

CREATE TABLE payment_orders (
    payment_id INT NOT NULL,
    order_id INT NOT NULL,
    PRIMARY KEY (payment_id, order_id),
    FOREIGN KEY (payment_id) REFERENCES payments(payment_id),
    FOREIGN KEY (order_id) REFERENCES customer_order(order_id)
);

CREATE TABLE shippings (
    shipping_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL,
    shipping_company VARCHAR(100) NOT NULL,
    delivery_time INT NOT NULL,
    FOREIGN KEY (order_id) REFERENCES customer_order(order_id)
);

CREATE TABLE shipping_satisfaction (
    shipping_id INT NOT NULL,
    rating INT,
    feedback TEXT,
    PRIMARY KEY (shipping_id),
    FOREIGN KEY (shipping_id) REFERENCES shippings(shipping_id)
);

CREATE OR REPLACE FUNCTION update_stock() RETURNS TRIGGER AS $$
BEGIN
    UPDATE product_warehouse
    SET storage_amount = storage_amount - NEW.quantity
    WHERE product_id = NEW.product_id AND warehouse_id = (
        SELECT warehouse_id FROM warehouses
        WHERE warehouses.address_id = (
            SELECT address_id FROM customers
            WHERE customers.customer_id = NEW.customer_id
        )
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_order_insert
AFTER INSERT ON customer_order
FOR EACH ROW
EXECUTE FUNCTION update_stock();

CREATE OR REPLACE FUNCTION update_stock_after_supplier_order() RETURNS TRIGGER AS $$
BEGIN
    UPDATE product_warehouse
    SET storage_amount = storage_amount + NEW.quantity
    WHERE product_id = NEW.product_id AND warehouse_id = (
        SELECT warehouse_id FROM warehouses
        WHERE warehouses.address_id = (
            SELECT address_id FROM suppliers
            WHERE suppliers.supplier_id = NEW.supplier_id
        )
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_supplier_order_insert
AFTER INSERT ON supplier_order
FOR EACH ROW
EXECUTE FUNCTION update_stock_after_supplier_order();