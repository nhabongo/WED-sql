-- should wed_attr domain restrictions be implemented as a foreign key on wed_flow ?
-- WED_trace could have duplicated (wid,tgid) in case of compensation ?

-- WED_pred: for a given condition c(cid,cname) in WED_cond, each row in WED_cond is a conjunction of non NULL WED_attributes
--for c. Thus, a predicate for c is the disjunction of these rows. 
-- how to insert a WED-predicative: 
--insert into wed_pred (cid,cname,a1,a2,...) values ((select cid from wed_cond where cname='nhaga'), 'nhaga', ...);

-- how to insert a new WED-attribute (if default_value is supressed, DEFAULT VALUE '')
--insert into wed_attr (name, default_value) values ('a0','vazio');

--kernel_function(): improve column name check expression
