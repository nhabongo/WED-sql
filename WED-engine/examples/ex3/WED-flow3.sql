BEGIN;
--WED-attributes
INSERT INTO wed_attr (name) values ('a2'),('a3');
INSERT INTO wed_attr (name, default_value) values ('a1','init');

--WED-conditions
INSERT INTO wed_cond (cname,cdesc) values ('init','initial condition'),('a2_ready','condition 2'),
                                          ('a3_ready','condition 3'), ('done_well', 'condition 4'),
                                          ('done_bad', 'condition 5');
INSERT INTO wed_cond (final,cname,cdesc) values ('t','final','final condition');

--order of match (final condition must came first !)
INSERT INTO wed_pred (cid,a1) values ((select cid from wed_cond where cname='final'), 'stopped');
INSERT INTO wed_pred (cid,a1) values ((select cid from wed_cond where cname='final'),'finished');
INSERT INTO wed_pred (cid,a1) values ((select cid from wed_cond where cname='init'), 'init');
INSERT INTO wed_pred (cid,a1,a2) values ((select cid from wed_cond where cname='a2_ready'),'started', 'ready');
INSERT INTO wed_pred (cid,a1,a3) values ((select cid from wed_cond where cname='a3_ready'),'started', 'ready');
INSERT INTO wed_pred (cid,a2,a3) values ((select cid from wed_cond where cname='done_well'),'done', 'done');
INSERT INTO wed_pred (cid,a2,a3) values ((select cid from wed_cond where cname='done_bad'),'error', 'done');
INSERT INTO wed_pred (cid,a2,a3) values ((select cid from wed_cond where cname='done_bad'),'done', 'error');
--INSERT INTO wed_pred (cid,a2,a3) values ((select cid from wed_cond where cname='done_bad'),'error', 'error');


--WED-transitions
INSERT INTO wed_trans (trname,trdesc) values ('tr1', 'initial transition');
INSERT INTO wed_trans (trname,trdesc) values ('tr2', 'a2 transition');
INSERT INTO wed_trans (trname,trdesc) values ('tr3', 'a3 transition');
INSERT INTO wed_trans (trname,trdesc) values ('tr4', 'final transition (well)');
INSERT INTO wed_trans (trname,trdesc) values ('tr5', 'final transition (bad)');

--WED-triggers
INSERT INTO wed_trig (cid,trid,tgname,tout) values ((select cid from wed_cond where cname='init'), 
                                             (select trid from wed_trans where trname='tr1'),
                                             'initial trigger','00:00:10');
INSERT INTO wed_trig (cid,trid,tgname,tout) values ((select cid from wed_cond where cname='a2_ready'), 
                                             (select trid from wed_trans where trname='tr2'),
                                             'a2 trigger','00:00:10');
INSERT INTO wed_trig (cid,trid,tgname,tout) values ((select cid from wed_cond where cname='a3_ready'), 
                                             (select trid from wed_trans where trname='tr3'),
                                             'a3 trigger','00:00:10');
INSERT INTO wed_trig (cid,trid,tgname,tout) values ((select cid from wed_cond where cname='done_well'), 
                                             (select trid from wed_trans where trname='tr4'),
                                             'final trigger (well)','00:00:15');
INSERT INTO wed_trig (cid,trid,tgname,tout) values ((select cid from wed_cond where cname='done_bad'), 
                                             (select trid from wed_trans where trname='tr5'),
                                             'final trigger (bad)','00:00:15');
--Display G (set of WED-triggers)                                             
SELECT tgname,cdesc,trdesc 
FROM wed_cond 
    INNER JOIN wed_trig ON wed_cond.cid = wed_trig.cid 
    INNER JOIN wed_trans ON wed_trig.trid = wed_trans.trid;

COMMIT;
--list all jobs not locked
--SELECT * FROM job_pool WHERE NOT locked;          
--lock a job
--UPDATE job_pool SET locked='t' WHERE wid=2 AND tgid=2 RETURNING itkn;                            
--list exceptions
--SELECT * FROM trg_pool WHERE locked AND (CURRENT_TIMESTAMP - ti) > tout;

--get a task                        
