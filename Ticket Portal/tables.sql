--Creates all the tables required


--Train Information
CREATE TABLE trains (
    number INT NOT NULL,
    name CHAR(50) ,
    PRIMARY KEY(number)
    );


--Keeps track of trains released into the system for booking
CREATE TABLE runs (
    train_number INT NOT NULL,
    departure_date DATE NOT NULL,
    ac_coach INT,
    sleeper_coach INT,
    PRIMARY KEY(train_number,departure_date),
    FOREIGN KEY(train_number) REFERENCES trains(number)
);

-- Enumrating all possible type of berths
create type BERTH as enum ('LB', 'UB', 'MB', 'SL', 'SU');


--Stores ticket information
CREATE TABLE tickets (
    PNR SERIAL ,
    train_number INT ,
    journey_date DATE ,
    passenger_name CHAR(16) ,
    coach CHAR(4) ,
    berth_type berth ,
    berth_number INT ,
    FOREIGN KEY(train_number) REFERENCES trains(number)
);
