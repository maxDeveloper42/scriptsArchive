#!/bin/bash
set -euo pipefail

# retry config
MAX_RETRY=20
SLEEP_SEC=15
COUNT=0

# log file
LOGFILE="west_sdk_install.log"

echo "=== west sdk install retry script, log to $LOGFILE ==="
nohup bash -c "
while true; do
  COUNT=\$((COUNT+1))
  echo \"[\$(date)] Attempt \$COUNT / $MAX_RETRY\" >> $LOGFILE
  if west sdk install >> $LOGFILE 2>&1; then
    echo \"[\$(date)] SUCCESS\" >> $LOGFILE
    exit 0
  fi
  echo \"[\$(date)] FAILED, sleep $SLEEP_SEC sec\" >> $LOGFILE
  if [ \$COUNT -ge $MAX_RETRY ]; then
    echo \"[\$(date)] MAX RETRY REACHED, exit\" >> $LOGFILE
    exit 1
  fi
  sleep $SLEEP_SEC
done
" > $LOGFILE 2>&1 &

echo "Background job started, PID: $!"
echo "tail -f $LOGFILE to watch progress"

