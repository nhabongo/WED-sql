SET ROLE wed_admin;

CREATE OR REPLACE FUNCTION pytest (a integer, b integer) RETURNS integer AS 
$$
    r = range(10)
    plpy.info(list(r))
    plpy.notice(dir(plpy))
    return b
$$ LANGUAGE plpython3u;

CREATE OR REPLACE FUNCTION rowtest (i integer) RETURNS SETOF wed_flow AS 
$$
    try:
        c = plpy.cursor('select * from wed_flow')
    except plpy.SPIError:
        plpy.error('erro !')
    else:
        l = [(i,'teste','teste')]
        for r in c:
            plpy.info(r)
            l.append(r)
            
    return l
$$ LANGUAGE plpython3u;
RESET ROLE;
