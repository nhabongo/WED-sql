-- insert / update wed_flow & wed_trace(history) columns when a new wed-attribute is inserted in wed_attr    
CREATE OR REPLACE FUNCTION new_wed_attr() RETURNS TRIGGER AS $new_attr$

DECLARE
    attr_row    wed_attr%ROWTYPE;
    query       TEXT;
BEGIN
    RAISE NOTICE 'Firing trigger % : %, %, %', TG_NAME, TG_WHEN, TG_LEVEL, TG_OP;
    IF (TG_OP = 'INSERT') THEN
        RAISE NOTICE 'Inserting new WED-attibute: %', NEW.name;
        query := format('ALTER TABLE wed_flow ADD COLUMN %1$I TEXT NOT NULL DEFAULT %2$L;
                        ALTER TABLE wed_trace ADD COLUMN %1$I TEXT NOT NULL DEFAULT %2$L', 
                        NEW.name, NEW.default_value );
        EXECUTE query;
        RAISE NOTICE '%', query;
        
    ELSIF (TG_OP = 'UPDATE') THEN
        IF OLD.name <> NEW.name THEN
            RAISE NOTICE 'Updating WED-attibute name: % -> %', OLD.name, NEW.name;
            query := format('ALTER TABLE wed_flow RENAME COLUMN %I TO %I; 
                            ALTER TABLE wed_trace RENAME COLUMN %I TO %I', OLD.name, NEW.name, OLD.name, NEW.name);
            EXECUTE query;
            RAISE NOTICE '%', query;

        END IF;
        IF OLD.default_value <> NEW.default_value THEN
            RAISE NOTICE 'Updating WED-attibute "%" default_value: % -> %',OLD.name, OLD.default_value, NEW.default_value;
            query := format('ALTER TABLE wed_flow ALTER COLUMN %1$I SET DEFAULT %2$L; 
                             ALTER TABLE wed_trace ALTER COLUMN %1$I SET DEFAULT %2$L', 
                             OLD.name, NEW.default_value);
            EXECUTE query;
            RAISE NOTICE '%', query;
        END IF;
 
    ELSIF (TG_OP = 'DELETE') THEN
        RAISE NOTICE 'DON''T YOU DARE ! (%)', OLD.name;
    END IF;
    
    RETURN NULL;
    
END;
$new_attr$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS new_attr ON wed_attr;
CREATE TRIGGER new_attr
AFTER INSERT OR UPDATE OR DELETE ON wed_attr
    FOR EACH ROW EXECUTE PROCEDURE new_wed_attr();

--****************************************************************************--

    
CREATE OR REPLACE FUNCTION new_wed_trace_entry() RETURNS TRIGGER AS $new_trace_entry$

DECLARE
    flow_row    wed_flow%ROWTYPE;
    flow_columns    TEXT[];
    query       TEXT;
BEGIN
    RAISE NOTICE 'Firing trigger % : %, %, %', TG_NAME, TG_WHEN, TG_LEVEL, TG_OP;
    IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
        RAISE NOTICE 'Inserting new WED-state from WED-flow %  into WED-trace ...', NEW.wid;
        EXECUTE 'select array(select column_name::text from information_schema.columns where table_name=''wed_flow'')'
            INTO flow_columns;
        query := format('INSERT INTO wed_flow (%s) VALUES %s', array_to_string(flow_columns, ','), NEW.*);
        RAISE NOTICE '%', query;
    ELSIF (TG_OP = 'DELETE') THEN
        RAISE NOTICE 'DON''T YOU DARE ! (%)', OLD.wid;
    END IF;
    
    RETURN NULL;
    
END;
$new_trace_entry$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS new_trace_entry ON wed_flow;
CREATE TRIGGER new_trace_entry
AFTER INSERT OR UPDATE OR DELETE ON wed_flow
    FOR EACH ROW EXECUTE PROCEDURE new_wed_trace_entry();
