/*
 
 SQL Tables: promotion， sales， product， promotion class
 1. 同时有low_fat flag 和其他flag的产品占总产品数的%
 2. 找出single media的产品
 3. promotion第一天和最后一天的transactions占总transactions的%
 4. 不同product family的total sale units，valid promotion sale units/total sale units, invalid promotion sale units/total sale units
 5. 说了思路只来得及写一半，实在记不太清了，好像是求不同product family里没有卖出过的products
 
 
 SQL：sales promotion product 的表。
 1. low fat和recyable的比例，记得换成float并且乘100
 2. top 5 media type，这题是要看你的debug，最后要filter掉原来的multi media的channel，面试官会提示
 3. sale在promotion第一天或者最后一天的比例，case when可以解
 4. 有promotion的units和没有promotion的units 的ratio，这里要用left join
 5. 做得太快还被加了一道SQL，但是大致思路是对的，category里面有units sold和完全没有units sold的ratio
 
 
 PRODUCT               | PROMOTION           | PROMOTION_MEDIA      | SALES
 ----------------------|---------------------|----------------------|-------------------
 product_id (PK)       | promotion_id (PK)   | promotion_id (PK,FK) | sale_id (PK)
 product_name          | promotion_name      | media_type (PK)      | product_id (FK)
 product_family        | start_date          |                      | sale_date
 category              | end_date            |                      | units_sold
 low_fat_flag          | promotion_class     |                      | revenue
 recyclable_flag       |                     |                      | promotion_id (FK)
 organic_flag          |                     |                      |
 shelf_life_days       |                     |                      |
 
 */
-- Q1 --
-- Calculate the percentage of products that have both the low_fat flag AND at least one other flag (recyclable or organic) relative to the total number of products.
-- percentage
-- -----------
-- XX.XX
SELECT CAST(
        COUNT(
            CASE
                WHEN low_fat_flag = 1
                AND (
                    recyclable_flag = 1
                    OR organic_flag = 1
                ) THEN 1
            END
        ) * 100.0 / COUNT(*) AS DECIMAL(10, 2)
    ) AS percentage
FROM product;

-- Q2 --
-- Identify the top 5 media types used in "single media" promotions (promotions that use exactly one media channel). Multi-media promotions should be excluded.
-- media_type  | promotion_count
-- ------------+----------------
-- Type1       | XX
-- Type2       | XX
-- ...
WITH single_medai AS (
    SELECT promotion_id,
        COUNT(media_type) AS media_count
    FROM promotion_media
    GROUP BY promotion_id
    HAVING COUNT(media_type) = 1
)
SELECT p.media_type,
    COUNT(*) AS promotion_count
FROM promotion_media p
    INNER JOIN single_media s ON p.promotion_id = s.promotion_id
GROUP BY p.media_type
ORDER BY promotion_count DESC
LIMIT 5;

-- Q3 --
-- Calculate the percentage of total transactions (by units sold) that occurred on either the first day or the last day of a promotion period.


-- Q4 --
-- For each product family, calculate:
-- Total units sold
-- Ratio of units sold with valid promotions to total units sold
-- Ratio of units sold without valid promotions to total units sold
-- Q5 --
-- For each product category, calculate the ratio of products that have zero units sold compared to the total number of products in that category.