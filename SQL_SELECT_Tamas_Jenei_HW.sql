--T1-1-V1
--TASK 1 animation movies between 2017 and 2019, all animation movies released during this period with rate more than 1
--1. All tables are located in the 'public' schema.
--2. 'Animation movies' are identified by joining the film table with the category table through the film_category bridge table.
--3. 'Rate' is interpreted as 'rental_rate' from the film table.
--4. The period 2017-2019 is inclusive (using BETWEEN).
--5. Only films with a matching category are required, so INNER JOIN is appropriate.
-- V1 It filters out any films that do not have a category assigned.
--If a film exists but isn't linked to 'Animation' in public.category, it won't appear.
--easy readeble fast running process only that data join which are in both tables
--Probably I use this solution because 2 inner join is not so much
--1 JOIN solution
select
	f.title,
	f.release_year,
	f.rental_rate
from public.film f
inner join public.film_category fc on f.film_id = fc.film_id
inner join public.category c on fc.category_id  =c.category_id 
where c.name = 'Animation'
	and f.release_year BETWEEN 2017 AND 2019
  	and f.rental_rate > 1
order by f.title ASC; 

--T1-1-V2
--Animation movies 2017-2019, rate > 1.--
--V2 Inside to outside logic so we use the subquery Animation select first as a filter--
--it is more complex than the first solution
--2 Subquery solution
select 
f.title, 
f.release_year,
f.rental_rate
from public.film f
where f.film_id in (
	select fc.film_id 
	from public.film_category fc 
	where fc.category_id = (select c.category_id 
							from public.category c
							where c.name ='Animation')
	)
and f.release_year BETWEEN 2017 AND 2019
and f.rental_rate > 1
	
--T1-1-V3
--Animation movies 2017-2019, rate > 1.--
-- V3 most complex solution if we need more time the ANimation film as a category for more querys I use that solution
--the next query could be shorter
--high complexity
--CTE Solution
with Animation_films as  (
select fc.film_id
from public.film_category fc
inner join public.category c on fc.category_id = c.category_id 
where c.name ='Animation'
)
select
	f.title,
	f.release_year,
	f.rental_rate
from public.film f
inner join Animation_films af on f.film_id = af.film_id
where f.release_year BETWEEN 2017 AND 2019
  	and f.rental_rate > 1
order by f.title ASC; 

--T1-2-V1
--TASK 2 Calculate the revenue earned by each rental store after March 2017 (since April). 
-- Include columns: address and address2 – as one column, revenue.
/* ASSUMPTIONS & LOGIC INTERPRETATION:
1. Revenue is calculated as the SUM of 'amount' from the public.payment table.
2. The period "after March 2017" is interpreted as payments where payment_date is on or after April 1st, 2017.
3. Each rental store is identified through the staff who processed the payment (payment -> staff -> store).
4. Store address is a concatenation of 'address' and 'address2'. 
5. COALESCE is used for 'address2' because if it is NULL, the entire concatenation would result in NULL without it.
6. All calculations and joins use the public schema.
*/
/* - JOIN type: INNER JOIN is used across payment, staff, store, and address tables. 
- It ensures only payments linked to a valid staff member and store with a registered address are included.
- It's a linear chain of joins.
- Low complexity, The database engine can optimize the join order efficiently.
- The GROUP BY clause becomes long because we need to group by both address components.
- I prefer this solution, because of easy readable
*/
select
a.address || ' ' || coalesce (a.address2, '') as store_address,
    sum(p.amount) as revenue
 from public.payment p 
 inner join public.staff s on p.staff_id = s.staff_id 
 inner join public.store s2 on s.store_id  = s2.store_id 
 inner join public.address a on s2.address_id = a.address_id 
 where p.payment_date >= '2017-04-01'
 group by a.address, a.address2
 order by revenue desc

--T1-2-V2
/* - Logical complexity medium, because it calculate the revenue per store_id first in a nested query.
- The internal result set must be generated before joining with the address table.
- Limitations: We can only "pass up" the store_id and the sum to the outer query.
- Lover readability because nested structures are generally harder to scan quickly.
- Performance is depends on how the optimizer handles the derived table.
-While this nested subquery approach is logically sound, it is significantly less efficient 
than a standard JOIN or CTE because it forces the database to create multiple intermediate materialized views.
*/
select
    a.address || ' ' || coalesce(a.address2, '') as store_address,
    store_rev.total_revenue as revenue
