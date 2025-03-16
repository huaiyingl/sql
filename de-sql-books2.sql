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
-- Q1 --
-- What is the total number of sold books and the unique number of sold books, grouped and sorted in descending order by payment_type?
-- payment_type, number of books
SELECT payment_type,
    SUM(book_count) AS total_books,
    COUNT(distict book_id) AS unique_books
FROM transactions
GROUP BY payment_type
ORDER BY payment_type DESC;


-- Q2 --
-- Customers can invite other customers, find the top five inviters’ average payment per book
/*
 invited_by_customer_id, customer_id(invites),                   payment_amount, book_count
 count, group by invited_by_customer_id   sum            sum
 customers                                                        transactions 
 */
SELECT c.invited_by_customer_id,
    ROUND(
        sum(t.payment_amount)::decimal / sum(t.book_count),
        2
    ) AS average_payment
FROM customers c
    LEFT JOIN transactions t ON c.invited_by_customer_id = t.customer_id
WHERE c.invited_by_customer_id IS NOT NULL
GROUP BY c.invited_by_customer_id
ORDER BY COUNT(DISTINCT customer_id) DESC
LIMIT 5;


-- Q3 CASE WHEN, EXISTS --
-- number of all authors, the percentage of authors match the url ended with ‘.com’ and the percentage of authors that made no sales 

/*
authors      authors match the url ended with ‘.com’    authors made no sales

authors      authors                                    authors,books,transactions

author_id      book_id     transaction_id(not found in transactions)
        join            join
*/
WITH author_stats AS (
    SELECT COUNT(*) AS total_authors,
        COUNT(
            CASE
                WHEN website LIKE '%.com' THEN 1
            END
        ) AS com_authors,
        COUNT(
            CASE
                WHEN NOT EXISTS (
                    SELECT 1
                    FROM books b
                        JOIN transactions t ON b.book_id = t.book_id
                    WHERE b.author_id = a.author_id
                ) THEN 1
            END
        ) AS no_sales_authors
    FROM authors a
)
SELECT total_authors,
    ROUND((com_authors::decimal / total_authors * 100), 2) AS com_percentage,
    ROUND(
        (no_sales_authors::decimal / total_authors * 100),
        2
    ) AS no_sales_percentage
FROM author_stats;


-- Q4 -- 
-- find the sales value of customers who purchased books from the same author but with different genres
/*
 1.find customers who have purchased at least two books from the same author, where those books belong to different genres/categories, 
 2. then sum up the payment amounts for these customers.
 
 customer_id*     book_id     author_id           category
 group by         join        group by          count distinct
 transactions                books
 
 */
WITH customer_author_category AS (
    SELECT t.customer_id
    FROM transactions t
        JOIN books b ON t.book_id = b.book_id
    GROUP BY t.customer_id,
        b.author_id
    HAVING COUNT(DISTINCT b.category) > 1
)
SELECT SUM(t.payment_amount) AS total_sales_value
FROM transactions t
WHERE t.customer_id IN (
        SELECT customer_id
        FROM customer_author_category
    )