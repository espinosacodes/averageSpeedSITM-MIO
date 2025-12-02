package calculator;

import graph.GraphBuilder;
import model.Arc;
import model.Datagram;
import model.SpeedResult;
import model.Stop;

import java.util.*;
import java.util.stream.Collectors;

public class SpeedCalculator {
    
    private GraphBuilder graphBuilder;
    private Map<Integer, List<Arc>> arcsByRoute;
    private static final double MAX_DISTANCE_TO_ARC = 0.1;
    
    //Dependency Injection
    public SpeedCalculator(GraphBuilder graphBuilder) {
        this.graphBuilder = graphBuilder;
        buildArcIndex();
    }
    
    private void buildArcIndex() {
        arcsByRoute = new HashMap<>();
        for (Arc arc : graphBuilder.getArcs()) {
            arcsByRoute.computeIfAbsent(arc.getRouteId(), k -> new ArrayList<>()).add(arc);
        }
    }
    
    //strategy pattern para calcular la velocidad de los arcos
    public Map<Integer, SpeedResult> calculateSpeeds(List<Datagram> datagrams) {
        Map<Integer, List<Datagram>> datagramsByRoute = datagrams.stream()
            .filter(d -> d.getLineId() > 0)
            .collect(Collectors.groupingBy(Datagram::getLineId));
        
        Map<Integer, SpeedResult> results = new HashMap<>();
        
        for (Map.Entry<Integer, List<Datagram>> entry : datagramsByRoute.entrySet()) {
            int routeId = entry.getKey();
            List<Datagram> routeDatagrams = entry.getValue();
            List<Arc> routeArcs = arcsByRoute.getOrDefault(routeId, new ArrayList<>());
            
            Map<Integer, List<Datagram>> datagramsByTrip = routeDatagrams.stream()
                .filter(d -> d.getTripId() > 0)
                .collect(Collectors.groupingBy(Datagram::getTripId));
            
            for (List<Datagram> tripDatagrams : datagramsByTrip.values()) {
                tripDatagrams.sort(Comparator.comparing(d -> d.getTimestamp() != null ? d.getTimestamp() : 
                    java.time.LocalDateTime.MIN));
                
                processTrip(tripDatagrams, routeArcs, results);
            }
        }
        
        return results;
    }
    
    private void processTrip(List<Datagram> tripDatagrams, List<Arc> routeArcs, 
                            Map<Integer, SpeedResult> results) {
        if (tripDatagrams.size() < 2) return;
        
        for (int i = 0; i < tripDatagrams.size() - 1; i++) {
            Datagram from = tripDatagrams.get(i);
            Datagram to = tripDatagrams.get(i + 1);
            
            if (from.getTimestamp() == null || to.getTimestamp() == null) continue;
            
            Arc matchedArc = findMatchingArc(from, to, routeArcs);
            if (matchedArc != null) {
                double distance = calculateArcDistance(matchedArc);
                long timeSeconds = java.time.Duration.between(from.getTimestamp(), to.getTimestamp()).getSeconds();
                
                if (timeSeconds > 0 && distance > 0) {
                    double speedKmh = (distance / 1000.0) / (timeSeconds / 3600.0);
                    
                    if (speedKmh > 0 && speedKmh < 200) {
                        SpeedResult result = results.computeIfAbsent(matchedArc.hashCode(), 
                            k -> new SpeedResult(matchedArc.hashCode()));
                        result.addSample(speedKmh, distance, timeSeconds);
                    }
                }
            }
        }
    }
    
    private Arc findMatchingArc(Datagram from, Datagram to, List<Arc> routeArcs) {
        Arc bestMatch = null;
        double bestScore = Double.MAX_VALUE;
        
        for (Arc arc : routeArcs) {
            Stop fromStop = graphBuilder.getStops().get(arc.getFromStop().getStopId());
            Stop toStop = graphBuilder.getStops().get(arc.getToStop().getStopId());
            
            if (fromStop == null || toStop == null) continue;
            
            double fromDist = from.distanceTo(fromStop.getLatitude(), fromStop.getLongitude());
            double toDist = to.distanceTo(toStop.getLatitude(), toStop.getLongitude());
            
            double totalDist = fromDist + toDist;
            
            if (totalDist < bestScore && totalDist < MAX_DISTANCE_TO_ARC * 1000) {
                bestScore = totalDist;
                bestMatch = arc;
            }
        }
        
        return bestMatch;
    }
    
    private double calculateArcDistance(Arc arc) {
        Stop fromStop = graphBuilder.getStops().get(arc.getFromStop().getStopId());
        Stop toStop = graphBuilder.getStops().get(arc.getToStop().getStopId());
        
        if (fromStop == null || toStop == null) return 0.0;
        
        return fromStop.getLatitude() != 0 && fromStop.getLongitude() != 0 &&
               toStop.getLatitude() != 0 && toStop.getLongitude() != 0 ?
               calculateHaversineDistance(fromStop.getLatitude(), fromStop.getLongitude(),
                                        toStop.getLatitude(), toStop.getLongitude()) : 0.0;
    }
    
    private double calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
        final int R = 6371000;
        double lat1Rad = Math.toRadians(lat1);
        double lat2Rad = Math.toRadians(lat2);
        double deltaLat = Math.toRadians(lat2 - lat1);
        double deltaLon = Math.toRadians(lon2 - lon1);
        
        double a = Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2) +
                   Math.cos(lat1Rad) * Math.cos(lat2Rad) *
                   Math.sin(deltaLon / 2) * Math.sin(deltaLon / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        
        return R * c;
    }
    
    public SpeedResult calculateSpeedForArc(int arcId, List<Datagram> datagrams) {
        Map<Integer, SpeedResult> allResults = calculateSpeeds(datagrams);
        return allResults.getOrDefault(arcId, new SpeedResult(arcId));
    }
}

