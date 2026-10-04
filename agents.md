# AGENTS.md — Real-Time Spatial Engineering Agent Specifications

## System Goal & Architecture
**Project Name:** North India AQI & Stubble Burning Real-Time Spatial Pipeline  
**Goal:** Build a production-grade, distributed data streaming platform that ingests satellite thermal data (NASA FIRMS), ground-station AQI metrics (CPCB/OpenAQ), and wind vectors (Open-Meteo) across North India (Punjab, Haryana, Delhi-NCR). Process streaming events using **PySpark Structured Streaming**, index location coordinates into **Uber H3 spatial cells (Resolution 7)**, stream into **Delta Lake**, and render a **3D spatial map** using Streamlit and PyDeck.

[ NASA FIRMS API ] ──────(1-3 hr poll)───┐
[ OpenAQ CPCB API ] ─────(1 hr poll)────┼──> [ Python Ingestion Producer ]
[ Open-Meteo API ] ──────(1 hr poll)────┘              │
▼
[ Apache Kafka / Redpanda ]
│
▼
[ PySpark Structured Streaming ]
├── JSON Schema Extraction
├── Uber H3 Spatial Hex Binning (Res 7)
├── Watermarking (15-min) & Windowing (1-hr)
└── Stream-to-Stream Aggregations
│
▼
[ Delta Lake / Parquet Storage ]
│
▼
[ Streamlit + PyDeck 3D Map UI ]


---

## Toolchain & Runtime Environment

| Layer | Technology | Version / Spec |
| :--- | :--- | :--- |
| **Language** | Python | 3.11+ |
| **Stream Engine** | PySpark | 3.5.x with `delta-spark` 3.1.0 |
| **Message Bus** | Apache Kafka | Confluent Platform / Redpanda (`docker-compose`) |
| **Spatial Index** | Uber H3 | `h3-py` >= 4.0.0 (`latlng_to_cell`) |
| **Storage Layer** | Delta Lake | Parquet Lakehouse (`/data/delta/`) |
| **Dashboard** | Streamlit + PyDeck | 3D Hexagon & Surface Map Layer |

