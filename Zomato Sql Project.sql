drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'09-22-2017'),
(3,'04-21-2017');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'05-20-2016',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

--1.what is total amount each customer spent on zomato?

SELECT
	u.userid,
	sum(p.price) as total_spent
FROM users as u
JOIN sales as s
on u.userid = s.userid
JOIN product as p
on s.product_id = p.product_id
group by 1

--2.how many days has each customer visited zomato?

SELECT
	userid,
	count(distinct created_date) as visted_days
FROM sales as s
group by 1

--3.what was FIRST product purchase by each customer?

WITH cte as
(
SELECT
	userid,
	created_date,
	product_id,
	row_number() over(partition by userid order by created_date) as ranks
FROM sales
)
SELECT
	userid,
	created_date,
	product_id
FROM cte
where ranks = 1

--4. what is the most purchased item on the menu and how many times it was purchased by each customers?

select
	userid,
	product_id as most_purchase_product,
	count(*) as purchase_count
from sales
where
	product_id = (select product_id from sales
					group by 1
					order by count(*) desc
					limit 1)
group by 1,2

--5. which item was more popular for each customer?

with cte as
(
SELECT
	userid,
	product_id,
	count(product_id) as order_count,
	rank() over(partition by userid order by count(product_id) desc) as ranks
FROM sales
group by 1,2
)
SELECT 
	userid,
	product_id as popular_product,
	order_count
from cte
where ranks = 1

--6.which items was purchased first by the customer after they became a member?

with cte as
(
select
	s.userid,
	s.product_id,
	s.created_date,
	g.gold_signup_date,
	rank() over(partition by s.userid order by s.created_date) as ranks
from sales as s
join goldusers_signup as g
on s.userid = g.userid
and s.created_date >= g.gold_signup_date
)
select
	userid,
	product_id,
	created_date,
	gold_signup_date
from cte
where ranks = 1

--7.which items was purchased just before the customer beacame a member?

with cte as
(
select
	s.userid,
	s.product_id,
	s.created_date,
	g.gold_signup_date,
	rank() over(partition by s.userid order by s.created_date desc) as ranks
from sales as s
join goldusers_signup as g
on s.userid = g.userid
and s.created_date <= g.gold_signup_date
)
select
	userid,
	product_id,
	created_date,
	gold_signup_date
from cte
where ranks = 1

--8.what is total orders and total amount spent for each user before they became a member?

with cte as
(
select
	s.userid,
	p.product_id,
	p.price,
	s.created_date,
	g.gold_signup_date
from sales as s
join goldusers_signup as g
on s.userid = g.userid
and s.created_date <= g.gold_signup_date
join product as p
on s.product_id = p.product_id
)
select
	userid,
	count(product_id) as product_purchased,
	sum(price) as total_spent
from cte
group by 1
order by 1

--9.if buying each product generates points for eg 5rs- 2zomato point and each product has different purchasing points 
--for eg p1 5rs - 1 pt , for p2 10rs - 5 point and p3 - 5rs -1 zomato point
--calculate points collected by each customers and for which product most ppoints have been given till now

--for points collected by each customers
SELECT
	s.userid,
	(sum(case WHEN p.product_id = 1 then (p.price/5)*1 else 0 end) +
	sum(case WHEN p.product_id = 2 then (p.price/10)*5 else 0 end) +
	sum(case WHEN p.product_id = 3 then (p.price/5)*1 else 0 end))*2.5 as total_money_earned
FROM product as p
join sales as s
on s.product_id = p.product_id
group by 1
order by 1

--for points collected by each product

SELECT
	s.product_id,
	(sum(case WHEN p.product_id = 1 then (p.price/5)*1 else 0 end) +
	sum(case WHEN p.product_id = 2 then (p.price/10)*5 else 0 end) +
	sum(case WHEN p.product_id = 3 then (p.price/5)*1 else 0 end)) as total_money_earned
FROM product as p
join sales as s
on s.product_id = p.product_id
group by 1
order by 2 DESC
limit 1

--10. in the first one year after customer joins the gold program (including their join date) irrespective
--of what the customer has purchased they earn 5 zomato points for every 10 rs spent who earned more 1 or 3
--and what was their points earning in their first year?

SELECT
	s.userid,
	s.product_id,
	s.created_date,
	g.gold_signup_date,
	p.price,
	p.price*0.5 total_points_earned
from sales as s
join goldusers_signup as g
on s.userid = g.userid
AND s.created_date BETWEEN g.gold_signup_date AND g.gold_signup_date + INTERVAL '1 YEAR'
JOIN product as p
on s.product_id = p.product_id

--11. rank all the transation of the customer

SELECT
	*,
	rank() over(partition by userid order by created_date) as transaction_rank
FROM sales

--12.rank all the transactions for each member whenever they are zomato gold member for every non-gold member transaction mark as na

WITH cte as
(
SELECT
	s.userid,
	s.product_id,
	s.created_date,
	g.gold_signup_date
FROM sales as s
LEFT JOIN goldusers_signup as g
on s.userid = g.userid
AND s.created_date >= g.gold_signup_date
)
SELECT
	*,
	case
		when gold_signup_date is null then 'na'
		else cast(rank() over(partition by userid order by created_date desc)as varchar)
	END as ranks
from cte