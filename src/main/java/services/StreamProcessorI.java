package services;

import calculator.SpeedCalculator;
import model.Datagram;
import model.SpeedResult;
import SITM.*;
import com.zeroc.Ice.Current;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

public class StreamProcessorI implements StreamProcessor {
    
    private SpeedCalculator speedCalculator;
    //Observer pattern para notificar los cambios de velocidad en tiempo real.
    private Map<Integer, SpeedResult> currentSpeeds = new ConcurrentHashMap<>();
    private Queue<SpeedUpdate> recentUpdates = new ArrayDeque<>();
    private final int MAX_RECENT_UPDATES = 1000;
    
    public StreamProcessorI(SpeedCalculator speedCalculator) {
        this.speedCalculator = speedCalculator;
    }
    
    @Override
    public void processDatagram(SITM.Datagram datagram, Current current) throws StreamingException {
        try {
            Datagram dg = convertDatagram(datagram);
            List<Datagram> single = Collections.singletonList(dg);
            
            Map<Integer, SpeedResult> results = speedCalculator.calculateSpeeds(single);
            
            for (Map.Entry<Integer, SpeedResult> entry : results.entrySet()) {
                int arcId = entry.getKey();
                SpeedResult newResult = entry.getValue();
                
                SpeedResult currentResult = currentSpeeds.get(arcId);
                if (currentResult == null) {
                    currentResult = new SpeedResult(arcId);
                    currentSpeeds.put(arcId, currentResult);
                }
                
                currentResult.merge(newResult);
                
                SpeedUpdate update = new SpeedUpdate();
                update.arcId = arcId;
                update.newAverageSpeed = currentResult.getAverageSpeed();
                update.sampleCount = currentResult.getSampleCount();
                update.timestamp = System.currentTimeMillis();
                
                synchronized (recentUpdates) {
                    recentUpdates.offer(update);
                    if (recentUpdates.size() > MAX_RECENT_UPDATES) {
                        recentUpdates.poll();
                    }
                }
            }
        } catch (java.lang.Exception e) {
            throw new StreamingException("Error processing datagram: " + e.getMessage());
        }
    }
    
    @Override
    public SpeedUpdate[] processDatagramBatch(SITM.Datagram[] datagrams, Current current) 
            throws StreamingException {
        try {
            List<Datagram> datagramList = new ArrayList<>();
            for (SITM.Datagram dg : datagrams) {
                datagramList.add(convertDatagram(dg));
            }
            
            Map<Integer, SpeedResult> results = speedCalculator.calculateSpeeds(datagramList);
            List<SpeedUpdate> updates = new ArrayList<>();
            
            for (Map.Entry<Integer, SpeedResult> entry : results.entrySet()) {
                int arcId = entry.getKey();
                SpeedResult newResult = entry.getValue();
                
                SpeedResult currentResult = currentSpeeds.get(arcId);
                if (currentResult == null) {
                    currentResult = new SpeedResult(arcId);
                    currentSpeeds.put(arcId, currentResult);
                }
                
                currentResult.merge(newResult);
                
                SpeedUpdate update = new SpeedUpdate();
                update.arcId = arcId;
                update.newAverageSpeed = currentResult.getAverageSpeed();
                update.sampleCount = currentResult.getSampleCount();
                update.timestamp = System.currentTimeMillis();
                
                updates.add(update);
                
                synchronized (recentUpdates) {
                    recentUpdates.offer(update);
                    if (recentUpdates.size() > MAX_RECENT_UPDATES) {
                        recentUpdates.poll();
                    }
                }
            }
            
            return updates.toArray(new SpeedUpdate[0]);
        } catch (java.lang.Exception e) {
            throw new StreamingException("Error processing batch: " + e.getMessage());
        }
    }
    
    @Override
    public SpeedUpdate[] getRecentUpdates(int limit, Current current) throws StreamingException {
        try {
            List<SpeedUpdate> updates = new ArrayList<>();
            synchronized (recentUpdates) {
                Iterator<SpeedUpdate> it = recentUpdates.iterator();
                int count = 0;
                while (it.hasNext() && count < limit) {
                    updates.add(it.next());
                    count++;
                }
            }
            return updates.toArray(new SpeedUpdate[0]);
        } catch (java.lang.Exception e) {
            throw new StreamingException("Error getting recent updates: " + e.getMessage());
        }
    }
    
    @Override
    public void shutdown(Current current) {
        System.out.println("StreamProcessor shutting down");
    }
    
    private Datagram convertDatagram(SITM.Datagram dg) {
        return new Datagram(
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
    }
}