from public.address a
inner join public.store s2 on a.address_id = s2.address_id
inner join (
    -- Subquery starts here: calculating revenue per store first
    select s.store_id, sum(p.amount) as total_revenue
    from public.payment p
    inner join public.staff s on p.staff_id = s.staff_id
    where p.payment_date >= '2017-04-01'
    group by s.store_id
) as store_rev on s2.store_id = store_rev.store_id
order by revenue desc;

--T1-2-V3
/* - Logical complexity medium because it breaks the query into a "Finance logic" part and a "Display logic" part.
- Resource usage is efficient in modern PostgreSQL (treated similarly to JOIN).
- The StoreRevenue block clearly defines how the math is done.
- Production choice: I would use this solution in production. 
  if in a real-world scenario, revenue logic often changes (e.g., adding taxes or refunds). 
  By isolating the calculation in a CTE, the code is much easier to maintain and update without breaking the address formatting logic.
*/
with StoreRevenue as (
    select 
        s2.store_id, 
        s2.address_id,
        sum(p.amount) as amount
    from public.payment p
    inner join public.staff s on p.staff_id = s.staff_id
    inner join public.store s2 on s.store_id = s2.store_id
    where p.payment_date >= '2017-04-01'
    group by s2.store_id, s2.address_id
)
select 
    addr.address || ' ' || coalesce(addr.address2, '') as store_address,
    sr.amount as revenue
from StoreRevenue sr
inner join public.address addr on sr.address_id = addr.address_id
order by revenue desc;

--T1-3-V1
/* ASSUMPTIONS & LOGIC INTERPRETATION:
1. "Top 5 actors" is defined by the highest count of film appearances.
2. Only movies released in or after 2015 are considered (release_year >= 2015).
3. The count is based on the 'film_id' from the 'public.film_actor' table.
4. Actors are identified by their 'first_name' and 'last_name'.
5. If two actors have the same number of movies, the order is arbitrary unless specified (here we use standard DESC order).
6. IIDs (actor_id, film_id) are used for joining but not hardcoded in filters.
7. As per Rule 6, we use full column names in GROUP BY instead of numbers.
8.The Relationship: There is no direct connection between the 'actor' and the 'film' tables. 
 A 'film_actor' table (known as a junction table or bridge table) is required to identify which actor played in which movie.
 A bridge table is necessary to resolve a many-to-many (M:N) relationship.
*/
-- TASK 3: Show top-5 actors by number of movies released since 2015. 
-- Include columns: first_name, last_name, number_of_movies.
--easy to follow, It ensures that the result set only contains "active" data.
--if a film exists in the database but hasn't been assigned to an actor in the film_actor table, it is completely ignored
--direct relationship path so I prefer this solution, if only need this data
select 
    a.first_name, 
    a.last_name, 
    count(fa.film_id) as number_of_movies
from public.actor a
inner join public.film_actor fa on a.actor_id = fa.actor_id
inner join public.film f on fa.film_id = f.film_id
where f.release_year >= 2015
group by a.first_name, a.last_name
order by number_of_movies desc
limit 5;

--T1-3-V2
-- SOLUTION 2: SUBQUERY
/* - The filtering and counting happen inside a derived table.
- The database creates the top list of actor_ids first.
- Only retrieve columns that are part of the subquery or the join key.
- Sllightly more overhead than a direct join.
- Due to the nested SELECT it is harder to read
*/
select 
    act.first_name, 
    act.last_name, 
    top_list.movie_count as number_of_movies
from public.actor act
inner join (
    -- subquery to count movies per actor since 2015
    select fa.actor_id, count(fa.film_id) as movie_count
    from public.film_actor fa
    inner join public.film f on fa.film_id = f.film_id
    where f.release_year >= 2015
    group by fa.actor_id
) as top_list on act.actor_id = top_list.actor_id
order by number_of_movies desc
limit 5;

--T1-3-V3
-- SOLUTION 3: CTE (Common Table Expression)
/* - Separates the counting logic from the name retrieval.
- Clear separation of concerns.
- Production choice: I would use this CTE solution in production. 
- Why: It is highly maintainable. If the definition of "Top Actor" changes (e.g., adding 
  rating requirements), we only change the CTE. The final presentation remains clean.
*/
with actor_performance as (
    select 
        fa.actor_id, 
        count(fa.film_id) as movie_count
    from public.film_actor fa
    inner join public.film f on fa.film_id = f.film_id
    where f.release_year >= 2015
    group by fa.actor_id
)
select 
    a.first_name, 
    a.last_name, 
    ap.movie_count as number_of_movies
from public.actor a
inner join actor_performance ap on a.actor_id = ap.actor_id
order by number_of_movies desc
limit 5;

