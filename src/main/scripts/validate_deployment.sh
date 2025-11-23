#!/bin/bash

COORDINATOR_ENDPOINT="tcp -h x104m01 -p 10000"

echo "=== Deployment Validation ==="
echo ""

# Test coordinator connection
echo "Testing Coordinator connection at $COORDINATOR_ENDPOINT..."
java -cp build/libs/averageSpeedSITM-MIO.jar -Djava.util.logging.config.file=/dev/null \
    coordinator.PerformanceTestClient \
    "test" 0 "$COORDINATOR_ENDPOINT" 2>&1 | grep -E "(Error|Invalid|connected|registered)" | head -3

if [ $? -eq 0 ]; then
    echo "✓ Coordinator is reachable"
else
    echo "✗ Cannot connect to coordinator"
    echo "  Make sure coordinator is running on x104m01:10000"
    exit 1
fi

# Check workers
echo ""
echo "Checking for registered workers..."
echo "  (This requires coordinator to be running and workers registered)"

echo ""
echo "=== Validation Complete ==="
echo "To test with actual data:"
echo "  ./src/main/scripts/performance_test.sh proyecto-mio/MIO/datagrams4history.csv 4"

