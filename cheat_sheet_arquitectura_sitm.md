# CHEAT SHEET - Arquitectura SITM-MIO

## 📊 NÚMEROS CLAVE
- **Buses actuales**: 1000 → **Proyección**: 2500
- **Eventos/día**: 2.5M - 3M
- **Pasajeros/día**: 450,000
- **Controladores**: 40
- **Sensores/bus**: 40
- **Frecuencia transmisión**: 30 segundos (vía GPRS)

---

## 🏗️ ARQUITECTURA EN 5 NODOS

### 1️⃣ NODO BUS
```
┌────────────────┐
│  GestorEventos │ → Captura eventos (GPS, averías, etc.)
│     UIBus      │ → Perilla de seguridad para conductor
└───────┬────────┘
        │ GPRS
        ↓
```

### 2️⃣ NODO CENTRAL (CEREBRO) ⭐
```
┌─────────────────────────────────────┐
│       ProcesadorCentral (Mediador)  │
├─────────────────────────────────────┤
│ • GestorRecepcionDatos              │ → Recibe datagramas
│ • GestorAnalisisEstimaciones        │ → Calcula velocidades
│ • GestorSincronizacionActualizacion │ → Notifica cambios
│ • GestorUsuariosSeguridad           │ → Autenticación
│ • GestorZonasRutas                  │ → Asignaciones
│ • ComunicacionExterna               │ → APIs
└─────────────────────────────────────┘
```

### 3️⃣ NODO MONITOREO
```
┌──────────────────┐
│  GestorMonitoreo │ → Recibe actualizaciones
│   UIMonitoreo    │ → Dashboard para 40 controladores
└──────────────────┘
Muestra: zonas, velocidades por arco, buses en tiempo real
```

### 4️⃣ NODO CONSULTAS
```
┌──────────────────┐
│ GestorConsultas  │ → API pública
│  UIConsultas     │ → Web para ciudadanos
└──────────────────┘
Provee: estado del sistema, estimaciones de tiempo
```

### 5️⃣ NODO BASE DE DATOS
```
┌──────────────┐
│  GestorBD    │ → Persistencia centralizada
└──────────────┘
Almacena: eventos históricos, usuarios, zonas, métricas
```

---

## 🔄 FLUJOS DE DATOS CRÍTICOS

### Flujo 1: Datagrama del Bus
```
Bus → GestorEventos → GPRS 
  → GestorRecepcionDatos → ProcesadorCentral 
  → GestorBD (guardar) 
  → GestorSincronizacionActualizacion 
  → GestorMonitoreo (actualizar pantalla)
```

### Flujo 2: Visualizar Zona
```
Controlador → UIMonitoreo → GestorMonitoreo 
  → ProcesadorCentral → GestorAnalisisEstimaciones 
  → GestorBD (consultar históricos) 
  → Calcular velocidad promedio 
  → UIMonitoreo (mostrar mapa + velocidades)
```

### Flujo 3: Consulta Ciudadano
```
Ciudadano → UIConsultas → GestorConsultas 
  → ProcesadorCentral → GestorAnalisisEstimaciones 
  → GestorBD → Retornar estimación
```

---

## 🎯 CASOS DE USO PRINCIPALES

### CU1: Visualizar Análisis de Movilidad por Zona
**Actor**: Controlador de operación
**Pasos**:
1. Selecciona "visualizar zonas"
2. Sistema verifica permisos ✓
3. Muestra zonas asignadas
4. Selecciona zona específica
5. Sistema calcula velocidad promedio por arco
6. Muestra mapa + velocidades + alertas

**Sub-casos**: Obtener velocidad, Calcular estimación de ruta, Registrar evento

### CU2: Consultar Estado del Sistema
**Actor**: Ciudadano/Empresa
**Pasos**:
1. Accede a interfaz pública
2. Selecciona "consultar estado"
3. Sistema muestra estado + rutas + estimaciones

**Sub-casos**: Obtener estado, Seleccionar ruta, Mostrar estimación

---

## 🧩 PATRONES DE DISEÑO APLICADOS

| Patrón | Componente | Propósito |
|--------|-----------|-----------|
| **Mediator** | ProcesadorCentral | Coordina todos los gestores sin acoplamiento directo |
| **Observer/Pub-Sub** | GestorSincronizacionActualizacion | Notifica cambios a nodo de monitoreo |
| **Repository** | GestorBD | Abstrae acceso a datos |
| **Layered** | Todos los nodos | UI → Lógica → Servicios → Datos |
| **SOA** | Entre nodos | Servicios independientes comunicándose |

---

## 📋 TARJETAS CRC - TOP 5

### 1. ProcesadorCentral ⭐⭐⭐
**Responsabilidades**:
- Coordinar TODOS los flujos del nodo central
- Delegar tareas a gestores especializados
- Punto central de orquestación

**Colaboradores**: Todos los gestores del nodo central

---

### 2. GestorAnalisisEstimaciones
**Responsabilidades**:
- Calcular velocidades promedio por arco
- Estimar tiempos de viaje
- Combinar datos históricos + tiempo real

**Colaboradores**: ProcesadorCentral, GestorBD

---

### 3. GestorSincronizacionActualizacion
**Responsabilidades**:
- Actualizar BD en tiempo real
- Notificar al nodo de monitoreo

**Colaboradores**: ProcesadorCentral, GestorMonitoreo, GestorBD

---

### 4. GestorRecepcionDatos
**Responsabilidades**:
- Recibir datagramas de buses (punto de entrada)
- Buffer/cola para alto volumen

**Colaboradores**: ProcesadorCentral, GestorEventos (bus)

---

### 5. GestorEventos (del Bus)
**Responsabilidades**:
- Capturar eventos de sensores
- Permitir registro manual (perilla)
- Asignar categoría y prioridad

