/*Choose your real top-3 favorite movies (released in different years, belong to different genres)
and add them to the 'film' table (films with the title Film1, Film2, etc - 
will not be taken into account and grade will be reduced by 20%)*/
/*1. General Justification for INSERT tasks

Data Uniqueness: I used the WHERE NOT EXISTS clause to check for the natural keys (e.g., film title, actor name, or unique rental timestamp).
 This ensures the script is rerunnable and does not produce duplicates.

Establishing Relationships: Instead of hardcoding IDs, I used subqueries (SELECT ID FROM ...) to dynamically fetch foreign keys.
 This ensures referential integrity even if the IDs differ across different database environments.

Advantage of INSERT INTO ... SELECT: This method allows for conditional logic (the WHERE clause), which is not possible with a standard VALUES constructor.
 It makes the script "smarter" and safer for repeated execution.*/

/*Justification for Transactions

Why separate transactions: Each logical step is wrapped in a transaction to ensure Atomicity.
This means either all parts of the step (e.g., creating a rental AND its payment) succeed together, or nothing changes.
Failure & Rollback: If a transaction fails (e.g., due to a constraint violation),
the database automatically prevents any partial data from being saved.
A ROLLBACK is possible and would revert the database to the state it was in before the BEGIN command,
ensuring no corrupted or orphaned data remains.
Referential Integrity: Transactions ensure that child records (like film_actor) are only created
if the parent records (film and actor) are successfully identified or created.*/


-- I use insert into ...select.. because with this I could check that does this film exist or not.
begin;
insert into public.film (title, release_year, language_id, rental_duration, rental_rate, last_update )--it is possible to filter
select
	'forrest gump',
	'1994',
	(select language_id from public.language where lower(name) = 'english'), --dinamic_ID, ensure the right foreign key
	7,
	4.99,
	current_date 
where not exists (
	select 1 from public.film where lower(title) = 'forrest gump'
	) --it is ensure not dupolicate, data uniqness
returning film_id;
commit;

--second film
begin;
insert into public.film (title, release_year, language_id, rental_duration, rental_rate, last_update )--it is possible to filter
select
	'downfall',
	'2004',
	(select language_id from public.language where lower(name) = 'german'), --dinamic_ID, ensure the right foreign key
	14,
	9.99,
	current_date 
where not exists (
	select 1 from public.film where lower(title) = 'downfall'
	) --it is ensure not dupolicate, data uniqness
returning film_id;
commit;

--third film
begin;
insert into public.film (title, release_year, language_id, rental_duration, rental_rate, last_update )--it is possible to filter
select
	'james bond casino royale',
	'2006',
	(select language_id from public.language where lower(name) = 'english'), --dinamic_ID, ensure the right foreign key
	21,
	19.99,
	current_date 
where not exists (
	select 1 from public.film where lower(title) = 'james bond casino royale'
	) --it is ensure not dupolicate, data uniqness
returning film_id;
commit;



/*Add the real actors who play leading roles in your favorite movies to the 'actor' and 'film_actor' tables (6 or more actors in total).
 *   Actors with the name Actor1, Actor2, etc - will not be taken into account and grade will be reduced by 20%.
 *  You must decide how to identify actors that already exist in the system and how to avoid duplicates */
begin;
insert into public.actor (first_name , last_name, last_update)
select 
	'tom',
	'hanks',
	current_date
where not exists (
	select 1
	from public.actor 
	where lower(first_name) = 'tom' and lower(last_name) = 'hanks')
returning actor_id;	
commit;

begin; --if the transaction fail between begin and commit all the modification will be unvalid
insert into public.film_actor(actor_id, film_id, last_update)
select 
(select actor_id from public.actor where first_name = 'tom' and last_name = 'hanks'), --reference ID search, dinamic mode
(select film_id from public.film where film.title = 'forrest gump'), --reference ID search, integrity
current_date 
where not exists (   --data uniqness
	select 1
	from public.film_actor
	where actor_id = (select actor_id from public.actor where first_name = 'tom' and last_name = 'hanks')
		and film_id = (select film_id from public.film where film.title = 'forrest gump')
		)
returning*;
commit;


--second actress
begin;
insert into public.actor (first_name , last_name, last_update)
select 
	'robin',
	'wright',
	current_date
where not exists (
	select 1
	from public.actor 
	where lower(first_name) = 'robin' and lower(last_name) = 'wright')
returning actor_id;	
commit;

begin; --if the transaction fail between begin and commit all the modification will be unvalid
insert into public.film_actor(actor_id, film_id, last_update)
select 
(select actor_id from public.actor where first_name = 'robin' and last_name = 'wright'), --reference ID search, dinamic mode
(select film_id from public.film where film.title = 'forrest gump'), --reference ID search, integrity
current_date 
where not exists (   --data uniqness
	select 1
	from public.film_actor
	where actor_id = (select actor_id from public.actor where first_name = 'robin' and last_name = 'wright')
		and film_id = (select film_id from public.film where film.title = 'forrest gump')
		)
