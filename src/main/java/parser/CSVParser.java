package parser;

import model.Route;
import model.Stop;
import model.LineStop;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class CSVParser {
    
    //Template Method Pattern para parsear los archivos CSV.
    public static List<Route> parseRoutes(String filePath) throws IOException {
        List<Route> routes = new ArrayList<>();
        try (BufferedReader br = new BufferedReader(new FileReader(filePath))) {
            String header = br.readLine();
            String line;
            while ((line = br.readLine()) != null) {
                if (line.trim().isEmpty()) continue;
                String[] fields = parseCSVLine(line);
                if (fields.length >= 6) {
                    int lineId = Integer.parseInt(fields[0].trim());
                    int planVersionId = Integer.parseInt(fields[1].trim());
                    String shortName = fields[2].trim();
                    String description = fields[3].trim();
                    String activationDate = fields[5].trim();
                    routes.add(new Route(lineId, planVersionId, shortName, description, activationDate));
                }
            }
        }
        return routes;
    }
    
    public static List<Stop> parseStops(String filePath) throws IOException {
        List<Stop> stops = new ArrayList<>();
        try (BufferedReader br = new BufferedReader(new FileReader(filePath))) {
            String header = br.readLine();
            String line;
            while ((line = br.readLine()) != null) {
                if (line.trim().isEmpty()) continue;
                String[] fields = parseCSVLine(line);
                if (fields.length >= 8) {
                    int stopId = Integer.parseInt(fields[0].trim());
                    int planVersionId = Integer.parseInt(fields[1].trim());
                    String shortName = fields[2].trim();
                    String longName = fields[3].trim();
                    double longitude = Double.parseDouble(fields[6].trim());
                    double latitude = Double.parseDouble(fields[7].trim());
                    stops.add(new Stop(stopId, planVersionId, shortName, longName, longitude, latitude));
                }
            }
        }
        return stops;
    }
    
    public static List<LineStop> parseLineStops(String filePath) throws IOException {
        List<LineStop> lineStops = new ArrayList<>();
        try (BufferedReader br = new BufferedReader(new FileReader(filePath))) {
            String header = br.readLine();
            String line;
            while ((line = br.readLine()) != null) {
                if (line.trim().isEmpty()) continue;
                String[] fields = parseCSVLine(line);
                if (fields.length >= 9) {
                    int lineStopId = Integer.parseInt(fields[0].trim());
                    int stopSequence = Integer.parseInt(fields[1].trim());
                    int orientation = Integer.parseInt(fields[2].trim());
                    int lineId = Integer.parseInt(fields[3].trim());
                    int stopId = Integer.parseInt(fields[4].trim());
                    int planVersionId = Integer.parseInt(fields[5].trim());
                    int lineVariant = Integer.parseInt(fields[6].trim());
                    int lineVariantType = Integer.parseInt(fields[8].trim());
                    lineStops.add(new LineStop(lineStopId, stopSequence, orientation, lineId, stopId, 
                                              planVersionId, lineVariant, lineVariantType));
                }
            }
        }
        return lineStops;
    }
    
    private static String[] parseCSVLine(String line) {
        List<String> fields = new ArrayList<>();
        boolean inQuotes = false;
        StringBuilder currentField = new StringBuilder();
        
        for (int i = 0; i < line.length(); i++) {
            char c = line.charAt(i);
            if (c == '"') {
                inQuotes = !inQuotes;
            } else if (c == ',' && !inQuotes) {
                fields.add(currentField.toString());
                currentField = new StringBuilder();
            } else {
                currentField.append(c);
            }
        }
        fields.add(currentField.toString());
        
        return fields.toArray(new String[0]);
    }
}

