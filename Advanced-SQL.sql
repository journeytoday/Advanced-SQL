-- Create Orders table
CREATE TABLE Orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    total_amount DECIMAL(10, 2)
);

-- Create OrderItems table
CREATE TABLE OrderItems (
    order_id INT,
    product_id INT,
    quantity INT,
    item_amount DECIMAL(10, 2)
);

-- Create Customers table
CREATE TABLE Customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100)
);

-- Create Products table
CREATE TABLE Products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    price DECIMAL(10, 2),
    category VARCHAR(100)
);

-- Insert sample data into Orders table
INSERT INTO Orders (order_id, customer_id, order_date, total_amount)
VALUES (1, 1, '2023-03-15', 100.00),
       (2, 2, '2023-03-16', 250.00);

-- Insert sample data into OrderItems table
INSERT INTO OrderItems (order_id, product_id, quantity, item_amount)
VALUES (1, 1, 2, 50.00),
       (1, 2, 3, 30.00),
       (2, 1, 1, 100.00);

-- Insert sample data into Customers table
INSERT INTO Customers (customer_id, customer_name)
VALUES (1, 'John Doe'),
       (2, 'Jane Smith');

-- Insert sample data into Products table
INSERT INTO Products (product_id, product_name, price, category)
VALUES (1, 'Product 1', 50.00, 'Category 1'),
       (2, 'Product 2', 20.00, 'Category 1'),
       (3, 'Product 3', 10.00, 'Category 2');

-- Create a materialized view to store pre-aggregated sales data
CREATE MATERIALIZED VIEW mv_sales_by_product AS
SELECT product_id, SUM(quantity) AS total_quantity, SUM(item_amount) AS total_item_amount
FROM OrderItems
GROUP BY product_id;

-- Create an index on the 'customer_name' column for faster search
CREATE INDEX idx_customer_name ON Customers (customer_name);

-- Example of using window functions to calculate running total of sales by customer
SELECT customer_id, order_date, order_amount, 
       SUM(order_amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS running_total
FROM (
    SELECT o.customer_id, o.order_date, SUM(oi.item_amount) AS order_amount
    FROM Orders o
    JOIN OrderItems oi ON o.order_id = oi.order_id
    GROUP BY o.customer_id, o.order_date
) AS Subquery
ORDER BY customer_id, order_date;

-- Example of using CTEs to simplify complex queries
WITH OrderDetails AS (
    SELECT o.order_id, o.customer_id, o.order_date, oi.product_id, oi.quantity, oi.item_amount,
           c.customer_name, p.product_name, p.price
    FROM Orders o
    JOIN OrderItems oi ON o.order_id = oi.order_id
    JOIN Customers c ON o.customer_id = c.customer_id
    JOIN Products p ON oi.product_id = p.product_id
)
SELECT order_id, customer_id, customer_name, order_date,product_id, product_name, quantity, price, item_amount,
SUM(item_amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS running_total
FROM OrderDetails
ORDER BY customer_id, order_date;

-- Example of using recursive CTE to query hierarchical data
WITH RECURSIVE ProductHierarchy AS (
SELECT product_id, product_name, category, 0 AS level
FROM Products
WHERE category = 'Category 1'
UNION ALL
SELECT p.product_id, p.product_name, p.category, ph.level + 1
FROM Products p
JOIN ProductHierarchy ph ON p.category = ph.product_name
)
SELECT product_id, product_name, category, level
FROM ProductHierarchy
ORDER BY level;

-- Example of using PIVOT and UNPIVOT to transform data
SELECT product_id, 'Q1' AS quarter1, 'Q2' AS quarter2, 'Q3' AS quarter3, 'Q4' AS quarter4
FROM (
SELECT product_id, CONCAT('Q', QUARTER(order_date)) AS quarter, SUM(quantity) AS total_quantity
FROM Orders o
JOIN OrderItems oi ON o.order_id = oi.order_id
GROUP BY product_id, quarter
) AS Subquery
PIVOT (
SUM(total_quantity)
FOR quarter IN ('Q1', 'Q2', 'Q3', 'Q4')
) AS PivotTable
ORDER BY product_id;

-- Example of using transactions with locking to ensure data integrity
BEGIN TRANSACTION;
BEGIN TRY
-- Insert a new order
INSERT INTO Orders (order_id, customer_id, order_date, total_amount)
VALUES (3, 1, '2023-03-17', 150.00);

-- Update the total amount of the order
UPDATE Orders
SET total_amount = 200.00
WHERE order_id = 3;

-- Delete an order item
DELETE FROM OrderItems
WHERE order_id = 3 AND product_id = 1;

COMMIT;
END TRY
BEGIN CATCH
-- Rollback the transaction in case of error
ROLLBACK;
END CATCH;

-- Clean up: Drop the materialized view and index
DROP MATERIALIZED VIEW mv_sales_by_product;
DROP INDEX idx_customer_name;
