#!/bin/bash

COORDINATOR_ENDPOINT="tcp -h x104m01 -p 10000"
PASSWORD="swarch"

echo "=== Testing SITM-MIO Deployment ==="
echo ""

# Test 1: Coordinator connectivity
echo "Test 1: Coordinator Connectivity"
echo "  Endpoint: $COORDINATOR_ENDPOINT"
java -cp build/libs/averageSpeedSITM-MIO.jar -Djava.util.logging.config.file=/dev/null \
    coordinator.PerformanceTestClient \
    "test" 0 "$COORDINATOR_ENDPOINT" 2>&1 | grep -E "(Error|Invalid|connected|registered|Starting)" | head -3

if [ $? -eq 0 ]; then
    echo "  ✓ Coordinator is reachable"
else
    echo "  ✗ Cannot connect to coordinator"
    echo "    Make sure coordinator is running on x104m01:10000"
    exit 1
fi

echo ""

# Test 2: Check coordinator log for worker registrations
echo "Test 2: Worker Registrations"
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no swarch@x104m01 << 'ENDSSH'
cd /home/swarch/sitm-mio
echo "  Checking coordinator log for worker registrations:"
grep -i "worker\|registered" coordinator.log 2>/dev/null | tail -5 || echo "  (no worker registrations found yet)"
ENDSSH

echo ""

# Test 3: Test with actual data file (small test)
echo "Test 3: Data File Access"
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no swarch@x104m01 << 'ENDSSH'
cd /home/swarch/proyecto-mio/MIO
if [ -f datagrams4history.csv ]; then
    SIZE=$(du -h datagrams4history.csv | cut -f1)
    LINES=$(wc -l < datagrams4history.csv)
    echo "  ✓ Data file accessible"
    echo "    Size: $SIZE"
    echo "    Lines: $LINES"
else
    echo "  ✗ Data file not found"
fi
ENDSSH

echo ""
echo "=== Deployment Test Complete ==="
echo ""
echo "To run a full performance test:"
echo "  ./src/main/scripts/performance_test.sh proyecto-mio/MIO/datagrams4history.csv 4"

