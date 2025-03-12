/*

电面：SQL 四道：
一）用SUM(case statement)去求满足两个条件的产品比例，注意integer和integer相除会截断为integer但结果要float所以要转换一下，可以用Cast(xx as float)，或者Convert(float xx)
二）找出使用single media type的客户，比如single的是 'TV'，而multi的是'TV,paper'，用LIKE判断有没有','
三）用SUM(case statement)去求有效优惠的产品销售数量，有效优惠产品由两个表JOIN后得到
四）最后一个比较长，要JOIN 四个表 输出 三个列，前两个列比较好办，ORDER BY和GROUP BY就解决，最后一个列需要用LEFT JOIN优惠券的表然后看结果里有没有NULL。