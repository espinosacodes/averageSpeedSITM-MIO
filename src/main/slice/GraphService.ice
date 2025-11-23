module SITM {

    struct Arc {
        int arcId;
        int routeId;
        int orientation;
        int fromStopId;
        int toStopId;
        int fromSequence;
        int toSequence;
    };
    
    sequence<Arc> ArcSequence;
    
    struct Stop {
        int stopId;
        string shortName;
        string longName;
        double longitude;
        double latitude;
    };
    
    struct Route {
        int routeId;
        string shortName;
        string description;
    };
    
    exception GraphException {
        string reason;
    };
    
    interface GraphService {
        ArcSequence getAllArcs()
            throws GraphException;
            
        ArcSequence getArcsByRoute(int routeId, int orientation)
            throws GraphException;
            
        Arc findArcByStops(int fromStopId, int toStopId, int routeId)
            throws GraphException;
            
        int findNearestArc(double latitude, double longitude, int routeId)
            throws GraphException;
            
        void loadGraph(string linesFile, string stopsFile, string linestopsFile)
            throws GraphException;
            
        void shutdown();
    };
};

