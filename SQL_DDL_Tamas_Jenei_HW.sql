create database car_sharing;
create schema if not EXIST car_sharing_data;--create schema 
set search path to car_sharing_data; --default searching folder, so don't have to write all the time set this, instead of public.

/* create the table first the "parents" table which are not direct to FK
 * then the children to be sure that all table exist what we refering

 */


CREATE TABLE IF NOT EXISTS Persons (
person_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    birth_date DATE,
    -- CHECK 1: Date limit (> 2000-01-01)
    -- avoid to old and irrelevant data in the database
    -- CONSTRAINT: NOT NULL - Ensures we don't have anonymous profiles.
    created_at DATE DEFAULT CURRENT_DATE CHECK (created_at > '2000-01-01'),
    personal_id VARCHAR(32) NOT NULL UNIQUE, -- Unique constraint to avoid duplicate
    email VARCHAR(100) NOT NULL UNIQUE
    );

-- Parents 2: vehicle_types
CREATE TABLE IF NOT EXISTS Vehicle_types (
    vehicle_type_id SERIAL PRIMARY KEY,
    manufacturer VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    car_type VARCHAR(50) NOT NULL,
    -- CONSTRAINT 3: SPECIFIC VALUE
    -- to avoid false data value (example 'XYZ-hajtás') insert
    drive_type VARCHAR(10) NOT NULL CHECK (drive_type IN ('diesel', 'gasoline', 'electric', 'other')),
    engine_size NUMERIC(10,1) NOT NULL,
    -- CONSTRAINT 2: not negativ value
    -- to avoid negativ consumption.
    average_consumption NUMERIC(6,2) NOT NULL CHECK (average_consumption >= 0),
    base_fee NUMERIC(10,2) NOT NULL
);

-- Children (Persons-ra and Vehicle_types reference)
-- We could delete a Person while their User account remains, leading to database corruption.
--IF FK is missing cause Referential Integrity lose
CREATE TABLE IF NOT EXISTS Users (
    user_id SERIAL PRIMARY KEY,
-- RISK OF LACK OF FK: If we omit REFERENCES, user_id could point
-- to a person_id that does not exist. This leads to data inconsistency (orphaned records).
    person_id INT NOT NULL REFERENCES Persons(person_id)
);

