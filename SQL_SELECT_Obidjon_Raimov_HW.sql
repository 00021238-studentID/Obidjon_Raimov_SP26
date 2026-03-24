-- PART 1

-- The marketing team needs a list of animation movies between 2017 and 2019 to promote family-friendly content in an upcoming season in stores.
-- Show all animation movies released during this period with rate more than 1, sorted alphabetically
-- Requirements:
	-- b/w 2017-2019
	-- animation movies
	-- rate > 1
	-- ordered alphabetically

-- JOIN version
SELECT f.title, f.release_year, f.rental_rate 
FROM public.film f 
INNER JOIN public.film_category fc	ON f.film_id = fc.film_id 
INNER JOIN public.category c		ON fc.category_id = c.category_id 
WHERE c."name" = 'Animation' 
	AND f.release_year 
	BETWEEN 2017 AND 2019
	AND f.rental_rate > 1
ORDER BY f.title ASC

-- SUBQUERY version
SELECT f.title, f.release_year, f.rental_rate
FROM public.film f 
WHERE f.release_year 
	BETWEEN 2017 AND 2019 
	AND f.rental_rate > 1
	AND EXISTS ( 
		SELECT *
		FROM public.film_category fc
		WHERE fc.film_id  = f.film_id 
			AND EXISTS (
				SELECT *
				FROM public.category c 
				WHERE c.category_id = fc.category_id 
					AND c."name" = 'Animation'
		)
)
ORDER BY f.title ASC

-- CTE version
WITH animation_films AS (
	SELECT *
	FROM public.film f 
	INNER JOIN public.film_category fc		ON f.film_id = fc.film_id
	INNER JOIN public.category c 			ON c.category_id = fc.category_id
)
SELECT af.title, af.release_year, af.rental_rate
FROM animation_films af
WHERE af.release_year BETWEEN 2017 AND 2019
	AND af."name" = 'Animation'
	AND af.rental_rate > 1
ORDER BY af.title ASC


-- The finance department requires a report on store performance to assess profitability and plan resource allocation for stores after March 2017. 
-- Calculate the revenue earned by each rental store after March 2017 (since April) (include columns: address and address2 – as one column, revenue)
-- Requirements:
	-- rev earned by each store
	-- after March 2017
	-- include address & address 2 -> as a single column, rev

-- JOIN version
SELECT 
    CONCAT(a.address, 
           CASE WHEN a.address2 IS NOT NULL AND a.address2 <> '' 
                THEN ' ' || a.address2 
                ELSE '' 
           END) AS full_address,
    ROUND(SUM(p.amount), 2) AS revenue
FROM public.store s
INNER JOIN public.staff st      ON s.store_id = st.store_id
INNER JOIN public.payment p     ON st.staff_id = p.staff_id
INNER JOIN public.address a     ON s.address_id = a.address_id
WHERE p.payment_date >= '2017-04-01'
GROUP BY s.store_id, a.address, a.address2
ORDER BY revenue DESC;

--SUBQUERY 	version
SELECT 
    CONCAT(a.address, 
           CASE WHEN a.address2 IS NOT NULL AND a.address2 <> '' 
                THEN ' ' || a.address2 
                ELSE '' 
           END) AS full_address,
    ROUND(SUM(p.amount), 2) AS revenue
FROM public.store s
INNER JOIN public.staff st      ON s.store_id = st.store_id
INNER JOIN public.address a     ON s.address_id = a.address_id
INNER JOIN public.payment p     ON st.staff_id = p.staff_id
WHERE p.payment_date >= '2017-04-01'
   AND p.staff_id IN (
       SELECT staff_id 
       FROM public.staff 
       WHERE store_id = s.store_id
   )
GROUP BY s.store_id, a.address, a.address2
ORDER BY revenue DESC;

-- CTE version
WITH payments_after_apr AS (
    SELECT p.staff_id, p.amount
    FROM public.payment p
    WHERE p.payment_date >= '2017-04-01'
)
SELECT 
    CONCAT(a.address, 
           CASE WHEN a.address2 IS NOT NULL AND a.address2 <> '' 
                THEN ' ' || a.address2 
                ELSE '' 
           END) AS full_address,
    ROUND(SUM(pa.amount), 2) AS revenue
FROM public.store s
INNER JOIN public.staff st      ON s.store_id = st.store_id
INNER JOIN payments_after_apr pa ON st.staff_id = pa.staff_id
INNER JOIN public.address a     ON s.address_id = a.address_id
GROUP BY s.store_id, a.address, a.address2
ORDER BY revenue DESC;


