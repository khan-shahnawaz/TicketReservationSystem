-- Stores triggers for different events


-- Trigger to delete tables of seats if corresponding entry is deleted from runs

CREATE TRIGGER del_seats_table BEFORE DELETE on RUNS FOR EACH ROW EXECUTE PROCEDURE drop_seat_tables();