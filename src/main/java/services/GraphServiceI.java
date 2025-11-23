package services;

import graph.GraphBuilder;
import model.Arc;
import model.Stop;
import SITM.*;
import com.zeroc.Ice.Current;

import java.util.ArrayList;
import java.util.List;

public class GraphServiceI implements GraphService {
    
    private GraphBuilder graphBuilder;
    
    public GraphServiceI(GraphBuilder graphBuilder) {
        this.graphBuilder = graphBuilder;
    }
    
    @Override
    public SITM.Arc[] getAllArcs(Current current) throws GraphException {
        try {
            List<model.Arc> arcs = graphBuilder.getArcs();
            return convertArcs(arcs);
        } catch (java.lang.Exception e) {
            throw new GraphException("Error getting arcs: " + e.getMessage());
        }
    }
    
    @Override
    public SITM.Arc[] getArcsByRoute(int routeId, int orientation, Current current) throws GraphException {
        try {
            List<model.Arc> arcs = graphBuilder.getArcsByRouteAndOrientation(routeId, orientation);
            return convertArcs(arcs);
        } catch (java.lang.Exception e) {
            throw new GraphException("Error getting arcs by route: " + e.getMessage());
        }
    }
    
    @Override
    public SITM.Arc findArcByStops(int fromStopId, int toStopId, int routeId, Current current) 
            throws GraphException {
        try {
            List<model.Arc> arcs = graphBuilder.getArcs();
            for (model.Arc arc : arcs) {
                if (arc.getRouteId() == routeId &&
                    arc.getFromStop().getStopId() == fromStopId &&
                    arc.getToStop().getStopId() == toStopId) {
                    return convertArc(arc);
                }
            }
            throw new GraphException("Arc not found");
        } catch (GraphException e) {
            throw e;
        } catch (java.lang.Exception e) {
            throw new GraphException("Error finding arc: " + e.getMessage());
        }
    }
    
    @Override
    public int findNearestArc(double latitude, double longitude, int routeId, Current current) 
            throws GraphException {
        try {
            List<Arc> arcs = graphBuilder.getArcsByRouteAndOrientation(routeId, 0);
            double minDistance = Double.MAX_VALUE;
            int nearestArcId = -1;
            
            for (Arc arc : arcs) {
                Stop fromStop = arc.getFromStop();
                Stop toStop = arc.getToStop();
                
                double dist1 = calculateDistance(latitude, longitude, 
                                                fromStop.getLatitude(), fromStop.getLongitude());
                double dist2 = calculateDistance(latitude, longitude,
                                                toStop.getLatitude(), toStop.getLongitude());
                double avgDist = (dist1 + dist2) / 2.0;
                
                if (avgDist < minDistance) {
                    minDistance = avgDist;
                    nearestArcId = arc.hashCode();
                }
            }
            
            return nearestArcId;
        } catch (java.lang.Exception e) {
            throw new GraphException("Error finding nearest arc: " + e.getMessage());
        }
    }
    
    @Override
    public void loadGraph(String linesFile, String stopsFile, String linestopsFile, Current current) 
            throws GraphException {
        throw new GraphException("Graph already loaded");
    }
    
    @Override
    public void shutdown(Current current) {
        System.out.println("GraphService shutting down");
    }
    
    private SITM.Arc[] convertArcs(List<model.Arc> arcs) {
        List<SITM.Arc> iceArcs = new ArrayList<>();
        for (model.Arc arc : arcs) {
            iceArcs.add(convertArc(arc));
        }
        return iceArcs.toArray(new SITM.Arc[0]);
    }
    
    private SITM.Arc convertArc(model.Arc arc) {
        SITM.Arc iceArc = new SITM.Arc();
        iceArc.arcId = arc.hashCode();
        iceArc.routeId = arc.getRouteId();
        iceArc.orientation = arc.getOrientation();
        iceArc.fromStopId = arc.getFromStop().getStopId();
        iceArc.toStopId = arc.getToStop().getStopId();
        iceArc.fromSequence = arc.getFromSequence();
        iceArc.toSequence = arc.getToSequence();
        return iceArc;
    }
    
    private double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
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
}

