-- Create table for Customers
CREATE TABLE IF NOT EXISTS Customers (
    CustomerID INTEGER PRIMARY KEY AUTOINCREMENT,
    FirstName TEXT,
    LastName TEXT,
    Email TEXT
);

-- Create table for Orders
CREATE TABLE IF NOT EXISTS Orders (
    OrderID INTEGER PRIMARY KEY AUTOINCREMENT,
    CustomerID INTEGER,
    OrderDate DATE,
    TotalPrice DECIMAL(10, 2),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

-- Create table for OrderItems
CREATE TABLE IF NOT EXISTS OrderItems (
    OrderItemID INTEGER PRIMARY KEY AUTOINCREMENT,
    OrderID INTEGER,
    ProductID INTEGER,
    Quantity INTEGER,
    Price DECIMAL(10, 2),
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

-- Create table for Products
CREATE TABLE IF NOT EXISTS Products (
    ProductID INTEGER PRIMARY KEY AUTOINCREMENT,
    ProductName TEXT,
    Description TEXT,
    Price DECIMAL(10, 2)
);

-- Insert dummy data into Customers table
INSERT INTO Customers (FirstName, LastName, Email)
VALUES ('John', 'Doe', 'johndoe@example.com'),
       ('Jane', 'Doe', 'janedoe@example.com'),
       ('Michael', 'Smith', 'michaelsmith@example.com');

-- Insert dummy data into Products table
INSERT INTO Products (ProductName, Description, Price)
VALUES ('Product 1', 'Description 1', 10.99),
       ('Product 2', 'Description 2', 19.99),
       ('Product 3', 'Description 3', 5.99);

-- Insert dummy data into Orders table
INSERT INTO Orders (CustomerID, OrderDate, TotalPrice)
VALUES (1, '2023-04-01', 10.99),
       (2, '2023-04-02', 19.99),
       (3, '2023-04-03', 5.99);

-- Insert dummy data into OrderItems table
INSERT INTO OrderItems (OrderID, ProductID, Quantity, Price)
VALUES (1, 1, 1, 10.99),
       (2, 2, 2, 19.99),
       (3, 3, 3, 5.99);


-- Trigger to calculate total price for Orders
CREATE TRIGGER IF NOT EXISTS OrderTotalTrigger
AFTER INSERT ON OrderItems
BEGIN
    UPDATE Orders
    SET TotalPrice = (
        SELECT SUM(Quantity * Price)
        FROM OrderItems
        WHERE OrderID = NEW.OrderID
    )
    WHERE OrderID = NEW.OrderID;
END;

-- Using subquery to achieve ROW_NUMBER() equivalent
SELECT (SELECT COUNT(*) 
        FROM Orders o 
        WHERE o.OrderDate < t.OrderDate OR (o.OrderDate = t.OrderDate AND o.OrderID <= t.OrderID)
       ) AS RowNumber,
       t.OrderID, t.CustomerID, t.OrderDate, t.TotalPrice
FROM Orders t
ORDER BY t.OrderDate, t.OrderID;
-- Using CTE to get total order value by customer
WITH TotalOrderValue AS (
    SELECT CustomerID, SUM(TotalPrice) AS TotalValue
    FROM Orders
    GROUP BY CustomerID
)
SELECT c.FirstName, c.LastName, t.TotalValue
FROM Customers c
JOIN TotalOrderValue t ON c.CustomerID = t.CustomerID;
-- Using recursive query to retrieve employees and their subordinates from an employee table
WITH RECURSIVE EmployeeHierarchy AS (
    SELECT EmployeeID, FirstName, LastName, SupervisorID
    FROM Employees
    WHERE EmployeeID = 1 -- Starting employee ID
    UNION ALL
    SELECT e.EmployeeID, e.FirstName, e.LastName, e.SupervisorID
    FROM Employees e
    INNER JOIN EmployeeHierarchy eh ON e.SupervisorID = eh.EmployeeID
)
SELECT EmployeeID, FirstName, LastName, SupervisorID
FROM EmployeeHierarchy;
-- Creating an index on the OrderDate column for faster queries
CREATE INDEX idx_OrderDate ON Orders (OrderDate);
-- Example of using transactions to update multiple tables atomically
BEGIN;
UPDATE Customers SET FirstName = 'John' WHERE CustomerID = 1;
UPDATE Orders SET TotalPrice = 20.99 WHERE CustomerID = 1;
COMMIT;
-- Using INNER JOIN to retrieve orders and corresponding customer information
SELECT o.OrderID, o.CustomerID, c.FirstName, c.LastName
FROM Orders o
JOIN Customers c ON o.CustomerID = c.CustomerID;
-- Creating a trigger to automatically update the LastModified column on updates to the Orders table
CREATE TRIGGER update_last_modified
AFTER UPDATE ON Orders
FOR EACH ROW
BEGIN
    UPDATE Orders SET LastModified = CURRENT_TIMESTAMP WHERE OrderID = NEW.OrderID;
END;

