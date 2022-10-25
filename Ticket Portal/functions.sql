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
    num_ac_coach INT,
    num_sleeper_coach INT
    ) AS
$$
    DECLARE
        ac_table_name TEXT;
        sleeper_table_name TEXT;
    BEGIN
        ac_table_name = 'AC' || train_no::TEXT || '_' || dep_date::TEXT ;
        sleeper_table_name = 'SL' || train_no::TEXT || '_' || dep_date::TEXT ;
        INSERT INTO runs (train_number,departure_date,ac_coach,sleeper_coach) 
        values (train_no,dep_date,num_ac_coach,num_sleeper_coach);
        EXECUTE FORMAT('CREATE TABLE %I (
                berth_number INT,
                coach INT,
                berth_type berth
                );',
        ac_table_name);

        EXECUTE FORMAT('CREATE TABLE %I (
                berth_number INT,
                coach INT,
                berth_type berth
                );',
        sleeper_table_name);

    COMMIT;
    END;
$$
LANGUAGE plpgsql;

-- Delete all the tables of seat when entry is deleted from runs

CREATE OR REPLACE FUNCTION drop_seat_tables() RETURNS TRIGGER AS
$$
    DECLARE
        ac_table_name TEXT;
        sleeper_table_name TEXT;
    BEGIN
        ac_table_name = 'AC' || OLD.train_number || '_' || OLD.departure_date::TEXT ;
        sleeper_table_name = 'SL' || OLD.train_number || '_' || OLD.departure_date::TEXT ;
    
        EXECUTE FORMAT('DROP TABLE IF EXISTS %I;', ac_table_name);
        EXECUTE FORMAT('DROP TABLE IF EXISTS %I;', sleeper_table_name);

        RETURN OLD;
    END;
$$
LANGUAGE plpgsql;