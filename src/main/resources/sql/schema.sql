CREATE TABLE IF NOT EXISTS arc_speeds (
    arc_id INTEGER PRIMARY KEY,
    route_id INTEGER NOT NULL,
    orientation INTEGER NOT NULL,
    from_stop_id INTEGER NOT NULL,
    to_stop_id INTEGER NOT NULL,
    average_speed DOUBLE PRECISION NOT NULL,
    min_speed DOUBLE PRECISION,
    max_speed DOUBLE PRECISION,
    sample_count INTEGER NOT NULL DEFAULT 0,
    last_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_arc_speeds_route ON arc_speeds(route_id, orientation);
CREATE INDEX IF NOT EXISTS idx_arc_speeds_update ON arc_speeds(last_update);

CREATE TABLE IF NOT EXISTS processing_tasks (
    task_id VARCHAR(255) PRIMARY KEY,
    partition_id VARCHAR(255) NOT NULL,
    worker_id VARCHAR(255) NOT NULL,
    status INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    processing_time_ms BIGINT
);

CREATE INDEX IF NOT EXISTS idx_tasks_status ON processing_tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_worker ON processing_tasks(worker_id);

CREATE TABLE IF NOT EXISTS processing_results (
    result_id SERIAL PRIMARY KEY,
    task_id VARCHAR(255) NOT NULL,
    arc_id INTEGER NOT NULL,
    average_speed DOUBLE PRECISION NOT NULL,
    sample_count INTEGER NOT NULL,
    processing_time_ms BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (task_id) REFERENCES processing_tasks(task_id)
);

CREATE INDEX IF NOT EXISTS idx_results_task ON processing_results(task_id);
CREATE INDEX IF NOT EXISTS idx_results_arc ON processing_results(arc_id);

CREATE TABLE IF NOT EXISTS stream_updates (
    update_id SERIAL PRIMARY KEY,
    arc_id INTEGER NOT NULL,
    new_average_speed DOUBLE PRECISION NOT NULL,
    sample_count INTEGER NOT NULL,
    timestamp_ms BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_stream_arc ON stream_updates(arc_id);
CREATE INDEX IF NOT EXISTS idx_stream_timestamp ON stream_updates(timestamp_ms);