--T1-4-V1
/* ASSUMPTIONS & LOGIC INTERPRETATION:
1. The goal is to count movies per year for three specific categories: 'Drama', 'Travel', and 'Documentary'.
2. Relationship: A many-to-many relationship between 'film' and 'category' is resolved via the 'film_category' bridge table.
3. Pivoting logic: To display categories as columns instead of rows, I use conditional aggregation (SUM with CASE WHEN).
4. NULL Handling: If a genre has no movies in a given year, the result should be 0 instead of NULL (handled by the ELSE 0 branch).
5. Sorting: Results are ordered by release_year in descending order as per common trend analysis standards.
*/
-- TASK 4: Show the number of Drama, Travel, and Documentary movies per year.
-- Include columns: release_year, number_of_drama_movies, number_of_travel_movies, number_of_documentary_movies.
/* - JOIN type: INNER JOIN between film, film_category, and category.
- Uses the CASE WHEN expression to "sort" data into the correct columns.
- It scans the joined data only once to calculate all three columns.
- The column names clearly indicate the genre being counted.
- Easy followable step by step, after it creates more easy to create the others
*/
select 
    f.release_year,
    sum(case when c.name = 'drama' then 1 else 0 end) as number_of_drama_movies,
    sum(case when c.name = 'travel' then 1 else 0 end) as number_of_travel_movies,
    sum(case when c.name = 'documentary' then 1 else 0 end) as number_of_documentary_movies
from public.film f
inner join public.film_category fc on f.film_id = fc.film_id
inner join public.category c on fc.category_id = c.category_id
group by f.release_year
order by f.release_year desc;

--T1-4-V2
-- SOLUTION 2: SUBQUERY 
/* - First create a flat list of movies and their genres, then aggregate outside.
- Higher resource usage  due to the intermediate result set (derived table).
- Slower than Solution 1 on very large datasets.
- Good for separating the "joining" and "counting" steps.
- Harder to write it so don't like this subquery solution
*/
select 
    sub.release_year,
    sum(sub.is_drama) as number_of_drama_movies,
    sum(sub.is_travel) as number_of_travel_movies,
    sum(sub.is_doc) as number_of_documentary_movies
from (
    select 
        f.release_year,
        case when c.name = 'drama' then 1 else 0 end as is_drama,
        case when c.name = 'travel' then 1 else 0 end as is_travel,
        case when c.name = 'documentary' then 1 else 0 end as is_doc
    from public.film f
    inner join public.film_category fc on f.film_id = fc.film_id
    inner join public.category c on fc.category_id = c.category_id
) as sub
group by sub.release_year
order by sub.release_year desc;

--T1-4-V3
-- SOLUTION 3: CTE (Common Table Expression)
/* -Step-by-step logic: 1. Get raw data, 2. Aggregate and format.
- The CTE acts as a clean data source for the final report.
- Production choice: I would use Solution 1 (INNER JOIN) for simple reports, but this CTE version is better 
  if we need to add more complex logic (like filtering by movie length or rating) later.
 - Basicaly create extra data table
*/
with yearly_genre_data as (
    select 
        f.release_year, 
        c.name as genre_name
    from public.film f
    inner join public.film_category fc on f.film_id = fc.film_id
    inner join public.category c on fc.category_id = c.category_id
    where c.name in ('Drama', 'Travel', 'Documentary') 
)
select 
    release_year,
    sum(case when genre_name = 'Drama' then 1 else 0 end) as number_of_drama_movies,
    sum(case when genre_name = 'Travel' then 1 else 0 end) as number_of_travel_movies,
    sum(case when genre_name = 'Documentary' then 1 else 0 end) as number_of_documentary_movies
from yearly_genre_data
group by release_year
order by release_year desc;

--T2-1-V1
/* Assumptions & logic interpretation:
1. the goal is to identify the top 3 staff members based on the total revenue they processed in 2017.
2. revenue calculation: it is derived from the sum of the 'amount' column in the public.payment table.
3. time filtering: only payments where the 'payment_date' falls between 2017-01-01 and 2017-12-31 are considered.
4. last store location: following the requirement to show the "last" store, we join the staff's currently 
   assigned store_id to the address table. as per the task assumption, if a staff member processed a payment, 
   they are considered to be working in that specific store at that time.
5. naming: first_name and last_name are concatenated to provide a professional full name format. || ' ' || coalesce function usage.
6. sorting & limit: results are ordered by total revenue in descending order, limited to the top 3 individuals.
*/
/* Task: Top 5 staff members by revenue in 2017 with their current store address.
- JOIN type: INNER JOIN.
- Logic: Connects staff to payments (for revenue) and staff to store/address (for location).
- Grouping: Must group by staff name and address to comply
*/
--linear solution
select 
    s.first_name || ' ' || s.last_name as staff_name,
    sum(p.amount) as total_revenue,
    a.address || ' ' || coalesce(a.address2, '') as last_store_address
