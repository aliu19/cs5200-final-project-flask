CREATE DATABASE IF NOT EXISTS trips;
use trips;

CREATE TABLE IF NOT EXISTS user (
username varchar(32) PRIMARY KEY,
password varchar(32) NOT NULL,
firstName varchar(32) NOT NULL,
lastName varchar(32) NOT NULL,
email varchar(32) NOT NULL
);

START TRANSACTION;
INSERT INTO user VALUES("enguyen1", "nguyen12", "Eric", "Nguyen", "nguyen.eri@northeastern.edu");
ROLLBACK;

DELIMITER $$

CREATE PROCEDURE create_user (
username_p varchar(32),
password_p varchar(32),
firstName_p varchar(32),
lastName_p varchar(32),
email_p varchar(32))
BEGIN 
INSERT INTO user VALUES(username_p, password_p, firstName_p, lastName_p, email_p);
END$$

DELIMITER ;

START TRANSACTION;
CALL create_user("enguyen1", "nguyen12", "Eric", "Nguyen", "nguyen.eri@northeastern.edu");
ROLLBACK;

DELIMITER $$

CREATE PROCEDURE update_user_password (
username_p varchar(32),
password_p varchar(32))
BEGIN 
UPDATE user
SET password = password_p
WHERE username = username_p;
END$$

DELIMITER ;



DELIMITER $$

CREATE PROCEDURE update_user_lastName (
username_p varchar(32),
lastName_p varchar(32))
BEGIN 
UPDATE user
SET lastName = lastName_p
WHERE username = username_p;
END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE update_user_firstName (
username_p varchar(32),
firstName_p varchar(32))
BEGIN 
UPDATE user
SET firstName = firstName_p
WHERE username = username_p;
END$$

DELIMITER ;

START TRANSACTION;
CALL update_user_password('enguyen1', 'nguyen15');
CALL update_user_firstName('enguyen1', 'Erick');
CALL update_user_lastName('enguyen1', 'Ngyen');
ROLLBACK;


CREATE TABLE IF NOT EXISTS geography (
city varchar(32) NOT NULL,
country varchar(32) NOT NULL,
PRIMARY KEY(city, country)
);

START TRANSACTION;
INSERT INTO geography VALUES ("Boston", "USA");
ROLLBACK;

DELIMITER $$

CREATE PROCEDURE create_location (
city_p varchar(32),
country_p varchar(32))
BEGIN 
INSERT INTO geography VALUES (city_p, country_p);
END$$

DELIMITER ;

START TRANSACTION;
CALL create_location("Boston", "USA");
ROLLBACK;

CREATE TABLE IF NOT EXISTS trip (
tripID INT AUTO_INCREMENT PRIMARY KEY,
city varchar(32) NOT NULL,
country varchar(32) NOT NULL,
tripName varchar(32) NOT NULL,
description varchar(32) DEFAULT NULL,
startDate DATE NOT NULL, 
endDate DATE NOT NULL,
owner varchar(32),
CONSTRAINT creates FOREIGN KEY (owner)
REFERENCES user(username) ON DELETE CASCADE,
CONSTRAINT takes_place_in FOREIGN KEY (city, country) 
REFERENCES geography(city, country) ON DELETE CASCADE
);

START transaction;
CALL create_user("enguyen1", "nguyen12", "Eric", "Nguyen", "nguyen.eri@northeastern.edu");
CALL create_location("Boston", "USA");
INSERT INTO trip (city, country, tripNAME, description, startDATE, endDATE, owner)
VALUES ("Boston", "USA", "MyTrip", "", '2024-01-01', '2024-01-08', "enguyen1");
ROLLBACK;


DELIMITER  $$

CREATE TRIGGER geography_before_insert_trip
BEFORE INSERT 
ON trip
FOR EACH ROW
BEGIN
	INSERT INTO geography VALUES (NEW.city, NEW.country);
END$$

DELIMITER ;

START TRANSACTION;
INSERT INTO user VALUES("enguyen1", "nguyen12", "Eric", "Nguyen", "nguyen.eri@northeastern.edu");
INSERT INTO trip (city, country, tripNAME, description, startDATE, endDATE, owner)
VALUES ("Boston", "USA", "MyTrip", "", '2024-01-01', '2024-01-08', "enguyen1");
ROLLBACK;

DELIMITER $$

CREATE PROCEDURE create_trip (
city_p varchar(32),
country_p varchar(32),
tripName_p varchar(32),
description_p varchar(32),
startDate_p DATE, 
endDate_p DATE,
owner_p varchar(32))
BEGIN 
INSERT INTO trip (city, country, tripNAME, description, startDATE, endDATE, owner)
VALUES (city_p, country_p, tripNAME_p, description_p, startDATE_p, endDATE_p, owner_p);
END$$

DELIMITER ;

START TRANSACTION;
INSERT INTO user VALUES("enguyen1", "nguyen12", "Eric", "Nguyen", "nguyen.eri@northeastern.edu");
CALL create_trip ("Boston", "USA", "MyTrip", "", '2024-01-01', '2024-01-08', "enguyen1");
ROLLBACK;

CREATE TABLE IF NOT EXISTS attends (
tripID INT NOT NULL, 
username varchar(32) NOT NULL, 
PRIMARY KEY (tripID, username), 
CONSTRAINT attendee_attends_trip FOREIGN KEY (username)
REFERENCES user(username) ON DELETE CASCADE,
CONSTRAINT trip_attended_by_users FOREIGN KEY (tripID)
REFERENCES trip(tripID) ON DELETE CASCADE 
);

