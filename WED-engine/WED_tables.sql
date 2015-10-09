--multiples instance of a particular wedflow

DROP TABLE IF EXISTS WED_attr;
DROP TABLE IF EXISTS WED_trace;
DROP TABLE IF EXISTS WED_flow;
DROP TABLE IF EXISTS WED_pred;
DROP TABLE IF EXISTS WED_trig;
DROP TABLE IF EXISTS WED_cond;
DROP TABLE IF EXISTS WED_trans;
--DROP SEQUENCE IF EXISTS wed_cond_cid;
--CREATE SEQUENCE wed_cond_cid;

-- An '*' means that WED-attributes columns will be added dynamicaly after an INSERT on WED-attr table
--*WED-flow instances
CREATE TABLE WED_flow (
    wid     SERIAL NOT NULL,
    PRIMARY KEY(wid)
);

--*WED-trace keeps the execution history for all instances
CREATE TABLE WED_trace (
    wid     INTEGER NOT NULL,
    timestamp   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (wid) REFERENCES WED_flow (wid) ON DELETE RESTRICT
);

CREATE TABLE WED_attr (
    aid     SERIAL NOT NULL,
    name    TEXT NOT NULL,
    default_value   TEXT NOT NULL DEFAULT ''
);
-- name must be unique 
CREATE UNIQUE INDEX wed_attr_lower_name_idx ON WED_attr (lower(name));

--WED-conditions
CREATE TABLE WED_cond (
    cid     SERIAL PRIMARY KEY, --UNIQUE NOT NULL
    cname   TEXT NOT NULL,
    cdesc   TEXT NOT NULL DEFAULT ''
);
CREATE UNIQUE INDEX wed_cond_pred_idx ON WED_cond (cid, cname);
CREATE UNIQUE INDEX wed_cond_lower_cname_idx ON WED_cond (lower(cname));

--*WED-predicatives
CREATE TABLE WED_pred (
    pid     SERIAL PRIMARY KEY,
    cid     INTEGER NOT NULL,
    cname   TEXT NOT NULL,
    FOREIGN KEY (cid, cname) REFERENCES WED_cond (cid, cname) ON DELETE RESTRICT
);

CREATE TABLE WED_trans (
    tid     SERIAL PRIMARY KEY,
    tname   TEXT NOT NULL,
    tret    JSON NOT NULL
);
CREATE UNIQUE INDEX wed_trans_lower_tname_idx ON WED_trans (lower(tname));

CREATE TABLE WED_trig (
    tgid     SERIAL PRIMARY KEY,
    cid     INTEGER REFERENCES WED_cond ON DELETE RESTRICT,
    tid     INTEGER REFERENCES WED_trans ON DELETE RESTRICT
);
    
    