returning*;
commit;

--third actor
begin;
insert into public.actor (first_name , last_name, last_update)
select 
	'bruno',
	'ganz',
	current_date
where not exists (
	select 1
	from public.actor 
	where lower(first_name) = 'bruno' and lower(last_name) = 'ganz')
returning actor_id;	
commit;

begin; --if the transaction fail between begin and commit all the modification will be unvalid
insert into public.film_actor(actor_id, film_id, last_update)
select 
(select actor_id from public.actor where first_name = 'bruno' and last_name = 'ganz'), --reference ID search, dinamic mode
(select film_id from public.film where film.title = 'downfall'), --reference ID search, integrity
current_date 
where not exists (   --data uniqness
	select 1
	from public.film_actor
	where actor_id = (select actor_id from public.actor where first_name = 'bruno' and last_name = 'ganz')
		and film_id = (select film_id from public.film where film.title = 'downfall')
		)
returning*;
commit;

--fourth actor
begin;
insert into public.actor (first_name , last_name, last_update)
select 
	'ulrich',
	'matthes',
	current_date
where not exists (
	select 1
	from public.actor 
	where lower(first_name) = 'ulrich' and lower(last_name) = 'matthes')
returning actor_id;	
commit;

begin; --if the transaction fail between begin and commit all the modification will be unvalid
insert into public.film_actor(actor_id, film_id, last_update)
select 
(select actor_id from public.actor where first_name = 'ulrich' and last_name = 'matthes'), --reference ID search, dinamic mode
(select film_id from public.film where film.title = 'downfall'), --reference ID search, integrity
current_date 
where not exists (   --data uniqness
	select 1
	from public.film_actor
	where actor_id = (select actor_id from public.actor where first_name = 'ulrich' and last_name = 'matthes')
		and film_id = (select film_id from public.film where film.title = 'downfall')
		)
returning*;
commit;

--fifth actor
begin;
insert into public.actor (first_name , last_name, last_update)
select 
	'daniel',
	'craig',
	current_date
where not exists (
	select 1
	from public.actor 
	where lower(first_name) = 'daniel' and lower(last_name) = 'craig')
returning actor_id;	
commit;

begin; --if the transaction fail between begin and commit all the modification will be unvalid
insert into public.film_actor(actor_id, film_id, last_update)
select 
(select actor_id from public.actor where first_name = 'daniel' and last_name = 'craig'), --reference ID search, dinamic mode
(select film_id from public.film where film.title = 'james bond casino royale'), --reference ID search, integrity
current_date 
where not exists (   --data uniqness
	select 1
	from public.film_actor
	where actor_id = (select actor_id from public.actor where first_name = 'daniel' and last_name = 'craig')
		and film_id = (select film_id from public.film where film.title = 'james bond casino royale')
		)
returning*;
commit;

--sixth actress
begin;
insert into public.actor (first_name , last_name, last_update)
select 
	'eva',
	'green',
	current_date
where not exists (
	select 1
	from public.actor 
	where lower(first_name) = 'eva' and lower(last_name) = 'green')
returning actor_id;	
commit;

begin; --if the transaction fail between begin and commit all the modification will be unvalid
insert into public.film_actor(actor_id, film_id, last_update)
select 
(select actor_id from public.actor where first_name = 'eva' and last_name = 'green'), --reference ID search, dinamic mode
(select film_id from public.film where film.title = 'james bond casino royale'), --reference ID search, integrity
current_date 
where not exists (   --data uniqness
	select 1
	from public.film_actor
	where actor_id = (select actor_id from public.actor where first_name = 'eva' and last_name = 'green')
		and film_id = (select film_id from public.film where film.title = 'james bond casino royale')
		)
returning*;
commit;

--check query
SELECT a.actor_id, a.first_name, a.last_name, fa.film_id 
FROM public.actor a
inner join film_actor fa on fa.actor_id = a.actor_id 
where a.actor_id  > 200;

/*Add your favorite movies to any store's inventory.
 *Film Selection: The movie is identified using the lower() function on the title 
to ensure we retrieve the correct, unique ID regardless of letter casing.
 *Store Selection: Following the instructions to use "any store," 
the script dynamically selects the first available store_id from the system.
 *Duplicate Protection: The WHERE NOT EXISTS clause ensures that a movie is only added to the inventory
if it is not already present in that specific store’s records.*/

--first movie
begin;
insert into public.inventory (film_id, store_id, last_update)
select
	(select film_id from public.film where lower(title) = 'forrest gump' limit 1),
	(select store_id from public.store limit 1),
	current_date 
