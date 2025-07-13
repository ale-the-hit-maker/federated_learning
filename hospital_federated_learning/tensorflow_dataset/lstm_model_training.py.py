import pandas as pd
from sqlalchemy import create_engine
import numpy as np
from tqdm import tqdm
from sklearn.model_selection import train_test_split
import tensorflow as tf
import matplotlib.pyplot as plt
import os
import glob
import json

# -------------------------------------------------------------------
# --- FASE 1: CONFIGURAZIONE E CONNESSIONE ---
# -------------------------------------------------------------------
print("FASE 1: Configurazione e Connessione")
DB_CONNECTION_STR = 'postgresql://postgres:Aleinnet29Linux@localhost:5432/mimiciv'
DB_ENGINE = create_engine(DB_CONNECTION_STR)
CDM_SCHEMA = 'cdm_atlas'
RESULTS_SCHEMA = 'cdm_atlas'
VOCABULARY_SCHEMA = 'omop_cdm'

RESULTS_DIR = 'D:/results'
BATCH_OUTPUT_DIR = os.path.join(RESULTS_DIR, 'batches')
if not os.path.exists(RESULTS_DIR):
    os.makedirs(RESULTS_DIR)
if not os.path.exists(BATCH_OUTPUT_DIR):
    os.makedirs(BATCH_OUTPUT_DIR)
print(f"I file di output verranno salvati in: {os.path.abspath(RESULTS_DIR)}")

# -------------------------------------------------------------------
# --- FASE 2: CARICAMENTO COORTE E CREAZIONE/CARICAMENTO VOCABOLARIO ---
# -------------------------------------------------------------------
print("\nFASE 2: Caricamento Coorte e Creazione/Caricamento Vocabolario")
try:
    cohort_df = pd.read_sql(
        f"SELECT * FROM {RESULTS_SCHEMA}.target_cohort WHERE cohort_definition_id = 1",
        DB_ENGINE
    )
    cohort_df['cohort_start_date'] = pd.to_datetime(cohort_df['cohort_start_date'])
    cohort_df['cohort_end_date'] = pd.to_datetime(cohort_df['cohort_end_date'])
    cohort_df['admission_id'] = cohort_df['subject_id'].astype(str) + '_' + cohort_df['cohort_start_date'].dt.strftime(
        '%Y%m%d')
    cohort_df = cohort_df.sort_values(by='admission_id').reset_index(drop=True)
    cohort_df['length_of_stay'] = (cohort_df['cohort_end_date'] - cohort_df['cohort_start_date']).dt.days
    print(f"Trovati {len(cohort_df)} ricoveri.")
except Exception as e:
    print(f"ERRORE: Impossibile caricare la tabella della coorte. Dettagli: {e}")
    exit()

VOCAB_FILE_PATH = os.path.join(RESULTS_DIR, 'vocabulary.json')

if os.path.exists(VOCAB_FILE_PATH):
    print("File del vocabolario trovato. Caricamento da disco...")
    with open(VOCAB_FILE_PATH, 'r') as f:
        vocab_data = json.load(f)
    concept_to_int = {int(k): v for k, v in vocab_data['concept_to_int'].items()}
    vocab_size = vocab_data['vocab_size']
    print("Vocabolario caricato con successo.")
else:
    print("File del vocabolario non trovato. Creazione da database (potrebbe richiedere tempo)...")
    sql_all_concepts = f"""
        SELECT DISTINCT concept_id FROM (
            SELECT condition_concept_id AS concept_id FROM {CDM_SCHEMA}.condition_occurrence WHERE person_id IN %(subject_ids)s UNION ALL
            SELECT drug_concept_id FROM {CDM_SCHEMA}.drug_exposure WHERE person_id IN %(subject_ids)s UNION ALL
            SELECT procedure_concept_id FROM {CDM_SCHEMA}.procedure_occurrence WHERE person_id IN %(subject_ids)s UNION ALL
            SELECT measurement_concept_id FROM {CDM_SCHEMA}.measurement WHERE person_id IN %(subject_ids)s UNION ALL
            SELECT observation_concept_id FROM {CDM_SCHEMA}.observation WHERE person_id IN %(subject_ids)s
        ) all_concepts;
    """
    all_patient_ids_for_vocab = tuple([int(x) for x in cohort_df['subject_id'].unique()])
    all_concepts_df = pd.read_sql(sql_all_concepts, DB_ENGINE, params={'subject_ids': all_patient_ids_for_vocab})
    unique_concepts = all_concepts_df['concept_id'].dropna().unique()
    concept_to_int = {int(concept): i + 1 for i, concept in enumerate(unique_concepts)}
    vocab_size = len(concept_to_int) + 1

    print("Salvataggio del vocabolario su disco per le esecuzioni future...")
    vocab_data_to_save = {
        'concept_to_int': {str(k): v for k, v in concept_to_int.items()},
        'vocab_size': vocab_size
    }
    with open(VOCAB_FILE_PATH, 'w') as f:
        json.dump(vocab_data_to_save, f)
    print(f"Vocabolario salvato in: {VOCAB_FILE_PATH}")

