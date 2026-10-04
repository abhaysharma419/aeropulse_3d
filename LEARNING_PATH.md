# Batch-First Learning Path: AeroPlus 3D Pipeline

## Context

You're a data engineer comfortable with API ingestion, batch processing, SQL, and Python, but new to PySpark and spatial operations. The agents.md file describes a streaming architecture that's too complex to learn all at once. This plan takes a **batch-first approach**: master PySpark DataFrame operations, H3 spatial indexing, and Delta Lake with static datasets before converting to streaming. This mirrors how production systems are actually built - validate the logic on historical data, then make it real-time.

**Why this works:**
- You can inspect data at each step without time pressure
- Debugging is simpler (re-run a cell vs restarting a stream)
- The transformations are identical - batch PySpark code converts to streaming with minimal changes
- You build confidence with the core concepts before adding streaming complexity

## Learning Phases

### Phase 0: Environment Setup (Docker-based)
**Goal:** Get a working PySpark + Jupyter + Delta Lake environment without Python dependency hell.

**Files to create:**
- `docker-compose.yml` - Jupyter notebook server with PySpark 3.5.x, Delta Lake 3.1.0, h3-py 4.x
- `requirements.txt` - Python packages: pyspark, delta-spark, h3, pandas, requests, tenacity, streamlit, pydeck
- `notebooks/00_environment_check.ipynb` - Verify PySpark, H3, Delta Lake are working
- `.env.example` - Placeholder for API keys (NASA FIRMS, OpenAQ if needed)

**What you'll learn:** Docker volume mapping, Jupyter + PySpark integration

---

### Phase 1: Fetch & Explore Raw Data (No PySpark Yet)
**Goal:** Get familiar with the three data sources and their schemas. Use plain Python to understand what you're working with.

**Files to create:**
- `scripts/fetch_sample_data.py` - Pull 1 day of data from each API:
  - NASA FIRMS: fires in North India bounding box (73,28,78,33)
  - OpenAQ: CPCB PM2.5 sensors
  - Open-Meteo: wind vectors for Delhi-NCR grid points
- `data/raw/` directory - Save JSON responses here
- `notebooks/01_data_exploration.ipynb` - Load JSON files, inspect schemas, visualize coordinates on a simple scatter plot

**What you'll learn:** 
- API response structures
- Lat/lon bounding boxes
- Data quality issues (missing fields, outliers)

**No algorithms yet** - just fetch, save, look at the data.

---

### Phase 2: Your First PySpark DataFrame Operations
**Goal:** Load the raw JSON data into PySpark, define explicit schemas, perform basic filtering and aggregations.

**Files to create:**
- `notebooks/02_pyspark_basics.ipynb`:
  - Create SparkSession with Delta Lake support
  - Define `StructType` schemas for fires, AQI, wind
  - Load JSON files into DataFrames
  - Basic operations: `.select()`, `.filter()`, `.groupBy()`, `.agg()`
  - Save as Parquet to `data/processed/`

**What you'll learn:**
- SparkSession initialization
- Explicit schema definition (why `inferSchema=False` for production)
- DataFrame API (lazy evaluation, actions vs transformations)
- Parquet file format

**Key concept:** PySpark DataFrames are lazy - nothing happens until you call `.show()`, `.write()`, or `.count()`

---

### Phase 3: Spatial Indexing with Uber H3
**Goal:** Understand why H3 exists and how to use it. Convert (lat, lon) points to hexagonal cell IDs.

**Files to create:**
- `notebooks/03_spatial_h3.ipynb`:
  - Register H3 as a PySpark UDF: `h3.latlng_to_cell(lat, lng, 7)`
  - Apply to fires, AQI sensors, wind points
  - Group by H3 cell, aggregate fire counts, avg PM2.5
  - Visualize H3 cells on a map (folium or simple matplotlib)

**What you'll learn:**
- Why hexagons? (equal area, no edge/corner bias, hierarchical)
- Resolution 7 = ~5.16 km² per cell (good for regional analysis)
- UDFs in PySpark (user-defined functions)
- Spatial aggregation pattern

**Key insight:** H3 turns scattered points into a consistent grid you can join and aggregate.

---

### Phase 4: Multi-Source Joins & Time Windows
**Goal:** Combine fires + AQI + wind data. Learn PySpark joins and time-based grouping.

**Files to create:**
- `notebooks/04_joins_and_windows.ipynb`:
  - Parse timestamps to PySpark `timestamp` type
  - Create 1-hour time windows: `window(col("acq_datetime"), "1 hour")`
  - Join fires + wind by H3 cell and time window
  - Calculate: total fire radiative power per cell, avg wind speed per cell
  - Left join with AQI sensors (not every cell has a sensor)

**What you'll learn:**
- PySpark joins: `.join(other_df, on="h3_index", how="left")`
- Time windowing with `window()` function
- Aggregations: `sum()`, `avg()`, `count()`

**Key concept:** Joins are expensive - use H3 cells and time windows to reduce cardinality before joining.

---

### Phase 5: Delta Lake Storage Layer
**Goal:** Write processed data to Delta Lake. Learn why Delta > plain Parquet.

**Files to create:**
- `notebooks/05_delta_lake.ipynb`:
  - Write aggregated H3 data to Delta format: `.write.format("delta").mode("overwrite").save("data/delta/stubble_aqi_h3")`
  - Partition by date: `.partitionBy("year", "month", "day")`
  - Read back from Delta
  - Demonstrate Delta features: schema evolution, time travel, ACID writes

**What you'll learn:**
- Delta Lake format (Parquet + transaction log)
- Why partition keys matter (query performance)
- `mode("overwrite")` vs `mode("append")`
- Delta's ACID guarantees

