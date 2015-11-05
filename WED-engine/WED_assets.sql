SET ROLE wed_admin;

CREATE OR REPLACE FUNCTION job_inspector () RETURNS bool AS 
$$
    from datetime import datetime
    
    now = plpy.quote_literal(str(datetime.now()))
    
    try:
        rows = plpy.execute('select uptkn from job_pool where tf is null and ('+now+'::timestamp - ti) > tout')
    except plpy.SPIError:
        plpy.error('JOB_POOL scanning')
    else:
        if not rows:
            return False
        
        try:
            with plpy.subtransaction():
                plpy.execute('alter table job_pool disable trigger lock_job')
                for r in rows:
                    plpy.execute('update job_pool set aborted=TRUE, tf='+now+'::timestamp where uptkn='+
                                 plpy.quote_literal(r['uptkn']))
                plpy.execute('alter table job_pool enable trigger lock_job')
        except plpy.SPIError as e:
            plpy.error('JOB_POOL inserting: '+str(e))
    return True
    
$$ LANGUAGE plpython3u;

RESET ROLE; 
