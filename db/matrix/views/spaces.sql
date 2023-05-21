--This creates a materialized view of all the spaces and their children
--FIX THIS LATER

DROP INDEX IF EXISTS spaces_idx;
DROP MATERIALIZED VIEW IF EXISTS spaces;

CREATE MATERIALIZED VIEW IF NOT EXISTS spaces AS 
    SELECT rooms.room_id, ra.room_alias, substring(split_part(ra.room_alias, ':', 1) FROM 2) as space_alias
    FROM rooms
    JOIN room_aliases ra ON ra.room_id = rooms.room_id
    JOIN event_json ej ON ej.room_id = rooms.room_id AND ej.json::jsonb->>'type' = 'm.room.create' AND ej.json::jsonb->'content'->>'type' = 'm.space';

CREATE UNIQUE INDEX IF NOT EXISTS spaces_idx ON spaces (room_id);

CREATE OR REPLACE FUNCTION spaces_mv_refresh()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY spaces;
    RETURN NULL;
END;
$$;

CREATE TRIGGER spaces_mv_trigger 
AFTER INSERT OR UPDATE OR DELETE
ON current_state_events
EXECUTE FUNCTION spaces_mv_refresh();
