# DANNY MA SQL CHALLENGE - CASESTUDY 1 - DANNY'S DINNER

#Creating the databASe
CREATE SCHEMA dannys_diner;
use dannys_diner;

# Creating sales table
CREATE TABLE sales (
  customer_id VARCHAR(2),
  order_date DATE,
  product_id INTEGER
);

#Inserting values into the sales table
INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

#Creating the menu table
CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(6),
  price INTEGER
);

#inserting into the menu table
INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  
#creating the members table
CREATE TABLE members (
  customer_id VARCHAR(2),
  JOIN_date DATE
);

#Inserting into the members table
INSERT INTO members
  (customer_id, JOIN_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  
  -- CASE STUDY QUESTIONS
  
  -- QUESTION 1: What is the total amount each customer hAS spent at the restaurant?
  -- SOLUTION:
		SELECT customer_id, 
			   SUM(price) AS 'Amount_Spent($)'
		FROM sales AS s
		JOIN menu AS m
			ON s.product_id = m.product_id
		GROUP BY customer_id;

-- QUESTION 2: How many days has each customer visited the restaurant?
-- SOLUTION:
	SELECT customer_id, 
		   COUNT(distinct order_date) AS Visited_days
	FROM sales
	GROUP BY customer_id;

-- QUESTION 3: What was the first from the menu purchased by each customer?
-- SOLUTION:
	SELECT rank_tab.customer_id, 
		   rank_tab.product_id, 
		   m.product_name
	FROM (
			SELECT customer_id, 
				   product_id, 
                   rank() OVER(PARTITION BY customer_id ORDER BY order_date) AS ranking
			FROM sales
			GROUP BY customer_id, product_id
        ) AS rank_tab
	JOIN menu AS m
		 ON rank_tab.product_id = m.product_id 
	WHERE rank_tab.ranking = 1;

-- QUESTION 4: What was the most purchased item ON the menu and how many times was it purchased by all customers?
-- SOLUTION:
SELECT sales.product_id,
	   menu.product_name, 
       COUNT(*) AS number_of_orders
FROM sales 
JOIN menu
	ON sales.product_id = menu.product_id	
GROUP BY product_id
ORDER BY number_of_orders desc
LIMIT 1;

-- QUESTION 5: Which item is the most popular for each customer?
-- SOLUTION:
	WITH favourite AS 
					(SELECT customer_id,
							product_id, 
                            COUNT(*) AS cnt, 
                            rank() OVER(PARTITION BY customer_id ORDER BY COUNT(product_id) desc) AS ranking
					FROM sales
					GROUP BY customer_id, product_id
                    )

	SELECT f.customer_id, 
		   m.product_name
	FROM favourite AS f
	JOIN menu AS m
		 ON m.product_id = f.product_id
	WHERE f.ranking =1
	ORDER BY f.customer_id;

-- QUESTION 6: Which item was purchased first by the customer after they became a menber?
-- SOLUTION:
	WITH customer_date AS 
						(SELECT s.customer_id, 
								s.product_id, 
                                m.JOIN_date, 
                                s.order_date, 
                                rank() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS ranking
						FROM sales AS s
						right JOIN members AS m
						ON s.customer_id = m.customer_id
						WHERE s.order_date > m.join_date)

	SELECT c.customer_id, 
		   c.product_id, 
           m.product_name
	FROM customer_date AS c
	JOIN menu AS m
		 ON m.product_id = c.product_id
	WHERE c.ranking =1
	ORDER BY c.customer_id;


-- QUESTION 7: Which item was purchased just before the customer became a menber?
-- SOLUTION:
	WITH customer_date AS 
						(SELECT s.customer_id,
								s.product_id, 
                                m.JOIN_date, 
                                s.order_date,
                                rank() OVER(PARTITION BY s.customer_id ORDER BY s.order_date desc) AS ranking
						FROM sales AS s
						right JOIN members AS m
						ON s.customer_id = m.customer_id
						WHERE s.order_date < m.JOIN_date)

	SELECT c.customer_id, c.product_id, m.product_name
	FROM customer_date AS c
	JOIN menu AS m
		 ON m.product_id = c.product_id
	WHERE c.ranking = 1
	ORDER BY c.customer_id;

-- QUESTION 8: what is the total items AND amount spent by each member before they became a menber?
-- SOLUTION:
	WITH customer_date AS 
						(SELECT s.customer_id,
								s.product_id, 
                                s.order_date
						FROM sales AS s
						LEFT JOIN members AS m
							     ON s.customer_id = m.customer_id
						WHERE s.order_date < m.join_date)

	SELECT c.customer_id, 
		   COUNT(c.product_id) AS product_count, 
           SUM(m.price) AS total_price
	FROM customer_date AS c
	JOIN menu AS m
		 ON m.product_id = c.product_id
	GROUP BY customer_id;

-- QUESTION 9: if each $1 spent equals to 10 points AND sushi hAS 2x multiplier. How many points would each customer have?
-- SOLUTION:
	WITH points_table AS 
    (
						SELECT *, 
						CASE WHEN product_name = "sushi" THEN 2 ELSE 1 END AS points
						FROM menu
	)
	SELECT s.customer_id, 
		   SUM(p.points * p.price *10) AS Points
	FROM sales AS s
	JOIN points_table AS p
	ON s.product_id = p.product_id
	GROUP BY s.customer_id;

-- QUESTION 10: In the first week after a customer JOINs a program (Including their JOIN date) they earn 2x points ON all items NOT just sushi. How many points do customer A AND B have at the END of January. 
-- SOLUTION:
	WITH validity_table AS
    (
				SELECT s.customer_id, 
                       s.product_id,s.order_date, 
                       m.JOIN_date, me.price, 
                       me.product_name, 
					   DATE_ADD(join_date, INTERVAL 6 DAY) AS week_after_join_date
				FROM members AS m
                JOIN sales AS s
                ON m.customer_id = s.customer_id
                JOIN menu AS me
                ON me.product_id = s.product_id
    )
    SELECT customer_id, 
    SUM(CASE WHEN order_date BETWEEN join_date AND week_after_join_date THEN price * 2* 10
		WHEN order_date NOT BETWEEN join_date AND week_after_join_date AND product_name <> "sushi" THEN price * 10
        WHEN order_date NOT BETWEEN join_date AND week_after_join_date AND product_name = "sushi" THEN price * 2* 10 END
        ) AS January_Points
    FROM validity_table
    WHERE order_date <= lASt_day("2021-01-01")
    GROUP BY customer_id
    ORDER BY January_Points desc;


-- BONUS QUESTIONS
-- 1
	SELECT s.customer_id,
		   s.order_date, 
           m.product_name, 
           m.price,
		   CASE WHEN s.order_date >= me.JOIN_date AND me.customer_id IS NOT NULL THEN "Y" ELSE "N" END AS Member
	FROM sales AS s
	JOIN menu AS m
	ON m.product_id = s.product_id
	LEFT JOIN members AS me
	ON me.customer_id = s.customer_id;

-- 2
	WITH customer_members AS
			(
                SELECT s.customer_id, 
					   s.order_date, 
                       m.product_name, 
                       m.price,
					   CASE WHEN s.order_date >= me.JOIN_date AND me.customer_id IS NOT NULL THEN "Y" ELSE "N" END AS Member
				FROM sales AS s
				JOIN menu AS m
				ON m.product_id = s.product_id
				LEFT JOIN members AS me
				ON me.customer_id = s.customer_id
			)

	SELECT *, 
	CASE WHEN Member = "N" THEN NULL ELSE DENSE_RANK() OVER(PARTITION BY customer_id, Member ORDER BY order_date) END AS Ranking
	FROM customer_members


-- Thanks for reading!
 





