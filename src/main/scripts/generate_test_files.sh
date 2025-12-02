#!/bin/bash

SOURCE_FILE="proyecto-mio/MIO/datagrams4history.csv"
OUTPUT_DIR="proyecto-mio/MIO/test_files"
PASSWORD="swarch"
COORDINATOR_NODE="swarch@x104m01"
COORDINATOR_DIR="/home/swarch/sitm-mio"

if [ ! -f "$SOURCE_FILE" ]; then
    echo "Error: Source file $SOURCE_FILE not found"
    exit 1
fi

echo "=== Generating Test Files ==="
echo ""

mkdir -p "$OUTPUT_DIR"

# Get header from source file
HEADER=$(head -1 "$SOURCE_FILE")
TOTAL_LINES=$(wc -l < "$SOURCE_FILE" | tr -d ' ')

echo "Source file: $SOURCE_FILE"
echo "Total lines in source: $TOTAL_LINES"
echo ""

# Generate 1M datagramas file
echo "Generating 1M datagramas file..."
if [ $TOTAL_LINES -ge 1000000 ]; then
    head -1000000 "$SOURCE_FILE" > "$OUTPUT_DIR/datagrams_1M.csv"
    echo "  Created: $OUTPUT_DIR/datagrams_1M.csv ($(wc -l < $OUTPUT_DIR/datagrams_1M.csv | tr -d ' ') lines)"
else
    echo "  Warning: Source file has less than 1M lines. Repeating lines..."
    head -1 "$SOURCE_FILE" > "$OUTPUT_DIR/datagrams_1M.csv"
    tail -n +2 "$SOURCE_FILE" | head -$((TOTAL_LINES - 1)) >> "$OUTPUT_DIR/datagrams_1M.csv"
    REPEAT_COUNT=$((1000000 / (TOTAL_LINES - 1)))
    for i in $(seq 2 $REPEAT_COUNT); do
        tail -n +2 "$SOURCE_FILE" >> "$OUTPUT_DIR/datagrams_1M.csv"
    done
    head -1000000 "$OUTPUT_DIR/datagrams_1M.csv" > "$OUTPUT_DIR/datagrams_1M.csv.tmp"
    mv "$OUTPUT_DIR/datagrams_1M.csv.tmp" "$OUTPUT_DIR/datagrams_1M.csv"
    echo "  Created: $OUTPUT_DIR/datagrams_1M.csv ($(wc -l < $OUTPUT_DIR/datagrams_1M.csv | tr -d ' ') lines)"
fi

# Generate 10M datagramas file
echo "Generating 10M datagramas file..."
if [ $TOTAL_LINES -ge 10000000 ]; then
    head -10000000 "$SOURCE_FILE" > "$OUTPUT_DIR/datagrams_10M.csv"
    echo "  Created: $OUTPUT_DIR/datagrams_10M.csv ($(wc -l < $OUTPUT_DIR/datagrams_10M.csv | tr -d ' ') lines)"
else
    echo "  Warning: Source file has less than 10M lines. Repeating lines..."
    head -1 "$SOURCE_FILE" > "$OUTPUT_DIR/datagrams_10M.csv"
    tail -n +2 "$SOURCE_FILE" | head -$((TOTAL_LINES - 1)) >> "$OUTPUT_DIR/datagrams_10M.csv"
    REPEAT_COUNT=$((10000000 / (TOTAL_LINES - 1)))
    for i in $(seq 2 $REPEAT_COUNT); do
        tail -n +2 "$SOURCE_FILE" >> "$OUTPUT_DIR/datagrams_10M.csv"
    done
    head -10000000 "$OUTPUT_DIR/datagrams_10M.csv" > "$OUTPUT_DIR/datagrams_10M.csv.tmp"
    mv "$OUTPUT_DIR/datagrams_10M.csv.tmp" "$OUTPUT_DIR/datagrams_10M.csv"
    echo "  Created: $OUTPUT_DIR/datagrams_10M.csv ($(wc -l < $OUTPUT_DIR/datagrams_10M.csv | tr -d ' ') lines)"
fi

# Generate 100M datagramas file
echo "Generating 100M datagramas file..."
if [ $TOTAL_LINES -ge 100000000 ]; then
    head -100000000 "$SOURCE_FILE" > "$OUTPUT_DIR/datagrams_100M.csv"
    echo "  Created: $OUTPUT_DIR/datagrams_100M.csv ($(wc -l < $OUTPUT_DIR/datagrams_100M.csv | tr -d ' ') lines)"
else
    echo "  Warning: Source file has less than 100M lines. Repeating lines..."
    head -1 "$SOURCE_FILE" > "$OUTPUT_DIR/datagrams_100M.csv"
    tail -n +2 "$SOURCE_FILE" | head -$((TOTAL_LINES - 1)) >> "$OUTPUT_DIR/datagrams_100M.csv"
    REPEAT_COUNT=$((100000000 / (TOTAL_LINES - 1)))
    for i in $(seq 2 $REPEAT_COUNT); do
        tail -n +2 "$SOURCE_FILE" >> "$OUTPUT_DIR/datagrams_100M.csv"
    done
    head -100000000 "$OUTPUT_DIR/datagrams_100M.csv" > "$OUTPUT_DIR/datagrams_100M.csv.tmp"
    mv "$OUTPUT_DIR/datagrams_100M.csv.tmp" "$OUTPUT_DIR/datagrams_100M.csv"
    echo "  Created: $OUTPUT_DIR/datagrams_100M.csv ($(wc -l < $OUTPUT_DIR/datagrams_100M.csv | tr -d ' ') lines)"
fi

echo ""
echo "=== Copying test files to coordinator node ==="
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $COORDINATOR_NODE "mkdir -p $COORDINATOR_DIR/proyecto-mio/MIO/test_files"
sshpass -p "$PASSWORD" scp -o StrictHostKeyChecking=no "$OUTPUT_DIR"/*.csv $COORDINATOR_NODE:$COORDINATOR_DIR/proyecto-mio/MIO/test_files/

echo ""
echo "=== Test files generated and deployed ==="
echo "Files available at:"
echo "  Local: $OUTPUT_DIR/"
echo "  Remote: $COORDINATOR_NODE:$COORDINATOR_DIR/proyecto-mio/MIO/test_files/"


