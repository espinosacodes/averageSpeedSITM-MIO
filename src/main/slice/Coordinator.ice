module SITM {

    struct PartitionInfo {
        string partitionId;
        string filePath;
        long startOffset;
        long endOffset;
        int expectedDatagrams;
    };
    
    sequence<PartitionInfo> PartitionInfoSequence;
    
    struct WorkerInfo {
        string workerId;
        string endpoint;
        bool available;
    };
    
    sequence<WorkerInfo> WorkerInfoSequence;
    
    struct ProcessingTask {
        string taskId;
        string partitionId;
        string workerId;
        int status; // 0=pending, 1=processing, 2=completed, 3=failed
    };
    
    sequence<ProcessingTask> ProcessingTaskSequence;
    
    struct AggregationResult {
        int arcId;
        double weightedAverageSpeed;
        int totalSamples;
        long processingTime;
    };
    
    sequence<AggregationResult> AggregationResultSequence;
    
    sequence<string> StringSequence;
    
    exception CoordinationException {
        string reason;
    };
    
    interface Coordinator {
        PartitionInfoSequence partitionDataFile(string filePath, int numPartitions)
            throws CoordinationException;
            
        WorkerInfoSequence registerWorker(string workerId, string endpoint)
            throws CoordinationException;
            
        void unregisterWorker(string workerId)
            throws CoordinationException;
            
        ProcessingTask assignTask(string partitionId, string workerId)
            throws CoordinationException;
            
        void updateTaskStatus(string taskId, int status)
            throws CoordinationException;
            
        AggregationResultSequence aggregateResults(StringSequence taskIds)
            throws CoordinationException;
    
    WorkerInfoSequence getAvailableWorkers()
            throws CoordinationException;
    
    ProcessingTask getTaskStatus(string taskId)
            throws CoordinationException;
            
    void shutdown();
};
};