-- The marketing department in our stores aims to identify the most successful actors since 2015 to boost customer interest in their films. 
-- Show top-5 actors by number of movies (released since 2015) they took part in (columns: first_name, last_name, number_of_movies, sorted by number_of_movies in descending order)
-- Requirements:
	-- top-5 actors by number of movies they were in
	-- movies that are released since 2015
	-- columns: first_name, last_name, number_of_movies, sorted by number_of_movies in descending order

-- JOIN version
SELECT 
    a.first_name,
    a.last_name,
    COUNT(f.film_id) AS number_of_movies
FROM public.actor a
INNER JOIN public.film_actor fa ON a.actor_id = fa.actor_id
INNER JOIN public.film f      	ON fa.film_id = f.film_id
WHERE f.release_year >= 2015
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY number_of_movies DESC
LIMIT 5;

-- SUBQUERY version
SELECT 
    a.first_name,
    a.last_name,
    (
        SELECT COUNT(fa2.film_id)
        FROM public.film_actor fa2
        INNER JOIN public.film f2 ON fa2.film_id = f2.film_id
        WHERE fa2.actor_id = a.actor_id
          AND f2.release_year >= 2015
    ) AS number_of_movies
FROM public.actor a
WHERE EXISTS (
    SELECT 1
    FROM public.film_actor fa
    INNER JOIN public.film f ON fa.film_id = f.film_id
    WHERE fa.actor_id = a.actor_id
      AND f.release_year >= 2015
)
ORDER BY number_of_movies DESC
LIMIT 5;

-- CTE version
WITH recent_films AS (
    SELECT film_id
    FROM public.film
    WHERE release_year >= 2015
),
actor_movies AS (
    SELECT 
        a.actor_id,
        a.first_name,
        a.last_name,
        COUNT(fa.film_id) AS number_of_movies
    FROM public.actor a
    INNER JOIN public.film_actor fa ON a.actor_id = fa.actor_id
    INNER JOIN recent_films rf ON fa.film_id = rf.film_id
    GROUP BY a.actor_id, a.first_name, a.last_name
)
SELECT 
    first_name,
    last_name,
    number_of_movies
FROM actor_movies
ORDER BY number_of_movies DESC
LIMIT 5;


-- The marketing team needs to track the production trends of Drama, Travel, and Documentary films to inform genre-specific marketing strategies. 
-- Show number of Drama, Travel, Documentary per year (include columns: release_year, number_of_drama_movies, number_of_travel_movies, number_of_documentary_movies), sorted by release year in descending order. Dealing with NULL values is encouraged)
-- Requirements:
	-- number of Drama, Travel, Documentary per year
	-- columns: release_year, number_of_drama_movies, number_of_travel_movies, number_of_documentary_movies
	-- sort by release year in descending order
	-- deal with null values

-- JOIN version
SELECT 
    f.release_year,
    SUM(CASE WHEN c.name = 'Drama'       THEN 1 ELSE 0 END) AS number_of_drama_movies,
    SUM(CASE WHEN c.name = 'Travel'      THEN 1 ELSE 0 END) AS number_of_travel_movies,
    SUM(CASE WHEN c.name = 'Documentary' THEN 1 ELSE 0 END) AS number_of_documentary_movies
FROM public.film f
INNER JOIN public.film_category fc ON f.film_id = fc.film_id
INNER JOIN public.category c       ON fc.category_id = c.category_id
WHERE c.name IN ('Drama', 'Travel', 'Documentary')
GROUP BY f.release_year
ORDER BY f.release_year DESC;

-- SUBQUERY version
SELECT 
    release_year,
    SUM(CASE WHEN name = 'Drama'       THEN 1 ELSE 0 END) AS number_of_drama_movies,
    SUM(CASE WHEN name = 'Travel'      THEN 1 ELSE 0 END) AS number_of_travel_movies,
    SUM(CASE WHEN name = 'Documentary' THEN 1 ELSE 0 END) AS number_of_documentary_movies
FROM (
    SELECT f.release_year, c.name
    FROM public.film f
    INNER JOIN public.film_category fc ON f.film_id = fc.film_id
    INNER JOIN public.category c       ON fc.category_id = c.category_id
    WHERE c.name IN ('Drama', 'Travel', 'Documentary')
) sub
GROUP BY release_year
ORDER BY release_year DESC;

