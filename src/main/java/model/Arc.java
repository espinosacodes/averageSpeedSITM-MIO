package model;

import java.util.Objects;

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
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Arc arc = (Arc) o;
        return routeId == arc.routeId &&
               orientation == arc.orientation &&
               fromSequence == arc.fromSequence &&
               toSequence == arc.toSequence &&
               fromStop.getStopId() == arc.fromStop.getStopId() &&
               toStop.getStopId() == arc.toStop.getStopId();
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(routeId, orientation, fromStop.getStopId(), 
                          toStop.getStopId(), fromSequence, toSequence);
    }
    
    @Override
    public String toString() {
        return "Arc{routeId=" + routeId + ", orientation=" + orientation + 
               ", from=" + fromStop.getStopId() + "(" + fromSequence + ")" +
               ", to=" + toStop.getStopId() + "(" + toSequence + ")" + "}";
    }
}

