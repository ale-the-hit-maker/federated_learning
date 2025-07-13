# Federated Learning for ICU Length-of-Stay Prediction using MIMIC-IV and OMOP-CDM

## Overview

This repository contains the complete implementation of a research project aimed at predicting Length of Stay (LoS) for patients admitted to Intensive Care Units (ICU). The core of the project is a recurrent neural network model, specifically a Long Short-Term Memory (LSTM), trained on sequential clinical data to learn patient trajectories over time.

The key innovation of this work lies in the adoption of a **Federated Learning (FL)** paradigm. This approach enables training a global and robust model by simulating collaboration between multiple "virtual hospitals" without the need to centralize or share sensitive patient data. To ensure interoperability and data consistency, the project is built on two fundamental pillars of clinical research: the **MIMIC-IV** database (Medical Information Mart for Intensive Care IV), one of the richest sources of real clinical data, and its conversion to the **OMOP Common Data Model (CDM)** standard, which allows harmonization of data from heterogeneous sources.

## Motivation and Context: Privacy-Preserving AI in Healthcare

Modern medical research relies on the ability to analyze large and diverse quantities of clinical data. However, this data, essential for scientific progress, is often trapped in "information silos" within individual hospital structures. This fragmentation is due to two main obstacles: the heterogeneity of storage systems (Electronic Health Records - EHR) and stringent privacy regulations protecting patient data (such as GDPR in Europe and HIPAA in the United States), which prevent direct sharing.

This situation creates a paradox: to develop accurate and generalizable predictive models, it is necessary to access data from large and varied populations, but technical and legal barriers make such access extremely complex. **Federated Learning** emerges as an elegant solution to this problem, proposing a paradigm shift: **instead of bringing data to the model, we bring the model to the data**.

The principle is conceptually simple but powerful. A central server distributes a machine learning model to multiple clients (in this case, hospitals). Each client trains the model locally using their own data, which never leaves the local infrastructure. Subsequently, only the model updates (weights or gradients), which are aggregated and anonymous, are sent to the central server. The server aggregates these contributions to create a new, more performant global model, which is then redistributed for a new training cycle.

This project is not motivated solely by the need to protect privacy, but also by a crucial scientific objective. A model trained on data from a single hospital is intrinsically limited and potentially biased by the specificities of the local population and adopted clinical protocols. Conversely, a global model trained through Federated Learning has the potential to generalize much more effectively, capturing the nuances and variabilities present in a wide cohort of geographically distributed patients. The ultimate goal is therefore twofold: to overcome privacy barriers to enable collaboration and, through this collaboration, to build a scientifically superior predictive model, more robust and reliable than any locally trained model. This repository provides an end-to-end prototype that demonstrates the feasibility of this approach for reproducible and collaborative research in intensive care.

## System Architecture

The project architecture is designed to be modular and reproducible, covering the entire data lifecycle, from raw form to use in the machine learning model. Below is a detailed description of each phase of the pipeline, accompanied by a visual diagram.

### Workflow Diagram

```mermaid
graph TD
    A[MIMIC-IV CSV Files] --> B["PostgreSQL DB (Native Schema)"]
    B --> |ETL Scripts Execution| C["PostgreSQL DB (OMOP CDM Schema)"]
    C --> |Cohort Definition ATLAS| D[Target Cohort]
    D --> |Query Execution| E[Extracted Clinical Data]
    E --> |Python Preprocessing Script| F[Tensorized Data]
    F --> G[Model Training]
    G --> H[Centralized Training]
    G --> I[Federated Learning Simulation]
```

### Architectural Breakdown

1. **Data Ingestion and Standardization**: The starting point is the raw MIMIC-IV dataset, provided as CSV files. These files are loaded into a PostgreSQL database, preserving their native structure. Subsequently, a complex series of Extract, Transform, Load (ETL) scripts, inspired by those maintained by the OHDSI community, are executed to map and transform data from the native MIMIC-IV schema to the OMOP Common Data Model standard. This phase, although computationally intensive, is fundamental to ensure semantic and structural harmonization of data, making large-scale analysis possible.

