--multiples instance of a particular wedflow

DROP TABLE IF EXISTS WED_attr;
DROP TABLE IF EXISTS WED_trace;
DROP TABLE IF EXISTS WED_flow CASCADE;
DROP TABLE IF EXISTS WED_cond;
DROP SEQUENCE IF EXISTS wed_cond_cid;

CREATE TABLE WED_flow (
    wid     SERIAL NOT NULL,
    PRIMARY KEY(wid)
);

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

CREATE TABLE WED_cond (
    uid     SERIAL NOT NULL,
    cid     INTEGER NOT NULL,
    cname   TEXT NOT NULL,
    PRIMARY KEY (uid, cid)
);
CREATE UNIQUE INDEX wed_cond_lower_name_idx ON WED_cond (lower(cname));
CREATE SEQUENCE wed_cond_cid;
