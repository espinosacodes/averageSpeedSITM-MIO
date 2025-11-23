package graph;

import model.Arc;
import model.LineStop;
import model.Route;
import model.Stop;

import java.util.*;
import java.util.stream.Collectors;

public class GraphBuilder {
    
    private Map<Integer, Route> routes;
    private Map<Integer, Stop> stops;
    private List<LineStop> lineStops;
    private List<Arc> arcs;
    
    public GraphBuilder(List<Route> routes, List<Stop> stops, List<LineStop> lineStops) {
        this.routes = routes.stream().collect(Collectors.toMap(Route::getLineId, r -> r));
        this.stops = stops.stream().collect(Collectors.toMap(Stop::getStopId, s -> s));
        this.lineStops = lineStops;
        this.arcs = new ArrayList<>();
        buildGraph();
    }
    
    private void buildGraph() {
        Map<String, List<LineStop>> grouped = lineStops.stream()
            .collect(Collectors.groupingBy(ls -> ls.getLineId() + "_" + ls.getOrientation()));
        
        for (Map.Entry<String, List<LineStop>> entry : grouped.entrySet()) {
            List<LineStop> sequence = entry.getValue();
            sequence.sort(Comparator.comparingInt(LineStop::getStopSequence));
            
            for (int i = 0; i < sequence.size() - 1; i++) {
                LineStop from = sequence.get(i);
                LineStop to = sequence.get(i + 1);
                
                Stop fromStop = stops.get(from.getStopId());
                Stop toStop = stops.get(to.getStopId());
                
                if (fromStop != null && toStop != null) {
                    Arc arc = new Arc(fromStop, toStop, from.getLineId(), 
                                     from.getOrientation(), from.getStopSequence(), to.getStopSequence());
                    arcs.add(arc);
                }
            }
        }
    }
    
    public List<Arc> getArcs() {
        return arcs;
    }
    
    public Map<Integer, Route> getRoutes() {
        return routes;
    }
    
    public Map<Integer, Stop> getStops() {
        return stops;
    }
    
    public List<Arc> getArcsByRouteAndOrientation(int routeId, int orientation) {
        return arcs.stream()
            .filter(arc -> arc.getRouteId() == routeId && arc.getOrientation() == orientation)
            .sorted(Comparator.comparingInt(Arc::getFromSequence))
            .collect(Collectors.toList());
    }
    
    public Set<Integer> getRouteIds() {
        return arcs.stream()
            .map(Arc::getRouteId)
            .collect(Collectors.toSet());
    }
}

