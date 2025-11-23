#!/bin/bash

SLICE_DIR="src/main/slice"
OUTPUT_DIR="src/main/slice-generated"

echo "Generating Ice code from slice files..."

mkdir -p $OUTPUT_DIR

slice2java --output-dir $OUTPUT_DIR --tie \
    $SLICE_DIR/DataProcessor.ice \
    $SLICE_DIR/GraphService.ice \
    $SLICE_DIR/SpeedCalculator.ice \
    $SLICE_DIR/Coordinator.ice \
    $SLICE_DIR/StreamProcessor.ice

if [ $? -eq 0 ]; then
    echo "Ice code generated successfully in $OUTPUT_DIR"
else
    echo "Error: Failed to generate Ice code. Make sure slice2java is installed and in PATH."
    exit 1
fi

