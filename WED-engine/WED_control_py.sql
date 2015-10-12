--CREATE LANGUAGE plpythonu;
--CREATE ROLE wed_admin WITH superuser noinherit;
--GRANT wed_admin TO wedflow;

SET ROLE wed_admin;
--Insert (or modify) a new WED-atribute in the apropriate tables 
------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION new_wed_attr() RETURNS TRIGGER AS 
$new_attr$
    plpy.info('Trigger "'+TD['name']+'" ('+TD['event']+','+TD['when']+') on "'+TD['table_name']+'"')
    if TD['event'] == 'INSERT':
        plpy.notice('Inserting new attribute: ' + TD['new']['name'])
        try:
            with plpy.subtransaction():
                plpy.execute('ALTER TABLE wed_flow ADD COLUMN ' 
                             + plpy.quote_ident(TD['new']['name']) 
                             + ' TEXT NOT NULL DEFAULT ' 
                             + plpy.quote_literal(TD['new']['default_value']))
                plpy.execute('ALTER TABLE wed_trace ADD COLUMN '
                             + plpy.quote_ident(TD['new']['name']) 
                             + ' TEXT NOT NULL DEFAULT ' 
                             + plpy.quote_literal(TD['new']['default_value']))
                plpy.execute('ALTER TABLE wed_pred ADD COLUMN '
                             + plpy.quote_ident(TD['new']['name']) 
                             + ' TEXT DEFAULT NULL')
        except plpy.SPIError:
            plpy.error('Could not insert new column at wed_flow')
        else:
            plpy.info('Column "'+TD['new']['name']+'" inserted into wed_flow, wed_trace, wed_cond')
            
    elif TD['event'] == 'UPDATE':
        if TD['new']['name'] != TD['old']['name']:
            plpy.notice('Updating attribute name: ' + TD['old']['name'] + ' -> ' + TD['new']['name'])
            try:
                with plpy.subtransaction():
                    plpy.execute('ALTER TABLE wed_flow RENAME COLUMN ' 
                                 + plpy.quote_ident(TD['old']['name']) 
                                 + ' TO ' 
                                 + plpy.quote_ident(TD['new']['name']))
                    plpy.execute('ALTER TABLE wed_trace RENAME COLUMN '
                                 + plpy.quote_ident(TD['old']['name']) 
                                 + ' TO ' 
                                 + plpy.quote_ident(TD['new']['name']))
                    plpy.execute('ALTER TABLE wed_pred RENAME COLUMN '
                                 + plpy.quote_ident(TD['old']['name']) 
                                 + ' TO ' 
                                 + plpy.quote_ident(TD['new']['name']))
            except plpy.SPIError:
                plpy.error('Could not rename columns at wed_flow')
            else:
                plpy.info('Column name updated in wed_flow, wed_trace, wed_cond')
            
        elif TD['new']['default_value'] != TD['old']['default_value']:
            plpy.notice('Updating attribute '+TD['old']['name']+' default value :' 
                        + TD['old']['default_value'] + ' -> ' + TD['new']['default_value'])
            try:
                with plpy.subtransaction():
                    plpy.execute('ALTER TABLE wed_flow ALTER COLUMN ' 
                                 + plpy.quote_ident(TD['old']['name']) 
                                 + ' SET DEFAULT ' 
                                 + plpy.quote_literal(TD['new']['default_value']))
                    plpy.execute('ALTER TABLE wed_trace ALTER COLUMN '
                                 + plpy.quote_ident(TD['old']['name']) 
                                 + ' SET DEFAULT ' 
                                 + plpy.quote_literal(TD['new']['default_value']))
            except plpy.SPIError:
                plpy.error('Could not insert new column into wed_flow')
            else:
                plpy.info('Column default value updated in wed_flow, wed_trace')
        else:
            plpy.error('UPDATE ERROR: name and or default_value must differ from previous value')
            return None
    else:
        plpy.error('UNDEFINED EVENT')
        return None
    return None    
$new_attr$ LANGUAGE plpython3u;

DROP TRIGGER IF EXISTS new_attr ON wed_attr;
CREATE TRIGGER new_attr
AFTER INSERT OR UPDATE ON wed_attr
    FOR EACH ROW EXECUTE PROCEDURE new_wed_attr();

--Insert a WED-flow modification into WED-trace (history)
------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION kernel_function() RETURNS TRIGGER AS $kt$
    
    from os import urandom
    import hashlib
    import binascii
    
    def new_itkn(trigger_name):
        salt = urandom(5)
        hash = hashlib.md5(salt + trigger_name)
        return hash.hexdigest()
    
    #-- wed_flow.iid must be absent or NULL (new wed_flow instance)
    if TD['event'] in ['INSERT']:
        
        k,v = zip(*[x for x in TD['new'].items() if x[0] not in ['var_itkn','var_trname']])
        wed_columns = str(k).replace('\'','')
        wed_values = str(v)
        tmp = new_itkn(b'nhaga')
        TD['new']['var_itkn'] = tmp
        
        plpy.info(wed_columns + wed_values)
        #try:
        #    plpy.execute('INSERT INTO wed_trace ' + wed_columns + ' VALUES ' + wed_values)
        #
        #except plpy.SPIError:
        #    plpy.error('Could not insert new entry into wed_trace')
        #else:
        #    plpy.info('New entry added to wed_trace')
            
        return "MODIFY"
    
    elif TD['event'] in ['UPDATE']:
        #-- lookup for itkn on TRG_POOL
        #-- if found then update wed_flow
        #-- look for transition entry on wed_trace and set the conclusion time (tf)
        plpy.info(TD['new'])
        plpy.info(TD['old'])
        if TD['new']['var_itkn'] != 'nhaga':
            plpy.error("invalid token !")
            return "SKIP"
            
        return "OK"
    
    else:
        return "SKIP"
    
    #--insert history into wed_trace
    #--scan wed_pred for matching wed_condition
    #--if matching wed_condition found then scan wed_trig to fire wed_trans and register it on TRG_POOL
    #--otherwise, check TRG_POOL for running trasitions (intermediate state). IF no running transitions for this
    #--wed-state is found on TRG_POOL, register this inconsistent state.
    
$kt$ LANGUAGE plpython3u;

DROP TRIGGER IF EXISTS kernel_trigger ON wed_flow;
CREATE TRIGGER kernel_trigger
BEFORE INSERT OR UPDATE ON wed_flow
    FOR EACH ROW EXECUTE PROCEDURE kernel_function();
    
------------------------------------------------------------------------------------------------------------------------

--CREATE OR REPLACE FUNCTION new_wed_trace_entry() RETURNS TRIGGER AS $new_trace_entry$
--   
--    if TD['event'] in ['INSERT','UPDATE']:
--        
--        
--    
--$new_trace_entry$ LANGUAGE plpython3u;
--
--DROP TRIGGER IF EXISTS new_trace_entry ON wed_flow;
--CREATE TRIGGER new_trace_entry
--AFTER INSERT OR UPDATE ON wed_flow
--    FOR EACH ROW EXECUTE PROCEDURE new_wed_trace_entry();

RESET ROLE;
