package parser;

import model.Datagram;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class DatagramParser {
    
    public static List<Datagram> parseCSV(String filePath) throws IOException {
        return parseCSV(filePath, 0, Long.MAX_VALUE);
    }
    
    public static List<Datagram> parseCSV(String filePath, long startOffset, long endOffset) throws IOException {
        List<Datagram> datagrams = new ArrayList<>();
        
        try (BufferedReader br = new BufferedReader(new FileReader(filePath))) {
            String header = br.readLine();
            if (header == null) return datagrams;
            
            long lineNumber = 1;
            String line;
            while ((line = br.readLine()) != null) {
                lineNumber++;
                if (lineNumber < startOffset) continue;
                if (lineNumber > endOffset) break;
                
                Datagram dg = parseLine(line);
                if (dg != null) {
                    datagrams.add(dg);
                }
            }
        }
        
        return datagrams;
    }
    
    private static Datagram parseLine(String line) {
        try {
            String[] fields = parseCSVLine(line);
            if (fields.length < 11) return null;
            
            int eventType = parseInt(fields[0]);
            String registerDate = fields[1].trim();
            int stopId = parseInt(fields[2]);
            int odometer = parseInt(fields[3]);
            double latitude = parseDouble(fields[4]) / 1000000.0;
            double longitude = parseDouble(fields[5]) / 1000000.0;
            int taskId = parseInt(fields[6]);
            int lineId = parseInt(fields[7]);
            int tripId = parseInt(fields[8]);
            String datagramDate = fields[10].trim();
            int busId = parseInt(fields[11]);
            
            return new Datagram(eventType, registerDate, stopId, odometer,
                              latitude, longitude, taskId, lineId, tripId,
                              datagramDate, busId);
        } catch (Exception e) {
            return null;
        }
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
    
    private static int parseInt(String s) {
        try {
            return Integer.parseInt(s.trim());
        } catch (NumberFormatException e) {
            return 0;
        }
    }
    
    private static double parseDouble(String s) {
        try {
            return Double.parseDouble(s.trim());
        } catch (NumberFormatException e) {
            return 0.0;
        }
    }
    
    public static long countLines(String filePath) throws IOException {
        long count = 0;
        try (BufferedReader br = new BufferedReader(new FileReader(filePath))) {
            while (br.readLine() != null) {
                count++;
            }
        }
        return count;
    }
}