2. **Cohort Definition**: Once data is available in OMOP CDM format, the study population is defined. Using the ATLAS tool from the OHDSI community, a cohort of patients with specific criteria is defined (e.g., male patients with at least one ICU admission). ATLAS automatically generates a complex SQL script, which is then executed on the OMOP database to extract all clinical data related only to patients who meet the inclusion criteria.

3. **Feature Engineering and Tensorization**: The extracted cohort data is processed by a Python script. For each patient, the script reconstructs their sequential clinical history, extracting all relevant events (diagnoses, procedures, medications, measurements) that occurred in a predefined time window (e.g., 365 days prior to ICU admission). This sequence of events is transformed into a three-dimensional tensor with dimensions `[number_patients, timesteps, number_features]`, which represents the ideal input for an LSTM model. To handle the high volume of data without exhausting RAM memory, the tensor is created on disk using the memory-mapping technique (numpy.memmap), a solution that proved necessary to overcome hardware limitations encountered during development.

4. **Model Training**:
   - **Centralized Baseline**: Initially, an LSTM model is trained on the entire dataset to establish a reference performance.
   - **Federated Simulation**: To simulate a multi-institutional environment, the dataset is partitioned into disjoint subsets, where each partition represents a "virtual hospital". A federated training cycle is then orchestrated, using the Federated Averaging (FedAvg) algorithm, to train a global model without ever merging data from individual partitions.

## Key Technical Components

This section delves into the technologies and key concepts that form the foundation of the project, explaining the reasoning behind each technical choice.

### Dataset: MIMIC-IV and OMOP CDM

**MIMIC-IV**: Acronym for Medical Information Mart for Intensive Care IV, is a large public and de-identified database containing detailed clinical data from tens of thousands of patients admitted to intensive care units at Beth Israel Deaconess Medical Center in Boston. Developed and maintained by the MIT Laboratory for Computational Physiology, MIMIC-IV is an invaluable resource for clinical research and the development of artificial intelligence algorithms in healthcare.

**OMOP CDM**: The Observational Medical Outcomes Partnership Common Data Model is an open and international standard designed to harmonize observational healthcare data from heterogeneous sources. Its function is to transform data with different structures and vocabularies into a common format, thus facilitating research reproducibility and large-scale analyses. The adoption of OMOP CDM in this project is an essential prerequisite for simulating a multi-institutional environment, as it ensures that data from each "virtual hospital" speaks the same language. The transformation was guided by tools and best practices from the OHDSI community.

### Prediction Task: ICU Length of Stay

The model's task is formally defined as a regression problem:

- **Input**: A temporal sequence of clinical events (diagnoses, procedures, medications, laboratory tests) related to a patient, extracted from a 365-day observation window preceding the moment of ICU admission (t=0).
- **Output**: A single continuous numerical value that predicts the total duration of the patient's ICU stay, measured in days.

### Model Architecture: LSTM Network

The choice of a Long Short-Term Memory (LSTM) network is motivated by its intrinsic ability to model long-term dependencies within sequential data. A patient's clinical history is a complex temporal sequence, where past events can have a significant impact on future outcomes; LSTMs are specifically designed to capture these temporal relationships. The architecture of the model implemented in TensorFlow/Keras is as follows:

- **InputLayer**: Defines the shape of the input tensor (`[timesteps, features]`).
- **Masking**: A fundamental layer that ignores timesteps that do not contain data (padding), allowing the model to handle variable-length sequences.
- **LSTM (units=64, return_sequences=True)**: The first LSTM layer that processes the sequence and returns output for each timestep.
- **Dropout (0.2)**: Regularization layer to reduce overfitting.
- **LSTM (units=32)**: A second LSTM layer that receives the processed sequence and returns only the output of the last timestep.
- **Dense (units=16, activation='relu')**: A first dense layer for final processing.
- **Dense (units=1, activation='linear')**: The final output layer with linear activation, appropriate for a regression task.

```python
model = Sequential([
    InputLayer(input_shape=(timesteps, features)),
    Masking(mask_value=0.0),
    LSTM(units=64, return_sequences=True),
    Dropout(0.2),
    LSTM(units=32),
    Dense(units=16, activation='relu'),
    Dense(units=1, activation='linear')
])
```

