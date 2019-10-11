import sys
import time

print()

j = int(sys.argv[1])
print("start" + str(j), file=sys.stdout, flush=True)

for i in range(5):
  print("noerr" + str(i), file=sys.stdout, flush=True)
  print("err" + str(i), file=sys.stderr, flush=True)
  time.sleep(1)
  if i >= j:
    j = i / 0

print("end", file=sys.stdout, flush=True)
exit(0)
