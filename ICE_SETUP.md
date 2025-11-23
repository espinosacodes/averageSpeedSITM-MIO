# Ice Setup Instructions

## Prerequisites

1. Install ZeroC Ice 3.7+ from https://zeroc.com/downloads/ice
2. Ensure `slice2java` is in your PATH
3. Java 11+ installed

## Generating Ice Code

After installing Ice, generate Java code from slice files:

```bash
slice2java --output-dir src/main/slice-generated \
           --tie \
           src/main/slice/DataProcessor.ice \
           src/main/slice/GraphService.ice \
           src/main/slice/SpeedCalculator.ice \
           src/main/slice/Coordinator.ice \
           src/main/slice/StreamProcessor.ice
```

Or use the script:

```bash
./src/main/scripts/generate_ice_code.sh
```

## Building the Project

```bash
./gradlew build
```

## Running

### Coordinator Node
```bash
java -cp build/libs/averageSpeedSITM-MIO.jar coordinator.CoordinatorNode
```

### Worker Node
```bash
java -cp build/libs/averageSpeedSITM-MIO.jar worker.WorkerNode worker1 "tcp -h swarch@x104m01 -p 10000"
```

