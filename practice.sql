/* 
=============================================
1번(10문제) : 기본 SELECT & FILTER
=============================================
*/
# 전체 사용자 수를 구하시오.
SELECT count(user_id)
FROM users;

# 성별(gender)별 사용자 수를 구하시오.
SELECT gender, count(gender)
FROM users
GROUP BY gender;

# 2023년에 가입한 사용자 수를 구하시오.


# 2023년 3월에 가입한 사용자만 조회하라.


# 가장 오래된 가입일(signup_date)과 가장 최근 가입일을 구하라.
SELECT MAX(signup_date), min(signup_date)
FROM users;

# session_duration_sec가 2000초 이상인 세션 수를 구하라.
SELECT count(*)
FROM sessions
WHERE session_duration_sec >= 2000;

# 가격(price)이 10만 원 이상인 상품 수를 구하라.
SELECT count(*)
FROM products
WHERE price >= 100000;

# 카테고리(category)별 상품 수를 구하라.
SELECT category, count(*)
FROM products
GROUP BY category;

# orders 테이블에서 주문 날짜가 가장 빠른 10개를 조회하라.
SELECT *
FROM orders
ORDER BY order_date
LIMIT 10;

# users에서 user_id가 orders에 단 한 번도 등장하지 않은 유저를 찾아라.
# --- 내가 푼 방법 ---
SELECT u.user_id
FROM users u
LEFT JOIN orders o ON u.user_id = o.user_id
WHERE o.user_id IS NULL;

# --- JOIN 없이 하는 방법 ---
SELECT *
FROM users u
WHERE NOT EXISTS (
SELECT 1
FROM orders o
WHERE o.user_id = u.user_id)


/* 
=============================================
2번(10문제) : JOIN 문제 (중급)
=============================================
*/

# 주문(order)을 한 적 있는 유저 목록을 조회하라.
SELECT DISTINCT u.user_id
FROM users u
JOIN orders o on u.user_id = o.user_id;

# 사용자별 총 주문 횟수를 구하라.


# 사용자별 총 주문 횟수를 내림차순 정렬하라.
SELECT u.user_id, COUNT(order_id)
FROM users u
LEFT JOIN orders o ON u.user_id = o.user_id
GROUP BY u.user_id
ORDER BY count(order_id) DESC;

# 성별별(gender) 평균 주문 횟수를 구하라.


# 주문이 있는 user_id 중 가장 최근 signup_date를 가진 유저 5명을 조회하라.
SELECT DISTINCT u.user_id, signup_date
FROM users u
JOIN orders o on u.user_id = o.user_id
ORDER BY signup_date DESC
LIMIT 5;

# 사용자별 마지막 주문일(last order date)을 구하라.
SELECT user_id, MAX(order_date)
FROM orders
GROUP BY user_id;

# 첫 주문일(first order date)이 가장 빠른 사용자 10명을 조회하라.
SELECT user_id, min(order_date)
FROM orders
GROUP BY user_id
ORDER BY min(order_date)
LIMIT 10;

# user_id, signup_date, first_order_date를 함께 조회하라.
SELECT u.user_id, u.signup_date, min(order_date) AS first_order_date
FROM users u
JOIN orders o on u.user_id = o.user_id
GROUP BY u.user_id
ORDER BY first_order_date;

# 첫 주문까지 걸린 일수를 계산하여 user_id별로 조회하라.
SELECT u.user_id, julianday(f.first_order_date) - julianday(u.signup_date) AS date
FROM users u
JOIN (
	SELECT user_id, min(order_date) AS first_order_date
	FROM orders o
	GROUP BY user_id) f
on u.user_id = f.user_id
GROUP BY u.user_id;

# 성별별 첫 주문까지 걸린 평균 일수를 구하라.
SELECT gender, AVG(date)
FROM (
	SELECT u.user_id, gender, julianday(min(order_date)) - julianday(u.signup_date) AS date
	FROM users u
	JOIN orders o on u.user_id = o.user_id
	GROUP BY u.user_id)
GROUP BY gender;


/* 
==================================================
3번(10문제) : DATE / COHORT / FUNNEL 문제 (중상급)
==================================================
*/

# 월별(signup_date 기준) 가입자 수를 구하라.
SELECT strftime('%Y-%m', signup_date) AS months, count(user_id)
FROM users
WHERE signup_date IS NOT NULL
GROUP BY strftime('%Y-%m', signup_date);

