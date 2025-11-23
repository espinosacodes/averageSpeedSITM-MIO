package model;

public class Route {
    private int lineId;
    private int planVersionId;
    private String shortName;
    private String description;
    private String activationDate;

    public Route(int lineId, int planVersionId, String shortName, String description, String activationDate) {
        this.lineId = lineId;
        this.planVersionId = planVersionId;
        this.shortName = shortName;
        this.description = description;
        this.activationDate = activationDate;
    }

    public int getLineId() {
        return lineId;
    }

    public int getPlanVersionId() {
        return planVersionId;
    }

    public String getShortName() {
        return shortName;
    }

    public String getDescription() {
        return description;
    }

    public String getActivationDate() {
        return activationDate;
    }

    @Override
    public String toString() {
        return "Route{lineId=" + lineId + ", shortName='" + shortName + "', description='" + description + "'}";
    }
}

