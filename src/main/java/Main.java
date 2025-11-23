import graph.GraphBuilder;
import model.LineStop;
import model.Route;
import model.Stop;
import output.GraphPrinter;
import parser.CSVParser;
import visualization.GraphVisualizer;

import java.io.IOException;
import java.util.List;

public class Main {
    
    private static final String BASE_PATH = "proyecto-mio/MIO/";
    private static final String LINES_FILE = BASE_PATH + "lines-241.csv";
    private static final String STOPS_FILE = BASE_PATH + "stops-241.csv";
    private static final String LINESTOPS_FILE = BASE_PATH + "linestops-241.csv";
    
    public static void main(String[] args) {
        try {
            System.out.println("Cargando archivos CSV...");
            List<Route> routes = CSVParser.parseRoutes(LINES_FILE);
            List<Stop> stops = CSVParser.parseStops(STOPS_FILE);
            List<LineStop> lineStops = CSVParser.parseLineStops(LINESTOPS_FILE);
            
            System.out.println("Rutas cargadas: " + routes.size());
            System.out.println("Paradas cargadas: " + stops.size());
            System.out.println("Paradas por ruta cargadas: " + lineStops.size());
            
            System.out.println("\nConstruyendo grafo...");
            GraphBuilder graphBuilder = new GraphBuilder(routes, stops, lineStops);
            
            System.out.println("Arcos construidos: " + graphBuilder.getArcs().size());
            
            System.out.println("\nImprimiendo arcos por ruta...");
            GraphPrinter printer = new GraphPrinter(graphBuilder);
            printer.printArcs();
            
            System.out.println("\nGenerando visualización gráfica...");
            GraphVisualizer visualizer = new GraphVisualizer(graphBuilder);
            visualizer.visualizeAndExport("graph_visualization.jpg");
            System.out.println("Visualización guardada en: graph_visualization.jpg");
            
        } catch (IOException e) {
            System.err.println("Error al leer archivos: " + e.getMessage());
            e.printStackTrace();
        } catch (Exception e) {
            System.err.println("Error: " + e.getMessage());
            e.printStackTrace();
        }
    }
}

