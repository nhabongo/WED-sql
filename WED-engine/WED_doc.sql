-- should wed_attr domain restrictions be implemented as a foreign key on wed_flow ?
-- WED_trace could have duplicated (wid,tgid) in case of compensation ?

-- WED_pred: for a given condition c(cid,cname) in WED_cond, each row in WED_cond is a conjunction of non NULL WED_attributes
--for c. Thus, a predicate for c is the disjunction of these rows. 
-- how to insert a WED-predicative: 
--insert into wed_pred (cid,cname,a1,a2,...) values ((select cid from wed_cond where cname='nhaga'), 'nhaga', ...);

-- how to insert a new WED-attribute (if default_value is supressed, DEFAULT VALUE '')
--insert into wed_attr (name, default_value) values ('a0','vazio');

--kernel_function(): improve column name check expression
--check for condition without a predicate
--check for conditions not associated with at least one transition (conditions that not fire any trigger)

--algorithm: on insert: wed-pred (find condition id) -> wed_trig (find transition id) -> trg_pool (registry fired trigger) -> wed_trace (history)
--JOB_POOL store the trigger exceptions (for now)
-- Could be two instances of the same trigger running for the same WED-flow instance ! (Consider two ongoing WED-transitions t1
--and t2 (lock is set on trg_pool), if t2 completes first and set the new WED-state to the very same state that fired t1, then
--there will be two simultaneous running transitions t1. Sounds like a semantic error.
--write a function to verify that all WED-conditions fire at least one WED-transition (DONE)
--Can two or more diferent conditions fire the same transition ? (NO: use predicates instead)
--pgagent or background workers (autovacuum) to catch stalled running transitions (timeout in prg_pool table) (DONE)
--create a table to store all possible states (or maybe just final states)(DONE, final condition)
--block final states for further modifications ? (DONE)
--improve job management(maybe store an worker id)(DONE)
--exception tokens
--better tying between transitions and conditions (restrict what each transition can do)
--Should concurrent WED-transitions be aware of each other abortions ?
--timeout abortion: forever pending job, job locked but not finished (done)
--deliberated abortion: user cancel, ...
--disable trigger
--compensation: S-1 -> fix the broken transition e fire then all again (if there is more than one transition for a given
--state)
--Asynchronous notifications to avoid pooling job_pool
--(index on job_pool.ti ??)
--must remove completed jobs from job_pool in order to avoid colisions on uptkn
--only allow one lock per transaction on job_pool (enforce use of uptkn via stored procedure)(done)
--temporay table for 'exception' token
--postgresql.conf: shared_preload_libraries = 'wed_worker' (done)
--bg_worker: restart on failure ?
--bg_worker: dynamically start on a given database (aborted)
--test install on ubuntu
--enforce that each wed-transition must modify its firing wed-attributes ?(a2='ready' -> a1='received' = trigger 1 fired again)
--improve wed_flow update 
 
