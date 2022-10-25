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

-- Function to book tickets
CREATE OR REPLACE FUNCTION book_tickets(
    num_passengers INT,
    coach_type CHAR(1),
    train_no INT,
    journey_date DATE,
    first_try BOOLEAN,
    names VARIADIC CHAR(16)[]
) RETURNS TEXT[] AS
$$
    DECLARE
        toreturn TEXT[];
        total_seats_not_booked INT;
        total_runs INT;
        table_name TEXT;
        ticket_rows seats_schema[];
        Coach_id CHAR(4);
        i INT;
        rec RECORD;
        PNR_number CHAR(19);
    BEGIN
        
        IF coach_type='A' THEN table_name='AC'||train_no::TEXT|| '_' ||journey_date::TEXT; END IF;
        IF coach_type='S' THEN table_name='SL'||train_no::TEXT|| '_' ||journey_date::TEXT; END IF;

        EXECUTE FORMAT('SELECT COUNT(*) from runs WHERE train_number=$1 AND departure_date=$2') USING train_no,journey_date INTO total_runs;
        IF total_runs=0 THEN toreturn = ARRAY_APPEND(toreturn,'-1'); RETURN toreturn; END IF;
        


        EXECUTE FORMAT('SELECT COUNT(*) from (SELECT * FROM %I LIMIT $1) as sub',table_name) USING num_passengers INTO total_seats_not_booked;
        IF total_seats_not_booked<num_passengers THEN toreturn = ARRAY_APPEND(toreturn,'-2'); RETURN toreturn; END IF;


        IF first_try='true' THEN

            EXECUTE FORMAT('SELECT ARRAY(SELECT row(berth_number, coach, berth_type) FROM %I LIMIT $1 FOR UPDATE SKIP LOCKED)',table_name) USING num_passengers INTO ticket_rows;
            IF CARDINALITY(ticket_rows)<num_passengers THEN toreturn = ARRAY_APPEND(toreturn,'-2'); RETURN toreturn; END IF;
            toreturn = ARRAY_APPEND(toreturn,'0');
            i=1;
            FOR rec IN (SELECT * FROM UNNEST(ticket_rows)) LOOP
                IF i=1 THEN
                    PNR_number = to_char(train_no,'fm00000') || to_char(journey_date,'YYYYMMDD')||to_char(rec.berth_number,'fm00')||to_char(rec.coach,'fm000');
                    IF coach_type='A' THEN PNR_number = PNR_number||'0'; END IF;
                    IF coach_type='S' THEN PNR_number = PNR_number||'1'; END IF;
                    toreturn = ARRAY_APPEND(toreturn,PNR_number);

                END IF;

                toreturn = ARRAY_APPEND(toreturn,rec.berth_number::TEXT);
                toreturn = ARRAY_APPEND(toreturn,rec.coach::TEXT);
                toreturn = ARRAY_APPEND(toreturn,rec.berth_type::TEXT);
                Coach_id = coach_type||rec.coach::TEXT;
                EXECUTE FORMAT('DELETE FROM %I WHERE berth_number=$1 AND coach=$2 AND berth_type=$3',table_name) USING rec.berth_number,rec.coach,rec.berth_type;
                EXECUTE FORMAT('INSERT INTO tickets(PNR, train_number, journey_date ,passenger_name ,coach, berth_type , berth_number) VALUES
                ($1,$2,$3,$4,$5,$6,$7)') USING PNR_number,train_no,journey_date, names[i], Coach_id, rec.berth_type, rec.berth_number;
                
                i=i+1;
            END LOOP;
            
        END IF;
        RETURN toreturn;
    END;
$$
LANGUAGE plpgsql;