DROP DATABASE IF EXISTS trips;
CREATE DATABASE IF NOT EXISTS trips;
USE trips;

-- tables
CREATE TABLE IF NOT EXISTS user (
	username VARCHAR(32) PRIMARY KEY,
	password VARCHAR(32) NOT NULL,
	firstName VARCHAR(32) NOT NULL,
	lastName VARCHAR(32) NOT NULL,
	email VARCHAR(32) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS trip (
	tripID INT AUTO_INCREMENT PRIMARY KEY,
	tripName VARCHAR(32) NOT NULL,
	description VARCHAR(300) NOT NULL,
	city VARCHAR(32) NOT NULL,
	country VARCHAR(32) NOT NULL,
	startDate DATE NOT NULL, 
	endDate DATE NOT NULL,
	owner VARCHAR(32) NOT NULL,
	FOREIGN KEY (owner) REFERENCES user(username) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS attends (
	tripID INT NOT NULL, 
	username VARCHAR(32) NOT NULL, 
	PRIMARY KEY (tripID, username), 
	FOREIGN KEY (username) REFERENCES user(username) ON DELETE CASCADE,
	FOREIGN KEY (tripID) REFERENCES trip(tripID) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS expense (
	expenseID INT AUTO_INCREMENT PRIMARY KEY,
	expenseName VARCHAR(32),
	total_cost DOUBLE NOT NULL 
);

CREATE TABLE IF NOT EXISTS accommodation(
	expenseID INT PRIMARY KEY,
    address VARCHAR(100) NOT NULL,
    startDate DATE NOT NULL, 
	endDate DATE NOT NULL,
    FOREIGN KEY (expenseID) REFERENCES expense(expenseID) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS plans(
	expenseID INT NOT NULL,
    tripID INT NOT NULL,
    username VARCHAR(32) NOT NULL,
    PRIMARY KEY(expenseID, tripID, username),
    FOREIGN KEY (expenseID) REFERENCES expense(expenseID) ON DELETE CASCADE,
    FOREIGN KEY (tripID) REFERENCES trip(tripID) ON DELETE CASCADE,
    FOREIGN KEY (username) REFERENCES user(username) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS repay (
	expenseID INT NOT NULL,
	payer VARCHAR(32) NOT NULL,
	owedTo VARCHAR(32) NOT NULL,
	amount DOUBLE NOT NULL,
	transactionCompleted BIT(1) NOT NULL,
	PRIMARY KEY(expenseID, payer, owedTo),
	FOREIGN KEY (expenseID)REFERENCES expense(expenseID),
	FOREIGN KEY (payer) REFERENCES user(username) ON DELETE CASCADE,
	FOREIGN KEY (owedTo) REFERENCES user(username) ON DELETE CASCADE
);

-- create and update user procedures
DELIMITER $$
CREATE PROCEDURE create_user (
	username_p VARCHAR(32),
	password_p VARCHAR(32),
	firstName_p VARCHAR(32),
	lastName_p VARCHAR(32),
	email_p VARCHAR(32)
)
BEGIN 
	INSERT INTO user VALUES(username_p, password_p, firstName_p, lastName_p, email_p);
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE update_user_password (
	username_p VARCHAR(32),
	password_p VARCHAR(32)
)
BEGIN 
	UPDATE user
	SET password = password_p
	WHERE username = username_p;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE update_user_lastName (
	username_p VARCHAR(32),
	lastName_p VARCHAR(32)
)
BEGIN 
	UPDATE user
	SET lastName = lastName_p
	WHERE username = username_p;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE update_user_firstName (
	username_p VARCHAR(32),
	firstName_p VARCHAR(32)
)
BEGIN 
	UPDATE user
	SET firstName = firstName_p
	WHERE username = username_p;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE check_login_exists (
	username_p VARCHAR(32),
	password_p VARCHAR(32)
)
BEGIN 
	SET @numRows = (SELECT COUNT(*) FROM (
			SELECT username, password FROM user
			WHERE username = username_p AND password = password_p
        ) AS numRowsRS);

	SELECT @numrows;
END$$
DELIMITER ;

-- create and update trip procedures
DELIMITER $$
CREATE PROCEDURE create_trip (
	city_p VARCHAR(32),
	country_p VARCHAR(32),
	tripName_p VARCHAR(32),
	description_p VARCHAR(32),
	startDate_p DATE, 
	endDate_p DATE,
	owner_p varchar(32)
)
BEGIN 
	INSERT INTO trip (tripNAME, description, city, country, startDATE, endDATE, owner)
	VALUES (tripNAME_p, description_p, city_p, country_p, startDATE_p, endDATE_p, owner_p);
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE update_trip_name (
	tripID_p INT,
	tripName_p VARCHAR(32)
)
BEGIN 
	UPDATE trip
	SET tripName = tripName_p
	WHERE tripID = tripID_p;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE update_trip_description (
	tripID_p INT,
	description_p VARCHAR(32)
)
BEGIN 
	UPDATE trip
	SET description = description_p
	WHERE tripID = tripID_p;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE update_trip_city (
	tripID_p INT,
	city_p VARCHAR(32)
)
BEGIN 
	UPDATE trip
	SET city = city_p
	WHERE tripID = tripID_p;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE update_trip_country (
	tripID_p INT,
	country_p VARCHAR(32)
)
BEGIN 
	UPDATE trip
	SET country = country_p
	WHERE tripID = tripID_p;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE update_trip_start_date (
	tripID_p INT,
	startDate_p DATE
)
BEGIN 
	UPDATE trip
	SET startDate = startDate_p
	WHERE tripID = tripID_p;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE update_trip_end_date (
	tripID_p INT,
	endDate_p DATE
)
BEGIN 
	UPDATE trip
	SET endDate = endDate_p
	WHERE tripID = tripID_p;
END$$
DELIMITER ;

-- TODO add or delete depending on list given
DELIMITER $$
CREATE PROCEDURE add_person_to_trip (
	tripID_p INT,
	username_p VARCHAR(32)
)
BEGIN 
	INSERT INTO attends (tripID, username) VALUES (tripID_p, username_p);
END$$
DELIMITER ;

-- trip triggers
DELIMITER  $$
CREATE TRIGGER add_attendee_after_adding_trip AFTER INSERT 
ON trip
FOR EACH ROW
BEGIN
	INSERT INTO attends VALUES (NEW.tripID, NEW.owner);
END$$
DELIMITER ;

-- get trip procedures
DELIMITER $$
CREATE PROCEDURE get_trips (
	username_p VARCHAR(32)
)
BEGIN
    SELECT * FROM trip WHERE tripID IN (SELECT tripID FROM attends WHERE username = username_p);
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE get_trip_info (
	tripID_p INT
)
BEGIN 
	SELECT trip.*, GROUP_CONCAT(username) FROM trip 
	JOIN attends USING(tripID)
	GROUP BY tripID
	HAVING tripID = tripID_p;
END$$
DELIMITER ;