CREATE TABLE IF NOT EXISTS Employees (
    employee_id SERIAL PRIMARY KEY,
    person_id INT NOT NULL REFERENCES Persons(person_id),
    hired_year SMALLINT,
    role VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS Vehicles (
    vehicle_id SERIAL PRIMARY KEY,
    vehicle_type_id INT NOT NULL REFERENCES Vehicle_types(vehicle_type_id),
    license_plate VARCHAR(15) UNIQUE NOT NULL,
    production_year SMALLINT NOT NULL
);

CREATE TABLE IF NOT EXISTS Rate_cards (
    rate_card_id SERIAL PRIMARY KEY,
    vehicle_type_id INT NOT NULL REFERENCES Vehicle_types(vehicle_type_id),
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP CHECK (valid_to IS NULL OR valid_to > valid_from),
    price_per_minute NUMERIC(10,2) NOT NULL,
    fuel_price NUMERIC(10,2) NOT NULL
);

-- next level
CREATE TABLE IF NOT EXISTS Reservations (
    reservation_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES Users(user_id),
    vehicle_id INT NOT NULL REFERENCES Vehicles(vehicle_id),
    -- CONSTRAINT 1: Date > 2000-01-01
    -- Ensure the reservation could not exist before the company.
    res_start_date TIMESTAMP NOT NULL CHECK (res_start_date > '2000-01-01 00:00:00'),
    res_end_date TIMESTAMP CHECK (res_end_date IS NULL OR res_end_date > res_start_date)
);

CREATE TABLE IF NOT EXISTS Trips (
    trip_id SERIAL PRIMARY KEY,
    reservation_id INT NOT NULL REFERENCES Reservations(reservation_id),
    applied_rate_card_id INT NOT NULL REFERENCES Rate_cards(rate_card_id),
    trips_start_date TIMESTAMP NOT NULL,
    trips_end_date TIMESTAMP CHECK (trips_end_date IS NULL OR trips_end_date > trips_start_date),
    distance NUMERIC(10,3)
);

CREATE TABLE IF NOT EXISTS Payments (
    payment_id SERIAL PRIMARY KEY,
    reservation_id INT NOT NULL REFERENCES Reservations(reservation_id),
    employee_id INT REFERENCES Employees(employee_id),
    type VARCHAR(50),
    status VARCHAR(20),
    currency CHAR(3) NOT NULL DEFAULT 'EUR',
    amount NUMERIC(10,2) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    paid_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS Ratings (
    rating_id SERIAL PRIMARY KEY,
    reservation_id INT NOT NULL REFERENCES Reservations(reservation_id),
    employee_id INT REFERENCES Employees(employee_id),
    rating_value INT NOT NULL CHECK (rating_value BETWEEN 1 AND 5), -- CONSTRAINT: Value between 1-5. Prevents invalid user feedback.
    comment VARCHAR(200)
);

CREATE TABLE IF NOT EXISTS Service_orders (
    service_order_id SERIAL PRIMARY KEY,
    employee_id INT NOT NULL REFERENCES Employees(employee_id),
    vehicle_id INT NOT NULL REFERENCES Vehicles(vehicle_id),
    opened_at TIMESTAMP NOT NULL,
    closed_at TIMESTAMP CHECK (closed_at IS NULL OR closed_at > opened_at),
    type VARCHAR(50) NOT NULL,
    summary VARCHAR(200)
);

CREATE TABLE IF NOT EXISTS Service_order_employees (
    service_order_employee_id SERIAL PRIMARY KEY,
    service_order_id INT NOT NULL REFERENCES Service_orders(service_order_id),
    employee_id INT NOT NULL REFERENCES Employees(employee_id),
    role_in_order VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS Inspections (
    inspection_id SERIAL PRIMARY KEY,
    service_order_id INT NOT NULL REFERENCES Service_orders(service_order_id),
    employee_id INT NOT NULL REFERENCES Employees(employee_id),
    performed_at TIMESTAMP NOT NULL,
    result VARCHAR(50) NOT NULL,
    summary VARCHAR(200)
);

CREATE TABLE IF NOT EXISTS  Vehicle_status_history (
    status_history_id SERIAL PRIMARY KEY,
    vehicle_id INT NOT NULL REFERENCES Vehicles(vehicle_id),
    status VARCHAR(30) NOT NULL,
    vehicle_status_valid_from TIMESTAMP NOT NULL,
    vehicle_status_valid_to TIMESTAMP  NULL CHECK (vehicle_status_valid_to IS NULL OR vehicle_status_valid_to > vehicle_status_valid_from),
    -- NULL allowed here to represent the 'Current' active status.
    reason VARCHAR(50)
);


CREATE TABLE  IF NOT EXISTS Vehicle_assignment_history (
    assignment_id SERIAL PRIMARY KEY,
    vehicle_id INT NOT NULL REFERENCES Vehicles(vehicle_id),
    employee_id INT NOT NULL REFERENCES Employees(employee_id),
    vehicle_assignment_valid_from TIMESTAMP NOT NULL,
    vehicle_assignment_valid_to TIMESTAMP NULL CHECK (vehicle_assignment_valid_to IS NULL OR vehicle_assignment_valid_to > vehicle_assignment_valid_from),
    -- NULL allowed here to represent the 'Current' active status.
    comment VARCHAR(100)
);


COMMIT;


--data uploading process
--Duplicate prevention: ON CONFLICT DO NOTHING ensures the script is re-runnable.
--explicit id-s and subqueries to ensure data validity
INSERT INTO Persons (person_id, first_name, last_name, personal_id, birth_date, email)
VALUES 
(1, 'Laszlo', 'Kovacs', '356725KL', '1985-08-02', 'Laszlo.kovacs85@gmail.com'),
(2, 'Maria', 'Szabo', '457889', '1991-05-12', 'Maria.95.szabo@gmail.com'),
-- Complete to Employee 3, 4, 5, 6 
(3, 'Gabor', 'Toth', '112233AA', '1990-01-01', 'gabor.toth@support.com'),
(4, 'Eszter', 'Kiss', '445566BB', '1992-03-15', 'eszter.kiss@admin.com'),
(5, 'Peter', 'Nagy',  '998877MM', '1988-11-20', 'peter.nagy88@gmail.com'),
(6, 'Zsofia', 'Horvath', '112244ZZ', '1993-07-05', 'zsofia.horvath93@outlook.com')
ON CONFLICT (person_id) DO NOTHING;


INSERT INTO vehicle_types (vehicle_type_id, manufacturer, model, car_type, drive_type, engine_size, average_consumption, base_fee)
VALUES 
(1, 'Tesla', 'Model 3', 'Sedan', 'electric', 64.0, 14.5, 10.00), -- drive_type to fit CHECK constraint
(2, 'Volkswagen', 'Golf', 'Compact', 'diesel', 1.6, 5.5, 5.00)
ON CONFLICT (vehicle_type_id) DO NOTHING;

INSERT INTO users (user_id, person_id)
VALUES 
(1, 1),
(2, 2)
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO employees (employee_id, person_id, hired_year, role)
VALUES 
(1, 5, 2022, 'Mechanic'),
(2, 3, 2024, 'Customer Support'),
-- Addition to Payments and Ratings reference:
(3, 4, 2023, 'Finance'),
(4, 6, 2025, 'Supervisor')
ON CONFLICT (employee_id) DO NOTHING;


INSERT INTO vehicles (vehicle_id, vehicle_type_id, license_plate, production_year)
VALUES 
(1, 1, 'ABC-123', 2023),
(2, 1, 'XYZ-987', 2024),
-- Addition Vehicle Status Historys (id: 3):
(3, 2, 'DEF-456', 2022)
ON CONFLICT (vehicle_id) DO NOTHING;


-- 6. RATE_CARDS
INSERT INTO rate_cards (rate_card_id, vehicle_type_id, valid_from, valid_to, price_per_minute, fuel_price)
VALUES 
(1, 1, '2025-01-01 00:00:00', '2026-01-01 00:00:00', 0.50, 1.4),
(2, 1, '2026-01-01 00:00:00', NULL, 0.55, 1.4)
ON CONFLICT (rate_card_id) DO NOTHING;

-- 7. RESERVATIONS (Foglalások) [cite: 123]
INSERT INTO reservations (reservation_id, user_id, vehicle_id, res_start_date, res_end_date)
VALUES 
(501, 1, 1, '2025-02-11 10:00:00', '2025-02-17 10:00:00'),
(502, 2, 1, '2025-02-14 10:00:00', NULL)
ON CONFLICT (reservation_id) DO NOTHING;

-- 8. TRIPS (Utazások) [cite: 137]
INSERT INTO trips (trip_id, reservation_id, applied_rate_card_id, trips_start_date, trips_end_date, distance)
VALUES 
(9001, 501, 1, '2026-03-24 10:15:00', '2026-03-24 10:45:00', 10.550),
(9002, 501, 1, '2026-03-24 11:00:00', '2026-03-24 11:20:00', 5.200)
ON CONFLICT (trip_id) DO NOTHING;

-- 9. PAYMENTS 
INSERT INTO payments (payment_id, reservation_id, employee_id, type, status, currency, amount, created_at, paid_at)
VALUES 
(1001, 501, 3, 'Credit Card', 'Completed', 'EUR', 45.50, '2026-03-24 12:00:00', '2026-03-24 12:05:00'),
(1002, 502, 2, 'Digital Wallet', 'Pending', 'EUR', 12.00, '2026-03-24 14:30:00', NULL)
ON CONFLICT (payment_id) DO NOTHING;

-- 10. RATINGS
INSERT INTO ratings (rating_id, reservation_id, employee_id, rating_value, comment)
VALUES 
(1, 501, 4, 5, 'Excellent car, very clean!'),
(2, 502, 4, 3, 'Car was fine but windows were a bit dirty.')
ON CONFLICT (rating_id) DO NOTHING;


-- 11. SERVICE_ORDERS (Szerviz rendelések) [cite: 161]
INSERT INTO service_orders (service_order_id, employee_id, vehicle_id, opened_at, closed_at, type, summary)
VALUES 
(201, 1, 1, '2026-03-20 08:00:00', '2026-03-20 16:30:00', 'Oil Change', 'Regular 10,000 km maintenance'),
(202, 1, 2, '2026-03-22 10:00:00', NULL, 'Repair', 'Emergency tire replacement')
ON CONFLICT (service_order_id) DO NOTHING;


-- 12. SERVICE_ORDER_EMPLOYEES 
INSERT INTO service_order_employees (service_order_employee_id, service_order_id, employee_id, role_in_order)
VALUES 
(1, 201, 1, 'Mechanic'),
(2, 202, 1, 'Supervisor')
ON CONFLICT (service_order_employee_id) DO NOTHING;

-- 13. INSPECTIONS
INSERT INTO inspections (inspection_id, service_order_id, employee_id, performed_at, result, summary)
VALUES 
(3001, 201, 1, '2026-03-20 09:15:00', 'Pass', 'Engine oil level checked'),
(3002, 202, 1, '2026-03-22 11:30:00', 'Needs Repair', 'Left rear tire puncture')
ON CONFLICT (inspection_id) DO NOTHING;

-- 14. VEHICLE_STATUS_HISTORY 
INSERT INTO vehicle_status_history (status_history_id, vehicle_id, status, vehicle_status_valid_from, vehicle_status_valid_to, reason)
VALUES 
(10, 1, 'Maintenance', '2026-03-20 08:00:00', '2026-03-21 14:00:00', '10,000 km oil change'),
(11, 1, 'Available', '2026-03-21 14:00:00', NULL, 'Service completed'),
(12, 3, 'In Use', '2026-03-24 10:15:00', NULL, 'Active reservation')
ON CONFLICT (status_history_id) DO NOTHING;

--VEHICLE_ASSIGNMENT_HISTORIES 
INSERT INTO vehicle_assignment_history (assignment_id, vehicle_id, employee_id, vehicle_assignment_valid_from, vehicle_assignment_valid_to, comment)
VALUES 
(1, 1, 1, '2024-03-20 08:00:00', '2024-03-22 17:00:00', 'Routine maintenance transport.'),
(2, 2, 1, '2026-03-21 09:00:00', NULL, 'Ad-Hoc Service (Ongoing).')
ON CONFLICT (assignment_id) DO NOTHING;

COMMIT;

-- extra timestamp checking column for automated tracking
ALTER TABLE Persons ADD COLUMN record_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE Vehicle_types ADD COLUMN record_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE Users ADD COLUMN record_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE Employees ADD COLUMN record_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE Vehicles ADD COLUMN record_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE Rate_cards ADD COLUMN record_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE Reservations ADD COLUMN record_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE Trips ADD COLUMN record_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE Payments ADD COLUMN record_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE Ratings ADD COLUMN record_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE Service_orders ADD COLUMN record_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE Service_order_employees ADD COLUMN record_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE Inspections ADD COLUMN record_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE Vehicle_status_history ADD COLUMN record_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE Vehicle_assignment_history ADD COLUMN record_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;

--check field
select*
from persons p; 