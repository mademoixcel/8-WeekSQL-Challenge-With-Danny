SET SEARCH_PATH = 'dannys_diner'

-- 1. What is the total amount each customer spent at the restaurant?

SELECT customer_id, SUM(price) AS total_amount
FROM sales
INNER JOIN menu
ON sales.product_id=menu.product_id
GROUP BY customer_id
ORDER BY customer_id;

-- 2. How many days has each customer visited the restaurant?

SELECT 
customer_id, COUNT(DISTINCT(order_date))
FROM sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
SELECT DISTINCT customer_id, product_name
FROM
(SELECT customer_id, order_date, product_name, product_id,
DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY order_date, product_id) AS ranks
FROM sales
INNER JOIN 
menu USING(product_id)) 
AS inner_query
WHERE ranks = 1

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT product_name, COUNT(product_name) AS pr_name
FROM sales
INNER JOIN menu
USING(product_id)
GROUP BY product_name
ORDER BY pr_name DESC
LIMIT 1

-- 5. Which item was the most popular for each customer?
SELECT customer_id, product_name FROM
(SELECT
product_name, COUNT(product_name), customer_id,
DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(product_name) DESC) AS ranks
FROM sales
FULL JOIN menu
USING(product_id)
GROUP BY customer_id, product_name
ORDER BY customer_id) AS inner_query
WHERE ranks=1

-- 6. Which item was purchased first by the customer after they became a member?

SELECT customer_id, product_name
FROM
(SELECT customer_id, product_name, order_date, sales.product_id,
DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY order_date, sales.product_id) AS ranks
FROM sales
FULL JOIN members
USING(customer_id)
FULL JOIN menu
ON sales.product_id=menu.product_id
WHERE order_date >= join_date
GROUP BY customer_id, product_name, order_date, sales.product_id) AS inner_query
WHERE ranks=1

-- 7. Which item was purchased just before the customer became a member?

SELECT customer_id, product_name
FROM
(SELECT *,DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY order_date DESC) AS ranks
FROM sales
INNER JOIN 
menu
USING(product_id)
INNER JOIN 
members
USING
(customer_id)
WHERE order_date < join_date) AS inner_query
WHERE ranks =1
ORDER BY customer_id

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT customer_id, COUNT(*) AS count_all, SUM(price)
FROM
(SELECT customer_id, price
FROM sales
INNER JOIN menu
USING(product_id)
INNER JOIN members
USING(customer_id)
WHERE order_date < join_date) AS inner_query
GROUP BY customer_id

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT customer_id, SUM(customer_point)
FROM
(SELECT customer_id, (CASE WHEN product_name = 'sushi' THEN price * 20 ELSE (price * 10) END) AS customer_point
FROM sales
INNER JOIN menu
USING(product_id)) AS inner_query
GROUP BY customer_id

-- 10. In the first week after a customer joins the program (including their join date) 
--they earn 2x points on all items, not just sushi 
-- how many points do customer A and B have at the end of January?


-- Bonus Questions
-- Join All The Things


WITH CTE AS 
(SELECT *
FROM sales
FULL JOIN 
members
USING(customer_id)
FULL JOIN menu
USING(product_id)
WHERE order_date BETWEEN '2021-01-01' AND '2021-01-31')

SELECT customer_id, SUM(CASE WHEN order_date BETWEEN
					join_date AND join_date + INTERVAL '6 days' THEN price * 20
				    WHEN product_name = 'sushi' THEN price * 20 ELSE price*10 END) AS df FROM CTE
					GROUP by customer_id
					ORDER BY customer_id
					

SELECT
customer_id, order_date, product_name, price,
(CASE WHEN order_date < join_date OR join_date IS NULL THEN 'N' ELSE 'Y' END) AS member
FROM sales
FULL JOIN menu
USING(product_id)
FULL JOIN members
USING(customer_id)
ORDER BY customer_id, order_date, product_name;


WITH CTE AS
(SELECT
customer_id, order_date, product_name, price,
(CASE WHEN order_date < join_date OR join_date IS NULL THEN 'N' ELSE 'Y' END) AS member
FROM sales
FULL JOIN menu
USING(product_id)
FULL JOIN members
USING(customer_id)
ORDER BY customer_id, order_date, product_name)

SELECT *, (CASE WHEN member = 'Y' THEN DENSE_RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date) ELSE NULL END) AS dd
FROM CTE