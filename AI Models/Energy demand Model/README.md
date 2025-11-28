# Industry Electricity Consumption Prediction

## About the Project

This project develops a machine learning model using GRU (Gated Recurrent Unit) neural networks to predict electricity consumption in an industry setting. The model leverages time series data to forecast energy usage, which can be crucial for energy management and cost optimization.

## Features

- Visualization of electricity consumption trends
- Time series data normalization
- Advanced deep learning model using GRU layers
- Train-test split for model evaluation
- Prediction and visualization of electricity consumption

## Prerequisites

Before you begin, ensure you have the following installed:

- Python 3.8+
- Jupyter Notebook (optional, but recommended)

## Installation

1. Clone the repository:
```bash
git clone https://github.com/Mrpriven/TSYP12-IAS-challenge-IEEE-SUPCOM-SB/tree/main/AI%20Models/Energy%20demand%20Model
cd energy demand Model
```

2. Install the required libraries:
```bash
pip install -r requirements.txt
```

### Requirements File (requirements.txt)

Create a `requirements.txt` file with the following content:

```
pandas==2.0.1
numpy==1.24.3
matplotlib==3.7.1
scikit-learn==1.2.2
tensorflow==2.12.0
openpyxl==3.1.2
```

## Usage

1. Place your Excel dataset named `Hospital Building Dataset.xlsx` in the project directory.
2. Run the Jupyter Notebook or Python script:
```bash
python electricity_consumption_prediction.py
```

## Model Architecture

The model uses a GRU-based neural network with the following key components:
- Input layer: 60 time steps
- First GRU layer: 256 units
- Global Max Pooling
- Dropout for regularization
- Second GRU layer: 256 units
- Dense layers for final prediction




