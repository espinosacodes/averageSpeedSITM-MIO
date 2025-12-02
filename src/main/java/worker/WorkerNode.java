package worker;

import calculator.SpeedCalculator;
import graph.GraphBuilder;
import model.LineStop;
import model.Route;
import model.Stop;
import parser.CSVParser;
import parser.DatagramParser;
import services.DataProcessorI;
import SITM.*;

import com.zeroc.Ice.*;

import java.util.List;

public class WorkerNode {
    
    private static final String GRAPH_BASE_PATH = System.getProperty("graph.path",
        System.getProperty("user.home") + "/proyecto-mio/MIO/");
    
    public static void main(String[] args) {
        if (args.length < 2) {
            System.err.println("Usage: WorkerNode <workerId> <coordinatorEndpoint>");
            System.exit(1);
        }
        
        String workerId = args[0];
        String coordinatorEndpoint = args[1];
        
        int status = 0;
        Communicator communicator = null;
        
        try {
            communicator = Util.initialize(args);
            
            System.out.println("Worker " + workerId + " starting...");
            System.out.println("Connecting to coordinator at: " + coordinatorEndpoint);
            
            System.out.println("Loading graph data...");
            List<Route> routes = CSVParser.parseRoutes(GRAPH_BASE_PATH + "lines-241.csv");
            List<Stop> stops = CSVParser.parseStops(GRAPH_BASE_PATH + "stops-241.csv");
            List<LineStop> lineStops = CSVParser.parseLineStops(GRAPH_BASE_PATH + "linestops-241.csv");
            
            GraphBuilder graphBuilder = new GraphBuilder(routes, stops, lineStops);
            SpeedCalculator speedCalculator = new SpeedCalculator(graphBuilder);
            
            System.out.println("Graph loaded: " + graphBuilder.getArcs().size() + " arcs");
            
            String adapterName = "WorkerAdapter_" + workerId;
            String endpoints = "tcp -h 0.0.0.0";
            
            ObjectAdapter adapter = communicator.createObjectAdapterWithEndpoints(adapterName, endpoints);
            
            DataProcessorI dataProcessor = new DataProcessorI(speedCalculator, workerId);
            String identity = "DataProcessor_" + workerId;
            adapter.add(dataProcessor, Util.stringToIdentity(identity));
            
            adapter.activate();
            
            Endpoint[] endpointsArray = adapter.getEndpoints();
            String workerEndpoint = endpointsArray[0].toString();
            System.out.println("Worker endpoint: " + workerEndpoint);
            
            //proxy pattern para la comunicacion remota 
            CoordinatorPrx coordinator = CoordinatorPrx.checkedCast(
                communicator.stringToProxy("Coordinator:" + coordinatorEndpoint));
            
            if (coordinator == null) {
                throw new RuntimeException("Invalid coordinator proxy");
            }
            
            WorkerInfo[] workers = coordinator.registerWorker(workerId, workerEndpoint);
            System.out.println("Registered with coordinator. Total workers: " + workers.length);
            
            System.out.println("Worker " + workerId + " ready and waiting for tasks...");
            
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

