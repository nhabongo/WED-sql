
CREATE OR REPLACE FUNCTION new_wed_attr() RETURNS TRIGGER AS $new_attr$

DECLARE
    attr_row    wed_attr%ROWTYPE;
BEGIN
    RAISE NOTICE 'Firing trigger % : %, %, %', TG_NAME, TG_WHEN, TG_LEVEL, TG_OP;
    IF (TG_OP = 'INSERT') THEN
        RAISE NOTICE 'Inserting new WED-attibute: %', NEW.name;
        EXECUTE 'ALTER TABLE wed_flow ADD COLUMN '
                || NEW.name || 
                ' TEXT NOT NULL DEFAULT '''
                || NEW.default_value || ''';'
                'ALTER TABLE wed_trace ADD COLUMN '
                || NEW.name || 
                ' TEXT NOT NULL DEFAULT '''
                || NEW.default_value || ''';';
        
    ELSIF (TG_OP = 'UPDATE') THEN
        IF OLD.name <> NEW.name THEN
            RAISE NOTICE 'Updating WED-attibute name: % -> %', OLD.name, NEW.name;
        END IF;
        IF OLD.default_value <> NEW.default_value THEN
            RAISE NOTICE 'Updating WED-attibute default_value: % -> %', OLD.default_value, NEW.default_value;
        END IF;
 
    ELSIF (TG_OP = 'DELETE') THEN
        RAISE NOTICE 'DONT YOU DARE ! (%)', OLD.name;
    END IF;
    
    RETURN NULL;
    
END;
$new_attr$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS new_attr ON wed_attr;
CREATE TRIGGER new_attr
AFTER INSERT OR UPDATE OR DELETE ON wed_attr
    FOR EACH ROW EXECUTE PROCEDURE new_wed_attr();
