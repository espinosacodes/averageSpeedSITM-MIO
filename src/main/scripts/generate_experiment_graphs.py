#!/usr/bin/env python3
"""
Script para generar gráficos de experimentos y determinar el punto de corte
para la distribución de procesamiento.
"""

import csv
import sys
import os
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
from collections import defaultdict

def parse_csv(csv_file):
    """Lee el archivo CSV y retorna los datos organizados."""
    data = defaultdict(lambda: {'nodes': [], 'time': [], 'speedup': [], 'efficiency': [], 'throughput': []})
    
    with open(csv_file, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            size = row.get('Tamaño_Datos', '').strip()
            if not size or size == 'Tamaño_Datos':
                continue
            
            try:
                nodes = int(row.get('Nodos', 0))
                time_str = row.get('Tiempo_seg', '').strip()
                speedup_str = row.get('Speedup', '').strip()
                efficiency_str = row.get('Eficiencia', '').strip()
                throughput_str = row.get('Throughput_dat_seg', '').strip()
                
                if time_str and time_str != 'N/A':
                    time = float(time_str)
                    data[size]['nodes'].append(nodes)
                    data[size]['time'].append(time)
                    
                    if speedup_str and speedup_str != 'N/A':
                        speedup = float(speedup_str.replace('%', ''))
                        data[size]['speedup'].append(speedup)
                    else:
                        data[size]['speedup'].append(None)
                    
                    if efficiency_str and efficiency_str != 'N/A':
                        efficiency = float(efficiency_str.replace('%', ''))
                        data[size]['efficiency'].append(efficiency)
                    else:
                        data[size]['efficiency'].append(None)
                    
                    if throughput_str and throughput_str != 'N/A':
                        throughput = float(throughput_str)
                        data[size]['throughput'].append(throughput)
                    else:
                        data[size]['throughput'].append(None)
            except (ValueError, KeyError) as e:
                continue
    
    return data

def find_cutoff_point(nodes, speedups, efficiencies):
    """Encuentra el punto de corte donde speedup > 1.2 y eficiencia > 60%."""
    for i, (node, speedup, efficiency) in enumerate(zip(nodes, speedups, efficiencies)):
        if speedup is not None and efficiency is not None:
            if speedup > 1.2 and efficiency > 60:
                return node, i
    return None, None

def generate_graphs(csv_file, output_dir):
    """Genera los gráficos de experimentos."""
    data = parse_csv(csv_file)
    
    if not data:
        print("No se encontraron datos válidos en el CSV")
        return None
    
    # Crear figura con subplots
    fig = plt.figure(figsize=(16, 12))
    
    # Gráfico 1: Tiempo de Procesamiento vs Número de Nodos
    ax1 = plt.subplot(2, 2, 1)
    for size in sorted(data.keys()):
        nodes = data[size]['nodes']
        times = data[size]['time']
        if nodes and times:
            sorted_data = sorted(zip(nodes, times))
            nodes_sorted, times_sorted = zip(*sorted_data)
            ax1.plot(nodes_sorted, times_sorted, marker='o', label=f'{size} datagramas', linewidth=2)
    ax1.set_xlabel('Número de Nodos', fontsize=11)
    ax1.set_ylabel('Tiempo de Procesamiento (segundos)', fontsize=11)
    ax1.set_title('Tiempo de Procesamiento vs Número de Nodos', fontsize=12, fontweight='bold')
    ax1.legend()
    ax1.grid(True, alpha=0.3)
    
    # Gráfico 2: Speedup vs Número de Nodos
    ax2 = plt.subplot(2, 2, 2)
    cutoff_points = {}
    for size in sorted(data.keys()):
        nodes = data[size]['nodes']
        speedups = data[size]['speedup']
        efficiencies = data[size]['efficiency']
        
        if nodes and speedups:
            valid_data = [(n, s, e) for n, s, e in zip(nodes, speedups, efficiencies) 
                         if s is not None and e is not None]
            if valid_data:
                sorted_data = sorted(valid_data, key=lambda x: x[0])
                nodes_sorted = [x[0] for x in sorted_data]
                speedups_sorted = [x[1] for x in sorted_data]
                efficiencies_sorted = [x[2] for x in sorted_data]
                
                ax2.plot(nodes_sorted, speedups_sorted, marker='o', label=f'{size} datagramas', linewidth=2)
                
                # Línea ideal (speedup lineal)
                if len(nodes_sorted) > 1:
                    max_nodes = max(nodes_sorted)
                    ax2.plot([1, max_nodes], [1, max_nodes], '--', color='gray', 
                            alpha=0.5, label='Speedup ideal' if size == sorted(data.keys())[0] else '')
                
                # Encontrar y marcar punto de corte
                cutoff_node, cutoff_idx = find_cutoff_point(nodes_sorted, speedups_sorted, efficiencies_sorted)
                if cutoff_node:
                    cutoff_points[size] = cutoff_node
                    ax2.plot(cutoff_node, speedups_sorted[cutoff_idx], 'r*', 
                            markersize=15, label=f'Punto de corte {size}' if size == sorted(data.keys())[0] else '')
                    ax2.annotate(f'Corte: {cutoff_node} nodos', 
                               xy=(cutoff_node, speedups_sorted[cutoff_idx]),
                               xytext=(10, 10), textcoords='offset points',
                               bbox=dict(boxstyle='round,pad=0.3', facecolor='yellow', alpha=0.7),
                               fontsize=9)
    
    ax2.set_xlabel('Número de Nodos', fontsize=11)
    ax2.set_ylabel('Speedup', fontsize=11)
    ax2.set_title('Speedup vs Número de Nodos', fontsize=12, fontweight='bold')
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    # Gráfico 3: Eficiencia vs Número de Nodos
    ax3 = plt.subplot(2, 2, 3)
    for size in sorted(data.keys()):
        nodes = data[size]['nodes']
        efficiencies = data[size]['efficiency']
        
        if nodes and efficiencies:
            valid_data = [(n, e) for n, e in zip(nodes, efficiencies) if e is not None]
            if valid_data:
                sorted_data = sorted(valid_data, key=lambda x: x[0])
                nodes_sorted = [x[0] for x in sorted_data]
                efficiencies_sorted = [x[1] for x in sorted_data]
                
                ax3.plot(nodes_sorted, efficiencies_sorted, marker='o', label=f'{size} datagramas', linewidth=2)
                
                # Línea ideal (100% eficiencia)
                if len(nodes_sorted) > 1:
                    max_nodes = max(nodes_sorted)
                    ax3.axhline(y=100, color='gray', linestyle='--', alpha=0.5, 
                               label='Eficiencia ideal' if size == sorted(data.keys())[0] else '')
    
    ax3.set_xlabel('Número de Nodos', fontsize=11)
    ax3.set_ylabel('Eficiencia (%)', fontsize=11)
    ax3.set_title('Eficiencia vs Número de Nodos', fontsize=12, fontweight='bold')
    ax3.legend()
    ax3.grid(True, alpha=0.3)
    
    # Gráfico 4: Throughput vs Número de Nodos
    ax4 = plt.subplot(2, 2, 4)
    for size in sorted(data.keys()):
        nodes = data[size]['nodes']
        throughputs = data[size]['throughput']
        
        if nodes and throughputs:
            valid_data = [(n, t) for n, t in zip(nodes, throughputs) if t is not None]
            if valid_data:
                sorted_data = sorted(valid_data, key=lambda x: x[0])
                nodes_sorted = [x[0] for x in sorted_data]
                throughputs_sorted = [x[1] for x in sorted_data]
                ax4.plot(nodes_sorted, throughputs_sorted, marker='o', label=f'{size} datagramas', linewidth=2)
    
    ax4.set_xlabel('Número de Nodos', fontsize=11)
    ax4.set_ylabel('Throughput (datagramas/segundo)', fontsize=11)
    ax4.set_title('Throughput vs Número de Nodos', fontsize=12, fontweight='bold')
    ax4.legend()
    ax4.grid(True, alpha=0.3)
    
    plt.tight_layout()
    
    # Guardar gráfico
    output_file = os.path.join(output_dir, 'experiment_graphs.png')
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    plt.close()
    
    print(f"Gráficos generados: {output_file}")
    
    # Generar gráfico específico del punto de corte
    generate_cutoff_graph(csv_file, output_dir, data, cutoff_points)
    
    return output_file, cutoff_points

def generate_cutoff_graph(csv_file, output_dir, data, cutoff_points):
    """Genera un gráfico específico para visualizar el punto de corte."""
    fig, ax = plt.subplots(figsize=(12, 8))
    
    colors = {'1M': 'blue', '10M': 'green', '100M': 'red'}
    
    for size in sorted(data.keys()):
        nodes = data[size]['nodes']
        speedups = data[size]['speedup']
        efficiencies = data[size]['efficiency']
        
        if nodes and speedups:
            valid_data = [(n, s, e) for n, s, e in zip(nodes, speedups, efficiencies) 
                         if s is not None and e is not None]
            if valid_data:
                sorted_data = sorted(valid_data, key=lambda x: x[0])
                nodes_sorted = [x[0] for x in sorted_data]
                speedups_sorted = [x[1] for x in sorted_data]
                efficiencies_sorted = [x[2] for x in sorted_data]
                
                color = colors.get(size, 'black')
                ax.plot(nodes_sorted, speedups_sorted, marker='o', label=f'{size} datagramas', 
                       linewidth=2.5, color=color, markersize=8)
                
                # Marcar punto de corte
                if size in cutoff_points:
                    cutoff_node = cutoff_points[size]
                    cutoff_idx = nodes_sorted.index(cutoff_node)
                    ax.plot(cutoff_node, speedups_sorted[cutoff_idx], 'r*', 
                           markersize=20, markeredgecolor='black', markeredgewidth=2)
                    ax.annotate(f'Punto de corte: {cutoff_node} nodos\n(Speedup: {speedups_sorted[cutoff_idx]:.2f}, '
                               f'Eficiencia: {efficiencies_sorted[cutoff_idx]:.1f}%)',
                               xy=(cutoff_node, speedups_sorted[cutoff_idx]),
                               xytext=(15, 15), textcoords='offset points',
                               bbox=dict(boxstyle='round,pad=0.5', facecolor='yellow', alpha=0.8, edgecolor='red', linewidth=2),
                               fontsize=10, fontweight='bold',
                               arrowprops=dict(arrowstyle='->', color='red', lw=2))
    
    # Línea ideal
    if data:
        max_nodes = max([max(d['nodes']) for d in data.values() if d['nodes']])
        ax.plot([1, max_nodes], [1, max_nodes], '--', color='gray', 
               alpha=0.5, linewidth=2, label='Speedup ideal (lineal)')
    
    # Línea de speedup mínimo (1.2)
    ax.axhline(y=1.2, color='orange', linestyle=':', linewidth=2, alpha=0.7, label='Speedup mínimo (1.2)')
    
    ax.set_xlabel('Número de Nodos', fontsize=13, fontweight='bold')
    ax.set_ylabel('Speedup', fontsize=13, fontweight='bold')
    ax.set_title('Punto de Corte para Distribución de Procesamiento\n(Speedup > 1.2 y Eficiencia > 60%)', 
                fontsize=14, fontweight='bold')
    ax.legend(fontsize=11, loc='best')
    ax.grid(True, alpha=0.3, linestyle='--')
    
    plt.tight_layout()
    
    output_file = os.path.join(output_dir, 'cutoff_point_graph.png')
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    plt.close()
    
    print(f"Gráfico de punto de corte generado: {output_file}")
    return output_file

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Uso: generate_experiment_graphs.py <csv_file> [output_dir]")
        sys.exit(1)
    
    csv_file = sys.argv[1]
    output_dir = sys.argv[2] if len(sys.argv) > 2 else 'docs'
    
    if not os.path.exists(csv_file):
        print(f"Error: Archivo CSV no encontrado: {csv_file}")
        sys.exit(1)
    
    os.makedirs(output_dir, exist_ok=True)
    
    output_file, cutoff_points = generate_graphs(csv_file, output_dir)
    
    if cutoff_points:
        print("\nPuntos de corte identificados:")
        for size, node in sorted(cutoff_points.items()):
            print(f"  {size} datagramas: {node} nodos")
    else:
        print("\nNo se identificaron puntos de corte (speedup > 1.2 y eficiencia > 60%)")