DELIMITER  $$

CREATE TRIGGER add_attendee_after_adding_trip
AFTER INSERT 
ON trip
FOR EACH ROW
BEGIN
	INSERT INTO attends VALUES (NEW.tripID, NEW.owner);
END$$

DELIMITER ;

START TRANSACTION;
INSERT INTO user VALUES("enguyen1", "nguyen12", "Eric", "Nguyen", "nguyen.eri@northeastern.edu");
CALL create_trip ("Boston", "USA", "MyTrip", "", '2024-01-01', '2024-01-08', "enguyen1");
ROLLBACK;

## Test Code to get list of attendees

## START transaction;
## CALL create_user("enguyen1", "nguyen12", "Eric", "Nguyen", "nguyen.eri@northeastern.edu");
## CALL create_user("enguyen2", "nguyen12", "Eric", "Nguyen", "nguyen.eri@northeastern.edu");
## CALL create_trip ("Boston", "USA", "MyTrip", "", '2024-01-01', '2024-01-08', "enguyen1");
## INSERT INTO attends VALUES (5, "enguyen2");
## SELECT GROUP_CONCAT(username) FROM attends GROUP BY tripID;
## ROLLBACK;

DELIMITER $$

CREATE PROCEDURE get_owner_active_trips (
username_p varchar(32))
BEGIN 
SELECT tripID, tripName FROM trip
WHERE owner = username_p;
END$$

DELIMITER ;

START transaction;
CALL create_user("enguyen1", "nguyen12", "Eric", "Nguyen", "nguyen.eri@northeastern.edu");
CALL create_trip ("Boston", "USA", "MyTrip", "", '2024-01-01', '2024-01-08', "enguyen1");
CALL create_trip ("Springfield", "USA", "MyTrip2", "", '2024-01-09', '2024-01-16', "enguyen1");
CALL get_owner_active_trips("enguyen1");
ROLLBACK;

DELIMITER $$

CREATE PROCEDURE add_person_to_trip (
tripID_p INT,
username_p varchar(32))
BEGIN 
INSERT INTO attends (tripID, username) VALUES (tripID_p, username_p);
END$$

DELIMITER ;

## START transaction;
## CALL create_user("enguyen3", "nguyen12", "Eric", "Nguyen", "nguyen.eri@gmail.com");
## CALL create_trip ("Boston", "USA", "MyTrip", "", '2024-01-01', '2024-01-08', "enguyen1");
## CALL create_trip ("Springfield", "USA", "MyTrip2", "", '2024-01-09', '2024-01-16', "enguyen1");
## CALL get_owner_active_trips("enguyen1");
## CALL add_person_to_trip(8, "enguyen3");
## ROLLBACK;

DELIMITER $$

CREATE PROCEDURE check_login_exists (
username_p varchar(32),
password_p varchar(32))
BEGIN 
SET @numRows = (SELECT COUNT(*) FROM(
SELECT username, password
FROM user
WHERE username = username_p AND password = password_p) AS numRowsRS);

#SELECT @numrows;

IF (@numRows = 1)
THEN
SELECT 'username and password exists' AS LOGIN_INFO_EXISTS;
END IF;

IF (@numRows = 0)
THEN
SELECT 'username and password does not exists' AS LOGIN_INFO_NOT_EXISTS;
END IF;
END$$

DELIMITER ;


START TRANSACTION;
INSERT INTO user VALUES("enguyen1", "nguyen12", "Eric", "Nguyen", "nguyen.eri@northeastern.edu");
CALL check_login_exists("enguyen1", "nguyen12");
CALL check_login_exists("enguyen1", "nguyen13");
ROLLBACK;

CREATE TABLE IF NOT EXISTS transaction (
transactionID INT AUTO_INCREMENT PRIMARY KEY,
amount INT NOT NULL, 
transactionCompleted TINYINT
);

CREATE TABLE IF NOT EXISTS expense (
expenseID INT AUTO_INCREMENT PRIMARY KEY,
expenseName varchar(32),
cost INT NOT NULL 
);

CREATE TABLE IF NOT EXISTS repays (
payer varchar(32) NOT NULL,
payee varchar(32), 
transactionID INT UNIQUE NOT NULL,
expenseID INT UNIQUE NOT NULL,
PRIMARY KEY(payer, transactionID, expenseID),
CONSTRAINT pays FOREIGN KEY (payer)
REFERENCES user(username) ON DELETE CASCADE,
CONSTRAINT getting_paid FOREIGN KEY (payee)
REFERENCES user(username) ON DELETE CASCADE,
CONSTRAINT record FOREIGN KEY (transactionID)
REFERENCES transaction(transactionID),
CONSTRAINT paid_for FOREIGN KEY (expenseID)
REFERENCES expense(expenseID)
);


###

DELIMITER $$

CREATE PROCEDURE create_expense (
expenseName_p varchar(32),
cost_p INT)
BEGIN 
INSERT INTO expense (expenseName, cost)
VALUES (expenseName_p, cost_p);
END$$

DELIMITER ;


START transaction;
CALL create_user("enguyen1", "nguyen12", "Eric", "Nguyen", "nguyen.eri@northeastern.edu");
CALL create_user("enguyen2", "nguyen12", "Eric", "Nguyen", "nguyen.eri@northeastern.edu");