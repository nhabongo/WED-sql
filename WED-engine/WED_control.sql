--CREATE LANGUAGE plpython3u;
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
    from datetime import datetime
    import hashlib
    import binascii
    
    #--Generates new instance trigger token ----------------------------------------------------------------------------
    def new_uptkn(trigger_name):
        salt = urandom(5)
        hash = hashlib.md5(salt + trigger_name)
        return hash.hexdigest()

    #--Match predicates against the new state -------------------------------------------------------------------------
    def wed_pred_match(k,v):
        attr = [x for x in k if x not in ['wid','awic']]
        mtch = set()
        final = False
        try:
            cur = plpy.cursor('select p.*, c.final from wed_pred p inner join wed_cond c on p.cid = c.cid')
        except plpy.SPIError:
            plpy.error('ERROR: wed_pred scan')
        else:
            #-- wed_pred must be validated to not allow all WED-attributes being NULL at once
            for r in cur:
                flag = True
                for c in attr:
                    if r[c]:
                        flag = flag and (TD['new'][c].lower() == r[c].lower())
                if flag:
                    plpy.info('MATCHES: ',r)
                    mtch.add(r['cid'])
                    final = final or r['final']
        return (mtch, final)
    
    #--must block diferents conditions firing the same transition ------------------------------------------------------
    def squeeze_the_trigger(trg_set):
        
        ftrg = 0
        if not trg_set:
            return ftrg
            
        try:
            cur = plpy.cursor('select * from wed_trig where cid in ('+str(trg_set).strip('{}')+')')
        except plpy.SPIError:
            plpy.error('ERROR: wed_trig scan')
        else:
            for r in cur:
                #--plpy.info(r)
                
                uptkn = new_uptkn(r['tgname'].encode('utf-8'))
                try:
                    plpy.execute('INSERT INTO job_pool (tgid,wid,uptkn,tout) VALUES ' + 
                              str((r['tgid'],TD['new']['wid'],uptkn,r['tout'])))
                except plpy.SPIError as e:
                    plpy.info('ERROR inserting new entry at JOB_POOL')
                    plpy.error(e)
                else:
                    ftrg += 1
        return ftrg            
    #--Create a new entry on history (WED_trace table) -----------------------------------------------------------------
    def new_trace_entry(k,v,tgid=False,final=False,excpt=False):
        if tgid:
            k = k + ('tgid',)
            v = v + (tgid,)
        
        if final:
            k = k + ('final',)
            v = v + (True,)
            
        if excpt:
            k = k + ('excpt',)
            v = v + (True,)
        
        wed_columns = str(k).replace('\'','')
        wed_values = str(v)
        
        try:
            plpy.execute('INSERT INTO wed_trace ' + wed_columns + ' VALUES ' + wed_values)
        except plpy.SPIError as e:
            plpy.info('Could not insert new entry into wed_trace')
            plpy.error(e)
    
    #-- Create a new entry on ST_STATUS for fast detecting final states ------------------------------------------------
    def new_st_status_entry(wid):
        try:
            plpy.execute('INSERT INTO st_status (wid) VALUES (' + str(wid) + ')')
        except plpy.SPIError as e:
            plpy.info('Could not insert new entry into st_status')
            plpy.error(e)    
    
    #-- Check for conditions that do not have at least one predicate ---------------------------------------------------
    def wed_cond_validation():
        try:
            res = plpy.execute('select c.cid from wed_cond c left join wed_pred p on c.cid = p.cid where p.pid is null')
        except plpy.SPIError:
            plpy.error('Cond-Pred validation error')
        else:
            if len(res):
                return False
            return True
    
    #-- Check for conditions that do not fire at least one transition (ignore final conditions)-------------------------
    def wed_trig_validation():
        try:
            res = plpy.execute('select c.cid from wed_cond c left join wed_trig t '+
                               'on c.cid = t.cid where t.tgid is null and (not c.final)')
        except plpy.SPIError:
            plpy.error('Cond-Trig validation error')
        else:
            if len(res):
                return False
            return True
    
    #-- Check if there is one and only one final condition (use WED_pred to define alternatives (boolean OR) final con-
    #--ditions ---------------------------------------------------------------------------------------------------------           
    def wed_final_cond_validation():
        try:
            res = plpy.execute('select cid from wed_cond where final')
        except plpy.SPIError:
            plpy.error('Final cond validation error')
        else:
            if not len(res):
                return False
            return True
    
    #-- Find job with uptkn on JOB_POOL --------------------------------------------------------------------------------
    def find_job(uptkn):
        try:
            with plpy.subtransaction():
                plpy.execute('alter table job_pool disable trigger lock_job')
                res = plpy.execute('update job_pool set tf='+plpy.quote_literal(str(datetime.now()))+
                                   '::timestamp where uptkn='+plpy.quote_literal(uptkn)+
                                   'and locked and tf is null returning tgid,wid,uptkn,locked,tout,ti,tf')
                plpy.execute('alter table job_pool enable trigger lock_job')
        except plpy.SPIError:
            plpy.error('Find job error')
        else:
            return list(res)
            
    #-- scan job_pool for pending transitions for WED-flow instance wid
    def pending_transitions(wid):
        try:
            res = plpy.execute('select tgid from job_pool where wid='+str(wid)+' and tf is null')
        except plpy.SPIError:
            plpy.error('Pending transitions error')
        else:
            return {x['tgid'] for x in res}
    
    #-- Check if a given wed-flow instance is already on a final state -------------------------------------------------
    def is_final(wid):
        try:
            res = plpy.execute('select final from st_status where wid='+str(wid))
        except plpy.SPIError:
            plpy.error('Reading st_status')
        else:
            if not len(res):
                plpy.error('wid not found !')
            else:
                return res[0]['final']
    
    #-- Set an WED-state status (final or not final)
    def set_st_status(wid,status=True):
        try:
            res = plpy.execute('update st_status set final='+str(status)+' where wid='+str(wid))
        except plpy.SPIError:
            plpy.error('Status set error on st_status table')
    
    #--Only get the WED-attributes columns to insert into WED-trace-----------------------------------------------------
    k,v = zip(*[x for x in TD['new'].items() if x[0] not in ['var_uptkn']])
    #-- New wed-flow instance (AFTER INSERT)----------------------------------------------------------------------------
    if TD['event'] in ['INSERT']:
        
        trg_set, final = wed_pred_match(k,v)
        plpy.info(trg_set, final)  
        if (not trg_set) and (not final):
            plpy.error('No predicate matches this initial WED-state, aborting ...')
            
        
        #--plpy.info(k,v)
        
        if not wed_final_cond_validation():
            plpy.error('No final condition(s) found !')
        
        if not wed_cond_validation():
            plpy.error('Condition without predicate found !')

        if not wed_trig_validation():
            plpy.error('Condition not associated with any transition found !')
        
        #-- if the initial state is a final state, do not fire any triggers
        if not final: 
            squeeze_the_trigger(trg_set)
            new_trace_entry(k,v)
            new_st_status_entry(TD['new']['wid'])
        else:
            plpy.notice('Final WED-state reached (no triggers fired).')
            new_trace_entry(k,v,final=True)
            new_st_status_entry(TD['new']['wid'])
            set_st_status(TD['new']['wid'])
            #-- Write the new state on wed_trace (tgid is the id of the trigger that lead to this state. It is null only
            #-- for initial states)
            

    #-- Updating an WED-state (BEFORE UPDATE)---------------------------------------------------------------------------
    elif TD['event'] in ['UPDATE']:
        for i in TD['args']:
            plpy.info('args',i)
        #-- lookup for uptkn on JOB_POOL
        #-- if found then update wed_flow
        #--plpy.info(TD['new'])
        #--plpy.info(TD['old'])
        if is_final(TD['old']['wid']):
            plpy.error('Cannot modify a final WED-state !')
        
        #-- token was provided
        if TD['new']['var_uptkn']:
            #--ignored token lookup on job_pool if uptkn='exception'
            if TD['new']['var_uptkn'].lower() != 'exception': 
                job = find_job(TD['new']['var_uptkn'])
                plpy.notice(job,'nhaga')
                if not len(job):
                    plpy.error('job not found, not locked or already completed, aborting ...')
                else:
                     trans_set = pending_transitions(job[0]['wid'])
                     trg_set, final = wed_pred_match(k,v)
                     plpy.notice(trans_set,trg_set,final)
                     
                     #--no pending transitions, not have fired any new transitions and is not a final state 
                     if (not trans_set) and (not trg_set):
                        plpy.warning('INCONSISTENT WED-state DETECTED !!!')
                        new_trace_entry(k,v,job[0]['tgid'],excpt=True)
                     
                     #-- WRONG !!! (final and pending !)
                     elif final:
                        if len(trg_set) != 1:
                            plpy.error('A FINAL WED-state CANNOT FIRE ADDITIONAL WED-triggers !')
                        else:
                            new_trace_entry(k,v,job[0]['tgid'],final=True)
                            set_st_status(TD['old']['wid'])
                     
                     else:
                        squeeze_the_trigger(trg_set - trans_set)
                        new_trace_entry(k,v,job[0]['tgid'])
                        
            else:
                plpy.info('dealing with an exception')
                #--new_trace_entry(k,v)
                #-------------------------------------
                    
        else:
            plpy.error('token needed to update wed_flow')
            
        return "OK"
    
    else:
        return "SKIP"
    