print(f"Vocabolario finale pronto con {vocab_size - 1} concetti unici.")

# -------------------------------------------------------------------
# --- FASE 3: ESTRAZIONE DATI E CREAZIONE TENSORI SU DISCO ---
# -------------------------------------------------------------------
print("\nFASE 3: Estrazione Dati e Creazione Tensori su Disco")

MAX_SEQ_LENGTH = 182
WINDOW_START = -182
WINDOW_END = 0
BATCH_SIZE = 64

X_MEMMAP_PATH = os.path.join(RESULTS_DIR, 'X_tensor.mmap')
Y_ARRAY_PATH = os.path.join(RESULTS_DIR, 'y_array.npy')

# --- RETE DI SICUREZZA ---
# Controlla se i file finali della Fase 3 esistono già.
if os.path.exists(X_MEMMAP_PATH) and os.path.exists(Y_ARRAY_PATH):
    print("File di dati pre-processati trovati. SALTO DELLA FASE 3.")
else:
    print("File di dati non trovati. Avvio del processo di estrazione (potrebbe richiedere molto tempo)...")

    print(f"Creazione del file memory-mapped per il tensore X in: {X_MEMMAP_PATH}")
    X = np.memmap(X_MEMMAP_PATH, dtype=np.int8, mode='w+', shape=(len(cohort_df), MAX_SEQ_LENGTH, vocab_size))
    y = cohort_df['length_of_stay'].values

    for i in tqdm(range(0, len(cohort_df), BATCH_SIZE), desc="Processamento pazienti in lotti"):
        batch_admissions = cohort_df.iloc[i:i + BATCH_SIZE]
        batch_patient_ids = tuple([int(x) for x in batch_admissions['subject_id'].unique()])

        if not batch_patient_ids:
            continue

        sql_batch_events = f"""
            SELECT subject_id, event_date, concept_id FROM (
                SELECT person_id AS subject_id, condition_start_date AS event_date, condition_concept_id AS concept_id FROM {CDM_SCHEMA}.condition_occurrence WHERE person_id IN %(subject_ids)s UNION ALL
                SELECT person_id, drug_exposure_start_date, drug_concept_id FROM {CDM_SCHEMA}.drug_exposure WHERE person_id IN %(subject_ids)s UNION ALL
                SELECT person_id, procedure_date, procedure_concept_id FROM {CDM_SCHEMA}.procedure_occurrence WHERE person_id IN %(subject_ids)s UNION ALL
                SELECT person_id, measurement_date, measurement_concept_id FROM {CDM_SCHEMA}.measurement WHERE person_id IN %(subject_ids)s UNION ALL
                SELECT person_id, observation_date, observation_concept_id FROM {CDM_SCHEMA}.observation WHERE person_id IN %(subject_ids)s
            ) all_batch_events;
        """
        batch_events_df = pd.read_sql(sql_batch_events, DB_ENGINE, params={'subject_ids': batch_patient_ids})
        batch_events_df['event_date'] = pd.to_datetime(batch_events_df['event_date'])

        merged_batch_df = pd.merge(batch_events_df, batch_admissions, on='subject_id')
        sequential_batch_df = merged_batch_df[merged_batch_df['event_date'] <= merged_batch_df['cohort_start_date']].copy()
        sequential_batch_df['relative_day'] = (
                    sequential_batch_df['event_date'] - sequential_batch_df['cohort_start_date']).dt.days
        sequential_batch_df = sequential_batch_df[
            (sequential_batch_df['relative_day'] >= WINDOW_START) & (sequential_batch_df['relative_day'] <= WINDOW_END)]

        for j, row in batch_admissions.iterrows():
            current_index = j
            patient_events = sequential_batch_df[sequential_batch_df['admission_id'] == row['admission_id']].copy()
            if not patient_events.empty:
                patient_events['concept_int'] = patient_events['concept_id'].map(concept_to_int)
                daily_groups = patient_events.groupby('relative_day')['concept_int'].apply(list)
                for day, concepts in daily_groups.items():
                    day_idx = day - WINDOW_START
                    if 0 <= day_idx < MAX_SEQ_LENGTH:
                        valid_concepts = np.nan_to_num(concepts).astype(int)
                        X[current_index, day_idx, valid_concepts] = 1

    print("Salvataggio dei dati processati su disco...")
    X.flush()
    del X
    np.save(Y_ARRAY_PATH, y)
    print("Preparazione dati completata.")

