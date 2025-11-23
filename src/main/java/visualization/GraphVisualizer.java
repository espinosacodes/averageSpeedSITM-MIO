package visualization;

import graph.GraphBuilder;
import model.Arc;
import model.Stop;

import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.geom.Point2D;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.util.*;
import java.util.List;

public class GraphVisualizer {
    
    private static final int IMAGE_WIDTH = 2000;
    private static final int IMAGE_HEIGHT = 2000;
    private static final int MARGIN = 50;
    private static final int NODE_RADIUS = 3;
    
    private GraphBuilder graphBuilder;
    private double minLongitude, maxLongitude, minLatitude, maxLatitude;
    
    public GraphVisualizer(GraphBuilder graphBuilder) {
        this.graphBuilder = graphBuilder;
        calculateBounds();
    }
    
    private void calculateBounds() {
        Collection<Stop> allStops = graphBuilder.getStops().values();
        minLongitude = allStops.stream().mapToDouble(Stop::getLongitude).min().orElse(-76.6);
        maxLongitude = allStops.stream().mapToDouble(Stop::getLongitude).max().orElse(-76.4);
        minLatitude = allStops.stream().mapToDouble(Stop::getLatitude).min().orElse(3.3);
        maxLatitude = allStops.stream().mapToDouble(Stop::getLatitude).max().orElse(3.5);
    }
    
    private Point2D.Double gpsToScreen(double longitude, double latitude) {
        double x = MARGIN + (longitude - minLongitude) / (maxLongitude - minLongitude) * 
                   (IMAGE_WIDTH - 2 * MARGIN);
        double y = IMAGE_HEIGHT - MARGIN - (latitude - minLatitude) / (maxLatitude - minLatitude) * 
                   (IMAGE_HEIGHT - 2 * MARGIN);
        return new Point2D.Double(x, y);
    }
    
    private Color getRouteColor(int routeId) {
        Random random = new Random(routeId);
        return new Color(random.nextInt(200) + 55, random.nextInt(200) + 55, random.nextInt(200) + 55);
    }
    
    public void visualizeAndExport(String filename) throws IOException {
        BufferedImage image = new BufferedImage(IMAGE_WIDTH, IMAGE_HEIGHT, BufferedImage.TYPE_INT_RGB);
        Graphics2D g2d = image.createGraphics();
        
        g2d.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
        g2d.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
        
        g2d.setColor(Color.WHITE);
        g2d.fillRect(0, 0, IMAGE_WIDTH, IMAGE_HEIGHT);
        
        Map<Integer, Color> routeColors = new HashMap<>();
        Set<Integer> routeIds = graphBuilder.getRouteIds();
        for (Integer routeId : routeIds) {
            routeColors.put(routeId, getRouteColor(routeId));
        }
        
        g2d.setStroke(new BasicStroke(1.0f));
        
        List<Arc> arcs = graphBuilder.getArcs();
        for (Arc arc : arcs) {
            Point2D.Double from = gpsToScreen(arc.getFromStop().getLongitude(), 
                                             arc.getFromStop().getLatitude());
            Point2D.Double to = gpsToScreen(arc.getToStop().getLongitude(), 
                                           arc.getToStop().getLatitude());
            
            Color routeColor = routeColors.get(arc.getRouteId());
            g2d.setColor(new Color(routeColor.getRed(), routeColor.getGreen(), 
                                  routeColor.getBlue(), 100));
            g2d.drawLine((int)from.x, (int)from.y, (int)to.x, (int)to.y);
        }
        
        g2d.setColor(Color.BLACK);
        Collection<Stop> allStops = graphBuilder.getStops().values();
        for (Stop stop : allStops) {
            Point2D.Double point = gpsToScreen(stop.getLongitude(), stop.getLatitude());
            g2d.fillOval((int)point.x - NODE_RADIUS, (int)point.y - NODE_RADIUS, 
                        NODE_RADIUS * 2, NODE_RADIUS * 2);
        }
        
        g2d.dispose();
        
        File outputFile = new File(filename);
        ImageIO.write(image, "jpg", outputFile);
    }
}

