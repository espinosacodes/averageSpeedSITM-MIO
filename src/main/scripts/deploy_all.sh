#!/bin/bash

set -e  # Salir si hay error

echo "=========================================="
echo "Desplegando SITM-MIO en todos los nodos"
echo "=========================================="
echo ""

# Verificar que el JAR existe
if [ ! -f "build/libs/averageSpeedSITM-MIO.jar" ]; then
    echo "ERROR: JAR no encontrado. Ejecuta './gradlew build' primero."
    exit 1
fi

echo "1. Desplegando Coordinador (x104m01) con StreamProcessor..."
timeout 300 ./src/main/scripts/deploy_coordinator.sh || {
    echo "ERROR: Fallo al desplegar coordinador (timeout o error)"
    exit 1
}

echo ""
echo "2. Esperando 5 segundos para que el coordinador inicie..."
sleep 5

echo ""
echo "3. Desplegando Workers (x104m02 a x104m31)..."
timeout 1800 ./src/main/scripts/deploy_all_workers.sh || {
    echo "WARNING: Algunos workers pueden no haberse desplegado correctamente"
}

echo ""
echo "4. Esperando 10 segundos para que todos los servicios inicien..."
sleep 10

echo ""
echo "5. Verificando estado del despliegue..."
timeout 120 ./src/main/scripts/check_status.sh || {
    echo "WARNING: No se pudo verificar el estado completo"
}

echo ""
echo "=========================================="
echo "Despliegue completado"
echo "=========================================="
echo ""
echo "El StreamProcessor está disponible en el coordinador (x104m01:10000)"
echo "Identidad Ice: StreamProcessor"
echo ""