where not exists ( --check that this film exist in this shop 
      select 1 from public.inventory
      where film_id = (select film_id from public.film where lower(title) = 'forrest gump' limit 1)
       and store_id =(select store_id from public.store limit 1)
      )
returning inventory_id;
commit;

--second movie
begin;
insert into public.inventory (film_id, store_id, last_update)
select
	(select film_id from public.film where lower(title) = 'downfall' limit 1),
	(select store_id from public.store limit 1),
	current_date 
where not exists ( --check that this film exist in this shop 
      select 1 from public.inventory
      where film_id = (select film_id from public.film where lower(title) = 'downfall' limit 1)
       and store_id =(select store_id from public.store limit 1)
      )
returning inventory_id;
commit;

--third movie
begin;
insert into public.inventory (film_id, store_id, last_update)
select
	(select film_id from public.film where lower(title) = 'james bond casino royale' limit 1),
	(select store_id from public.store limit 1),
	current_date 
where not exists ( --check that this film exist in this shop 
      select 1 from public.inventory
      where film_id = (select film_id from public.film where lower(title) = 'james bond casino royale' limit 1)
       and store_id =(select store_id from public.store limit 1)
      )
returning inventory_id;
commit;

--Check query inventory
select 
    f.film_id, 
    f.title, 
    f.rental_rate, 
    f.rental_duration,
    (select count(*) from public.inventory i where i.film_id = f.film_id) as inventory_count,
    string_agg(a.first_name || ' ' || a.last_name, ', ') as actors
from public.film f
left join public.film_actor fa on f.film_id = fa.film_id
left join public.actor a on fa.actor_id = a.actor_id
where lower(f.title) in ('forrest gump', 'downfall', 'james bond casino royale')
group by f.film_id, f.title, f.rental_rate, f.rental_duration;

/*Alter any existing customer in the database with at least 43 rental and 43 payment records.
 *Change their personal data to yours (first name, last name, address, etc.).
 *You can use any existing address from the "address" table.
 *Please do not perform any updates on the "address" table, as this can impact multiple records with the same address.*/
--first i will choose my ID
select 
    c.customer_id, 
    c.first_name, 
    c.last_name, 
    count(distinct r.rental_id) as rental_count, 
    count(distinct p.payment_id) as payment_count
from public.customer c
join public.rental r on c.customer_id = r.customer_id
join public.payment p on c.customer_id = p.customer_id
group by c.customer_id, c.first_name, c.last_name
having count(distinct r.rental_id) >= 43 
   and count(distinct p.payment_id) >= 43
order by rental_count desc
limit 10;

--my customer_id will be TAMMY SANDERS with 75 customer id
--address_id query 79 so I will change example address 10
select address_id
from public.customer 
where customer_id = 75;
select customer_id
from public.customer
where address_id = 10;
--update part
begin;
update public.customer
set 
    first_name = 'tamas', -- my name
    last_name = 'jenei',   -- my name
    email = 'tamas.jenei967@gmail.com',
    address_id = 10,                   -- my choosen address ID
    last_update = current_date
where customer_id = 75;                -- Tammy Sanders original ID
commit;

/*Remove any records related to you (as a customer) from all tables except 'Customer' and 'Inventory'*/
--first I will delete the payment table data and then rental 
begin;
-- 1. payment delete
delete from public.payment
where customer_id = 75
returning *;
-- 2. rental delete
delete from public.rental
where customer_id = 75
returning *;
commit;
--checking my delete work
select * 
from public.payment
where customer_id = 75;
select * 
from public.rental
where customer_id = 75
/*--Why deleting is safe: Deleting from payment and rental is safe because these are child tables of customer. 
 * By filtering strictly for customer_id = 75, we only remove the history of the modified customer without affecting other users.
--Referential Integrity: The deletion order follows the hierarchy: first we remove the payments, then the rentals.
This prevents "Foreign Key constraint" errors.*/


/*Last part of the task:
 * Rent you favorite movies from the store they are in and pay for them
 * (add corresponding records to the database to represent this activity)
(Note: to insert the payment_date into the table payment, you can create a new partition
(see the scripts to install the training database ) or add records for the first half of 2017)
 */
begin;
--first I record the rental 
insert into public.rental (rental_date, inventory_id, customer_id, return_date, staff_id, last_update )
select
   '2017-03-30 10:00:00', --first half of 2017
   (select inventory_id from public.inventory 
   where film_id = (select film_id
                          from public.film 
                          where lower(title)= 'forrest gump' limit 1 )
   limit 1),
   75, --customer_id
   --dinamic redemption date
   '2017-03-30 10:00:00'::timestamp + (select rental_duration * interval '1 day' from public.film where lower(title) = 'forrest gump' limit 1), -- rental date day
   (select staff_id 
      from public.staff limit 1), --dinamikus staff_id
   current_date 
 where not exists ( --Recurrence: we do not rent the same inventory at the same time
    select 1 from public.rental 
    where customer_id =75 and rental_date = '2017-03-30 10:00:00'::timestamp )
  returning rental_id;