**Key insight:** Delta Lake is Parquet with a commit log - you get ACID, schema enforcement, and time travel for free.

---

### Phase 6: End-to-End Batch Pipeline
**Goal:** Tie everything together in a single script you can run daily.

**Files to create:**
- `scripts/batch_pipeline.py`:
  - Fetch yesterday's data from all 3 APIs (with tenacity retry)
  - Load into PySpark with explicit schemas
  - Apply H3 spatial indexing
  - Time window aggregations
  - Multi-source join
  - Write to Delta Lake partitioned by date
- `notebooks/06_pipeline_validation.ipynb` - Query Delta Lake, spot-check results

**What you'll learn:**
- Production patterns: retry logic, error handling, logging
- Command-line args: `python batch_pipeline.py --date 2026-10-02`
- Idempotent pipelines (re-running the same date overwrites safely)

---

### Phase 7: Simple Streamlit Dashboard
**Goal:** Visualize your batch results in 3D using PyDeck.

**Files to create:**
- `dashboard/app.py`:
  - Load latest partition from Delta Lake
  - PyDeck HexagonLayer: height = fire radiative power, color = PM2.5
  - Simple filters: date selector, layer toggles
- Run with: `streamlit run dashboard/app.py`

**What you'll learn:**
- Streamlit basics (caching, widgets)
- PyDeck 3D visualization
- Delta Lake as a serving layer

**Key insight:** Your batch pipeline produces the same schema that streaming will - the dashboard works for both.

---

### Phase 8: Convert Batch → Streaming (The Easy Part)
**Goal:** Show that the transformations you already wrote work in streaming mode with minimal changes.

**Files to create:**
- `docker-compose.yml` - Add Kafka/Redpanda container
- `scripts/streaming_producers.py` - Push sample data to Kafka every 10 seconds (simulation)
- `scripts/spark_streaming.py`:
  - Replace `spark.read.json()` with `spark.readStream.format("kafka")`
  - **Same transformations** (H3 UDF, joins, aggregations)
  - Add watermarking: `.withWatermark("acq_datetime", "15 minutes")`
  - Write stream: `.writeStream.format("delta").outputMode("append").option("checkpointLocation", ...)`

**What you'll learn:**
- Kafka topic structure
- PySpark Structured Streaming API (readStream/writeStream)
- Watermarking (handles late data)
- Checkpointing (exactly-once semantics)

**Key insight:** The core logic (schemas, H3, joins, aggregations) is identical. You just changed the read/write APIs.

---

## Project Structure

```
aeropulse_3d/
├── docker-compose.yml
├── requirements.txt
├── .env.example
├── scripts/
│   ├── fetch_sample_data.py          # Phase 1
│   ├── batch_pipeline.py             # Phase 6
│   ├── streaming_producers.py        # Phase 8
│   └── spark_streaming.py            # Phase 8
├── notebooks/
│   ├── 00_environment_check.ipynb    # Phase 0
│   ├── 01_data_exploration.ipynb     # Phase 1
│   ├── 02_pyspark_basics.ipynb       # Phase 2
│   ├── 03_spatial_h3.ipynb           # Phase 3
│   ├── 04_joins_and_windows.ipynb    # Phase 4
│   ├── 05_delta_lake.ipynb           # Phase 5
│   └── 06_pipeline_validation.ipynb  # Phase 6
├── dashboard/
│   └── app.py                        # Phase 7
├── data/
│   ├── raw/                          # JSON from APIs
│   ├── processed/                    # Parquet intermediates
│   ├── delta/                        # Delta Lake tables
│   └── checkpoints/                  # Streaming checkpoints
└── agents.md                         # Original spec (streaming-first)
```

## Verification Strategy

After each phase:
1. **Jupyter notebooks:** Run all cells, verify outputs match expectations
2. **Batch script:** `python scripts/batch_pipeline.py --date 2026-10-02` should complete without errors
3. **Delta Lake validation:** Query with `spark.read.format("delta").load("data/delta/stubble_aqi_h3")` and spot-check row counts, date ranges
4. **Dashboard:** `streamlit run dashboard/app.py` should render 3D map with data

## What You'll Understand After This

**Spatial concepts:**
- Why hexagonal grids (H3) are better than lat/lon squares
- How to aggregate point data (fires, sensors) into spatial cells
- Spatial joins (fires + wind in the same cell)

**PySpark fundamentals:**
- DataFrame API (select, filter, groupBy, agg, join)
- Lazy evaluation (transformations vs actions)
- UDFs for custom logic (H3 spatial indexing)
- Time windowing for temporal aggregations

**Delta Lake advantages:**
- ACID transactions (safe concurrent writes)
- Schema enforcement (catches data quality issues)
- Partitioning for query performance
- Time travel (query historical versions)

**Streaming mindset:**
- Batch = process all data once
- Streaming = run the same logic continuously on new data
- Watermarking = tolerate late arrivals
- Checkpointing = survive failures without data loss

## Next Steps After Completion

Once you've completed Phase 8, you'll be ready for:
- **Real-time deployment:** Run streaming jobs 24/7 with proper monitoring
- **Advanced windowing:** Sliding windows, session windows
- **Stream-to-stream joins:** Join two live Kafka topics
- **Complex event processing:** Detect fire clusters, predict AQI spikes
- **MLlib integration:** Train models on historical Delta Lake data, score in streaming

## Timeline Estimate

- **Phase 0-3:** 1-2 days (environment + basic PySpark)
- **Phase 4-5:** 1-2 days (joins, Delta Lake)
- **Phase 6-7:** 1 day (pipeline + dashboard)
- **Phase 8:** Half day (streaming conversion)

Total: **4-6 days** at a comfortable learning pace.
