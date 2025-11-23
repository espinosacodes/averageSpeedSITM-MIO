module SITM {

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
    
    struct SpeedUpdate {
        int arcId;
        double newAverageSpeed;
        int sampleCount;
        long timestamp;
    };
    
    sequence<SpeedUpdate> SpeedUpdateSequence;
    
    sequence<Datagram> DatagramSequence;
    
    exception StreamingException {
        string reason;
    };
    
    interface StreamProcessor {
        void processDatagram(Datagram datagram)
            throws StreamingException;
            
        SpeedUpdateSequence processDatagramBatch(DatagramSequence datagrams)
            throws StreamingException;
            
        SpeedUpdateSequence getRecentUpdates(int limit)
            throws StreamingException;
            
        void shutdown();
    };
};

