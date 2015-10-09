
INSERT INTO wed_attr (name) values ('a1'),('a2');
INSERT INTO wed_attr (name, default_value) values ('a3','new');

INSERT INTO wed_cond (cname,cdesc) values ('c1','condition 1'),('c2','condition 2');
INSERT INTO wed_pred (cid,cname,a1) values ((select cid from wed_cond where cname='c1'), 'c1', 'waiting');
INSERT INTO wed_pred (cid,cname,a1) values ((select cid from wed_cond where cname='c1'), 'c1', 'ready');
