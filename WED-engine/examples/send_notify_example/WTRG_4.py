import select,sys,json
import psycopg2
import psycopg2.extensions

import time

def wed_state(tgid):
    return "a1='final'"
    
def wed_trans(curs, job, sleep):
    try:
        curs.callproc('job_lock',[job['uptkn'],'W1_WTRG_4'])
    except Exception:
        print('Could not get a lock on job %s' %(job['uptkn']))
    else:
        if True in curs.fetchone():
            print('Job %s locked !' %(job['uptkn']))
            print('Running transition ...')
            new_wed_state = wed_state(job['tgid']) 
            time.sleep(sleep)
            try:
                curs.execute("UPDATE wed_flow SET var_uptkn='"+job['uptkn']+"', "+new_wed_state+" where wid="+str(job['wid'])+" RETURNING wid")
            except Exception as e:
                print ("WED-transition not completed: %s" %(e))
            else:
                if not curs.fetchall():
                    print("UPDATE: 0 rows affected !")
                else:
                    print("UPDATE: wed_flow %d updated" %(job['wid']))

        else:
            print('Invalid token %s' %(job['uptkn']))

def job_lookup(curs,tgid):
    try:
        curs.execute('SELECT tgid, wid, uptkn from job_pool WHERE tgid='+tgid+' AND NOT locked LIMIT 1')
    except Exception as e:
        print ('job_pool scan error: %s' %(e))
    else:
        data = curs.fetchone()
        if data:
            job = dict()
            job['tgid'], job['wid'], job['uptkn'] = data
            wed_trans(curs, job, 5)
        else:
            print("Nothing to do, going back to sleep.")
            

def main(argv):
    if len(argv) > 2:
        conn_str = argv[1]
        tgid = argv[2]
    else:
        print('python %s <connection string> <channel to listen (tgid)>' %(sys.argv[0]))
        return 1

    try:
        conn = psycopg2.connect(conn_str)
    except Exception as e:
        print(e)
        return 1
        
    conn.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_AUTOCOMMIT)

    curs = conn.cursor()
    curs.execute("LISTEN WTRG_"+tgid)

    print("Listening on channel '\033[32mWTRG_%s\033[0m'" %(tgid))
    while 1:
        if select.select([conn],[],[],5) == ([],[],[]):
            print("Timeout: looking for pending jobs...")
            job_lookup(curs,tgid)
        else:
            conn.poll()

            while conn.notifies:
                notify = conn.notifies.pop(0)
                print("Got NOTIFY: %d, %s, %s" %(notify.pid, notify.channel, notify.payload))
                job = json.loads(notify.payload)
                wed_trans(curs,job,26)
               

if __name__ == '__main__':
    sys.exit(main(sys.argv))
