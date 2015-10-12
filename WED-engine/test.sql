SET ROLE wed_admin;

CREATE OR REPLACE FUNCTION pytest (a integer, b integer) RETURNS integer AS 
$$
    from os import urandom
    import hashlib
    import binascii
    
    def hash_bongo():
        salt = urandom(5)
        plpy.info(binascii.hexlify(salt).decode('ascii'))
        hash = hashlib.md5(salt + b'nhaga')
        plpy.info(hash.hexdigest())
        
        return 0
    
    return hash_bongo()
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

-----------------------------TRIGGER TESTS------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION before_i_forget_you() RETURNS TRIGGER AS $bf$
    
    if TD['event'] in ['INSERT','UPDATE']:
        
        k,v = zip(*TD['new'].items())
        wed_columns = str(k).replace('\'','')
        wed_values = str(v)
        
        #TD['new']['tgid'] = 99
        plpy.notice(TD)
        TD['new']['aaa'] = 'modified'
        return "MODIFY"
                
$bf$ LANGUAGE plpython3u;

DROP TRIGGER IF EXISTS before_i_forget ON wed_flow;
CREATE TRIGGER before_i_forget
BEFORE INSERT OR UPDATE ON wed_flow
    FOR EACH ROW EXECUTE PROCEDURE before_i_forget_you();

CREATE OR REPLACE FUNCTION cant_forget_you() RETURNS TRIGGER AS $cf$
    
    if TD['event'] in ['INSERT','UPDATE']:
        
        k,v = zip(*TD['new'].items())
        wed_columns = str(k).replace('\'','')
        wed_values = str(v)
        
        #TD['new']['tgid'] = 99
        plpy.notice(TD)
        return "SKIP"
                
$cf$ LANGUAGE plpython3u;

DROP TRIGGER IF EXISTS cant_forget ON wed_flow;
CREATE TRIGGER cant_forget
BEFORE INSERT OR UPDATE ON wed_flow
    FOR EACH ROW EXECUTE PROCEDURE cant_forget_you();
    
RESET ROLE;
