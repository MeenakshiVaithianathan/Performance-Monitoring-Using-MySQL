-- 8 Week SQL Challenge --
-- https://8weeksqlchallenge.com/case-study-1/

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
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
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

  select * from sales

-- What is the total amount each customer spent at the restaurant?
  select S.customer_id,sum(M.price) from sales as S 
  join menu as M on S.product_id = M.product_id
  group by S.customer_id ;
-------------------------------------------------------------------------------------------------------

--How many days has each customer visited the restaurant?
select customer_id, count(distinct order_date) from sales
group by customer_id ;
-------------------------------------------------------------------------------------------------------

--What was the first item from the menu purchased by each customer?
select * from members

select A.customer_id,string_agg(S.product_id,',') as First_Ordered_Item from sales as S
join 
(select customer_id, min(order_date) as Min_date from sales group by customer_id) as A
on S.customer_id = A.customer_id and
S.order_date = A.Min_date
group by A.customer_id;
-------------------------------------------------------------------------------------------------------

--What is the most purchased item on the menu and how many times was it purchased by all customers?
select top 1 product_id, count(product_id) as Purchase_count from sales
group by product_id
order by Purchase_count desc;
-------------------------------------------------------------------------------------------------------

--Which item was the most popular for each customer?

select A.customer_id,string_agg(A.product_id,',') Popular_item from
(
select customer_id,product_id,
rank() over (partition by customer_id order by count(product_id) desc) as Rn
from sales
group by customer_id,product_id
) as A
where Rn =1
group by A.customer_id;  
-------------------------------------------------------------------------------------------------------

--Which item was purchased first by the customer after they became a member?

select SS.customer_id,SS.product_id from
(
select S.customer_id, S.order_date ,
rank() over (partition by S.customer_id order by order_date) as Rn
from sales as S
join members as M on S.customer_id = M.customer_id
where order_date >= join_date
) as A 
join sales as SS
on SS.customer_id = A.customer_id 
and SS.order_date = A.order_date
where A.Rn = 1;
-------------------------------------------------------------------------------------------------------

--Which item was purchased just before the customer became a member?
select distinct SS.customer_id,SS.order_date,SS.product_id from
(
select S.customer_id, S.order_date ,
rank() over (partition by S.customer_id order by order_date desc) as Rn
from sales as S
join members as M 
on S.customer_id = M.customer_id
where order_date < join_date
) as A 
join sales as SS
on SS.customer_id = A.customer_id 
and SS.order_date = A.order_date
where A.Rn = 1;
-------------------------------------------------------------------------------------------------------

--What is the total items and amount spent for each member before they became a member?

select S.customer_id, count(S.product_id) as Total_Items, sum(M.price) as Amount_Spent
from sales as S
left join members as MM on S.customer_id = MM.customer_id
join menu as M on S.product_id = M.product_id
where S.order_date < ISNULL(MM.join_date,GETDATE())
group by S.customer_id;

select GETDATE();
--If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

select A.customer_id,sum(A.Amount*10*A.multiplier) as Points
from
(
select 
s.customer_id,s.product_id, count(s.product_id)*m.price as Amount,
case when m.product_name = 'sushi' then 2 else 1 end as multiplier
from sales as s
join menu as m on s.product_id = m.product_id
group by s.customer_id,s.product_id,m.price,m.product_name
) as A
group by A.customer_id; -- not recommended


select 
s.customer_id, sum(m.price*10*(case when m.product_name = 'sushi' then 2 else 1 end)) as Amount
from sales as s
join menu as m on s.product_id = m.product_id
group by s.customer_id,s.product_id,m.price,m.product_name

-- ##DOUBT## should we include m.price also in the group by even though it is just  a part of the calculation???
-------------------------------------------------------------------------------------------------------------------------

--In the first week after a customer joins the program (including their join date) they earn 2x points on all items,
--not just sushi - how many points do customer A and B have at the end of January?

select A.customer_id,sum(A.Amount*10*A.multiplier) as Points
from
(
select 
s.customer_id,s.product_id,s.order_date, count(s.product_id)*m.price as Amount,
	case 
	 when s.order_date >= mm.join_date and s.order_date < DATEADD(day,7, mm.join_date) then 2 
	 when m.product_name = 'sushi' then 2 else 1 
	end as multiplier
from sales as s
join menu as m on s.product_id = m.product_id
join members as mm on s.customer_id = mm.customer_id
group by s.customer_id,s.product_id,s.order_date,m.product_name,m.price,mm.join_date
) as A
where month(A.order_date)<2
group by A.customer_id;
-------------------------------------------------------------------------------------------------------------------------

-- create a table with customer_id, order_date, product_name, price, member(Y/N) column, Ranking 
--( rank the customer products only after they become members

select A.customer_id, A.order_date, A.product_name, A.price,A.member,
CASE WHEN A.member = 'Y'
			THEN RANK() over (partition by A.customer_id,A.member order by A.order_date) 
	   ELSE NULL
	   END as ranking
from
(
SELECT s.customer_id, s.order_date,m2.join_date, m.product_name, m.price,
       CASE WHEN m2.customer_id IS NOT NULL and s.order_date >= m2.join_date
	   THEN 'Y' ELSE 'N' END AS member
FROM sales s
JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members m2 ON s.customer_id = m2.customer_id
) as A;
-------------------------------------------------------------------------------------------------------------------------





