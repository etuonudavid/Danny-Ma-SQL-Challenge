# DANNY MA SQL CHALLENGE - CASESTUDY 1 - DANNY'S DINNER

#Creating the database
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
  join_date DATE
);

#Inserting into the members table
INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  
  -- CASE STUDY QUESTIONS
  
  -- QUESTION 1: What is the total amount each customer has spent at the restaurant?
  -- SOLUTION:
		Select customer_id, 
			   sum(price) as 'Amount_Spent($)'
		From sales as s
		Join menu as m
			on s.product_id = m.product_id
		Group by customer_id;

-- QUESTION 2: How many days has each customer visited the restaurant?
-- SOLUTION:
	Select customer_id, 
		   count(distinct order_date)
	From sales
	Group by customer_id;

-- QUESTION 3: What was the first from the menu purchased by each customer?
-- SOLUTION:
	Select rank_tab.customer_id, 
		   rank_tab.product_id, 
		   m.product_name
	from (
			Select customer_id, 
				   product_id, 
                   dense_rank() over(partition by customer_id order by order_date) as ranking
			from sales
			group by customer_id, product_id
        ) as rank_tab
	join menu as m
		 on rank_tab.product_id = m.product_id 
	where rank_tab.ranking = 1;

-- QUESTION 4: What was the most purchased item on the menu and how many times was it purchased by each customer?
-- SOLUTION:
	with popular_prod  as
	(	select product_id, 
			   count(*) as cnt
		from sales 
		group by product_id
		order by cnt desc
		limit 1
	) 

	Select s.customer_id,
           m.product_name, 
           count(*) as quantity_ordered
	from sales  as s
	right join popular_prod  as p
		       on s.product_id = p.product_id
	join menu as m
		on s.product_id = m.product_id
	group by s.customer_id;

-- QUESTION 5: Which item is the most popular for each customer?
-- SOLUTION:
	with favourite as 
					(Select customer_id,
							product_id, 
                            count(*) as cnt, 
                            dense_rank() over(partition by customer_id order by count(product_id) desc) as ranking
					from sales
					group by customer_id, product_id
                    )

	select f.customer_id, 
		   m.product_name
	from favourite as f
	join menu as m
		 on m.product_id = f.product_id
	where f.ranking =1
	order by f.customer_id;

-- QUESTION 6: Which item was purchased first by the customer after they became a menber?
-- SOLUTION:
	with customer_date as 
						(Select s.customer_id, 
								s.product_id, 
                                m.join_date, 
                                s.order_date, 
                                dense_rank() over(partition by s.customer_id order by s.order_date) as ranking
						from sales as s
						right join members as m
						on s.customer_id = m.customer_id
						where s.order_date > m.join_date)

	Select c.customer_id, 
		   c.product_id, 
           m.product_name
	from customer_date as c
	join menu as m
		 on m.product_id = c.product_id
	where c.ranking =1
	order by c.customer_id;


-- QUESTION 7: Which item was purchased just before the customer became a menber?
-- SOLUTION:
	with customer_date as 
						(Select s.customer_id,
								s.product_id, 
                                m.join_date, 
                                s.order_date,
                                dense_rank() over(partition by s.customer_id order by s.order_date desc) as ranking
						from sales as s
						right join members as m
						on s.customer_id = m.customer_id
						where s.order_date < m.join_date)

	Select c.customer_id, c.product_id, m.product_name
	from customer_date as c
	join menu as m
		 on m.product_id = c.product_id
	where c.ranking = 1
	order by c.customer_id;

-- QUESTION 8: what is the total items and amount spent by each member before they became a menber?
-- SOLUTION:
	with customer_date as 
						(Select s.customer_id,
								s.product_id, 
                                s.order_date
						from sales as s
						left join members as m
							     on s.customer_id = m.customer_id
						where s.order_date < m.join_date)

	Select c.customer_id, 
		   count(c.product_id) as product_count, 
           sum(m.price) as total_price
	from customer_date as c
	join menu as m
		 on m.product_id = c.product_id
	group by customer_id;

-- QUESTION 9: if each $1 spent equals to 10 points and sushi has 2x multiplier. How many points would each customer have?
-- SOLUTION:
	with points_table as 
    (
						Select *, 
						CASE When product_name = "sushi" then 2 else 1 end as points
						from menu
	)
	Select s.customer_id, 
		   sum(p.points * p.price *10) as Points
	from sales as s
	join points_table as p
	on s.product_id = p.product_id
	group by s.customer_id;

-- QUESTION 10: In the first week after a customer joins a program (Including their join date) they earn 2x points on all items not just sushi. How many points do customer A and B have at the end of January. 
-- SOLUTION:
	with validity as
    (
				Select *, 
					   date_add(join_date, INTERVAL 6 DAY) as valid_date, last_day("2021-01-01") as Last_day
				from members
    )

	Select s.customer_id, 
		   s.order_date, 
           s.product_id, 
           m.product_name, 
           m.price,
		   Case when s.product_id = 1 THEN 2 * 10 * m.price
				when s.order_date BETWEEN v.join_date AND v.valid_date THEN 2 * 10 * m.price
	            else 10 * m.price end as vd
	from sales as s
	join menu as m
	on s.product_id = m.product_id
	join validity as v
	on v.customer_id = s.customer_id
	where s.order_date <= v.Last_day
	group by  s.customer_id, s.order_date, v.join_date, v.valid_date, v.Last_day, m.product_name, m.price;


-- BONUS QUESTIONS
-- 1
	Select s.customer_id, s.order_date, m.product_name, m.price,
	Case when s.order_date >= me.join_date AND me.customer_id IS NOT NULL then "Y" ELSE "N" end as Member
	from sales as s
	join menu as m
	on m.product_id = s.product_id
	left join members as me
	on me.customer_id = s.customer_id;

-- 2
	with customer_members as (Select s.customer_id, s.order_date, m.product_name, m.price,
	Case when s.order_date >= me.join_date AND me.customer_id IS NOT NULL then "Y" ELSE "N" end as Member
	from sales as s
	join menu as m
	on m.product_id = s.product_id
	left join members as me
	on me.customer_id = s.customer_id)

	Select *, 
	case when Member = "N" then NULL else dense_rank() over(partition by customer_id, Member order by order_date) end as Ranking
	from customer_members


-- Thanks for reading!
 





