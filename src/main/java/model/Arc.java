package model;

public class Arc {
    private Stop fromStop;
    private Stop toStop;
    private int routeId;
    private int orientation;
    private int fromSequence;
    private int toSequence;

    public Arc(Stop fromStop, Stop toStop, int routeId, int orientation, int fromSequence, int toSequence) {
        this.fromStop = fromStop;
        this.toStop = toStop;
        this.routeId = routeId;
        this.orientation = orientation;
        this.fromSequence = fromSequence;
        this.toSequence = toSequence;
    }

    public Stop getFromStop() {
        return fromStop;
    }

    public Stop getToStop() {
        return toStop;
    }

    public int getRouteId() {
        return routeId;
    }

    public int getOrientation() {
        return orientation;
    }

    public int getFromSequence() {
        return fromSequence;
    }

    public int getToSequence() {
        return toSequence;
    }

    @Override
    public String toString() {
        return "Arc{routeId=" + routeId + ", orientation=" + orientation + 
               ", from=" + fromStop.getStopId() + "(" + fromSequence + ")" +
               ", to=" + toStop.getStopId() + "(" + toSequence + ")" + "}";
    }
}