-- CTE version
WITH genre_counts AS (
    SELECT 
        f.release_year,
        c.name,
        COUNT(*) AS movie_count
    FROM public.film f
    INNER JOIN public.film_category fc ON f.film_id = fc.film_id
    INNER JOIN public.category c       ON fc.category_id = c.category_id
    WHERE c.name IN ('Drama', 'Travel', 'Documentary')
    GROUP BY f.release_year, c.name
)
SELECT 
    release_year,
    SUM(CASE WHEN name = 'Drama'       THEN movie_count ELSE 0 END) AS number_of_drama_movies,
    SUM(CASE WHEN name = 'Travel'      THEN movie_count ELSE 0 END) AS number_of_travel_movies,
    SUM(CASE WHEN name = 'Documentary' THEN movie_count ELSE 0 END) AS number_of_documentary_movies
FROM genre_counts
GROUP BY release_year
ORDER BY release_year DESC;

-- I would choose the JOIN version in production.
-- Reason: highest readability + best performance (PostgreSQL optimizer handles multi-table JOINs very efficiently here).
-- CTE is excellent for readability and would be my second choice if the query becomes more complex later.
-- Subquery version I would avoid unless there's a very specific reason (e.g. very large film table and we want semi-join optimization in rare cases).

-- PART 2

-- 1.
-- The HR department aims to reward top-performing employees in 2017 with bonuses to recognize their contribution to stores revenue. 
-- Show which three employees generated the most revenue in 2017? 

-- JOIN version
WITH staff_revenue AS (
    SELECT 
        p.staff_id,
        SUM(p.amount) AS total_revenue,
        MAX(p.payment_date) AS last_payment_date
    FROM public.payment p
    WHERE EXTRACT(YEAR FROM p.payment_date) = 2017
    GROUP BY p.staff_id
)
SELECT 
    st.first_name,
    st.last_name,
    CONCAT(a.address, 
           CASE WHEN a.address2 IS NOT NULL AND a.address2 <> '' 
                THEN ' ' || a.address2 
                ELSE '' 
           END) AS last_store_address,
    ROUND(sr.total_revenue, 2) AS total_revenue
FROM staff_revenue sr
INNER JOIN public.staff st      ON sr.staff_id = st.staff_id
INNER JOIN public.store s       ON st.store_id = s.store_id
INNER JOIN public.address a     ON s.address_id = a.address_id
ORDER BY sr.total_revenue DESC
LIMIT 3;

-- SUBQUERY version
SELECT 
    st.first_name,
    st.last_name,
    (
        SELECT CONCAT(a2.address, 
                      CASE WHEN a2.address2 IS NOT NULL AND a2.address2 <> '' 
                           THEN ' ' || a2.address2 
                           ELSE '' 
                      END)
        FROM public.staff st2
        INNER JOIN public.store s2 ON st2.store_id = s2.store_id
        INNER JOIN public.address a2 ON s2.address_id = a2.address_id
        WHERE st2.staff_id = st.staff_id
        ORDER BY (
            SELECT MAX(payment_date) 
            FROM public.payment 
            WHERE staff_id = st.staff_id 
              AND EXTRACT(YEAR FROM payment_date) = 2017
        ) DESC
        LIMIT 1
    ) AS last_store_address,
    (
        SELECT SUM(amount)
        FROM public.payment p
        WHERE p.staff_id = st.staff_id
          AND EXTRACT(YEAR FROM p.payment_date) = 2017
    ) AS total_revenue
FROM public.staff st
WHERE EXISTS (
    SELECT 1 
    FROM public.payment p 
    WHERE p.staff_id = st.staff_id 
      AND EXTRACT(YEAR FROM p.payment_date) = 2017
)
ORDER BY total_revenue DESC
LIMIT 3;

-- CTE version
WITH payments_2017 AS (
    SELECT 
        staff_id,
        amount,
        payment_date
    FROM public.payment
    WHERE EXTRACT(YEAR FROM payment_date) = 2017
),
staff_revenue AS (
    SELECT 
        staff_id,
        SUM(amount) AS total_revenue,
        MAX(payment_date) AS last_payment_date
    FROM payments_2017
    GROUP BY staff_id
)
SELECT 
    st.first_name,
    st.last_name,
    CONCAT(a.address, 
           CASE WHEN a.address2 IS NOT NULL AND a.address2 <> '' 
                THEN ' ' || a.address2 
                ELSE '' 
           END) AS last_store_address,
    ROUND(sr.total_revenue, 2) AS total_revenue