--Second I record the payment
--create connect with the rental
insert into public.payment (customer_id, staff_id, rental_id, amount, payment_date)
select 
    75, 
    (select staff_id from public.staff limit 1),
    -- search the rental id
    (select rental_id from public.rental 
     where customer_id = 75 and rental_date = '2017-03-30 10:00:00'::timestamp limit 1),
    -- dynamic price base on film title
    (select rental_rate from public.film where lower(title) = 'forrest gump' limit 1),
    -- payment date is the same as the rental
    '2017-03-30 10:00:00'::timestamp
where not exists (
    select 1 from public.payment
    where rental_id = (select rental_id from public.rental 
                       where customer_id = 75 and rental_date = '2017-03-30 10:00:00'::timestamp limit 1)
)
returning *;
 commit;


--Second film
begin;
--first I record the rental 
insert into public.rental (rental_date, inventory_id, customer_id, return_date, staff_id, last_update )
select
   '2017-03-30 10:15:00', --first half of 2017
   (select inventory_id from public.inventory 
   where film_id = (select film_id
                          from public.film 
                          where lower(title)= 'downfall' limit 1 )
   limit 1),
   75, --customer_id
   --dinamic redemption date
   '2017-03-30 10:15:00'::timestamp + (select rental_duration * interval '1 day' from public.film where lower(title) = 'downfall' limit 1), -- rental date day
   (select staff_id 
      from public.staff limit 1), --dinamikus staff_id
   current_date 
 where not exists ( --Recurrence: we do not rent the same inventory at the same time
    select 1 from public.rental 
    where customer_id =75 and rental_date = '2017-03-30 10:15:00'::timestamp )
  returning rental_id;
--Second I record the payment
--create connect with the rental
insert into public.payment (customer_id, staff_id, rental_id, amount, payment_date)
select 
    75, 
    (select staff_id from public.staff limit 1),
    -- search the rental id
    (select rental_id from public.rental 
     where customer_id = 75 and rental_date = '2017-03-30 10:15:00'::timestamp limit 1),
    -- dynamic price base on film title
    (select rental_rate from public.film where lower(title) = 'downfall' limit 1),
    -- payment date is the same as the rental
    '2017-03-30 10:15:00'::timestamp
where not exists (
    select 1 from public.payment
    where rental_id = (select rental_id from public.rental 
                       where customer_id = 75 and rental_date = '2017-03-30 10:15:00'::timestamp limit 1)
)
returning *;
 commit;

--Third film
begin;
--first I record the rental 
insert into public.rental (rental_date, inventory_id, customer_id, return_date, staff_id, last_update )
select
   '2017-03-30 10:10:00', --first half of 2017
   (select inventory_id from public.inventory 
   where film_id = (select film_id
                          from public.film 
                          where lower(title)= 'james bond casino royale' limit 1 )
   limit 1),
   75, --customer_id
   --dinamic redemption date
   '2017-03-30 10:10:00'::timestamp + (select rental_duration * interval '1 day' from public.film where lower(title) = 'james bond casino royale' limit 1), -- rental date day
   (select staff_id 
      from public.staff limit 1), --dinamikus staff_id
   current_date 
 where not exists ( --Recurrence: we do not rent the same inventory at the same time
    select 1 from public.rental 
    where customer_id =75 and rental_date = '2017-03-30 10:10:00'::timestamp )
  returning rental_id;
--Second I record the payment
--create connect with the rental
insert into public.payment (customer_id, staff_id, rental_id, amount, payment_date)
select 
    75, 
    (select staff_id from public.staff limit 1),
    -- search the rental id
    (select rental_id from public.rental 
     where customer_id = 75 and rental_date = '2017-03-30 10:10:00'::timestamp limit 1),
    -- dynamic price base on film title
    (select rental_rate from public.film where lower(title) = 'james bond casino royale' limit 1),
    -- payment date is the same as the rental
    '2017-03-30 10:10:00'::timestamp
where not exists (
    select 1 from public.payment
    where rental_id = (select rental_id from public.rental 
                       where customer_id = 75 and rental_date = '2017-03-30 10:10:00'::timestamp limit 1)
)
returning *;
 commit;



--checking query
select c.first_name, c.last_name, f.title, r.rental_date, r.return_date , p.amount, p.payment_date 
from public.customer c
join public.rental r on c.customer_id = r.customer_id
join public.inventory i on r.inventory_id = i.inventory_id
join public.film f on i.film_id = f.film_id
join public.payment p on r.rental_id = p.rental_id
where c.customer_id = 75;





