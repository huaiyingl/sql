/*
 Database Schema
 
 Table "books"                       Table "authors"
 +------------------+-----------+    +-------------+-----------+
 |      Column      |   Type    |    |   Column    |   Type    |
 +------------------+-----------+    +-------------+-----------+
 | book_id          | INT (KEY) | +->| author_id   | INT (KEY) |
 | title            | VARCHAR   | |  | first_name  | VARCHAR   |
 | author_id        | INT >-----|-+  | last_name   | VARCHAR   |
 | publication_date | DATE      |    | birthday    | DATE      |
 | category         | VARCHAR   |    | website_url | VARCHAR   |
 | price            | DOUBLE    |    +-------------+-----------+
 +------------------+-----------+
 
 Table "transactions"                Table "customers"
 +------------------+-----------+    +--------------------------+-----------+
 |      Column      |   Type    |    |         Column           |   Type    |
 +------------------+-----------+    +--------------------------+-----------+
 | transaction_id   | INT (KEY) | +->| customer_id              | INT (KEY) |<-+
 | book_id          | INT       | |  | first_name               | VARCHAR   |  |
 | customer_id      | INT >-----|-+  | last_name                | VARCHAR   |  |
 | payment_amount   | DOUBLE    |    | registration_date        | DATE      |  |
 | book_count       | INT       |    | interested_in_categories | VARCHAR   |  |
 | tax_rate         | DOUBLE    |    | is_rewards_member        | BOOLEAN   |  |
 | discount_rate    | DOUBLE    |    | invited_by_customer_id   | INT >-----|--+
 | transaction_date | DATE      |    +--------------------------+-----------+
 | payment_type     | VARCHAR   |
 +------------------+-----------+
 
 */
-- Q1 AGGREGATION --
-- What was the total number of sold books and the unique number of sold books, grouped and sorted in descending order by payment_type?
/* Expected Output:
 payment_type | total_sold_books | unique_sold_books
 -------------|-----------------|------------------
 'VISA'       | 150            | 45
 'MASTERCARD' | 120            | 38
 'CASH'       | 80             | 25
 */
SELECT payment_type,
    sum(book_count) AS total_sold_books,
    COUNT(DISTINCT book_id) AS unique_sold_books
FROM transactions
GROUP BY payment_type
ORDER BY payment_type DESC;


-- Q2 JOIN --
-- Existing customers can invite other people to join the bookstore. 
--Find the top 3 customers ordered by the total sales value of the people they directly invited.
/* Expected Output:
 customer_id_who_invited_people | sales_value_of_invited_people
 -----------------------------|---------------------------
 1001                         | 2500.50
 1002                         | 2100.75
 1003                         | 1850.25
 */
SELECT c.invited_by_customer_id AS customer_id_who_invited_people,
    SUM(t.payment_amount) AS sales_value_of_invited_people
FROM customers c
    LEFT JOIN transactions t ON c.customer_id = t.customer_id
WHERE c.invited_by_customer_id IS NOT NULL
GROUP BY c.invited_by_customer_id
ORDER BY sales_value_of_invited_people DESC
LIMIT 3;


-- Q3 CASE WHEN, MULTI JOINS --
-- Find the number of authors who have website URLs prefixed with "http://" and that never made a sale. Compare this with the total number of authors.
/* Expected Output:
 authors_with_http_and_no_sales | authors_in_total
 ------------------------------|------------------
 5                             | 50
 */
-- author - book - transaction table --

-- solution 1-- 
WITH author_sales AS (
    SELECT DISTINCT a.author_id,
        a.website_url
    FROM authors a
        LEFT JOIN books b ON a.author_id = b.author_id
        LEFT JOIN transactions t ON b.book_id = t.book_id
    GROUP BY a.author_id,
        a.website_url
    HAVING COUNT(t.transaction_id) = 0
)
SELECT COUNT(
        CASE
            WHEN website_url LIKE 'http://%' THEN 1
        END
    ) AS authors_with_http_and_no_sales,
    (
        SELECT COUNT(*)
        FROM authors
    ) AS authors_in_total
FROM author_sales;


-- alternatively instead of using case when, use a CTE first to filter out authors_with_http_and_no_sales
WITH author_no_sales AS (
    SELECT a.author_id
    FROM authors a
        LEFT JOIN books b ON a.author_id = b.author_id
        LEFT JOIN transactions t ON b.book_id = t.book_id
    WHERE a.website_url LIKE 'http://%'
    GROUP BY a.author_id
    HAVING COUNT(t.transaction_id) = 0
)
SELECT (
        SELECT COUNT(*)
        FROM author_no_sales
    ) AS authors_with_http_and_no_sales,
    (
        SELECT COUNT(*)
        FROM authors
    ) AS authors_in_total;


-- alternatively use 3 subqueries --
SELECT (
        SELECT COUNT(*)
        FROM (
                SELECT a.author_id
                FROM authors a
                    LEFT JOIN books b ON a.author_id = b.author_id
                    LEFT JOIN transactions t ON b.book_id = t.book_id
                WHERE a.website_url LIKE 'http://%'
                GROUP BY a.author_id
                HAVING COUNT(t.transaction_id) = 0
            ) AS no_sales
    ) AS authors_with_http_and_no_sales,
    (
        SELECT COUNT(*)
        FROM authors
    ) AS authors_in_total;


-- Q4 MULTI JOINS, GROUP BY --
-- Find customers who purchased books, from the same author, belonging to at least 2 categories. show the top 3 customers ordered by how much they spent on these books
/* Expected Output:
 customer_id | total_spent
 ------------|-------------
 101         | 1250.75
 102         | 1100.50
 103         | 950.25
 */
SELECT c.customer_id,
    sum(t.payment_amount) AS total_spent
FROM customer c
    JOIN transactions t ON c.customer_id = t.customer_id
    JOIN books b ON t.book_id = b.book_id
GROUP BY c.customer_id,
    b.author_id
HAVING COUNT(DISTINCT b.category) >= 2
ORDER BY total_spent DESC
LIMIT 3;


-- Q5 WINDOW FUNCTION-- 
-- Find the top 3 customers who spent the most money in 2023, along with their total spending amount and rank.
-- ranks with gaps
/* Expected Output: 
 customer_id | total_spent | customer_rank
 ------------|-------------|---------------
 501         | 3500.50    | 1
 502         | 3200.75    | 2
 503         | 2800.25    | 3
 */
SELECT c.customer_id,
    ROUND(SUM(t.payment_amount), 2) AS total_spent,
    RANK() OVER (
        ORDER BY SUM(t.payment_amount) DESC
    ) AS customer_rank
FROM customers c
    JOIN transactions t ON c.customer_id = t.customer_id
WHERE YEAR(t.transaction_date) = 2023
GROUP BY c.customer_id
ORDER BY customer_rank
LIMIT 3;