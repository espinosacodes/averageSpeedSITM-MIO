package model;

public class Stop {
    private int stopId;
    private int planVersionId;
    private String shortName;
    private String longName;
    private double longitude;
    private double latitude;

    public Stop(int stopId, int planVersionId, String shortName, String longName, double longitude, double latitude) {
        this.stopId = stopId;
        this.planVersionId = planVersionId;
        this.shortName = shortName;
        this.longName = longName;
        this.longitude = longitude;
        this.latitude = latitude;
    }

    public int getStopId() {
        return stopId;
    }

    public int getPlanVersionId() {
        return planVersionId;
    }

    public String getShortName() {
        return shortName;
    }

    public String getLongName() {
        return longName;
    }

    public double getLongitude() {
        return longitude;
    }

    public double getLatitude() {
        return latitude;
    }

    @Override
    public String toString() {
        return "Stop{stopId=" + stopId + ", shortName='" + shortName + "', longName='" + longName + "'}";
    }
}

