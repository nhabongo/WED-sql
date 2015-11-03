--multiples instance of a particular wedflow

DROP TABLE IF EXISTS WED_attr;
DROP TABLE IF EXISTS WED_trace;
DROP TABLE IF EXISTS WED_pred;
DROP TABLE IF EXISTS JOB_POOL;
DROP TABLE IF EXISTS WED_trig;
DROP TABLE IF EXISTS WED_cond;
DROP TABLE IF EXISTS WED_trans;
DROP TABLE IF EXISTS ST_STATUS;
DROP TABLE IF EXISTS WED_flow CASCADE;
--DROP SEQUENCE IF EXISTS wed_cond_cid;
--CREATE SEQUENCE wed_cond_cid;

-- An '*' means that WED-attributes columns will be added dynamicaly after an INSERT on WED-attr table
--*WED-flow instances
CREATE TABLE WED_flow (
    wid     SERIAL NOT NULL,
    var_uptkn     TEXT DEFAULT NULL,
    PRIMARY KEY(wid)
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
    final   BOOL NOT NULL DEFAULT FALSE,
    cname   TEXT NOT NULL,
    cdesc   TEXT NOT NULL DEFAULT ''
);
CREATE UNIQUE INDEX wed_cond_lower_cname_idx ON WED_cond (lower(cname));
CREATE UNIQUE INDEX wed_cond_final_idx ON WED_cond (final) WHERE final is TRUE;


--*WED-predicatives
CREATE TABLE WED_pred (
    pid     SERIAL PRIMARY KEY,
    cid     INTEGER NOT NULL,
    FOREIGN KEY (cid) REFERENCES WED_cond (cid) ON DELETE CASCADE
);

CREATE TABLE WED_trans (
    trid     SERIAL PRIMARY KEY,
    trname   TEXT NOT NULL,
    trdesc    TEXT NOT NULL DEFAULT 11
);
CREATE UNIQUE INDEX wed_trans_lower_tname_idx ON WED_trans (lower(trname));

-- use wed_pred to allow two or more diferent conditions to fire the same transition
CREATE TABLE WED_trig (
    tgid     SERIAL PRIMARY KEY,
    tgname  TEXT NOT NULL DEFAULT 'anonymous',
    cid     INTEGER NOT NULL,
    trid     INTEGER NOT NULL,
    tout    INTERVAL DEFAULT '01:00',
    FOREIGN KEY (trid) REFERENCES WED_trans (trid) ON DELETE RESTRICT,
    FOREIGN KEY (cid) REFERENCES WED_cond (cid) ON DELETE RESTRICT
);
CREATE INDEX wed_trig_cid_idx ON WED_trig (cid);
CREATE UNIQUE INDEX wed_trig_trid_idx ON WED_trig (trid);

--Running transitions (set locked and ti)
CREATE TABLE JOB_POOL (
    tgid    INTEGER NOT NULL ,
    wid     INTEGER NOT NULL ,
    uptkn   TEXT NOT NULL,
    lckid   TEXT,
    locked  BOOL NOT NULL DEFAULT FALSE,    
    tout    INTERVAL NOT NULL,
    ti      TIMESTAMP DEFAULT NULL,
    tf      TIMESTAMP DEFAULT NULL,
    FOREIGN KEY (tgid) REFERENCES WED_trig (tgid) ON DELETE RESTRICT,
    FOREIGN KEY (wid) REFERENCES WED_flow (wid) ON DELETE RESTRICT
);     
CREATE UNIQUE INDEX trg_pool_itkn_idx ON JOB_POOL (lower(uptkn));

--Fast final WED-state detection
CREATE TABLE ST_STATUS (
    wid     INTEGER PRIMARY KEY,
    final   BOOL NOT NULL DEFAULT FALSE,
    excpt   BOOL NOT NULL DEFAULT FALSE,
    FOREIGN KEY (wid) REFERENCES WED_flow (wid) ON DELETE RESTRICT
);

--*WED-trace keeps the execution history for all instances
CREATE TABLE WED_trace (
    wid     INTEGER,
    tgid_wrote    INTEGER DEFAULT NULL,
    tgid_fired    INTEGER[] DEFAULT NULL,
    final    BOOL NOT NULL DEFAULT FALSE,
    excpt    BOOL NOT NULL DEFAULT FALSE,
    tstmp      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (wid) REFERENCES WED_flow (wid) ON DELETE RESTRICT,
    FOREIGN KEY (tgid_wrote) REFERENCES WED_trig (tgid) ON DELETE RESTRICT
);
