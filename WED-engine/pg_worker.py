import re
import sys

path = sys.argv[1]
worker_name = sys.argv[2]
with open(path,'r') as f:
    regex = re.compile(r"^#?(shared_preload_libraries)\s*=\s*'(.*)'")
    new_file = ''
    for l in f:
        result = regex.match(l)
        if result:
            print(l.rstrip('\n'))
            workers = result.group(2).replace(' ','')
            param = result.group(1)
            if workers:
                new_line = param+' = \''+workers+','+worker_name+'\'\n'
                new_file += new_line
                print(new_line)
            else:
                new_line = param+' = \''+worker_name+'\'\n'
                new_file += new_line
                print(new_line)
        else:
            new_file += l

with open(path,'w') as f:
    f.write(new_file)