$kt$ LANGUAGE plpython3u;

DROP TRIGGER IF EXISTS kernel_trigger_insert ON wed_flow;
CREATE TRIGGER kernel_trigger_insert
AFTER INSERT ON wed_flow
    FOR EACH ROW EXECUTE PROCEDURE kernel_function('insert');
    
DROP TRIGGER IF EXISTS kernel_trigger_update ON wed_flow;
CREATE TRIGGER kernel_trigger_update
BEFORE UPDATE ON wed_flow
    FOR EACH ROW EXECUTE PROCEDURE kernel_function('update');
    
------------------------------------------------------------------------------------------------------------------------
-- Lock a job from job_pool seting locked=True and ti = CURRENT_TIMESTAMP
CREATE OR REPLACE FUNCTION set_job_lock() RETURNS TRIGGER AS $pv$
    
    from datetime import datetime
       
    #--plpy.info(TD['new'])
    #--plpy.info(TD['old'])
   
    if TD['old']['locked']:
        plpy.error('Job \''+TD['new']['uptkn']+'\' already locked, aborting ...')
    
    if TD['new']['locked']:
        #-- allow update only on 'locked' column
        TD['new'] = TD['old']
        TD['new']['locked'] = True
        TD['new']['ti'] = datetime.now()
        
    return "MODIFY"  
    
$pv$ LANGUAGE plpython3u;

DROP TRIGGER IF EXISTS lock_job ON job_pool;
CREATE TRIGGER lock_job
BEFORE UPDATE ON job_pool
    FOR EACH ROW EXECUTE PROCEDURE set_job_lock();

RESET ROLE;
