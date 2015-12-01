import select,sys,json
import psycopg2
import psycopg2.extensions

import time

channel='2'
#dbs = "dbname='template1' user='dbuser' host='localhost' password='dbpass'"
#trgname = 'cb trigger'
dbs = "user=thread"
wed_state_str = "d2=d2::integer + 1"

def wed_state(tgid):
    global wed_state_str
    return wed_state_str
    
def wed_trans(curs, job, sleep):
    global channel
    try:
        curs.callproc('job_lock',[job['uptkn'],'W1_WTRG_'+channel])
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
                    print("UPDATE: wed_flow %d updated\n" %(job['wid']))

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
            wed_trans(curs, job, 1)
        else:
            print("Nothing to do, going back to sleep.")
            

def main(argv):
    
    global channel,dbs
    
    try:
        conn = psycopg2.connect(dbs)
    except Exception as e:
        print(e)
        return 1
        
    conn.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_AUTOCOMMIT)

    curs = conn.cursor()
    curs.execute("LISTEN WTRG_"+channel)

    print("Listening on channel '\033[32mWTRG_%s\033[0m'" %(channel))
    while 1:
        if select.select([conn],[],[],5) == ([],[],[]):
            print("Timeout: looking for pending jobs...")
            job_lookup(curs,channel)
        else:
            conn.poll()

            while conn.notifies:
                notify = conn.notifies.pop(0)
                print("\nGot NOTIFY: %d, %s, %s" %(notify.pid, notify.channel, notify.payload))
                job = json.loads(notify.payload)
                wed_trans(curs,job,1)
               
if __name__ == '__main__':
    sys.exit(main(sys.argv))
