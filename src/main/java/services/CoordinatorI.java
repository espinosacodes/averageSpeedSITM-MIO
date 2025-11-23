package services;

import SITM.*;
import com.zeroc.Ice.Current;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

public class CoordinatorI implements Coordinator {
    
    private Map<String, WorkerInfo> workers = new ConcurrentHashMap<>();
    private Map<String, ProcessingTask> tasks = new ConcurrentHashMap<>();
    private Map<String, PartitionInfo> partitions = new ConcurrentHashMap<>();
    private Map<String, List<ProcessingResult>> taskResults = new ConcurrentHashMap<>();
    
    @Override
    public PartitionInfo[] partitionDataFile(String filePath, int numPartitions, Current current) 
            throws CoordinationException {
        try {
            long fileSize = new java.io.File(filePath).length();
            long partitionSize = fileSize / numPartitions;
            
            List<PartitionInfo> partitionList = new ArrayList<>();
            for (int i = 0; i < numPartitions; i++) {
                PartitionInfo partition = new PartitionInfo();
                partition.partitionId = "partition_" + i;
                partition.filePath = filePath;
                partition.startOffset = i * partitionSize;
                partition.endOffset = (i == numPartitions - 1) ? fileSize : (i + 1) * partitionSize;
                partition.expectedDatagrams = 0;
                
                partitions.put(partition.partitionId, partition);
                partitionList.add(partition);
            }
            
            return partitionList.toArray(new PartitionInfo[0]);
        } catch (Exception e) {
            throw new CoordinationException("Error partitioning file: " + e.getMessage());
        }
    }
    
    @Override
    public WorkerInfo[] registerWorker(String workerId, String endpoint, Current current) 
            throws CoordinationException {
        try {
            WorkerInfo worker = new WorkerInfo();
            worker.workerId = workerId;
            worker.endpoint = endpoint;
            worker.available = true;
            
            workers.put(workerId, worker);
            
            return workers.values().toArray(new WorkerInfo[0]);
        } catch (Exception e) {
            throw new CoordinationException("Error registering worker: " + e.getMessage());
        }
    }
    
    @Override
    public void unregisterWorker(String workerId, Current current) throws CoordinationException {
        workers.remove(workerId);
        tasks.values().removeIf(task -> task.workerId.equals(workerId));
    }
    
    @Override
    public ProcessingTask assignTask(String partitionId, String workerId, Current current) 
            throws CoordinationException {
        try {
            if (!partitions.containsKey(partitionId)) {
                throw new CoordinationException("Partition not found: " + partitionId);
            }
            
            if (!workers.containsKey(workerId)) {
                throw new CoordinationException("Worker not found: " + workerId);
            }
            
            ProcessingTask task = new ProcessingTask();
            task.taskId = "task_" + UUID.randomUUID().toString();
            task.partitionId = partitionId;
            task.workerId = workerId;
            task.status = 0;
            
            tasks.put(task.taskId, task);
            workers.get(workerId).available = false;
            
            return task;
        } catch (CoordinationException e) {
            throw e;
        } catch (Exception e) {
            throw new CoordinationException("Error assigning task: " + e.getMessage());
        }
    }
    
    @Override
    public void updateTaskStatus(String taskId, int status, Current current) 
            throws CoordinationException {
        ProcessingTask task = tasks.get(taskId);
        if (task == null) {
            throw new CoordinationException("Task not found: " + taskId);
        }
        
        task.status = status;
        
        if (status == 2 || status == 3) {
            WorkerInfo worker = workers.get(task.workerId);
            if (worker != null) {
                worker.available = true;
            }
        }
    }
    
    public void addTaskResult(String taskId, ProcessingResult[] results) {
        taskResults.putIfAbsent(taskId, new ArrayList<>());
        taskResults.get(taskId).addAll(Arrays.asList(results));
    }
    
    @Override
    public AggregationResult[] aggregateResults(String[] taskIds, Current current) 
            throws CoordinationException {
        try {
            Map<Integer, List<ProcessingResult>> resultsByArc = new HashMap<>();
            
            for (String taskId : taskIds) {
                List<ProcessingResult> results = taskResults.get(taskId);
                if (results != null) {
                    for (ProcessingResult result : results) {
                        resultsByArc.computeIfAbsent(result.arcId, k -> new ArrayList<>())
                                   .add(result);
                    }
                }
            }
            
            List<AggregationResult> aggregated = new ArrayList<>();
            for (Map.Entry<Integer, List<ProcessingResult>> entry : resultsByArc.entrySet()) {
                AggregationResult agg = new AggregationResult();
                agg.arcId = entry.getKey();
                
                double totalSpeed = 0.0;
                int totalSamples = 0;
                long totalTime = 0;
                
                for (ProcessingResult result : entry.getValue()) {
                    totalSpeed += result.averageSpeed * result.sampleCount;
                    totalSamples += result.sampleCount;
                    totalTime += result.processingTime;
                }
                
                agg.weightedAverageSpeed = totalSamples > 0 ? totalSpeed / totalSamples : 0.0;
                agg.totalSamples = totalSamples;
                agg.processingTime = totalTime;
                
                aggregated.add(agg);
            }
            
            return aggregated.toArray(new AggregationResult[0]);
        } catch (Exception e) {
            throw new CoordinationException("Error aggregating results: " + e.getMessage());
        }
    }
    
    @Override
    public WorkerInfo[] getAvailableWorkers(Current current) throws CoordinationException {
        return workers.values().stream()
            .filter(w -> w.available)
            .toArray(WorkerInfo[]::new);
    }
    
    @Override
    public ProcessingTask getTaskStatus(String taskId, Current current) throws CoordinationException {
        ProcessingTask task = tasks.get(taskId);
        if (task == null) {
            throw new CoordinationException("Task not found: " + taskId);
        }
        return task;
    }
    
    @Override
    public void shutdown(Current current) {
        System.out.println("Coordinator shutting down");
    }
}