# 월별(order_date 기준) 주문 수를 구하라.
SELECT strftime('%Y-%m', order_date) AS months, count(o.user_id)
FROM users u
JOIN orders o on u.user_id = o.user_id
GROUP BY months;

# 월별 재구매율(월에 2회 이상 구매한 사용자 비율)을 구하라.


# cohorts: 가입 월 기준 다음달 주문을 한 사용자 수를 구하라.


# cohorts: 가입 후 3개월 이내 재구매한 사용자 비율을 구하라.


# “1일차 → 7일차 → 30일차” 리텐션을 계산하는 쿼리를 작성하라.


# 세션(session) 시작 날짜 기준, 일별 DAU를 구하라.
SELECT session_start, count(user_id)
FROM sessions
GROUP BY session_start;

# user_id별 평균 세션 길이를 구하라.
select user_id, AVG(session_duration_sec) AS avg_sec
FROM sessions
GROUP BY user_id;

# 성별별 평균 세션 길이 비교
SELECT gender, AVG(session_duration_sec)
FROM users u
LEFT JOIN sessions s ON u.user_id = s.user_id
GROUP BY gender;

# 가입 후 첫 접속까지 걸린 기간을 계산하라.
SELECT u.user_id, julianday(MIN(session_start)) - julianday(signup_date)
FROM users u
JOIN sessions s on u.user_id = s.user_id
GROUP BY u.user_id;

/* 
===================================================
4번(10문제) : A/B Test, Window Function 문제 (상급)
===================================================
*/

# user_id별 주문 순번(row_number)을 계산하라.


# user_id별 누적 주문 수(cumulative count)를 나타내라.


# user_id별 주문 간격(이전 주문일과의 차이)을 계산하라.


# 주문 날짜 기준 상위 10%에 해당하는 주문을 조회하라.
SELECT order_date, order_id
FROM orders
ORDER by order_date DESC
limit (SELECT count(*)*0.1
		FROM orders);

# 가격이 가장 높은 상품 TOP 5를 조회하되, 동일 가격이면 product_id 오름차순.
SELECT product_id, price
FROM products
ORDER BY price DESC, product_id
LIMIT 5;

# 세션 길이가 상위 1% 이상인 사용자들 목록을 조회하라.
SELECT user_id
FROM sessions
GROUP BY user_id
ORDER BY SUM(session_duration_sec) DESC
LIMIT (SELECT count(DISTINCT user_id)*0.01
		FROM sessions)
	

# 최근 30일 주문 수와 이전 30일 주문 수를 나란히 조회하라.


# 카테고리(category)별 상품의 평균 가격을 구하고, 평균 가격이 높은 순서대로 정렬하라.
SELECT category, AVG(price)
FROM products
GROUP BY category
ORDER BY AVG(price) DESC;

# 카테고리(category)별 상품 개수를 전체 상품 개수 대비 비율로 계산하라.
sELECT category, COUNT(product_id)* 1.0 / (SELECT count(DISTINCT product_id) FROM products) 
FROM products
GROUP BY category


# 최근 7일 동안 주문한 사용자 수를 rolling window로 계산하라.


/* 
===================================================
5번(10문제) : 종합 분석 문제 (실제 코딩 테스트 급)(상급)
===================================================
*/

# Funnel: step1: signup / step2: session / step3: order
# 위 3단계 전환율을 계산하라.


# products 테이블을 기준으로, 카테고리(category)별 상품 수가 전체 상품 수에서 차지하는 비율을 구하라.
SELECT category,
		count(DISTINCT product_id) * 1.0 / (SELECT count(DISTINCT product_id) FROM products) AS rate
FROM products
GROUP BY category

# orders 테이블을 기준으로, user별 주문 수 비율을 전체 주문 수 대비로 계산하라.
SELECT user_id,
		round(count(DISTINCT order_id) *1.0 / (SELECT count(DISTINCT order_id) FROM orders),3) AS rate
FROM orders
GROUP BY user_id

# 가입 주차(week)마다 평균 주문 수를 구하라.
WITH weekly_orders AS (
	SELECT strftime('%Y-%W', signup_date) AS weekly, u.user_id, COUNT(DISTINCT order_id) AS order_cnt
	FROM users u
	LEFT JOIN orders o ON u.user_id = o.user_id
	GROUP by strftime('%Y-%W', signup_date), u.user_id)
	
SELECT weekly, AVG(order_cnt)
FROM weekly_orders
group by weekly