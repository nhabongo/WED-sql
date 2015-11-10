import re
import sys

path = sys.argv[1]
worker_name = sys.argv[2]
with open(path,'r') as f:
    regex = re.compile(r"^#?(shared_preload_libraries)\s*=\s*'(.*)'")
    for l in f:
        l = l.rstrip()
        result = regex.match(l)
        if result:
            print(l.rstrip('\n'))
            workers = result.group(2).replace(' ','')
            param = result.group(1)
            if workers:
                print(param+' = \''+workers+','+worker_name+'\'')
            else:
                print(param+' = \''+worker_name+'\'')

    

