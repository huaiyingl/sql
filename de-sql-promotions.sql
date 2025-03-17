/*
 
 SQL Tables: promotion， sales， product， promotion class
 1. 同时有low_fat flag 和其他flag的产品占总产品数的%
 2. 找出single media的产品
 3. promotion第一天和最后一天的transactions占总transactions的%
 4. 不同category的total sale units，valid promotion sale units/total sale units, invalid promotion sale units/total sale units
 5. 说了思路只来得及写一半，实在记不太清了，好像是求不同category里没有卖出过的products
 
 -- A Better Version of Description ---
 SQL：sales promotion product 的表。
 1. low fat和recyable的比例，记得换成float并且乘100
 2. top 5 media type，这题是要看你的debug，最后要filter掉原来的multi media的channel，面试官会提示
 3. sale在promotion第一天或者最后一天的比例，case when可以解
 4. 有promotion的units和没有promotion的units 的ratio，这里要用left join
 5. 做得太快还被加了一道SQL，但是大致思路是对的，category里面有units sold和完全没有units sold的ratio
 
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
-- Calculate the percentage of products that have both the low_fat flag AND at least one other flag (recyclable or organic) relative to the total number of products.
-- percentage
-- -----------
-- XX.XX
SELECT ROUND(
        COUNT(
            CASE
                WHEN low_fat_flag = 1
                AND (
                    recyclable_flag = 1
                    OR organic_flag = 1
                ) THEN 1
            END
        )::DECIMAL / COUNT(*) * 100.0,
        2
    ) AS percentage
FROM product;


-- Q2 --
-- Identify the top 5 media types used in "single media" promotions (promotions that use exactly one media channel). Multi-media promotions should be excluded.
-- media_type  | promotion_count
-- ------------+----------------
-- Type1       | XX
-- Type2       | XX
-- ...
WITH single_media_promption AS (
    SELECT promotion_id
    FROM promotion_media
    GROUP BY promotion_id
    HAVING COUNT(media_type) = 1
)
SELECT p.media_type,
    COUNT(p.*) AS promotion_count
FROM promotion_media_promotion p
    INNER JOIN single_media s ON p.promotion_id = s.promotion_id
GROUP BY p.media_type
ORDER BY promotion_count DESC
LIMIT 5;


-- Q3 --
-- Calculate the percentage of total transactions (by units sold) that occurred on either the first day or the last day of a promotion period.
-- sale_id, promotion_id, start_date, end_date
-- sum(selected units_sold) / sum(units_sold)
SELECT ROUND(
        (
            SELECT SUM(units_sold)
            FROM sales s
                LEFT JOIN promotion p ON s.promotion_id = p.promotion_id
            WHERE s.sale_date = p.start_date
                OR s.sale_date = p.end_date
        ) / (
            SELECT SUM(units_sold)
            FROM sales
        ) * 100.0,
        2
    ) AS percentage_transactions;


-- alternatively use case when (Recommended) --
SELECT ROUND(
        SUM(
            CASE
                WHEN (
                    s.sale_date = p.start_date
                    OR s.sale_date = p.end_date
                ) THEN s.units_sold
                ELSE 0
            END
        ) / SUM(s.units_sold) * 100.0,
        2
    ) AS percentage_transactions
FROM sales s
    LEFT JOIN promotion p ON s.promotion_id = p.promotion_id;


-- Q4 --
-- For each product family, calculate:
-- Ratio of units sold with valid promotions to total units sold
-- Ratio of units sold without valid promotions to total units sold
-- product_family, units_sold, promotions_id
WITH category_promotion AS (
    SELECT p.category,
        SUM(s.units_sold) AS total_units,
        SUM(
            CASE
                WHEN s.promotion_id IS NOT NULL THEN s.units_sold
                ELSE 0
            END
        ) AS promotion_units,
        SUM(
            CASE
                WHEN s.promotion_id IS NULL THEN s.units_sold
                ELSE 0
            END
        ) AS no_promotion_units
    FROM product p
        LEFT JOIN sales s ON p.product_id = s.product_id
    GROUP BY p.category
)
SELECT category,
    total_units,
    ROUND(
        CAST(promotion_units AS DECIMAL) / total_units,
        2
    ) AS ratio_promotion,
    ROUND(no_promotion_units::DECIMAL / total_units, 2) AS ratio_no_promotion
FROM category_promotion;


-- Q5 --
-- For each product category, calculate the ratio of products that have zero units sold compared to the total number of products in that category.
-- each family - count of product id of 0 units sold / count of product id
-- product id, product family, units_sold
WITH category_counts AS (
    SELECT p.category,
        COUNT(p.product_id) AS total_products,
        -- number --
        SUM(
            CASE
                WHEN NOT EXISTS (
                    SELECT 1
                    FROM sales s
                    WHERE s.product_id = p.product_id
                        AND s.units_sold > 0
                ) THEN 1
                ELSE 0
            END
        ) AS zero_sales_products -- number --
    FROM product p
    GROUP BY p.category
)
SELECT category,
    zero_sales_products::DECIMAL / total_products::DECIMAL AS zero_sales_ratio
FROM category_counts;


/*
 SQL has a special operator called EXISTS. It is used to check if a subquery returns any rows. 
 If the subquery returns any rows, the EXISTS operator returns TRUE. 
 If the subquery returns no rows, the EXISTS operator returns FALSE.
 
 
 外查询遍历product表的每行
 当这行的product_id在sales中有匹配且不存在units_sold > 0时，当前的product_id符合条件，计数为1
 统计符合条件的product_id总数，用sum计数
 
 */