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
        b_type berth;
        temp INT;
    BEGIN
        ac_table_name = 'AC' || train_no::TEXT || '_' || dep_date::TEXT ;
        sleeper_table_name = 'SL' || train_no::TEXT || '_' || dep_date::TEXT ;
        INSERT INTO runs (train_number,departure_date,ac_coach,sleeper_coach) 
        values (train_no,dep_date,num_ac_coach,num_sleeper_coach);
        EXECUTE FORMAT('CREATE TABLE %I (
                berth_number INT,
                coach INT,
                berth_type BERTH
                );',
        ac_table_name);

        EXECUTE FORMAT('CREATE TABLE %I (
                berth_number INT,
                coach INT,
                berth_type BERTH
                );',
        sleeper_table_name);
        FOR Coach_no in 1..num_ac_coach LOOP
            FOR Berth_no in 1..18 LOOP
                temp=MOD(Berth_no,6);
                IF temp=0 THEN b_type='SU'; END IF;
                IF temp=1 OR temp=2 THEN b_type='LB'; END IF;
                IF temp=3 OR temp=4 THEN b_type='UB'; END IF;
                IF temp=5 THEN b_type='SL'; END IF;

                EXECUTE FORMAT('INSERT INTO %I (berth_number, coach, berth_type) VALUES ($1,$2,$3)',ac_table_name) USING Berth_no, Coach_no, b_type;
            END LOOP;
        END LOOP;

        FOR Coach_no in 1..num_sleeper_coach LOOP
            FOR Berth_no in 1..24 LOOP
                temp=MOD(Berth_no,8);
                IF temp=0 THEN b_type='SU'; END IF;
                IF temp=1 OR temp=4 THEN b_type='LB'; END IF;
                IF temp=2 OR temp=5 THEN b_type='MB'; END IF;
                IF temp=3 OR temp=6 THEN b_type='UB'; END IF;
                IF temp=7 THEN b_type='SL'; END IF;

                EXECUTE FORMAT('INSERT INTO %I (berth_number, coach, berth_type) VALUES ($1,$2,$3)',sleeper_table_name) USING Berth_no, Coach_no, b_type;
            END LOOP;
        END LOOP;

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