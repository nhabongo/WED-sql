import select
import psycopg2
import psycopg2.extensions

conn = psycopg2.connect('user=wedflow dbname=wedflow')
conn.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_AUTOCOMMIT)

curs = conn.cursor()
curs.execute("LISTEN NEW_JOB")

print("Waiting for notifications on channel 'NEW_JOB'")
while 1:
    if select.select([conn],[],[],5) == ([],[],[]):
        print("Timeout")
    else:
        conn.poll()
        while conn.notifies:
            notify = conn.notifies.pop(0)
            print("Got NOTIFY: %d, %s, %s" %(notify.pid, notify.channel, notify.payload))