**Colaboradores**: UIBus, GestorRecepcionDatos (central)

---

## 🚀 DECISIONES DE DISEÑO - JUSTIFICACIÓN

### ¿Por qué distribuida?
✅ **Escalabilidad**: De 1000 a 2500 buses
✅ **Separación**: Buses ≠ Procesamiento ≠ Visualización ≠ Consultas
✅ **Tolerancia a fallos**: Nodo caído ≠ sistema caído
✅ **Rendimiento**: Procesamiento paralelo de 2.5M eventos/día

### ¿Por qué ProcesadorCentral mediador?
✅ Evita acoplamiento NxN entre componentes
✅ Facilita agregar nuevos gestores
✅ Logging y monitoreo centralizado
✅ Lógica de orquestación compleja

### ¿Por qué BD centralizada?
✅ Consistencia de datos
✅ Análisis requieren datos históricos completos
✅ Transacciones simplificadas
⚠️ Futuro: considerar sharding por zona

### ¿Procesamiento tiempo real o batch?
✅ **HÍBRIDO**:
- **Tiempo real**: Posiciones, eventos críticos
- **Análisis periódico**: Velocidades promedio con históricos
- **Incremental**: Nuevos datos ajustan métricas

---

## 🔑 REQUERIMIENTOS FUNCIONALES - RESUMEN

| ID | Categoría | Descripción Corta |
|----|-----------|-------------------|
| RF1 | Eventos | Buses generan eventos automáticos/manuales con prioridad |
| RF2 | Seguridad | Perilla giratoria para eventos (seguridad vial) |
| RF3 | Usuarios | Admin de roles, usuarios, permisos |
| RF4 | Visualización | Mapa tiempo real con todos los buses |
| RF5 | Datos | Recibir y persistir 2.5M-3M eventos/día |
| RF6 | Análisis | Calcular velocidades promedio por arco |
| RF7 | Asignación | Asignar zonas/rutas a controladores |
| RF8 | Monitoreo | 40 controladores ven sus zonas + velocidades |
| RF9 | Auth | Login/logout para usuarios |
| RF10 | Escalabilidad | Adaptarse al crecimiento (→ 2500 buses) |
| RF11 | Disponibilidad | Procesar eventos sin afectar disponibilidad |
| RF12 | API Pública | Consultas para ciudadanos/empresas |

---

## 🎓 PREGUNTAS RÁPIDAS DE REPASO

**Q**: ¿Cuál es el componente más importante del nodo central?
**A**: **ProcesadorCentral** - es el mediador que coordina todo

**Q**: ¿Cómo llega un datagrama del bus al monitoreo?
**A**: Bus → GPRS → GestorRecepcionDatos → ProcesadorCentral → GestorBD → GestorSincronización → GestorMonitoreo

**Q**: ¿Qué patrón usa el ProcesadorCentral?
**A**: **Patrón Mediator**

**Q**: ¿Cuántos eventos por día maneja el sistema?
**A**: **2.5M - 3M eventos/día**

**Q**: ¿Por qué la perilla en lugar de touchscreen?
**A**: **Seguridad vial** - conductor no desvía vista de la carretera

**Q**: ¿Qué nodo contacta el ciudadano para consultas?
**A**: **Nodo de Consultas** (API pública)

**Q**: ¿Quién notifica al monitoreo de cambios?
**A**: **GestorSincronizacionActualizacion**

**Q**: ¿Dónde se calculan las velocidades promedio?
**A**: **GestorAnalisisEstimaciones** (nodo central)

---

## 📐 DIAGRAMA MENTAL SIMPLIFICADO

```
                    ┌─────────────┐
                    │    BUS      │
                    │ (Eventos)   │
                    └──────┬──────┘
                           │ GPRS
                           ↓
    ┌──────────────────────────────────────┐
    │         NODO CENTRAL                 │
    │  ┌────────────────────────────┐      │
    │  │   ProcesadorCentral        │      │
    │  │   (Mediador Maestro)       │      │
    │  └──┬─────┬─────┬─────┬────┬──┘      │
    │     │     │     │     │    │         │
    │  Recep  Anál  Sync  Usr  Zonas       │
    └─────┼─────┼─────┼─────────────────────┘
          │     │     │
          ↓     ↓     ↓
      ┌──────┐ ┌──────────┐ ┌──────────┐
      │  BD  │ │ MONITOR  │ │ CONSULTAS│
      │      │ │ (40 ops) │ │ (público)│
      └──────┘ └──────────┘ └──────────┘
```

---

## ✅ CHECKLIST ANTES DEL EXAMEN

- [ ] Puedo dibujar el deployment diagram de memoria
- [ ] Sé explicar el rol de cada nodo
- [ ] Conozco los 5 gestores principales del nodo central
- [ ] Entiendo el flujo completo de un datagrama
- [ ] Puedo explicar por qué se eligió arquitectura distribuida
- [ ] Sé qué patrón usa ProcesadorCentral y por qué
- [ ] Conozco los 2 casos de uso principales y sus flujos
- [ ] Puedo explicar las tarjetas CRC de 3 componentes
- [ ] Sé justificar cada decisión de diseño
- [ ] Memoricé los números clave (2.5M eventos, 1000→2500 buses, etc.)

---

## 💡 TIP FINAL

**La clave del diseño**: 
> "Nodos especializados comunicándose vía servicios, coordinados por un ProcesadorCentral mediador, para manejar millones de eventos de forma escalable y tolerante a fallos."

Si puedes explicar esa frase con ejemplos concretos de tu diseño, ¡estás listo! 🎯

---

**Última revisión**: Octubre 2025
**Proyecto**: Arquitectura SITM-MIO
**Estudiantes**: Santiago Espinosa, Juan Esteban Gómez
