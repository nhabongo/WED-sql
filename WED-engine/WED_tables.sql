--multiples instance of a particular wedflow

DROP TABLE IF EXISTS WED_flow;
CREATE TABLE WED_flow (
    wid     SERIAL NOT NULL,
    PRIMARY KEY(wid)
);

DROP TABLE IF EXISTS WED_trace;
CREATE TABLE WED_trace (
    wid     INTEGER NOT NULL,
    timestamp   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (wid) REFERENCES WED_flow (wid) ON DELETE RESTRICT
);

DROP TABLE IF EXISTS WED_attr;
CREATE TABLE WED_attr (
    aid     SERIAL NOT NULL,
    name    TEXT,
    default_value   TEXT DEFAULT ''
);
-- name must be unique 
CREATE UNIQUE INDEX wed_attr_lower_name_idx ON WED_attr (lower(name));


