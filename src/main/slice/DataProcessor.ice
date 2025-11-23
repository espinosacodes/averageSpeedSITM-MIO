module SITM {

    sequence<byte> DataChunk;
    
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
    
    struct ProcessingResult {
        int arcId;
        double averageSpeed;
        int sampleCount;
        long processingTime;
    };
    
    sequence<ProcessingResult> ProcessingResultSequence;
    
    exception ProcessingException {
        string reason;
    };
    
    interface DataProcessor {
        ProcessingResultSequence processDatagrams(DatagramSequence datagrams, string partitionId)
            throws ProcessingException;
            
        ProcessingResultSequence processDataChunk(DataChunk chunk, string partitionId)
            throws ProcessingException;
            
        void shutdown();
    };
};