### Federated Learning Paradigm

Since MIMIC-IV comes from a single center, to evaluate the federated approach it was necessary to simulate a multi-institutional environment. This was achieved by partitioning the complete dataset into several non-overlapping subsets, each representing a client (or "hospital"). Training was orchestrated using the Federated Averaging (FedAvg) algorithm, where a central server coordinates the training process by aggregating weights from models trained locally by each client.

One of the main challenges in Federated Learning, which this project proposes to address in the future, is the management of Non-IID (Non-Independently and Identically Distributed) data. In the real world, the distribution of clinical data varies significantly between different hospitals (due to specialization, patient demographics, etc.). Simulation on partitioned data allows studying the impact of this heterogeneity on convergence and global model performance.

## Repository Structure

To facilitate navigation and understanding of the code, the repository is organized according to the following structure, inspired by open-source reference projects like mimic-code:

```
.
├── cohort_definition/
│   └── icu_male_patients.sql         # SQL query generated by ATLAS for cohort definition
├── etl_scripts/
│   ├── 1_ddl/                        # SQL scripts for OMOP table creation (DDL)
│   ├── 2_staging/                    # SQL scripts for intermediate table creation (staging)
│   ├── 3_etl/                        # SQL scripts for ETL transformation logic
│   └── 4_vocab/                      # Scripts for OHDSI vocabulary loading
├── federated_learning/
│   └── hospital_federated_learning.py # Main Python script for feature engineering and training
├── notebooks/
│   └── exploratory_analysis.ipynb    # (Optional) Notebook for exploratory data analysis
├── requirements.txt                  # Python project dependencies
└── README.md                         # This file
```

## Getting Started: Experiment Replication

This section provides a detailed, step-by-step guide to replicate the entire workflow, from data preparation to model training.

### 1. Prerequisites

Ensure you have the following software installed:

- Git
- Python 3.9 or higher
- PostgreSQL 12 or higher

Clone the repository and install Python dependencies:

```bash
# Clone the repository
git clone https://github.com/ale-the-hit-maker/federated_learning.git
cd federated_learning

# Install dependencies
pip install -r requirements.txt
```

### 2. Data Acquisition

To run the project, two main datasets are required:

1. **MIMIC-IV**: Access to the MIMIC-IV database is controlled. You need to request it through the PhysioNet platform, completing the mandatory training course on human data protection ("CITI Data or Specimens Only Research"). Once access is obtained, download the database CSV files.

2. **OHDSI Vocabularies**: Standardized vocabularies (e.g., SNOMED, RxNorm, LOINC, ICD10) are essential for the ETL process. They can be downloaded from the OHDSI community's Athena portal after registration.

### 3. Database Setup and ETL Execution

**Configure PostgreSQL**: Create a database and a user dedicated to the project. For detailed instructions and common problem resolution (e.g., authentication errors), refer to the mimic-code repository documentation.

**Execute ETL Scripts**: Scripts in the `etl_scripts/` folder must be executed in precise order to correctly populate the database with data in OMOP CDM format:

1. **Load Vocabularies**: Execute scripts in `etl_scripts/4_vocab/` to load vocabularies downloaded from Athena.
2. **Create OMOP Tables**: Execute scripts in `etl_scripts/1_ddl/` to create the OMOP schema table structure.
3. **Load MIMIC-IV Data**: Load MIMIC-IV CSV files into native schema tables.
4. **Execute Transformation**: Execute scripts in `etl_scripts/2_staging/` and `etl_scripts/3_etl/` sequentially to complete the conversion.

#### A Note on Vocabulary Validation

During the vocabulary loading phase, quality control scripts may report inconsistencies. Experience gained during this internship has shown that some of these "errors" are actually intrinsic characteristics of complex standard vocabularies. For example:

- **Inconsistent Dates (check_id=7)**: Some concepts might have a past valid_end_date while still being marked as valid. This behavior has been observed even on the official Athena portal and does not compromise the ETL process, which is primarily based on the invalid_reason field.

