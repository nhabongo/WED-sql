BEGIN;
--WED-attributes
INSERT INTO wed_attr (name) values ('a1'),('a2');
INSERT INTO wed_attr (name, default_value) values ('a3','new');

--WED-conditions
INSERT INTO wed_cond (cname,cdesc) values ('c1','condition 1'),('c2','condition 2');
INSERT INTO wed_pred (cid,cname,a1,a3) values ((select cid from wed_cond where cname='c1'), 'c1', 'waiting', 'seated');
INSERT INTO wed_pred (cid,cname,a2) values ((select cid from wed_cond where cname='c1'), 'c1', 'ready');
INSERT INTO wed_pred (cid,cname,a1) values ((select cid from wed_cond where cname='c2'), 'c2', 'received');

--WED-transitions
INSERT INTO wed_trans (trname,trdesc) values ('tr1', 'transition one');
INSERT INTO wed_trans (trname,trdesc) values ('tr2', 'transition two');
INSERT INTO wed_trans (trname,trdesc) values ('tr3', 'transition three');
INSERT INTO wed_trans (trname,trdesc) values ('tr4', 'transition four');

--WED-triggers
INSERT INTO wed_trig (cid,trid,tgname,tout) values ((select cid from wed_cond where cname='c1'), 
                                             (select trid from wed_trans where trname='tr1'),
                                             'trigger one','00:03:00');
INSERT INTO wed_trig (cid,trid,tgname,tout) values ((select cid from wed_cond where cname='c1'), 
                                             (select trid from wed_trans where trname='tr2'),
                                             'trigger two','00:05:00');
INSERT INTO wed_trig (cid,trid,tgname,tout) values ((select cid from wed_cond where cname='c1'), 
                                             (select trid from wed_trans where trname='tr4'),
                                             'trigger three','02:00:00');
INSERT INTO wed_trig (cid,trid,tgname,tout) values ((select cid from wed_cond where cname='c2'), 
                                             (select trid from wed_trans where trname='tr3'),
                                             'trigger four','00:00:15');
--Display G (set of WED-triggers)                                             
SELECT tgname,cdesc,trdesc 
FROM wed_cond 
    INNER JOIN wed_trig ON wed_cond.cid = wed_trig.cid 
    INNER JOIN wed_trans ON wed_trig.trid = wed_trans.trid;

COMMIT;                                      
--list exceptions
--SELECT * FROM trg_pool WHERE locked AND (CURRENT_TIMESTAMP - ti) > tout;

--get a task
                                                                   
