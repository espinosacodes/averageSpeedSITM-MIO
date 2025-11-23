package model;

public class LineStop {
    private int lineStopId;
    private int stopSequence;
    private int orientation;
    private int lineId;
    private int stopId;
    private int planVersionId;
    private int lineVariant;
    private int lineVariantType;

    public LineStop(int lineStopId, int stopSequence, int orientation, int lineId, int stopId, 
                    int planVersionId, int lineVariant, int lineVariantType) {
        this.lineStopId = lineStopId;
        this.stopSequence = stopSequence;
        this.orientation = orientation;
        this.lineId = lineId;
        this.stopId = stopId;
        this.planVersionId = planVersionId;
        this.lineVariant = lineVariant;
        this.lineVariantType = lineVariantType;
    }

    public int getLineStopId() {
        return lineStopId;
    }

    public int getStopSequence() {
        return stopSequence;
    }

    public int getOrientation() {
        return orientation;
    }

    public int getLineId() {
        return lineId;
    }

    public int getStopId() {
        return stopId;
    }

    public int getPlanVersionId() {
        return planVersionId;
    }

    public int getLineVariant() {
        return lineVariant;
    }

    public int getLineVariantType() {
        return lineVariantType;
    }
}

