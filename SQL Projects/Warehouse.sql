--  @author Maryam Khanahmadi - 20-July 2024
-- **** Create Dimension Tables ****
-- Create DimClients
USE sql_invoic;

-- Create and use the data warehouse database
DROP DATABASE IF EXISTS `sql_invoic_warehouse`;
CREATE DATABASE `sql_invoic_warehouse`; 
USE `sql_invoic_warehouse`;

-- Set names
SET NAMES utf8;
SET character_set_client = utf8mb4;

-- Create DimClients table
DROP TABLE IF EXISTS DimClients;
CREATE TABLE DimClients (
    client_id INT PRIMARY KEY,
    name VARCHAR(50),
    address VARCHAR(50),
    city VARCHAR(50),
    phone VARCHAR(50)
);

-- Insert data into DimClients
INSERT INTO DimClients (client_id, name, address, city, phone)
SELECT client_id, name, address, city, phone
FROM sql_invoic.clients;

-- Create DimTime table
DROP TABLE IF EXISTS DimTime;
CREATE TABLE DimTime (
    date_id INT PRIMARY KEY AUTO_INCREMENT,
    date DATE,
    year INT,
    month INT,
    day INT
);

-- Insert data into DimTime
INSERT INTO DimTime (date, year, month, day)
SELECT DISTINCT invoice_date, YEAR(invoice_date), MONTH(invoice_date), DAY(invoice_date)
FROM sql_invoic.invoices;

-- Create DimPaymentMethod table
DROP TABLE IF EXISTS DimPaymentMethod;
CREATE TABLE DimPaymentMethod (
    payment_method_id TINYINT PRIMARY KEY,
    name VARCHAR(50)
);

-- Populate DimPaymentMethod from existing payment_method table
INSERT INTO DimPaymentMethod (payment_method_id, name)
SELECT payment_method_id, name
FROM sql_invoic.payment_method;

-- Create FactInvoices table
DROP TABLE IF EXISTS FactInvoices;
CREATE TABLE FactInvoices (
    invoice_id INT PRIMARY KEY,
    client_id INT,
    date_id INT,
    payment_method_id TINYINT,
    invoice_total DECIMAL(9,2),
    payment_total DECIMAL(9,2),
    remaining_balance DECIMAL(9,2),
    invoice_date DATE,
    due_date DATE,
    payment_date DATE,
    FOREIGN KEY (client_id) REFERENCES DimClients(client_id),
    FOREIGN KEY (date_id) REFERENCES DimTime(date_id),
    FOREIGN KEY (payment_method_id) REFERENCES DimPaymentMethod(payment_method_id)
);

-- **** Indexing ****
CREATE INDEX idx_fact_invoices_client_id ON FactInvoices(client_id);
CREATE INDEX idx_fact_invoices_date_id ON FactInvoices(date_id);
CREATE INDEX idx_fact_invoices_payment_method_id ON FactInvoices(payment_method_id);
CREATE INDEX idx_dim_clients_name ON DimClients(name);

-- **** Aggregation ****
SELECT c.name, SUM(f.invoice_total) AS total_sales
FROM FactInvoices f
JOIN DimClients c ON f.client_id = c.client_id
GROUP BY c.name;

-- **** ETL Process ****
-- Create staging table for invoices (for ETL example)
DROP TABLE IF EXISTS staging_invoices;
CREATE TABLE staging_invoices (
    invoice_id INT,
    client_id INT,
    invoice_total DECIMAL(9,2),
    payment_total DECIMAL(9,2),
    remaining_balance DECIMAL(9,2),
    invoice_date DATE,
    due_date DATE,
    payment_date DATE,
    payment_method_id TINYINT
);

-- Extract data from source
INSERT INTO staging_invoices (invoice_id, client_id, invoice_total, payment_total, remaining_balance, invoice_date, due_date, payment_date, payment_method_id)
SELECT 
    i.invoice_id, 
    i.client_id, 
    i.invoice_total, 
    SUM(p.amount) AS payment_total,
    (i.invoice_total - SUM(p.amount)) AS remaining_balance, 
    i.invoice_date, 
    i.due_date, 
    MAX(p.date) AS payment_date,
    MAX(p.payment_method) AS payment_method_id
FROM 
    sql_invoic.invoices i
LEFT JOIN 
    sql_invoic.payments p ON i.invoice_id = p.invoice_id
GROUP BY 
    i.invoice_id, i.client_id, i.invoice_total, i.invoice_date, i.due_date;

-- Load data into FactInvoices
INSERT INTO FactInvoices (invoice_id, client_id, date_id, payment_method_id, invoice_total, payment_total, remaining_balance, invoice_date, due_date, payment_date)
SELECT 
    s.invoice_id,
    s.client_id,
    t.date_id,
    s.payment_method_id,
    s.invoice_total,
    s.payment_total,
    s.remaining_balance,
    s.invoice_date,
    s.due_date,
    s.payment_date
FROM 
    staging_invoices s
JOIN 
    DimTime t ON s.invoice_date = t.date;

-- Drop staging table if no longer needed
DROP TABLE IF EXISTS staging_invoices;
