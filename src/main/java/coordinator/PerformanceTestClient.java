package coordinator;

import parser.DatagramParser;
import services.CoordinatorI;
import SITM.*;

import com.zeroc.Ice.*;

import java.util.List;

public class PerformanceTestClient {
    
    public static void main(String[] args) {
        if (args.length < 3) {
            System.err.println("Usage: PerformanceTestClient <dataFile> <numWorkers> <coordinatorEndpoint>");
            System.exit(1);
        }
        
        String dataFile = args[0];
        int numWorkers = Integer.parseInt(args[1]);
        String coordinatorEndpoint = args[2];
        
        Communicator communicator = null;
        
        try {
            communicator = Util.initialize();
            
            CoordinatorPrx coordinator = CoordinatorPrx.checkedCast(
                communicator.stringToProxy("Coordinator:" + coordinatorEndpoint));
            
            if (coordinator == null) {
                throw new RuntimeException("Invalid coordinator proxy");
            }
            
            System.out.println("Starting performance test...");
            System.out.println("Data file: " + dataFile);
            System.out.println("Number of workers: " + numWorkers);
            
            long totalLines = DatagramParser.countLines(dataFile);
            System.out.println("Total lines in file: " + totalLines);
            
            long startTime = System.currentTimeMillis();
            
            PartitionInfo[] partitions = coordinator.partitionDataFile(dataFile, numWorkers);
            System.out.println("Created " + partitions.length + " partitions");
            
            WorkerInfo[] availableWorkers = coordinator.getAvailableWorkers();
            System.out.println("Available workers: " + availableWorkers.length);
            
            String[] taskIds = new String[partitions.length];
            int taskIndex = 0;
            
            for (PartitionInfo partition : partitions) {
                if (availableWorkers.length == 0) {
                    System.err.println("No available workers!");
                    break;
                }
                
                WorkerInfo worker = availableWorkers[taskIndex % availableWorkers.length];
                ProcessingTask task = coordinator.assignTask(partition.partitionId, worker.workerId);
                taskIds[taskIndex++] = task.taskId;
                
                System.out.println("Assigned partition " + partition.partitionId + 
                                 " to worker " + worker.workerId);
            }
            
            System.out.println("Waiting for tasks to complete...");
            
            boolean allComplete = false;
            while (!allComplete) {
                allComplete = true;
                Thread.sleep(5000);
                
                for (String taskId : taskIds) {
                    ProcessingTask task = coordinator.getTaskStatus(taskId);
                    if (task.status != 2 && task.status != 3) {
                        allComplete = false;
                        break;
                    }
                }
                
                if (!allComplete) {
                    System.out.print(".");
                }
            }
            
            System.out.println("\nAll tasks completed. Aggregating results...");
            
            AggregationResult[] results = coordinator.aggregateResults(taskIds);
            
            long endTime = System.currentTimeMillis();
            long elapsed = endTime - startTime;
            
            System.out.println("\n=== Performance Results ===");
            System.out.println("Total processing time: " + elapsed + " ms (" + 
                             (elapsed / 1000.0) + " seconds)");
            System.out.println("Number of results: " + results.length);
            System.out.println("Throughput: " + (totalLines * 1000.0 / elapsed) + " datagrams/second");
            
            String outputFile = "performance_results_" + numWorkers + "workers.txt";
            java.io.PrintWriter writer = new java.io.PrintWriter(outputFile);
            writer.println("Performance Test Results");
            writer.println("========================");
            writer.println("Data file: " + dataFile);
            writer.println("Number of workers: " + numWorkers);
            writer.println("Total lines: " + totalLines);
            writer.println("Processing time: " + elapsed + " ms");
            writer.println("Throughput: " + (totalLines * 1000.0 / elapsed) + " datagrams/second");
            writer.println("\nResults by arc:");
            for (AggregationResult result : results) {
                writer.println("Arc " + result.arcId + ": " + 
                            String.format("%.2f", result.weightedAverageSpeed) + 
                            " km/h (" + result.totalSamples + " samples)");
            }
            writer.close();
            
            System.out.println("Results saved to " + outputFile);
            
        } catch (java.lang.Exception e) {
            System.err.println("Error: " + e.getMessage());
            e.printStackTrace();
        } finally {
            if (communicator != null) {
                communicator.destroy();
            }
        }
    }
}

