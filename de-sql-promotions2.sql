/*
 
 电面：SQL 四道：
 一）用SUM(case statement)去求满足两个条件的产品比例，注意integer和integer相除会截断为integer但结果要float所以要转换一下，可以用Cast(xx as float)，或者Convert(float xx)
 二）找出使用single media type的客户，比如single的是 'TV'，而multi的是'TV,paper'，用LIKE判断有没有','
 三）用SUM(case statement)去求有效优惠的产品销售数量，有效优惠产品由两个表JOIN后得到
 四）最后一个比较长，要JOIN 四个表 输出 三个列，前两个列比较好办，ORDER BY和GROUP BY就解决，最后一个列需要用LEFT JOIN优惠券的表然后看结果里有没有NULL。
 
 Database Schema
 
 Table "PRODUCT"                          Table "PROMOTION"
 +-------------------+-----------+        +----------------+-----------+
 |      Column       |   Type    |        |     Column     |   Type    |
 +-------------------+-----------+        +----------------+-----------+
 | product_id        | INT (KEY) |        | promotion_id   | INT (KEY) |
 | product_name      | VARCHAR   |        | promotion_name | VARCHAR   |
 | category          | VARCHAR   |        | start_date     | DATE      |
 | low_fat_flag      | BOOLEAN   |        | end_date       | DATE      |
 | recyclable_flag   | BOOLEAN   |        | promotion_class| VARCHAR   |
 | organic_flag      | BOOLEAN   |        +----------------+-----------+
 | shelf_life_days   | INT       |        
 +-------------------+-----------+        
 
 Table "PROMOTION_MEDIA"                  Table "SALES"
 +-------------------+-----------+        +-------------------+-----------+
 |      Column       |   Type    |        |      Column       |   Type    |
 +-------------------+-----------+        +-------------------+-----------+
 | promotion_id      | INT (KEY) |        | sale_id           | INT (KEY) |
 | media_type        | VARCHAR   |        | product_id        | INT       |
 +-------------------+-----------+        | sale_date         | DATE      |
 | units_sold        | INT       |
 | revenue           | DOUBLE    |
 | promotion_id      | INT       |
 +-------------------+-----------+
 
 
 */
-- Q1 --
-- Calculate the proportion of low-fat products that are also organic out of all products. Return the result as a decimal value.
/*
 low fat and organic count / product count
 product table 
 */
SELECT(
        COUNT(
            CASE
                WHEN (
                    low_fat_flag IS TRUE
                    AND organic_flag IS TRUE
                ) THEN 1
            END
        )::FLOAT / COUNT(*)
    ) AS low_fat_organic_proportion
FROM product;


-- Q2 --
-- Identify all promotions that use only a single media type. A promotion using multiple media types will have entries in the PROMOTION_MEDIA table with commas in the media_type field (e.g., 'TV,paper'), while single media type promotions will not have commas. 
-- use INNER JOIN since we only want sales with promotions
SELECT p.promotion_id,
    p.promotion_name,
    m.media_type
FROM promotion p
    INNER JOIN promotion_media m ON p.promotion_id = m.promotion_id
WHERE m.media_type NOT LIKE '%,%';


-- Q3 -- 
-- Calculate the total units sold for products that were sold during valid promotions. A valid promotion is one where the sale_date falls between the promotion's start_date and end_date. Group the results by category.
-- sum(units_sold)  sale_date     start_date, end_date   category
-- sales                          promotion               product
-- use INNER JOIN since we only want sales with promotions, and sales with valid products
SELECT p.category,
    SUM(s.units_sold) AS total_units_sold
FROM sales s
    INNER JOIN promotion pm ON s.promotion_id = pm.promotion_id
    INNER JOIN product p ON s.product_id = p.product_id
WHERE s.sale_date BETWEEN pm.start_date AND pm.end_date
GROUP BY p.category;


-- Q4 --
-- Retrieve the following information for each product:
-- The product name (product_name),
-- The total units sold for that product (total_units_sold),
-- A flag indicating whether the product was never involved in any promotion (no_promotion_flag, which should be TRUE if the product was never part of any promotion, and FALSE otherwise).
-- Sort by total units sold
SELECT p.product_name,
    COALESCE(SUM(s.units_sold), 0) AS total_units_sold,
    CASE
        WHEN NOT EXISTS (
            SELECT 1
            FROM sales s2
            WHERE s2.product_id = p.product_id
                AND s2.promotion_id IS NOT NULL
        ) THEN TRUE
        ELSE FALSE
    END AS no_promotion_flag
FROM product p
    LEFT JOIN sales s ON p.product_id = s.product_id
GROUP BY p.product_name
ORDER BY total_units_sold DESC;


-- we use LEFT JOIN to keep all products and all product categories
-- Q5 --
-- For each product category, report:
-- The total revenue
-- The most recent sale_date
-- Whether all products in that category have been promoted at least once. Yes - True, No - False
-- Return the results ordered by total revenue in descending order.
SELECT p.category,
    SUM(s.revenue) AS total_revenue,
    MAX(s.sale_date) AS most_recent_sale,
    CASE
        WHEN COUNT(DISTINCT p.product_id) = SUM(
            CASE
                WHEN EXISTS (
                    SELECT 1
                    FROM SALES s2
                    WHERE s2.product_id = p.product_id
                        AND s2.promotion_id IS NOT NULL
                ) THEN 1
                ELSE 0
            END
        ) THEN TRUE
        ELSE FALSE
    END AS promotion_coverage
FROM PRODUCT p
    LEFT JOIN SALES s ON p.product_id = s.product_id
GROUP BY p.category
ORDER BY total_revenue DESC;


-- we use LEFT JOIN to keep all products and all product categories