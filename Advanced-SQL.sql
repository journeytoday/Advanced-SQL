-- Create Orders table
CREATE TABLE Orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    total_amount DECIMAL(10, 2)
);

-- Create OrderItems table
CREATE TABLE OrderItems (
    order_item_id INT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT,
    price DECIMAL(10, 2),
    item_amount DECIMAL(10, 2),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

-- Create Products table
CREATE TABLE Products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(255),
    category VARCHAR(255)
);

-- Create materialized view for sales by product
CREATE MATERIALIZED VIEW mv_sales_by_product AS
SELECT
    oi.product_id,
    p.product_name,
    SUM(oi.quantity) AS total_quantity,
    SUM(oi.item_amount) AS total_amount
FROM
    OrderItems oi
JOIN
    Products p ON oi.product_id = p.product_id
JOIN
    Orders o ON oi.order_id = o.order_id
WHERE
    o.order_date BETWEEN '2022-01-01' AND '2022-12-31'
GROUP BY
    oi.product_id, p.product_name;

-- Create index on customer_name column in Orders table
CREATE INDEX idx_customer_name ON Orders(customer_name);

-- Example of using Common Table Expressions (CTEs)
WITH OrderSummary AS (
    SELECT
        order_id,
        SUM(quantity) AS total_quantity,
        SUM(item_amount) AS total_amount
    FROM
        OrderItems
    GROUP BY
        order_id
)
SELECT
    o.order_id,
    o.order_date,
    o.total_amount,
    os.total_quantity,
    os.total_amount,
    SUM(os.total_amount) OVER (PARTITION BY o.customer_id ORDER BY o.order_date) AS running_total
FROM
    Orders o
JOIN
    OrderSummary os ON o.order_id = os.order_id
ORDER BY
    o.customer_id, o.order_date;

-- Example of using recursive CTE to query hierarchical data
WITH RECURSIVE ProductHierarchy AS (
    SELECT
        product_id,
        product_name,
        category,
        0 AS level
    FROM
        Products
    WHERE
        category = 'Category 1'
    UNION ALL
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        ph.level + 1
    FROM
        Products p
    JOIN
        ProductHierarchy ph ON p.category = ph.product_name
)
SELECT
    product_id,
    product_name,
    category,
    level
FROM
    ProductHierarchy
ORDER BY
    level;

-- Example of using PIVOT and UNPIVOT to transform data
SELECT
    product_id,
    quarter1,
    quarter2,
    quarter3,
    quarter4
FROM (
    SELECT
        product_id,
        CONCAT('Q', QUARTER(order_date)) AS quarter,
        SUM(quantity) AS total_quantity
    FROM
        Orders o
    JOIN
        OrderItems oi ON o.order_id = oi.order_id
    GROUP BY
        product_id, quarter
) AS Subquery
PIVOT (
    SUM(total_quantity)
    FOR quarter IN ('Q1', 'Q2', 'Q3', 'Q4')
) AS PivotTable
ORDER BY
    product_id;

-- Example of using transactions with locking to ensure data integrity
START TRANSACTION;
BEGIN TRY
    -- Insert a new order
    INSERT INTO Orders (order_id, customer_id, order_date, total_amount)
VALUES (101, 1, '2023-04-12', 1000.00);

-- Update the total_amount for the order
UPDATE Orders
SET total_amount = total_amount + 500.00
WHERE order_id = 101;

-- Delete an order item
DELETE FROM OrderItems
WHERE order_item_id = 1;

COMMIT;
END TRY
BEGIN CATCH
-- If any errors occur, rollback the transaction
ROLLBACK;
-- Print error message
SELECT CONCAT('Error: ', ERROR_MESSAGE()) AS error_message;
END CATCH;
