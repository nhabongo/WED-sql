--CREATE LANGUAGE plpythonu;
--CREATE ROLE wed_admin WITH superuser noinherit;
--GRANT wed_admin TO wedflow;

SET ROLE wed_admin;
CREATE OR REPLACE FUNCTION pytest (a integer, b integer) RETURNS integer AS 
$$
    if a > b:
        r = range(10)
        c = str(slice(r))
        plpy.info(c )
        return a
    return b
$$ LANGUAGE plpython3u
RESET ROLE;
