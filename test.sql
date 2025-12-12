/* 
======================================================
test 1 : 5문제, 제한시간 60분 / 22분 소요, 4/5(합격 예상)
======================================================
*/

# 1번 : 가입한 연도별로 사용자 수를 구하라.
SELECT strftime('%Y', signup_date) AS year, count(DISTINCT user_id) AS user_count
FROM users
GROUP BY strftime('%Y', signup_date)

# 2번 : 사용자별로 총 주문 횟수를 구하고, 주문 횟수가 많은 순서대로 정렬하라.
SELECT u.user_id, COUNT(DISTINCT order_id) AS order_count
FROM users u
LEFT JOIN orders o ON u.user_id = o.user_id
GROUP BY u.user_id
ORDER BY order_count DESC

# 3번 : 사용자별 첫 주문까지 걸린 일수를 계산하라. (주문이 없는 사용자는 제외)
# --- 틀린 답 ---
SELECT u.user_id, julianday(order_date) - julianday(signup_date) AS days_to_first_order
FROM users u
JOIN orders o ON u.user_id = o.user_id
GROUP BY u.user_id

/* --- 오답 : MIN(order_date) 사용 ---
   -- 추가로 u.signup_date 도 GROUP BY 해주는 게 좋음 -- */
SELECT u.user_id, julianday(MIN(order_date)) - julianday(signup_date) AS days_to_first_order 
FROM users u
JOIN orders o ON u.user_id = o.user_id
GROUP BY u.user_id, u.signup_date

# 절댓값 구하는 함수 알아보기

# 4번 : 사용자별로 주문 순번을 매겨라. (첫 주문이 1번)
SELECT u.user_id, order_id, order_date, row_number()OVER(PARTITION BY u.user_id ORDER BY order_date) AS order_rank
FROM users u
LEFT JOIN orders o ON u.user_id = o.user_id

# 5번 : 가입 후 7일 이내에 세션을 한 사용자의 비율을 구하라.
SELECT (COUNT(DISTINCT user_id) * 1.0 / (SELECT count(DISTINCT user_id) FROM users)) AS retention_rate
FROM (SELECT u.user_id, (julianday(session_start) - julianday(signup_date)) AS question
FROM users u
LEFT JOIN sessions s ON u.user_id = s.user_id) AS new_table
WHERE question >= 0 AND question <= 7


/* 
======================================================
test 2 : 5문제, 제한시간 60분 / 44분 소요, 4/5(합격 예상)
======================================================
*/

# 1번 : 성별(gender)별로 평균 첫 세션까지 걸린 일수를 구하라. (세션이 없는 유저는 제외)
-- 부분 정답 --
SELECT gender, avg(julianday(MIN(session_start)) - julianday(signup_date)) as avg_days_to_first_session
FROM users u
JOIN sessions s on u.user_id = s.user_id
GROUP BY gender

-- 제대로 된 답 -- 
WITH first_session AS (
    SELECT
        u.user_id,
        u.gender,
        u.signup_date,
        MIN(s.session_start) AS first_session_start
    FROM users u
    JOIN sessions s ON u.user_id = s.user_id
    GROUP BY u.user_id, u.gender, u.signup_date
)
SELECT
    gender,
    AVG(julianday(first_session_start) - julianday(signup_date)) AS avg_days_to_first_session
FROM first_session
GROUP BY gender;


# 2번 : 사용자별로 세션 간 간격(일 단위)을 계산하라. (이전 세션이 없는 경우는 NULL)
-- 틀림 (group by user_id 가 LAG 식에 들어가야함(PARTITION BY 사용))--
SELECT u.user_id, session_id, session_start, julianday(session_start) - julianday(LAG(session_start)OVER(ORDER BY session_start)) AS days_from_prev_session
from users u
JOIN sessions s on u.user_id = s.user_id
GROUP BY u.user_id

-- 정답 --
SELECT user_id, session_id, session_start, julianday(session_start) - julianday(LAG(session_start) OVER (PARTITION BY user_id ORDER BY session_start)) AS days_from_prev_session
FROM sessions

# 3번 : 아래 퍼널 전환율을 구하라.
# Step 정의: signup (users), session (sessions), order (orders)
# 요구 결과: session / signup 전환율, order / session 전환율
# -- 틀림 (join 필요없음, 1.0 왜 안 곱했니?) --
WITH all_tables AS (
SELECT *
FROM users u
left join sessions s on u.user_id = s.user_id
left join orders o on u.user_id = o.user_id)

SELECT (SELECT COUNT(DISTINCT user_id) FROM sessions) / COUNT(DISTINCT user_id) AS step,
(SELECT COUNT(DISTINCT user_id) FROM all_tables) / (SELECT count(DISTINCT user_id) FROM sessions) AS conversion_rate
FROM users

-- 정답 --
WITH cnt AS (
    SELECT
        (SELECT COUNT(DISTINCT user_id) FROM users)   AS signup_cnt,
        (SELECT COUNT(DISTINCT user_id) FROM sessions) AS session_cnt,
        (SELECT COUNT(DISTINCT user_id) FROM orders)   AS order_cnt
)
SELECT
    session_cnt * 1.0 / signup_cnt  AS session_rate,
    order_cnt * 1.0 / session_cnt   AS order_rate
FROM cnt;


# 4번 : 주문 날짜 기준으로 가장 최근 10%에 해당하는 주문을 조회하라.
# -- 틀림(날짜 수의 10% 가 아니라 최신 10% 행 반환)
SELECT order_id, user_id, order_date
FROM orders
GROUP BY order_date
ORDER BY order_date DESC
LIMIT (SELECT count(DISTINCT order_date) from orders) * 0.1

# -- 정답 --


# 5번 : 아래 조건을 만족하는 “활성 사용자”를 조회하라.
# 활성 사용자 정의 : 전체 평균 세션 수보다 많이 세션한 사용자 
#              AND 전체 평균 세션 시간보다 평균 세션 시간이 긴 사용자

-- 틀림 (AVG(COUNT ()) 이거 불가능) --
with new_tables AS (SELECT user_id, session_id, AVG(COUNT(session_id)) AS all_session_count, session_duration_sec, AVG(session_duration_sec) AS all_avg_session_duration
FROM sessions)

SELECT user_id, AVG(count(session_id)) AS session_count, AVG(count(session_duration_sec)) AS avg_session_duration
FROM new_tables
GROUP BY user_id
HAVING all_session_count < AVG(count(session_id)) 
	AND all_avg_session_duration < AVG(count(session_duration_sec))

# -- 정답 --
# user_stats 사용자의 수
# session_count를 global_avg에 사용하는 이유 : user_stats 에서는 group by user_id 때문에 user_id 별로 session_count 가 나오는 것
# session_count 만 봤을 때 전체 평균 가능
WITH user_stats AS (
    SELECT
        user_id,
        COUNT(*) AS session_count,
        AVG(session_duration_sec) AS avg_session_duration
    FROM sessions
    GROUP BY user_id
),
global_avg AS (
    SELECT
        AVG(session_count) AS overall_avg_session_count,
        AVG(avg_session_duration) AS overall_avg_session_duration
    FROM user_stats
)
SELECT
    u.user_id,
    u.session_count, 
    u.avg_session_duration
FROM user_stats u
JOIN global_avg g
WHERE
    u.session_count > g.overall_avg_session_count
    AND u.avg_session_duration > g.overall_avg_session_duration;