FROM staff_revenue sr
INNER JOIN public.staff st ON sr.staff_id = st.staff_id
INNER JOIN public.store s  ON st.store_id = s.store_id
INNER JOIN public.address a ON s.address_id = a.address_id
ORDER BY sr.total_revenue DESC
LIMIT 3;

-- 2.
-- The management team wants to identify the most popular movies and their target audience age groups to optimize marketing efforts. 
-- Show which 5 movies were rented more than others (number of rentals), and what's the expected age of the audience for these movies? To determine expected age please use 'Motion Picture Association film rating system'

-- JOIN version
SELECT 
    f.title,
    f.rating,
    CASE f.rating
        WHEN 'G'       THEN 'All Ages (0+)'
        WHEN 'PG'      THEN 'Parental Guidance Suggested (~10+)'
        WHEN 'PG-13'   THEN 'Parents Strongly Cautioned (~13+)'
        WHEN 'R'       THEN 'Restricted (~17+ with adult)'
        WHEN 'NC-17'   THEN 'Adults Only (18+)'
        ELSE 'Unknown'
    END AS expected_audience_age_group,
    COUNT(r.rental_id) AS number_of_rentals
FROM public.film f
INNER JOIN public.inventory i ON f.film_id = i.film_id
INNER JOIN public.rental r    ON i.inventory_id = r.inventory_id
GROUP BY f.film_id, f.title, f.rating
ORDER BY number_of_rentals DESC
LIMIT 5;

-- SUBQUERY version
SELECT 
    f.title,
    f.rating,
    CASE f.rating
        WHEN 'G'       THEN 'All Ages (0+)'
        WHEN 'PG'      THEN 'Parental Guidance Suggested (~10+)'
        WHEN 'PG-13'   THEN 'Parents Strongly Cautioned (~13+)'
        WHEN 'R'       THEN 'Restricted (~17+ with adult)'
        WHEN 'NC-17'   THEN 'Adults Only (18+)'
        ELSE 'Unknown'
    END AS expected_audience_age_group,
    (
        SELECT COUNT(r.rental_id)
        FROM public.inventory i
        INNER JOIN public.rental r ON i.inventory_id = r.inventory_id
        WHERE i.film_id = f.film_id
    ) AS number_of_rentals
FROM public.film f
WHERE EXISTS (
    SELECT 1 
    FROM public.inventory i
    INNER JOIN public.rental r ON i.inventory_id = r.inventory_id
    WHERE i.film_id = f.film_id
)
ORDER BY number_of_rentals DESC
LIMIT 5;

-- CTE version
WITH movie_rentals AS (
    SELECT 
        i.film_id,
        COUNT(r.rental_id) AS number_of_rentals
    FROM public.inventory i
    INNER JOIN public.rental r ON i.inventory_id = r.inventory_id
    GROUP BY i.film_id
)
SELECT 
    f.title,
    f.rating,
    CASE f.rating
        WHEN 'G'       THEN 'All Ages (0+)'
        WHEN 'PG'      THEN 'Parental Guidance Suggested (~10+)'
        WHEN 'PG-13'   THEN 'Parents Strongly Cautioned (~13+)'
        WHEN 'R'       THEN 'Restricted (~17+ with adult)'
        WHEN 'NC-17'   THEN 'Adults Only (18+)'
        ELSE 'Unknown'
    END AS expected_audience_age_group,
    mr.number_of_rentals
FROM movie_rentals mr
INNER JOIN public.film f ON mr.film_id = f.film_id
ORDER BY mr.number_of_rentals DESC
LIMIT 5;

-- PART 3
-- Which actors/actresses didn't act for a longer period of time than the others? 
-- The stores’ marketing team wants to analyze actors' inactivity periods to select those with notable career breaks for targeted promotional campaigns, highlighting their comebacks or consistent appearances to engage customers with nostalgic or reliable film stars
-- The task can be interpreted in various ways, and here are a few options (provide solutions for each one):
-- V1: gap between the latest release_year and current year per each actor;
-- V2: gaps between sequential films per each actor;

-- V1 - JOIN version
SELECT 
    a.first_name,
    a.last_name,
    MAX(f.release_year) 		AS latest_film_year,
    2026 - MAX(f.release_year) 	AS years_inactive
