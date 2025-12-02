package model;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

public class Datagram {
    private int eventType;
    private String registerDate;
    private int stopId;
    private int odometer;
    private double latitude;
    private double longitude;
    private int taskId;
    private int lineId;
    private int tripId;
    private String datagramDate;
    private int busId;
    private LocalDateTime timestamp;
    
    public Datagram() {
    }
    
    //Constructor para crear un Datagram a partir de los datos del CSV.
    public Datagram(int eventType, String registerDate, int stopId, int odometer,
                   double latitude, double longitude, int taskId, int lineId,
                   int tripId, String datagramDate, int busId) {
        this.eventType = eventType;
        this.registerDate = registerDate;
        this.stopId = stopId;
        this.odometer = odometer;
        this.latitude = latitude;
        this.longitude = longitude;
        this.taskId = taskId;
        this.lineId = lineId;
        this.tripId = tripId;
        this.datagramDate = datagramDate;
        this.busId = busId;
        parseTimestamp();
    }
    
    private void parseTimestamp() {
        try {
            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
            if (datagramDate != null && !datagramDate.isEmpty()) {
                this.timestamp = LocalDateTime.parse(datagramDate.trim(), formatter);
            }
        } catch (Exception e) {
            this.timestamp = null;
        }
    }
    
    public int getEventType() {
        return eventType;
    }
    
    public void setEventType(int eventType) {
        this.eventType = eventType;
    }
    
    public String getRegisterDate() {
        return registerDate;
    }
    
    public void setRegisterDate(String registerDate) {
        this.registerDate = registerDate;
    }
    
    public int getStopId() {
        return stopId;
    }
    
    public void setStopId(int stopId) {
        this.stopId = stopId;
    }
    
    public int getOdometer() {
        return odometer;
    }
    
    public void setOdometer(int odometer) {
        this.odometer = odometer;
    }
    
    public double getLatitude() {
        return latitude;
    }
    
    public void setLatitude(double latitude) {
        this.latitude = latitude;
    }
    
    public double getLongitude() {
        return longitude;
    }
    
    public void setLongitude(double longitude) {
        this.longitude = longitude;
    }
    
    public int getTaskId() {
        return taskId;
    }
    
    public void setTaskId(int taskId) {
        this.taskId = taskId;
    }
    
    public int getLineId() {
        return lineId;
    }
    
    public void setLineId(int lineId) {
        this.lineId = lineId;
    }
    
    public int getTripId() {
        return tripId;
    }
    
    public void setTripId(int tripId) {
        this.tripId = tripId;
    }
    
    public String getDatagramDate() {
        return datagramDate;
    }
    
    public void setDatagramDate(String datagramDate) {
        this.datagramDate = datagramDate;
        parseTimestamp();
    }
    
    public int getBusId() {
        return busId;
    }
    
    public void setBusId(int busId) {
        this.busId = busId;
    }
    
    public LocalDateTime getTimestamp() {
        return timestamp;
    }
    
    public double distanceTo(double lat, double lon) {
        final int R = 6371000;
        double lat1Rad = Math.toRadians(this.latitude);
        double lat2Rad = Math.toRadians(lat);
        double deltaLat = Math.toRadians(lat - this.latitude);
        double deltaLon = Math.toRadians(lon - this.longitude);
        
        double a = Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2) +
                   Math.cos(lat1Rad) * Math.cos(lat2Rad) *
                   Math.sin(deltaLon / 2) * Math.sin(deltaLon / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        
        return R * c;
    }
    
    @Override
    public String toString() {
        return "Datagram{lineId=" + lineId + ", busId=" + busId + 
               ", lat=" + latitude + ", lon=" + longitude + ", stopId=" + stopId + "}";
    }
}

