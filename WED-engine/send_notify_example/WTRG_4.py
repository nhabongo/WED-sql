import select,sys,json
import psycopg2
import psycopg2.extensions

import time

def wed_trans(tgid):
    return "a1='final'"
    
def main(argv):
    if len(argv) > 2:
        conn_str = argv[1]
        channel = argv[2]
    else:
        print('python %s <connection string> <channel to listen>' %(sys.argv[0]))
        return 1

    try:
        conn = psycopg2.connect(conn_str)
    except Exception as e:
        print(e)
        return 1
        
    conn.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_AUTOCOMMIT)

    curs = conn.cursor()
    curs.execute("LISTEN "+channel)

    print("Listening on channel '\033[32m%s\033[0m'" %(channel))
    while 1:
        if select.select([conn],[],[],5) == ([],[],[]):
            print("Timeout: still awating ...")
        else:
            conn.poll()

            while conn.notifies:
                notify = conn.notifies.pop(0)
                print("Got NOTIFY: %d, %s, %s" %(notify.pid, notify.channel, notify.payload))
                job = json.loads(notify.payload)
                
                try:
                    curs.callproc('job_lock',[job['uptkn']])
                except Exception:
                    print('Could not get a lock on job %s' %(job['uptkn']))
                else:
                    if True in curs.fetchone():
                        print('Job %s locked !' %(job['uptkn']))
                        print('Running transition ...')
                        new_wed_state = wed_trans(job['tgid']) 
                        #time.sleep(26)
                        try:
                            curs.execute("UPDATE wed_flow SET var_uptkn='"+job['uptkn']+"', "+new_wed_state+" where wid="+job['wid']+" RETURNING wid")
                        except Exception as e:
                            print ("WED-transition not completed: %s" %(e))
                        else:
                            if not curs.fetchall():
                                print("UPDATE: 0 rows affected !")
                            else:
                                print("UPDATE: wed_flow %s updated" %(job['wid']))
 
                    else:
                        print('Invalid token %s' %(job['uptkn']))

if __name__ == '__main__':
    sys.exit(main(sys.argv))
