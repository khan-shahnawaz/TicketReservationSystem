-- Adds all the procedures/functions

-- Procedure to add a train in the database

CREATE OR REPLACE PROCEDURE add_train(train_number INT, train_name CHAR(50)) AS
$$
    BEGIN
        INSERT INTO trains (number,name) values (train_number,train_name);
    END;
$$
LANGUAGE plpgsql;

-- Procedure to add train into the booking system for a particular date

CREATE OR REPLACE PROCEDURE release_into_booking(
    train_no INT,
    dep_date DATE,
    ac_coach INT,
    sleeper_coach INT
    ) AS
$$
    DECLARE
        ac_total INT; sleeper_total INT;
    BEGIN
        ac_total = ac_coach*18;
        sleeper_total = sleeper_coach*24;
        INSERT INTO runs (train_number,departure_date,ac_available,sleeper_available) 
        values (train_no,dep_date,ac_total,sleeper_total);
    END;
$$
LANGUAGE plpgsql;