# -------------------------------------------------------------------
# --- FASE 4: PIPELINE DATI TENSORFLOW E ADDESTRAMENTO (CORRETTO) ---
# -------------------------------------------------------------------
print("\nFASE 4: Creazione Pipeline Dati e Addestramento Modello")

MAX_SEQ_LENGTH = 182
BATCH_SIZE = 64

print("Caricamento dei dati da disco (in modalità memory-mapped)...")
X = np.memmap(X_MEMMAP_PATH, dtype=np.int8, mode='r', shape=(len(cohort_df), MAX_SEQ_LENGTH, vocab_size))
y = np.load(Y_ARRAY_PATH)

print("Creazione degli indici per lo split del dataset...")
indices = np.arange(len(cohort_df))
train_indices, test_indices = train_test_split(indices, test_size=0.2, random_state=42)
print(f"Split degli indici completato: {len(train_indices)} per il training, {len(test_indices)} per il test.")

# Creiamo i dataset TensorFlow a partire dagli INDICI
train_dataset_indices = tf.data.Dataset.from_tensor_slices(train_indices)
test_dataset_indices = tf.data.Dataset.from_tensor_slices(test_indices)


# Funzione che carica un singolo campione (X, y) dal disco usando il suo indice
def load_from_memmap(index):
    # tf.py_function è necessario per usare codice NumPy all'interno della pipeline di TensorFlow
    def _load(index_tensor):
        idx = index_tensor.numpy()
        x_data = X[idx]
        y_data = y[idx]
        return x_data.astype(np.float32), y_data.astype(np.float32)

    x_tensor, y_tensor = tf.py_function(_load, [index], [tf.float32, tf.float32])

    # Dobbiamo specificare manualmente la forma dell'output per TensorFlow
    x_tensor.set_shape([MAX_SEQ_LENGTH, vocab_size])
    y_tensor.set_shape([])
    return x_tensor, y_tensor


# Costruiamo la pipeline di dati finale
print("Costruzione della pipeline di dati TensorFlow...")
ds_train = (
    train_dataset_indices.shuffle(buffer_size=len(train_indices))
    .map(load_from_memmap, num_parallel_calls=tf.data.AUTOTUNE)
    .batch(BATCH_SIZE)
    .prefetch(tf.data.AUTOTUNE)
)

ds_test = (
    test_dataset_indices.batch(BATCH_SIZE)
    .map(load_from_memmap, num_parallel_calls=tf.data.AUTOTUNE)
    .prefetch(tf.data.AUTOTUNE)
)
print("Pipeline di dati create e ottimizzate per lo streaming da disco.")

# Definiamo l'architettura del modello
model = tf.keras.models.Sequential([
    tf.keras.layers.Input(shape=(MAX_SEQ_LENGTH, vocab_size)),
    tf.keras.layers.Masking(mask_value=0.),
    tf.keras.layers.LSTM(units=64, return_sequences=True),
    tf.keras.layers.Dropout(0.2),
    tf.keras.layers.LSTM(units=32),
    tf.keras.layers.Dropout(0.2),
    tf.keras.layers.Dense(units=16, activation='relu'),
    tf.keras.layers.Dense(units=1, activation='linear')
])

model.compile(optimizer='adam', loss='mean_squared_error', metrics=['mean_absolute_error'])
model.summary()

# Addestramento
print("\nInizio addestramento...")
history = model.fit(
    ds_train,
    epochs=100,
    validation_data=ds_test,
    callbacks=[
        tf.keras.callbacks.EarlyStopping(monitor='val_loss', patience=10, restore_best_weights=True),
        tf.keras.callbacks.ModelCheckpoint(os.path.join(RESULTS_DIR, 'best_lstm_model.keras'), monitor='val_loss',
                                           save_best_only=True)
    ]
)

# Valutazione e plotting
print("\nValutazione del modello finale...")
test_loss, test_mae = model.evaluate(ds_test, verbose=0)
print(f"Loss sul Test Set (MSE): {test_loss:.2f}")
print(f"Errore Assoluto Medio sul Test Set (MAE): {test_mae:.2f} giorni")

plt.figure(figsize=(12, 6))
plt.plot(history.history['loss'], label='Loss di Addestramento')
plt.plot(history.history['val_loss'], label='Loss di Validazione')
plt.title('Andamento della Loss durante l\'Addestramento')
plt.xlabel('Epoca')
plt.ylabel('Mean Squared Error (MSE)')
plt.legend()
plt.grid(True)
plt.savefig(os.path.join(RESULTS_DIR, 'training_history.png'))
plt.show()
