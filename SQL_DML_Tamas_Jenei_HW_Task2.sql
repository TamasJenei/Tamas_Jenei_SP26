CREATE TABLE table_to_delete AS
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1,(10^7)::int) x;

SELECT *, pg_size_pretty(total_bytes) AS total,
          pg_size_pretty(index_bytes) AS INDEX,
          pg_size_pretty(toast_bytes) AS toast,
          pg_size_pretty(table_bytes) AS TABLE
FROM ( 
    SELECT *, total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes
    FROM (
        SELECT c.oid, nspname AS table_schema,
               relname AS TABLE_NAME,
               c.reltuples AS row_estimate,
               pg_total_relation_size(c.oid) AS total_bytes,
               pg_indexes_size(c.oid) AS index_bytes,
               pg_total_relation_size(reltoastrelid) AS toast_bytes
        FROM pg_class c
        LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE relkind = 'r'
    ) a
) a
WHERE table_name LIKE '%table_to_delete%';



DELETE 
FROM table_to_delete
WHERE REPLACE(col, 'veeeeeeery_long_string','')::int % 3 = 0; -- removes 1/3 of all rows


VACUUM FULL VERBOSE table_to_delete;


DROP TABLE table_to_delete;
CREATE TABLE table_to_delete AS
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1,(10^7)::int) x;

TRUNCATE table_to_delete;


/*Space consumption log
* Initial Size (10M rows): ~575 MB

*After DELETE (3.3M rows removed): ~740 MB (Size remained unchanged)

*After VACUUM FULL: ~383 MB (Physical size reduced)

*After TRUNCATE: 0 MB (Table reset to empty)
*
*--delete vs truncate comparision
*Execution Time:

      delete: Slow (approx. 23s). It scans and processes each row individually.

      truncate: Instant (milliseconds). It operates at the file system level.

Disk Space Usage:

      delete: Does not release space to the OS; it creates "dead tuples" (bloat).

      truncate: Releases all disk space immediately by re-initializing the data file.

Transaction Behavior:

       Both operations are transaction-safe in PostgreSQL.

Rollback Possibility:

       Both can be rolled back if they were executed within an active transaction block.