from public.staff s
inner join public.payment p on s.staff_id = p.staff_id
inner join public.store st on s.store_id = st.store_id
inner join public.address a on st.address_id = a.address_id
where p.payment_date between '2017-01-01' and '2017-12-31'
group by s.first_name, s.last_name, a.address, a.address2
order by total_revenue desc
limit 3;

--T2-1-V2
/* Task: Top 5 staff 2017.
- Logic: Step 1 (CTE): Calculate 2017 revenue. Step 2: Join with staff and address details.
- Production choice: I would use this in production for clarity and easier debugging of the 2017 filter. easy to add another common table
*/
with staff_revenue_2017 as (
    select 
        staff_id, 
        sum(amount) as yearly_amount
    from public.payment
    where payment_date between '2017-01-01' and '2017-12-31'
    group by staff_id
)
select 
    s.first_name || ' ' || s.last_name as staff_name,
    sr.yearly_amount as total_revenue,
    addr.address || ' ' || coalesce(addr.address2, '') as last_store_address
from staff_revenue_2017 sr
inner join public.staff s on sr.staff_id = s.staff_id
inner join public.store st on s.store_id = st.store_id
inner join public.address addr on st.address_id = addr.address_id
order by total_revenue desc
limit 3;

--T2-1-V3
--It could be too complex with subquery

--T2-2-V1
/* ASSUMPTIONS & LOGIC INTERPRETATION:
1. "Most popular" is measured by the total count of rentals (from the public.rental table).
2. The relationship is: film -> inventory -> rental.
3. To determine the expected age, I am mapping the MPAA ratings (G, PG, PG-13, R, NC-17) 
   to specific age groups using a CASE statement.
4. If a movie has no rentals, it will not appear in the top list (INNER JOIN behavior).
5. As per Rule 6, all columns in GROUP BY are listed by name.
*/
----------------------------------------------------------------------------------------------------
-- TASK 2: Show which 5 movies were rented more than others, and what's the expected age of the audience?
-- Columns: title, rental_count, expected_audience_age.
----------------------------------------------------------------------------------------------------
-- SOLUTION 1: INNER JOIN
/* - JOIN type: INNER JOIN across film, inventory, and rental tables.
- Direct path to count rentals per film title.
- Standard aggregation.
- Most direct execution for a top-N analysis.
- The CASE statement is integrated directly into the main SELECT.
*/
select 
    f.title, 
    count(r.rental_id) as rental_count,
    case 
        when f.rating = 'G' then 'all ages'
        when f.rating = 'PG' then '8+'
        when f.rating = 'PG-13' then '13+'
        when f.rating = 'R' then '17+'
        when f.rating = 'NC-17' then '18+'
        else 'unknown'
    end as expected_audience_age
from public.film f
inner join public.inventory i on f.film_id = i.film_id
inner join public.rental r on i.inventory_id = r.inventory_id
group by f.title, f.rating
order by rental_count desc
limit 5;

--T2-2-V2
-- Readability: Moderate. Separates the raw counting from the "human-readable" rating translation.
----I could not find working solution with subquery

--T2-2-V3
-- SOLUTION 3: CTE (Common Table Expression)
/* - Breaks the task into logical steps.
- Defines 'MovieStats' first, then applies the business logic (age mapping).
- Production choice: I would use this in production. It makes it very easy to update the age 
  definitions or add new marketing filters without rewriting the core rental count logic.
*/
with movie_stats as (
    select 
        f.title, 
        f.rating, 
        count(r.rental_id) as rental_count
    from public.film f
    inner join public.inventory i on f.film_id = i.film_id
    inner join public.rental r on i.inventory_id = r.inventory_id
    group by f.title, f.rating)
select 
    title,
    rental_count,
    case 
        when rating = 'G' then 'all ages'
        when rating = 'PG' then '8+'
        when rating = 'PG-13' then '13+'
        when rating = 'R' then '17+'
        when rating = 'NC-17' then '18+'
        else 'unknown'
    end as expected_audience_age
from movie_stats
order by rental_count desc
limit 5;

--T3-1-V1
/* ASSUMPTIONS:
1. "Inactivity period" (V1) is defined as the number of years since the actor's last movie release.
2. Current year is 2026.
3. Relationship: actor -> film_actor -> film.
*/
-- TASK: V1: Gap between the latest release_year and current year (2026) per each actor.
-- SOLUTION 1: INNER JOIN
/* - Join all 3 tables, find the MAX release_year per actor, and subtract it from 2026.
- Direct aggregation.
- Easy to understand the logic, fast solution and I prefer this.
*/
select 
    a.first_name, 
    a.last_name, 
    (2026 - max(f.release_year)) as years_since_last_movie
