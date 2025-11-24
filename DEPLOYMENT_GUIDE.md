# Deployment Guide - SITM-MIO Distributed System

## Prerequisites

1. **SSH Access**: Configure SSH keys for passwordless access to nodes

   ```bash
   ssh-keygen -t rsa
   ssh-copy-id swarch@x104m01
   ssh-copy-id swarch@x104m02
   # ... repeat for all nodes
   ```
2. **Java 11+** installed on all nodes
3. **ZeroC Ice 3.7+** installed on all nodes (or use the JAR with bundled dependencies)
4. **Network**: ZeroTier VPN configured and nodes can reach each other

## Step 1: Deploy Coordinator

### Option A: Automated (requires SSH keys)

```bash
./src/main/scripts/deploy_coordinator.sh
```

### Option B: Manual

```bash
# Copy files
scp build/libs/averageSpeedSITM-MIO.jar swarch@x104m01:/home/swarch/sitm-mio/
scp -r proyecto-mio/MIO swarch@x104m01:/home/swarch/sitm-mio/

# SSH and start
ssh swarch@x104m01
cd /home/swarch/sitm-mio
java -Xmx4g -jar averageSpeedSITM-MIO.jar coordinator.CoordinatorNode &
echo $! > coordinator.pid
```

### Verify Coordinator

```bash
# On x104m01
ps aux | grep CoordinatorNode
netstat -tlnp | grep 10000
```

## 523

## .Step 2: Deploy Workers

### Option A: Automated (requires SSH keys)

```bash
./src/main/scripts/deploy_all_workers.sh
```

### Option B: Manual (for specific worker)

```bash
./src/main/scripts/deploy_worker.sh worker1 swarch@x104m02 "tcp -h x104m01 -p 10000"
```

### Option C: Manual (one by one)

```bash
# For each node x104m02 to x104m31
WORKER_ID="worker02"
NODE="swarch@x104m02"
COORDINATOR="tcp -h x104m01 -p 10000"

scp build/libs/averageSpeedSITM-MIO.jar $NODE:/home/swarch/sitm-mio/
scp -r proyecto-mio/MIO $NODE:/home/swarch/sitm-mio/

ssh $NODE << EOF
cd /home/swarch/sitm-mio
java -Xmx2g -jar averageSpeedSITM-MIO.jar worker.WorkerNode $WORKER_ID "$COORDINATOR" &
echo \$! > worker_${WORKER_ID}.pid
EOF
```

## Step 3: Validate Deployment

```bash
./src/main/scripts/validate_deployment.sh
```

Or manually test:

```bash
java -cp build/libs/averageSpeedSITM-MIO.jar \
    coordinator.PerformanceTestClient \
    "test" 0 "tcp -h x104m01 -p 10000"
```

## Step 4: Run Performance Tests

```bash
# Test with 4 workers
./src/main/scripts/performance_test.sh proyecto-mio/MIO/datagrams4history.csv 4

# Test with 8 workers
./src/main/scripts/performance_test.sh proyecto-mio/MIO/datagrams4history.csv 8

# Test with 16 workers
./src/main/scripts/performance_test.sh proyecto-mio/MIO/datagrams4history.csv 16
```

## Monitoring

### Check Coordinator Status

```bash
ssh swarch@x104m01 "ps aux | grep CoordinatorNode"
```

### Check Worker Status

```bash
for i in {02..31}; do
    echo "Checking x104m$i..."
    ssh swarch@x104m$i "ps aux | grep WorkerNode"
done
```

### View Logs

```bash
# Coordinator logs
ssh swarch@x104m01 "tail -f /home/swarch/sitm-mio/coordinator.log"

# Worker logs
ssh swarch@x104m02 "tail -f /home/swarch/sitm-mio/worker_worker02.log"
```

## Troubleshooting

### Port Already in Use

```bash
# Find process using port 10000
netstat -tlnp | grep 10000
# Kill if needed
kill -9 <PID>
```

### Workers Not Connecting

- Verify coordinator is running
- Check network connectivity: `ping x104m01`
- Check firewall rules
- Verify ZeroTier VPN is active

### Out of Memory

- Increase heap size: `-Xmx4g` for coordinator, `-Xmx2g` for workers
- Reduce number of workers
- Process smaller data partitions

## Performance Testing Results

Results will be saved to:

- `performance_results_4workers.txt`
- `performance_results_8workers.txt`
- etc.

Each file contains:

- Processing time
- Throughput (datagrams/second)
- Results by arc (speed, sample count)
