package coordinator;

import graph.GraphBuilder;
import model.LineStop;
import model.Route;
import model.Stop;
import parser.CSVParser;
import services.CoordinatorI;
import services.GraphServiceI;
import SITM.*;

import com.zeroc.Ice.*;

import java.util.List;

public class CoordinatorNode {
    
    private static final String GRAPH_BASE_PATH = System.getProperty("graph.path", 
        System.getProperty("user.home") + "/proyecto-mio/MIO/");
    
    public static void main(String[] args) {
        int status = 0;
        Communicator communicator = null;
        
        try {
            communicator = Util.initialize(args);
            
            String adapterName = "CoordinatorAdapter";
            String port = System.getProperty("coordinator.port", "10000");
            String endpoints = "tcp -h 0.0.0.0 -p " + port;
            
            ObjectAdapter adapter = communicator.createObjectAdapterWithEndpoints(adapterName, endpoints);
            
            System.out.println("Loading graph data...");
            List<Route> routes = CSVParser.parseRoutes(GRAPH_BASE_PATH + "lines-241.csv");
            List<Stop> stops = CSVParser.parseStops(GRAPH_BASE_PATH + "stops-241.csv");
            List<LineStop> lineStops = CSVParser.parseLineStops(GRAPH_BASE_PATH + "linestops-241.csv");
            
            GraphBuilder graphBuilder = new GraphBuilder(routes, stops, lineStops);
            System.out.println("Graph loaded: " + graphBuilder.getArcs().size() + " arcs");
            
            GraphServiceI graphService = new GraphServiceI(graphBuilder);
            CoordinatorI coordinator = new CoordinatorI();
            
            adapter.add(graphService, Util.stringToIdentity("GraphService"));
            adapter.add(coordinator, Util.stringToIdentity("Coordinator"));
            
            adapter.activate();
            
            System.out.println("Coordinator node started on endpoints: " + endpoints);
            System.out.println("GraphService available at: GraphService");
            System.out.println("Coordinator available at: Coordinator");
            System.out.println("Waiting for workers to connect...");
            
            // Log status every 30 seconds
            final CoordinatorI coord = coordinator;
            Thread statusThread = new Thread(() -> {
                while (!Thread.currentThread().isInterrupted()) {
                    try {
                        Thread.sleep(30000);
                        WorkerInfo[] workers = coord.getAvailableWorkers(new com.zeroc.Ice.Current());
                        System.out.println("[STATUS " + new java.util.Date() + "] Registered workers: " + workers.length);
                    } catch (java.lang.Exception e) {
                        // Ignore
                    }
                }
            });
            statusThread.setDaemon(true);
            statusThread.start();
            
            communicator.waitForShutdown();
            
        } catch (java.lang.Exception e) {
            System.err.println("Error: " + e.getMessage());
            e.printStackTrace();
            status = 1;
        } finally {
            if (communicator != null) {
                try {
                    communicator.destroy();
                } catch (java.lang.Exception e) {
                    System.err.println("Error destroying communicator: " + e.getMessage());
                }
            }
        }
        
        System.exit(status);
    }
}

