-- @author Maryam Khanahmadi - 27-July 2024
-- Multi- SELECT statement- Replace Data
USE sql_invoic;

-- Update the city name from 'Malmo' to 'NewCity'
UPDATE clients
SET city = 'NewCity'
WHERE client_id IN
    (SELECT client_id
     FROM invoices
     WHERE client_id <= 3 );

-- Select the records to verify the update
SELECT client_id, phone, address, name, city
FROM clients
WHERE client_id IN
     (SELECT client_id
      FROM invoices
      WHERE client_id <= 3 AND city = 'NewCity');

-- count the number of clients from the updated city.
SELECT COUNT(*) AS count_of_clients_in_newcity
FROM clients
WHERE city = 'NewCity';

-- calculate the average invoice amount for common clients with client_id <= 3
SELECT AVG(invoice_total) AS average_invoice_amount
FROM invoices
WHERE client_id IN
    (SELECT client_id
     FROM clients
     WHERE client_id <= 3);

-- comprehensive view of the invoice totals 
SELECT MAX(invoice_total) AS max_invoice_amount,
	   MIN(invoice_total) AS min_invoice_amount,
       SUM(invoice_total) AS total_invoice_amount
FROM invoices
WHERE client_id IN
    (SELECT client_id
     FROM clients
     WHERE client_id <= 3);