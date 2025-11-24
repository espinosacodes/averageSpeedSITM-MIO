#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: view_logs.sh [coordinator|worker<id>|all]"
    echo "Example: view_logs.sh coordinator"
    echo "Example: view_logs.sh worker03"
    echo "Example: view_logs.sh all"
    exit 1
fi

PASSWORD="swarch"
WHAT=$1

if [ "$WHAT" = "coordinator" ] || [ "$WHAT" = "all" ]; then
    echo "=== Coordinator Log (x104m01) ==="
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no swarch@x104m01 \
        "cd /home/swarch/sitm-mio && tail -30 coordinator.log 2>/dev/null" 2>&1 | \
        grep -v "Welcome\|Documentation\|Management\|Support\|updates\|firmware\|ESM\|Pseudo-terminal"
    echo ""
fi

if [ "$WHAT" = "all" ]; then
    echo "=== Worker Logs ==="
    for i in 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31; do
        WORKER_ID="worker$i"
        LOG=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 swarch@x104m$i \
            "cd /home/swarch/sitm-mio && tail -5 worker_${WORKER_ID}.log 2>/dev/null" 2>/dev/null)
        if [ ! -z "$LOG" ]; then
            echo "--- x104m$i ($WORKER_ID) ---"
            echo "$LOG" | grep -v "Welcome\|Documentation"
            echo ""
        fi
    done
elif [[ "$WHAT" =~ ^worker ]]; then
    WORKER_ID=$WHAT
    NODE_NUM=${WORKER_ID#worker}
    echo "=== Worker Log ($WORKER_ID on x104m$NODE_NUM) ==="
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no swarch@x104m$NODE_NUM \
        "cd /home/swarch/sitm-mio && tail -30 worker_${WORKER_ID}.log 2>/dev/null" 2>&1 | \
        grep -v "Welcome\|Documentation\|Management\|Support\|updates\|firmware\|ESM\|Pseudo-terminal"
fi

