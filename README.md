# Db_Hw_car_sharing_service

Table users {
  id int [pk, increment]
  first_name varchar(50) [not null]
  last_name varchar(50) [not null]
  birth_date date
  personal_id varchar (32) [unique]
  email varchar(100) [not null, unique]
}

Table vehicle_types {
  id int [pk, increment]
  manufacturer varchar(50) [not null]
  model varchar(50) [not null]
  car_type varchar(50) [not null]
  drive_type varchar(10) [not null]
  engine_size numeric(10,1)
  average_consumption numeric(6,2)
  base_fee numeric(10,2)
}

Table vehicles {
  id int [pk, increment]
  vehicle_type_id int [not null]
  license_plate char(8) [not null, unique]
  production_year smallint
 
}

Table employees {
  id int [pk, increment]
  first_name varchar(50) [not null]
  last_name varchar(50) [not null]
  birth_date date
  personal_id varchar(32) [unique]
  hired_year smallint
  role varchar(50) [not null] 
  email varchar(100) [not null, unique]
}

Table reservations {
  id int [pk, increment]
  user_id integer [not null]
  vehicle_id integer [not null]
  start_date timestamp
  end_date timestamp
  
}

Table trips {
  id int [pk, increment]
  reservation_id integer [not null]
  applied_rate_card_id integer [not null]
  start_date timestamp [not null]
  end_date timestamp 
  distance numeric(10,3)
}

Table payments {
  id int [pk, increment]
  reservation_id int [not null]
  employee_id int 
  type varchar(50)
  status varchar(20)
  currency char(3) [not null, default: 'EUR']
  amount numeric (10,2) [not null] 
  created_at timestamp [not null]
  paid_at timestamp 
}

Table ratings {
  id int [pk, increment]
  employee_id int 
  reservation_id integer [not null]
  rating_value int [not null] //1..5
  comment varchar(200)
}

Table service_order {
  id int [pk, increment]
  employee_id int [not null]
  vehicle_id int [not null]
  opened_at timestamp [not null]
  closed_at timestamp 
  type varchar(50) [not null]
  summary varchar(200)
}

Table service_order_employees{
  id int [pk, increment]
  service_order_id int [not null]
  employee_id int [not null]
  role_in_order  varchar(50)
}

Table inspections {
  id int [pk, increment]
  service_order_id int [not null]
  employee_id int [not null]
  performed_at timestamp [not null]
  result varchar(50)  [not null]
  summary varchar(200)
}


Table rate_cards {
  id int [pk, increment]
  vehicle_type_id int [not null]
  valid_from timestamp [not null]
  valid_to timestamp
  price_per_minute numeric(10,2) [not null]
  fuel_price numeric(10,2) [not null]
}

Table vehicle_status_history {
  id int [pk, increment]
  vehicle_id int
  status varchar (30) [not null]
  valid_from timestamp [not null]
  valid_to timestamp
  reason varchar(50)
}


Table vehicle_assignment_history {
  id int [pk, increment]
  vehicle_id int [not null]
  employee_id int [not null]
  valid_from timestamp [not null]
  valid_to timestamp
  comment varchar(100)
}





Ref: vehicles.vehicle_type_id > vehicle_types.id


Ref: reservations.user_id    > users.id
Ref: reservations.vehicle_id > vehicles.id

Ref: trips.reservation_id       > reservations.id
Ref: trips.applied_rate_card_id > rate_cards.id


Ref: rate_cards.vehicle_type_id > vehicle_types.id


Ref: payments.reservation_id > reservations.id
Ref: payments.employee_id    > employees.id


Ref: ratings.reservation_id > reservations.id
Ref: ratings.employee_id    > employees.id


Ref: service_order.vehicle_id > vehicles.id
Ref: service_order.employee_id > employees.id          


Ref: service_order_employees.service_order_id > service_order.id
Ref: service_order_employees.employee_id      > employees.id


Ref: inspections.service_order_id > service_order.id
Ref: inspections.employee_id      > employees.id


Ref: vehicle_status_history.vehicle_id      > vehicles.id
Ref: vehicle_assignment_history.vehicle_id  > vehicles.id
Ref: vehicle_assignment_history.employee_id > employees.id




