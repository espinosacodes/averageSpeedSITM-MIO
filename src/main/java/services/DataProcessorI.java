package services;

import calculator.SpeedCalculator;
import model.Datagram;
import model.SpeedResult;
import parser.DatagramParser;
import SITM.*;
import com.zeroc.Ice.Current;

import java.util.List;
import java.util.Map;

public class DataProcessorI implements DataProcessor {
    
    private SpeedCalculator speedCalculator;
    private String workerId;
    
    public DataProcessorI(SpeedCalculator speedCalculator, String workerId) {
        this.speedCalculator = speedCalculator;
        this.workerId = workerId;
    }
    
    @Override
    public ProcessingResult[] processDatagrams(SITM.Datagram[] datagrams, String partitionId, Current current) 
            throws ProcessingException {
        try {
            List<Datagram> datagramList = convertToDatagramList(datagrams);
            Map<Integer, SpeedResult> results = speedCalculator.calculateSpeeds(datagramList);
            
            return results.values().stream()
                .map(this::convertToProcessingResult)
                .toArray(ProcessingResult[]::new);
        } catch (Exception e) {
            throw new ProcessingException("Error processing datagrams: " + e.getMessage());
        }
    }
    
    @Override
    public ProcessingResult[] processDataChunk(byte[] chunk, String partitionId, Current current) 
            throws ProcessingException {
        throw new ProcessingException("Not implemented - use processDatagrams");
    }
    
    @Override
    public void shutdown(Current current) {
        System.out.println("DataProcessor " + workerId + " shutting down");
    }
    
    private List<Datagram> convertToDatagramList(SITM.Datagram[] iceDatagrams) {
        List<Datagram> list = new java.util.ArrayList<>();
        for (SITM.Datagram dg : iceDatagrams) {
            Datagram d = new Datagram(
                dg.eventType,
                dg.registerDate,
                dg.stopId,
                dg.odometer,
                dg.latitude,
                dg.longitude,
                dg.taskId,
                dg.lineId,
                dg.tripId,
                dg.datagramDate,
                dg.busId
            );
            list.add(d);
        }
        return list;
    }
    
    private ProcessingResult convertToProcessingResult(SpeedResult result) {
        ProcessingResult pr = new ProcessingResult();
        pr.arcId = result.getArcId();
        pr.averageSpeed = result.getAverageSpeed();
        pr.sampleCount = result.getSampleCount();
        pr.processingTime = System.currentTimeMillis();
        return pr;
    }
}

