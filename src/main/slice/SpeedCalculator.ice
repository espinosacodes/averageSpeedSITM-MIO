module SITM {

    struct SpeedResult {
        int arcId;
        double averageSpeed;
        double minSpeed;
        double maxSpeed;
        int sampleCount;
        long lastUpdate;
    };
    
    sequence<SpeedResult> SpeedResultSequence;
    
    struct Datagram {
        int eventType;
        string registerDate;
        int stopId;
        int odometer;
        double latitude;
        double longitude;
        int taskId;
        int lineId;
        int tripId;
        string datagramDate;
        int busId;
    };
    
    sequence<Datagram> DatagramSequence;
    
    sequence<int> IntSequence;
    
    exception CalculationException {
        string reason;
    };
    
    interface SpeedCalculator {
        SpeedResult calculateSpeedForArc(int arcId, DatagramSequence datagrams)
            throws CalculationException;
            
        SpeedResultSequence calculateSpeedsForArcs(IntSequence arcIds, DatagramSequence datagrams)
            throws CalculationException;
            
        SpeedResult updateSpeedIncremental(int arcId, Datagram newDatagram, SpeedResult currentResult)
            throws CalculationException;
            
        void shutdown();
    };
};