from public.actor a
inner join public.film_actor fa on a.actor_id = fa.actor_id
inner join public.film f on fa.film_id = f.film_id
group by a.first_name, a.last_name
order by years_since_last_movie desc;

--T3-1-V2
-- SOLUTION 2: SUBQUERY
/* - The subquery calculates the latest release_year for each actor_id.
-Isolates the timestamp logic before joining names.
*/
select 
    act.first_name, 
    act.last_name, 
    (2026 - latest.last_year) as years_since_last_movie
from public.actor act
inner join (
    select actor_id, max(release_year) as last_year
    from public.film_actor fa
    inner join public.film f on fa.film_id = f.film_id
    group by actor_id
) as latest on act.actor_id = latest.actor_id
order by years_since_last_movie desc;

--T3-1-V3
-- SOLUTION 3: CTE
/* - Creates a clean 'LatestReleases' table first.
- modularizes the calculation of the most recent year, making the query easier to maintain.
*/
with latest_releases as (
    select fa.actor_id, max(f.release_year) as max_year
    from public.film_actor fa
    inner join public.film f on fa.film_id = f.film_id
    group by fa.actor_id)
select 
    a.first_name, 
    a.last_name, 
    (2026 - lr.max_year) as years_since_last_movie
from public.actor a
inner join latest_releases lr on a.actor_id = lr.actor_id
order by years_since_last_movie desc;

--T3-2-V1
/* ASSUMPTIONS:
1. goal: find the longest year gap between any two films for each actor using a cte.
2. cte (actor_filmography): this creates a simplified temporary table that maps each 
   actor_id to their movie release years, making the subsequent joins much cleaner.
3.T he cte to itself twice (f_earlier and f_later) to compare 
   every movie in an actor's history against every other movie they made.
4. chronological filter: the 'where' clause ensures we only calculate differences 
   where the second movie was released after the first one.
5. Eextract the 'max' difference for each actor to identify their 
   most significant career hiatus
*/
--TASK: V2: Maximum gap between sequential films per each actor.
/* - Join the film list with itself to find the "next" movie for every movie.
- Join Type: INNER JOIN on actor_id.
-two type of film searching
-not easy to read because of fa1 and fa2
*/
select 
    a.first_name, 
    a.last_name, 
    max(f2.release_year - f1.release_year) as max_career_break
from public.actor a
inner join public.film_actor fa1 on a.actor_id = fa1.actor_id
inner join public.film f1 on fa1.film_id = f1.film_id
inner join public.film_actor fa2 on a.actor_id = fa2.actor_id
inner join public.film f2 on fa2.film_id = f2.film_id
where f2.release_year > f1.release_year
group by a.first_name, a.last_name
order by max_career_break desc;

--T3-2-V1
-- SOLUTION 2: SUBQUERY
/* - Logic: Pre-calculates actor film years in a subquery to reduce complexity in the main join.
*/
select 
    act.first_name, 
    act.last_name, 
    max(years.next_year - years.current_year) as max_break
from public.actor act
inner join (
    select f1.actor_id, f1.release_year as current_year, f2.release_year as next_year
    from (
        select fa.actor_id, f.release_year 
        from public.film_actor fa 
        join public.film f on fa.film_id = f.film_id
    ) f1
    join (
        select fa.actor_id, f.release_year 
        from public.film_actor fa 
        join public.film f on fa.film_id = f.film_id
    ) f2 
    on f1.actor_id = f2.actor_id and f2.release_year > f1.release_year
) as years on act.actor_id = years.actor_id
group by act.first_name, act.last_name
order by max_break desc;

--T3-3-V1
-- SOLUTION 3: CTE
/* -Separates the filmography into a CTE, then performs the gap analysis.
- Better for such a complex self-comparison.
*/
with actor_filmography as (
    select fa.actor_id, f.release_year
    from public.film_actor fa
    inner join public.film f on fa.film_id = f.film_id)
select 
    a.first_name, 
    a.last_name, 
    max(f_later.release_year - f_earlier.release_year) as longest_break
from public.actor a
inner join actor_filmography f_earlier on a.actor_id = f_earlier.actor_id
inner join actor_filmography f_later on a.actor_id = f_later.actor_id
where f_later.release_year > f_earlier.release_year
group by a.first_name, a.last_name
order by longest_break desc;