- **Multiple Substitution Relationships (check_id=10)**: A concept might have multiple active equivalence relationships toward standard concepts. Again, this is a known complexity of the vocabulary (e.g., SNOMED). The ETL is designed to prioritize the "Maps to" relationship, resolving ambiguity.

These issues, while requiring attention, do not block the process and can be documented as part of the source data characteristics.

### 4. Cohort Generation

The SQL script `cohort_definition/icu_male_patients.sql` contains the logic to identify the study population. Execute this script on the OMOP database to populate the `target_cohort` table in the results schema.

### 5. Training Pipeline Execution

The main script `federated_learning/hospital_federated_learning.py` handles the entire process of feature engineering, tensorization, and model training.

To start it, execute the following command from the repository root:

```bash
python federated_learning/hospital_federated_learning.py
```

#### Memory Management

This script has been optimized to work with large datasets on machines with limited hardware resources. During development, assembling the input tensor in RAM caused system crashes. To solve this problem, the script uses the `numpy.memmap` function to create the `X_tensor.mmap` tensor directly on disk. This approach dramatically reduces RAM usage but requires adequate disk space in the results folder.

## Experimental Results

This section is a template intended to be filled with results obtained from running the experiments.

### Centralized Training Performance

**Training Progress**: Below is the loss curve for training and validation of the centralized LSTM model. The monitored metric was val_loss, and Early Stopping techniques were used to interrupt training at the optimal moment and prevent overfitting.

*(Insert training_history.png image here)*

**Evaluation Metrics**: The final model was evaluated on a held-out test set. Performance is summarized in the following table:

| Metric | Value | Description |
|--------|-------|-------------|
| Mean Squared Error (MSE) | TO BE FILLED | The average of squared differences between predicted and actual values |
| Mean Absolute Error (MAE) | TO BE FILLED | The average of absolute differences, representing the average prediction error in days |

### Federated Learning Simulation (Future Work)

This section will present preliminary results of the federated simulation, comparing the performance of the global model with the centralized baseline.

*(Insert table or chart comparing centralized vs. federated model performance)*

## Future Developments

This project lays the foundation for numerous future research directions:

1. **Complete Federated Learning Implementation**: Finalize the FL algorithm implementation and conduct rigorous evaluation, exploring aggregation strategies alternative to FedAvg.

2. **Non-IID Data Analysis**: Conduct in-depth experiments to analyze model performance in more realistic Non-IID data scenarios, simulating different heterogeneities between clients.

3. **Hyperparameter Optimization**: Perform systematic search for optimal hyperparameters for both the LSTM model and the federated training process (e.g., learning rate, number of local epochs, client fraction per round).

4. **Alternative Architecture Exploration**: Evaluate the effectiveness of other deep learning architectures for sequential data, such as Transformers or Gated Recurrent Units (GRU).

5. **Application to Other Clinical Tasks**: Adapt the existing pipeline to address other relevant prediction problems in clinical settings, such as mortality prediction, sepsis onset, or readmission risk.

## Citation and Acknowledgments

### Citing this Repository

If you use the code from this repository for your research, please cite it as follows:

```bibtex
@misc{federated_lstm_mimic_omop_2024,
  author = {Alessandro Villani},
  title = {Federated Learning for ICU Length-of-Stay Prediction using MIMIC-IV and OMOP-CDM},
  year = {2024},
  publisher = {GitHub},
  journal = {GitHub repository},
  howpublished = {\url{https://github.com/ale-the-hit-maker/federated_learning}}
}
```

### Acknowledgments

This work would not have been possible without the following fundamental resources:

- The **MIMIC-IV database**, for which we thank the MIT Laboratory for Computational Physiology for its creation and maintenance. Please cite MIMIC-IV as described on its PhysioNet project page.

- The **OHDSI community** (Observational Health Data Sciences and Informatics), for the development of the OMOP Common Data Model, the ATLAS tool, and the ETL scripts that have been an indispensable guide for data standardization.

## License

This project is released under the MIT License. For more details, see the LICENSE file.
