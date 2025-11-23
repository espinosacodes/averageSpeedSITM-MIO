package output;

import graph.GraphBuilder;
import model.Arc;
import model.Route;

import java.util.*;

public class GraphPrinter {
    
    private GraphBuilder graphBuilder;
    
    public GraphPrinter(GraphBuilder graphBuilder) {
        this.graphBuilder = graphBuilder;
    }
    
    public void printArcs() {
        Set<Integer> routeIds = graphBuilder.getRouteIds();
        List<Integer> sortedRouteIds = new ArrayList<>(routeIds);
        Collections.sort(sortedRouteIds);
        
        for (Integer routeId : sortedRouteIds) {
            Route route = graphBuilder.getRoutes().get(routeId);
            if (route == null) continue;
            
            System.out.println("\n========================================");
            System.out.println("RUTA: " + route.getShortName() + " (LINEID: " + routeId + ")");
            System.out.println("DESCRIPCIÓN: " + route.getDescription());
            System.out.println("========================================");
            
            List<Arc> outboundArcs = graphBuilder.getArcsByRouteAndOrientation(routeId, 0);
            List<Arc> returnArcs = graphBuilder.getArcsByRouteAndOrientation(routeId, 1);
            
            if (!outboundArcs.isEmpty()) {
                System.out.println("\n--- IDA (ORIENTATION: 0) ---");
                printArcsForOrientation(outboundArcs);
            }
            
            if (!returnArcs.isEmpty()) {
                System.out.println("\n--- REGRESO (ORIENTATION: 1) ---");
                printArcsForOrientation(returnArcs);
            }
        }
        
        System.out.println("\n========================================");
        System.out.println("TOTAL DE ARCOS: " + graphBuilder.getArcs().size());
        System.out.println("========================================");
    }
    
    private void printArcsForOrientation(List<Arc> arcs) {
        for (Arc arc : arcs) {
            System.out.println(String.format(
                "  Secuencia %d → %d: Parada %d (%s) → Parada %d (%s)",
                arc.getFromSequence(),
                arc.getToSequence(),
                arc.getFromStop().getStopId(),
                arc.getFromStop().getLongName(),
                arc.getToStop().getStopId(),
                arc.getToStop().getLongName()
            ));
        }
    }
}