FROM public.actor a
LEFT JOIN public.film_actor fa 	ON a.actor_id = fa.actor_id
LEFT JOIN public.film f       	ON fa.film_id = f.film_id
GROUP BY a.actor_id, a.first_name, a.last_name
HAVING MAX(f.release_year) IS NOT NULL
ORDER BY years_inactive	DESC;

-- V1 - SUBQUERY version
SELECT 
    a.first_name,
    a.last_name,
    (SELECT MAX(f.release_year)
     FROM public.film_actor fa
     INNER JOIN public.film f 			ON fa.film_id = f.film_id
     WHERE fa.actor_id = a.actor_id) 	AS latest_film_year,
    2026 - (SELECT MAX(f.release_year)
            FROM public.film_actor fa
            INNER JOIN public.film f 		ON fa.film_id = f.film_id
            WHERE fa.actor_id = a.actor_id) AS years_inactive
FROM public.actor a
WHERE EXISTS (
    SELECT 1 
    FROM public.film_actor fa 
    WHERE fa.actor_id = a.actor_id
)
ORDER BY years_inactive DESC;

-- V1 - CTE version
WITH actor_latest_film AS (
    SELECT 
        a.actor_id,
        a.first_name,
        a.last_name,
        MAX(f.release_year) 		AS latest_film_year
    FROM public.actor a
    LEFT JOIN public.film_actor fa 	ON a.actor_id = fa.actor_id
    LEFT JOIN public.film f        	ON fa.film_id = f.film_id
    GROUP BY a.actor_id, a.first_name, a.last_name
)
SELECT 
    first_name,
    last_name,
    latest_film_year,
    2026 - latest_film_year AS years_inactive
FROM actor_latest_film
WHERE latest_film_year IS NOT NULL
ORDER BY years_inactive DESC;

-- V2 - JOIN version
SELECT 
    a.first_name,
    a.last_name,
    MIN(f.release_year) 						AS first_film_year,
    MAX(f.release_year) 						AS last_film_year,
    MAX(f.release_year) - MIN(f.release_year) 	AS gap_years
FROM public.actor a
INNER JOIN public.film_actor fa 				ON a.actor_id = fa.actor_id
INNER JOIN public.film f        				ON fa.film_id = f.film_id
GROUP BY a.actor_id, a.first_name, a.last_name
HAVING COUNT(DISTINCT f.release_year) >= 2
ORDER BY gap_years DESC;

-- V2 - SUBQUERY version
SELECT 
    a.first_name,
    a.last_name,
    (SELECT MIN(f.release_year) FROM public.film_actor fa 
     INNER JOIN public.film f 	ON fa.film_id = f.film_id 
     WHERE fa.actor_id = a.actor_id) 	AS first_film_year,     
    (SELECT MAX(f.release_year) FROM public.film_actor fa 
     INNER JOIN public.film f 	ON fa.film_id = f.film_id 
     WHERE fa.actor_id = a.actor_id) 	AS last_film_year,
    (SELECT MAX(f.release_year) - MIN(f.release_year) 
     FROM public.film_actor fa 
     INNER JOIN public.film f 	ON fa.film_id = f.film_id 
     WHERE fa.actor_id = a.actor_id) 	AS gap_years
FROM public.actor a
WHERE EXISTS (
    SELECT 1 
    FROM public.film_actor fa 
    WHERE fa.actor_id = a.actor_id
)
ORDER BY gap_years DESC;

-- V2 - CTE version
WITH actor_films AS (
    SELECT 
        a.actor_id,
        a.first_name,
        a.last_name,
        f.release_year
    FROM public.actor a
    INNER JOIN public.film_actor fa ON a.actor_id = fa.actor_id
    INNER JOIN public.film f        ON fa.film_id = f.film_id
),
film_gaps AS (
    SELECT 
        actor_id,
        first_name,
        last_name,
        MIN(release_year) 						AS first_film_year,
        MAX(release_year) 						AS last_film_year,
        MAX(release_year) - MIN(release_year) 	AS biggest_gap
    FROM actor_films
    GROUP BY actor_id, first_name, last_name
    HAVING COUNT(DISTINCT release_year) >= 2
)
SELECT 
    first_name,
    last_name,
    first_film_year,
    last_film_year,
    biggest_gap AS gap_years
FROM film_gaps
ORDER BY biggest_gap DESC;