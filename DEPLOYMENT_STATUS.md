# Deployment Status and Testing Guide

## Quick Commands

### Check Status
```bash
./src/main/scripts/check_status.sh
```

### View Logs
```bash
# Coordinator log
./src/main/scripts/view_logs.sh coordinator

# Specific worker log
./src/main/scripts/view_logs.sh worker03

# All logs
./src/main/scripts/view_logs.sh all
```

### Stop All Services
```bash
./src/main/scripts/stop_all.sh
```

### Test Deployment
```bash
./src/main/scripts/test_deployment.sh
```

## Current Deployment

- **Coordinator**: Running on x104m01:10000
- **Workers**: Deploy to x104m03-x104m31 as needed
- **Data Files**: Located at /home/swarch/proyecto-mio/MIO/ on each node

## Testing Workflow

1. **Check Status**: `./src/main/scripts/check_status.sh`
2. **View Coordinator Log**: `./src/main/scripts/view_logs.sh coordinator`
3. **Check Worker Registration**: Look for "[STATUS]" messages in coordinator log
4. **Run Performance Test**: `./src/main/scripts/performance_test.sh proyecto-mio/MIO/datagrams4history.csv 4`

## Troubleshooting

- **Workers not connecting**: Check worker logs with `view_logs.sh worker<id>`
- **Coordinator not responding**: Check coordinator log and port 10000
- **File not found errors**: Ensure CSV files are in proyecto-mio/MIO/ on each node

