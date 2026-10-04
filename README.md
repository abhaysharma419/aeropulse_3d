# AeroPulse 3D

A comprehensive air quality monitoring and visualization platform that integrates multiple data sources including NASA FIRMS (fire data), OpenAQ (air quality), and Open-Meteo (weather data) to provide real-time insights into environmental conditions.

## Features

- **Multi-source Data Integration**: Combines fire incidents, air quality metrics, and weather data
- **3D Visualization**: Interactive visualization capabilities for spatial data analysis
- **Real-time Monitoring**: Track environmental conditions with up-to-date data
- **Docker Support**: Containerized deployment for easy setup and scaling

## Project Structure

```
aeropulse_3d/
├── data/               # Data storage
│   ├── raw/           # Raw data from APIs
│   ├── processed/     # Processed and cleaned data
│   └── external/      # External datasets
├── notebooks/         # Jupyter notebooks for analysis
├── scripts/           # Utility scripts
├── dashboard/         # Dashboard application
├── docker-compose.yml # Docker configuration
└── requirements.txt   # Python dependencies
```

## Setup

### Prerequisites

- Python 3.8+
- Docker and Docker Compose (optional, for containerized deployment)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd aeropulse_3d
```

2. Create a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Set up environment variables:
```bash
cp .env.example .env
# Edit .env and add your NASA FIRMS API key
```

### Getting API Keys

- **NASA FIRMS**: Register at https://firms.modaps.eosdis.nasa.gov/api/ to get your MAP_KEY
- **OpenAQ**: No API key required for public access
- **Open-Meteo**: No API key required

### Docker Deployment

```bash
docker-compose up -d
```

## Usage

### Running Notebooks

```bash
jupyter notebook notebooks/
```

### Data Collection Scripts

```bash
python scripts/fetch_data.py
```

## Learning Resources

Check out [LEARNING_PATH.md](LEARNING_PATH.md) for a comprehensive guide on the technologies and concepts used in this project.

## Data Sources

- **NASA FIRMS**: Active fire data from satellite observations
- **OpenAQ**: Global air quality data from monitoring stations
- **Open-Meteo**: Weather and climate data

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.

## Acknowledgments

- NASA FIRMS for fire data
- OpenAQ for air quality data
- Open-Meteo for weather data