### Core Infrastructure & Execution Commands
```bash
# 1. Start message broker and Spark environment
docker-compose up -d

# 2. Execute Python API Ingestion Producers
python -m ingestion.nasa_firms_producer
python -m ingestion.openaq_producer
python -m ingestion.open_meteo_producer

# 3. Submit Spark Structured Streaming Job
spark-submit \
  --packages io.delta:delta-spark_2.12:3.1.0,org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.0 \
  processing/spark_stream_processor.py

# 4. Launch 3D Streamlit Visualization UI
streamlit run dashboard/app.py
Technical Specifications & Schemas
Spatial Bounding Box (North India Corridor)
West: 73.0 | South: 28.0 | East: 78.0 | North: 33.0

External Data APIs
NASA FIRMS (Satellite Thermal Anomalies):
https://firms.modaps.eosdis.nasa.gov/api/area/csv/{MAP_KEY}/VIIRS_SNPP_NRT/73,28,78,33/1

OpenAQ v3 (CPCB Ground Sensors):
https://api.openaq.org/v3/locations?country_id=IN&parameters_id=2

Open-Meteo (Wind Vectors):
https://api.open-meteo.com/v1/forecast?latitude=28.6139&longitude=77.2090&current=wind_speed_10m,wind_direction_10m

Data Schemas & Topics
Kafka Topic: stubble-fires

JSON
{
  "latitude": 30.375,
  "longitude": 74.850,
  "brightness": 325.4,
  "frp": 14.2,
  "acq_datetime": "2026-10-03T08:30:00Z"
}
Kafka Topic: cpcb-aqi

JSON
{
  "location_id": "IN-CPCB-001",
  "latitude": 28.613,
  "longitude": 77.209,
  "pm25": 184.5,
  "aqi": 342,
  "acq_datetime": "2026-10-03T09:00:00Z"
}
Kafka Topic: wind-vectors

JSON
{
  "latitude": 28.6139,
  "longitude": 77.2090,
  "wind_speed_10m": 12.4,
  "wind_direction_10m": 315.0,
  "acq_datetime": "2026-10-03T09:00:00Z"
}
Delta Lake Output Table: /data/delta/stubble_aqi_h3

Partition Keys: year, month, day, h3_index

Spatial Index: Uber H3 Resolution 7 (h3.latlng_to_cell(lat, lng, 7))

Three-Tier Guardrail Rules for AI Agents
🚫 NEVER DO
Never mock external API data in production ingestion producers. Scripts in /ingestion must execute live calls against external APIs.

Never execute HTTP REST calls directly inside PySpark UDFs or worker tasks. Ingestion fetching must occur exclusively in standalone Python producers (/ingestion).

Never use PySpark inferSchema on Kafka streaming string records. Always define explicit StructType schemas for incoming JSON topics.

Never tamper with auto-generated Delta Lake checkpoints in /data/checkpoints/ or corrupt Parquet commit logs in /data/delta/.

⚠️ ASK FIRST
Ask before adding heavy third-party Java/Python packages to docker-compose.yml or spark-submit.

Ask before changing the spatial Uber H3 resolution level (Resolution 7 is default; changing impacts partition sizes and memory joins).

Ask before adjusting Spark Structured Streaming watermarking windows (Default threshold: 15 minutes).

✅ ALWAYS DO
Always implement exponential backoff retry mechanisms (using the tenacity library) on external REST API HTTP requests.

Always ensure compatibility with h3-py >= v4.0 (Use h3.latlng_to_cell(lat, lng, res) instead of legacy geo_to_h3).

Always specify explicit checkpoint paths (.option("checkpointLocation", ...) ) on every PySpark streaming write pipeline.

Always adhere strictly to the target project layout:

Plaintext
.
├── docker-compose.yml
├── ingestion/
│   ├── nasa_firms_producer.py
│   ├── openaq_producer.py
│   └── open_meteo_producer.py
├── processing/
│   └── spark_stream_processor.py
├── dashboard/
│   └── app.py
├── data/
│   ├── delta/
│   └── checkpoints/
└── AGENTS.md
Phase-by-Phase Roadmap
Phase 1: Infrastructure & Message Bus Setup
[ ] Create docker-compose.yml running Apache Kafka (Zookeeper/KRaft mode) and a PySpark driver with Delta Lake 3.1.0 support.

[ ] Ensure shared directory volumes exist for /data/delta/ and /data/checkpoints/.

Phase 2: Ingestion Producers
[ ] Build ingestion/nasa_firms_producer.py to query NASA FIRMS CSV for North India bounding box 73,28,78,33 and push payloads to Kafka topic stubble-fires.

[ ] Build ingestion/openaq_producer.py to query OpenAQ v3 for India (PM 
2.5
​
 ) and push to Kafka topic cpcb-aqi.

[ ] Build ingestion/open_meteo_producer.py to query wind metrics for Delhi-NCR and push to Kafka topic wind-vectors.

Phase 3: PySpark Spatial Processing
[ ] Implement processing/spark_stream_processor.py:

Define StructType schemas for all incoming Kafka payloads.

Register Uber H3 PySpark UDF mapping latitude/longitude to Resolution 7 cells.

Set a 15-minute event timestamp watermark and execute 1-hour tumbling window aggregations (total_frp, avg_pm25).

Write output stream to Delta Lake format at /data/delta/stubble_aqi_h3.

Phase 4: Visualization Dashboard
[ ] Build dashboard/app.py using Streamlit and PyDeck.

[ ] Load Delta Lake Parquet data and render a 3D HexagonLayer over Punjab/Haryana (height representing Fire Radiative Power) and AQI surface layer over Delhi-NCR.


---

<ElicitationsGroup message="Where would you like to start?">
  <Elicitation label="Generate Phase 1 docker-compose.yml file" query="Provide the complete Docker Compose file to run Apache Kafka and PySpark with Delta Lake setup."/>
  <Elicitation label="Generate Phase 2 ingestion producer scripts" query="Write the complete Python ingestion scripts with rate limiting for NASA FIRMS, OpenAQ, and Open-Meteo."/>
</ElicitationsGroup>
