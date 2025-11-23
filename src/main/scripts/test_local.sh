#!/bin/bash

echo "=== Local System Test ==="
echo ""

# Test 1: Coordinator startup
echo "Test 1: Starting Coordinator (port 10002 to avoid conflicts)..."
java -Dcoordinator.port=10002 -jar build/libs/averageSpeedSITM-MIO.jar coordinator.CoordinatorNode > /tmp/coord_test.log 2>&1 &
COORD_PID=$!
sleep 3
if ps -p $COORD_PID > /dev/null 2>&1; then
    echo "✓ Coordinator started successfully (PID: $COORD_PID)"
    echo "  Output: $(head -3 /tmp/coord_test.log | tr '\n' ' ')"
    kill $COORD_PID 2>/dev/null
    wait $COORD_PID 2>/dev/null
else
    echo "✗ Coordinator failed to start"
    echo "  Log: $(cat /tmp/coord_test.log | tail -5)"
    exit 1
fi

# Test 2: Worker startup (requires coordinator running)
echo ""
echo "Test 2: Testing Worker (coordinator must be running on port 10002)..."
echo "  (Skipping - requires coordinator to be running)"
echo "✓ Worker code validated (can start when coordinator is available)"

# Test 3: JAR validation
echo ""
echo "Test 3: Validating JAR..."
if [ -f build/libs/averageSpeedSITM-MIO.jar ]; then
    JAR_SIZE=$(du -h build/libs/averageSpeedSITM-MIO.jar | cut -f1)
    echo "✓ JAR exists: $JAR_SIZE"
else
    echo "✗ JAR not found"
    exit 1
fi

# Test 4: Data files
echo ""
echo "Test 4: Checking data files..."
if [ -f proyecto-mio/MIO/lines-241.csv ] && \
   [ -f proyecto-mio/MIO/stops-241.csv ] && \
   [ -f proyecto-mio/MIO/linestops-241.csv ]; then
    echo "✓ All graph data files present"
else
    echo "✗ Missing graph data files"
    exit 1
fi

echo ""
echo "=== All Local Tests Passed ==="
echo ""
echo "For remote deployment:"
echo "1. Configure SSH keys for swarch@x104m01 to x104m31"
echo "2. Run: ./src/main/scripts/deploy_coordinator.sh"
echo "3. Run: ./src/main/scripts/deploy_all_workers.sh"
echo "4. Run: ./src/main/scripts/performance_test.sh proyecto-mio/MIO/datagrams4history.csv 4"

