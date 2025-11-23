package model;

public class SpeedResult {
    private int arcId;
    private double averageSpeed;
    private double minSpeed;
    private double maxSpeed;
    private int sampleCount;
    private long lastUpdate;
    private double totalSpeed;
    private double totalDistance;
    private double totalTime;
    
    public SpeedResult() {
        this.totalSpeed = 0.0;
        this.totalDistance = 0.0;
        this.totalTime = 0.0;
        this.sampleCount = 0;
        this.minSpeed = Double.MAX_VALUE;
        this.maxSpeed = 0.0;
    }
    
    public SpeedResult(int arcId) {
        this();
        this.arcId = arcId;
    }
    
    public void addSample(double speed, double distance, double time) {
        if (speed > 0 && speed < 200) {
            totalSpeed += speed;
            totalDistance += distance;
            totalTime += time;
            sampleCount++;
            
            if (speed < minSpeed) {
                minSpeed = speed;
            }
            if (speed > maxSpeed) {
                maxSpeed = speed;
            }
            
            if (sampleCount > 0) {
                averageSpeed = totalSpeed / sampleCount;
            }
            
            lastUpdate = System.currentTimeMillis();
        }
    }
    
    public void merge(SpeedResult other) {
        if (other.sampleCount == 0) return;
        
        int totalSamples = this.sampleCount + other.sampleCount;
        if (totalSamples > 0) {
            this.averageSpeed = (this.averageSpeed * this.sampleCount + 
                               other.averageSpeed * other.sampleCount) / totalSamples;
        }
        
        this.totalSpeed += other.totalSpeed;
        this.totalDistance += other.totalDistance;
        this.totalTime += other.totalTime;
        this.sampleCount = totalSamples;
        
        if (other.minSpeed < this.minSpeed) {
            this.minSpeed = other.minSpeed;
        }
        if (other.maxSpeed > this.maxSpeed) {
            this.maxSpeed = other.maxSpeed;
        }
        
        if (other.lastUpdate > this.lastUpdate) {
            this.lastUpdate = other.lastUpdate;
        }
    }
    
    public int getArcId() {
        return arcId;
    }
    
    public void setArcId(int arcId) {
        this.arcId = arcId;
    }
    
    public double getAverageSpeed() {
        return averageSpeed;
    }
    
    public void setAverageSpeed(double averageSpeed) {
        this.averageSpeed = averageSpeed;
    }
    
    public double getMinSpeed() {
        return minSpeed == Double.MAX_VALUE ? 0.0 : minSpeed;
    }
    
    public void setMinSpeed(double minSpeed) {
        this.minSpeed = minSpeed;
    }
    
    public double getMaxSpeed() {
        return maxSpeed;
    }
    
    public void setMaxSpeed(double maxSpeed) {
        this.maxSpeed = maxSpeed;
    }
    
    public int getSampleCount() {
        return sampleCount;
    }
    
    public void setSampleCount(int sampleCount) {
        this.sampleCount = sampleCount;
    }
    
    public long getLastUpdate() {
        return lastUpdate;
    }
    
    public void setLastUpdate(long lastUpdate) {
        this.lastUpdate = lastUpdate;
    }
    
    public double getTotalSpeed() {
        return totalSpeed;
    }
    
    public double getTotalDistance() {
        return totalDistance;
    }
    
    public double getTotalTime() {
        return totalTime;
    }
    
    @Override
    public String toString() {
        return "SpeedResult{arcId=" + arcId + ", avgSpeed=" + String.format("%.2f", averageSpeed) +
               " km/h, samples=" + sampleCount + "}";
    }
}

