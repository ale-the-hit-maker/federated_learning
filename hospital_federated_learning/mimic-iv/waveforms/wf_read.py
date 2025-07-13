'''
-------------------------------------------------------------------
@2020, Odysseus Data Services, Inc. All rights reserved
MIMIC IV CDM Conversion - PostgreSQL Version
-------------------------------------------------------------------

Iterate through waveform source csv files, organized in folders
Folders hierarchy:
    root_source_files/case_id/subject_id/wfdb_reference_id.csv

'''

import os
import sys
import getopt
import json
import datetime
import psycopg2
import pandas as pd
from pathlib import Path
import glob

# ----------------------------------------------------
# default config values
# To override default config values, copy the keys to be overridden to a json file,
# and indicate this file as --config parameter
# ----------------------------------------------------

config_default = {
    "variables": {
        "@waveforms_csv_path": "/path/to/waveforms/csv/files",
        "@pg_host": "localhost",
        "@pg_port": "5432",
        "@pg_database": "mimic_waveforms",
        "@pg_user": "postgres",
        "@pg_password": "password",
        "@wf_schema": "waveform_source_poc"
    }
}


# ----------------------------------------------------
# read_params()
# ----------------------------------------------------

def read_params():
    print('Reading params...')
    params = {
        "etlconf_file": "",
        "config_file": "",
        "script_files": [],
        "files_not_found": []
    }

    # Parsing command line arguments
    try:
        opts, args = getopt.getopt(sys.argv[1:], "e:c:", ["etlconf=", "config="])
        if len(opts) == 0:
            raise getopt.GetoptError("read_params() error", "Mandatory argument is missing.")

    except getopt.GetoptError as err:
        print(err.args)
        print("Please indicate correct params:")
        print("etlconf_file:   optional: indicate '-e' for 'etlconf', global config json file")
        print("config_file:    optional: indicate '-c' for 'config', local config json file")
        sys.exit(2)

    # get config files names
    for opt, arg in opts:
        if opt == '-e' or opt == '--etlconf':
            if os.path.isfile(arg):
                params['etlconf_file'] = arg
        if opt == '-c' or opt == '--config':
            if os.path.isfile(arg):
                params['config_file'] = arg

    # collect script names
    for arg in args:
        if os.path.isfile(arg):
            params['script_files'].append(arg)
        else:
            params['files_not_found'].append(arg)

    print('scripts to run', params)
    return params


# ----------------------------------------------------
# read_config()
# ----------------------------------------------------

def read_config(etlconf_file, config_file):
    print('Reading config...')
    config = {}
    config_read = {}
    etlconf_read = {}

    if etlconf_file and os.path.isfile(etlconf_file):
        with open(etlconf_file) as f:
            etlconf_read = json.load(f)

    if config_file and os.path.isfile(config_file):
        with open(config_file) as f:
            config_read = json.load(f)

    # global config has lower priority
    for k in config_default:
        s = etlconf_read.get(k, config_default[k])
        config[k] = s

    # local config has higher priority
    for k in config_default:
        s = config_read.get(k, config[k])
        config[k] = s

    print(config)
    return config


# ----------------------------------------------------
# get_database_connection()
# ----------------------------------------------------

def get_database_connection(config):
    """Create PostgreSQL database connection"""
    try:
        conn = psycopg2.connect(
            host=config['variables']['@pg_host'],
            port=config['variables']['@pg_port'],
            database=config['variables']['@pg_database'],
            user=config['variables']['@pg_user'],
            password=config['variables']['@pg_password']
        )
        conn.autocommit = True
        print("Database connection established successfully")
        return conn
    except Exception as e:
        print(f"Error connecting to database: {e}")
        raise e


# ----------------------------------------------------
# create_schema_if_not_exists()
# ----------------------------------------------------

def create_schema_if_not_exists(conn, schema_name):
    """Create schema if it doesn't exist"""
    try:
        cursor = conn.cursor()
        cursor.execute(f"CREATE SCHEMA IF NOT EXISTS {schema_name}")
        print(f"Schema {schema_name} created or already exists")
        cursor.close()
    except Exception as e:
        print(f"Error creating schema: {e}")
        raise e


# ----------------------------------------------------
# get_files_list()
# ----------------------------------------------------

def get_files_list(path):
    """
    Get list of CSV files from local filesystem
    Replace gsutil with local file system operations
    """
    files_list = []

    # Use glob to find all CSV files recursively
    pattern = os.path.join(path, "**", "*.csv")
    files_list = glob.glob(pattern, recursive=True)

    # Convert to Path objects for easier manipulation
    files_list = [str(Path(f)) for f in files_list]

    print(f"Found {len(files_list)} CSV files")
    return files_list


# ----------------------------------------------------
# get_header_csv()
# ----------------------------------------------------

def get_header_csv(files_list, root_path):
    """
    Create a "header table" from the files list
    Modified to work with local file paths
    """
    result = []
    header = "case_id,subject_id,short_reference_id,long_reference_id\n"
    result.append(header)

    for file_path in files_list:
        # Convert to Path object for easier manipulation
        path_obj = Path(file_path)

        # Get relative path from root
        try:
            rel_path = path_obj.relative_to(Path(root_path))
            parts = rel_path.parts

            if len(parts) >= 3:  # case_id/subject_id/filename.csv
                case_id = parts[0]
                subject_id = parts[1]
                short_reference_id = path_obj.stem  # filename without extension
                long_reference_id = str(file_path)

                result.append(f"{case_id},{subject_id},{short_reference_id},{long_reference_id}\n")
        except ValueError:
            # File is not under root_path, skip it
            continue

    print(f"Generated {len(result) - 1} header records")
    return result


# ----------------------------------------------------
# create_tmp_csv()
# ----------------------------------------------------

def create_tmp_csv(header_csv, table_name):
    """Create temporary CSV file for header data"""
    csv_temp_name = f"tmp_{table_name}.csv"

    with open(csv_temp_name, 'w') as f:
        for s in header_csv:
            f.write(s)
        print(f'Generated {csv_temp_name}')

    return csv_temp_name


# ----------------------------------------------------
# create_tables()
# ----------------------------------------------------

def create_tables(conn, schema_name):
    """Create necessary tables in PostgreSQL based on defined structure"""
    cursor = conn.cursor()

    # Create header table
    header_table_sql = f"""
    DROP TABLE IF EXISTS {schema_name}.wf_header;
    CREATE TABLE {schema_name}.wf_header (
        case_id TEXT,
        subject_id TEXT,
        short_reference_id TEXT,
        long_reference_id TEXT
    )
    """

    # Create details table with the exact structure defined in the comment
    details_table_sql = f"""
    DROP TABLE IF EXISTS {schema_name}.wf_details;
    CREATE TABLE {schema_name}.wf_details (
        case_id TEXT,
        segment_name TEXT,
        date_time DATE,
        src_name TEXT,
        concept_id BIGINT,
        concept_name TEXT,
        value NUMERIC,
        unit_concept_id BIGINT,
        unit_concept_name TEXT
    )
    """

    try:
        cursor.execute(header_table_sql)
        cursor.execute(details_table_sql)
        print("Tables created successfully")
        print("- wf_header: case_id, subject_id, short_reference_id, long_reference_id")
        print(
            "- wf_details: case_id, segment_name, date_time, src_name, concept_id, concept_name, value, unit_concept_id, unit_concept_name")
    except Exception as e:
        print(f"Error creating tables: {e}")
        raise e
    finally:
        cursor.close()


# ----------------------------------------------------
# load_table_from_csv()
# ----------------------------------------------------

def load_table_from_csv(conn, schema_name, table_name, csv_file_path, replace_flag=False):
    """
    Load data from CSV file into PostgreSQL table
    """
    return_code = 0

    if not os.path.isfile(csv_file_path):
        print(f'Source file {csv_file_path} is not found.')
        return 1

    try:
        cursor = conn.cursor()
        full_table_name = f"{schema_name}.{table_name}"

        # Clear table if replace_flag is True
        if replace_flag:
            cursor.execute(f"TRUNCATE TABLE {full_table_name}")
            print(f"Table {full_table_name} truncated")

        # Use COPY command for efficient loading
        with open(csv_file_path, 'r') as f:
            cursor.copy_expert(
                f"COPY {full_table_name} FROM STDIN WITH CSV HEADER",
                f
            )

        print(f"Data loaded successfully into {full_table_name} from {csv_file_path}")

    except Exception as e:
        print(f"Error loading data: {e}")
        return_code = 2
        raise e
    finally:
        cursor.close()

    return return_code


# ----------------------------------------------------
# load_waveform_details()
# ----------------------------------------------------

def load_waveform_details(conn, schema_name, csv_file_path, case_id, subject_id, reference_id):
    """
    Load individual waveform CSV file into details table
    Maps CSV columns to the defined table structure.
    """

    print(f"Attempting to load details from: {csv_file_path}")
    try:
        # Leggi il CSV con pandas
        # Assicurati che il delimitatore sia corretto e gestisci potenziali problemi di parsing
        try:
            df = pd.read_csv(csv_file_path, delimiter=',')
        except pd.errors.EmptyDataError:
            print(f"Warning: File {csv_file_path} is empty. Skipping.")
            return
        except Exception as read_e:
            print(f"Error reading CSV file {csv_file_path} with pandas: {read_e}. Skipping.")
            return

        # ***** INIZIO MODIFICA PER GESTIRE NOMI COLONNE CSV DIVERSI *****
        # Definisci la mappa dai nomi delle colonne nel tuo CSV ai nomi attesi dallo script/tabella DB
        # Basato sulla tua intestazione: "Case ID,Segment Name,Date-time,Src Name,Concept ID,Concept Name,Value,Unit Concept ID,Unit Concept Name"
        column_name_map = {
            'Case ID': 'case_id_csv', # Rinomina in modo univoco per evitare conflitto con case_id_from_path
            'Segment Name': 'segment_name',
            'Date-time': 'date_time',
            'Src Name': 'src_name',
            'Concept ID': 'concept_id',
            'Concept Name': 'concept_name',
            'Value': 'value',
            'Unit Concept ID': 'unit_concept_id',
            'Unit Concept Name': 'unit_concept_name'
        }

        # Rinomina le colonne nel DataFrame SOLO se esistono
        cols_to_rename_actually_present = {k: v for k, v in column_name_map.items() if k in df.columns}
        if cols_to_rename_actually_present:
            df.rename(columns=cols_to_rename_actually_present, inplace=True)
            print(f"  Renamed columns for {csv_file_path}: {cols_to_rename_actually_present}")
        else:
            print(f"  No columns to rename based on map for {csv_file_path}. Current columns: {df.columns.tolist()}")
        # ***** FINE MODIFICA *****


        # Colonne richieste dalla tabella wf_details (SENZA case_id, che aggiungiamo dal percorso)
        # case_id viene passato come argomento e aggiunto dopo
        target_table_columns = ['case_id', 'segment_name', 'date_time', 'src_name', 'concept_id',
                                     'concept_name', 'value', 'unit_concept_id', 'unit_concept_name']


        # Controlla le colonne mancanti DOPO la rinomina
        missing_columns = [col for col in target_table_columns if col not in df.columns]
        if missing_columns:
            print(f"Warning: After renaming, still missing data columns in {csv_file_path}: {missing_columns}")
            # Aggiungi colonne mancanti con valori di default appropriati
            for col in missing_columns:
                if col == 'date_time':
                    df[col] = None # pd.NaT farà inserire NULL per le date
                elif col in ['concept_id', 'unit_concept_id']:
                    df[col] = pd.NA # Per interi nullable
                elif col == 'value':
                    df[col] = pd.NA # Per numerici nullable
                else: # segment_name, src_name, concept_name, unit_concept_name
                    df[col] = None # Per stringhe, None diventerà NULL


        # Aggiungi case_id derivato dal percorso della cartella
        df['case_id'] = str(case_id)


        # Assicura i tipi di dato corretti prima dell'inserimento
        if 'date_time' in df.columns:
            df['date_time'] = pd.to_datetime(df['date_time'], errors='coerce').dt.date

        # Per colonne BIGINT (concept_id, unit_concept_id)
        for col_bigint in ['concept_id', 'unit_concept_id']:
            if col_bigint in df.columns:
                df[col_bigint] = pd.to_numeric(df[col_bigint], errors='coerce').astype('Int64') # Usa Int64 per i nullable int

        # Per colonna NUMERIC (value)
        if 'value' in df.columns:
            df['value'] = pd.to_numeric(df['value'], errors='coerce')
            # Non è necessario .astype() qui se la colonna del DB è NUMERIC, pandas float va bene

        # Seleziona e riordina le colonne per farle corrispondere all'ordine della tabella wf_details
        # Assicurati che target_table_columns elenchi le colonne nell'ordine corretto della INSERT

        # Rimuovi eventuali colonne extra che non sono nella tabella di destinazione
        df_filtered = df[[col for col in target_table_columns if col in df.columns]].copy()
        # Aggiungi colonne mancanti da target_table_columns se non presenti in df_filtered, con None
        for col_target in target_table_columns:
            if col_target not in df_filtered.columns:
                df_filtered[col_target] = None
        df_filtered = df_filtered[target_table_columns] # Riordina


        # Inserimento dati
        cursor = conn.cursor()
        insert_sql = f"""
        INSERT INTO {schema_name}.wf_details 
        (case_id, segment_name, date_time, src_name, concept_id, concept_name, value, unit_concept_id, unit_concept_name)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        """

        # Sostituisci i NaN di pandas con None per psycopg2
        data_tuples = [tuple(row) for row in df_filtered.to_numpy()]

        if data_tuples: # Solo se ci sono dati da inserire
            cursor.executemany(insert_sql, data_tuples)
            conn.commit() # Commit per ogni file o potresti farlo alla fine
            print(f"  Loaded {len(df_filtered)} records from {csv_file_path} into {schema_name}.wf_details")
        else:
            print(f"  No data to load from {csv_file_path} after filtering/processing.")

        cursor.close()

    except psycopg2.Error as db_e: # Catch specific database errors
        conn.rollback()
        print(f"Database error loading waveform details from {csv_file_path}: {db_e}")
        # Non fare raise e qui per permettere allo script di continuare con altri file,
        # ma registra l'errore.
    except pd.errors.ParserError as parse_e:
        print(f"Pandas parsing error for file {csv_file_path}: {parse_e}. Skipping this file.")
    except FileNotFoundError:
        print(f"Error: File not found {csv_file_path}. Skipping this file.")
    except Exception as e:
        print(f"Generic error processing file {csv_file_path}: {e}")




# ----------------------------------------------------
# Global table names
# ----------------------------------------------------

table_wf_header = 'wf_header'
table_wf_details = 'wf_details'


# ----------------------------------------------------
# main function
# ----------------------------------------------------

def main():
    rc = 0
    duration = datetime.datetime.now()

    try:
        params = read_params()
        config = read_config(params['etlconf_file'], params['config_file'])

        # Get database connection
        conn = get_database_connection(config)

        # Create schema if not exists
        schema_name = config['variables']['@wf_schema']
        create_schema_if_not_exists(conn, schema_name)

        # Create tables
        create_tables(conn, schema_name)

        # Read folders structure from local filesystem
        csv_path = config['variables']['@waveforms_csv_path']
        files_list = get_files_list(csv_path)

        if not files_list:
            print("No CSV files found in the specified path")
            return 1

        # Create header CSV
        header_csv = get_header_csv(files_list, csv_path)
        tmp_csv = create_tmp_csv(header_csv, table_wf_header)

        # Load header table
        load_table_from_csv(conn, schema_name, table_wf_header, tmp_csv, replace_flag=True)

        # Clean up temporary file
        if os.path.exists(tmp_csv):
            os.remove(tmp_csv)

        # Load details tables
        print(f"Processing {len(files_list)} files...")
        for i, file_path in enumerate(files_list):
            print(f"Processing file {i + 1}/{len(files_list)}: {file_path}")

            # Extract metadata from file path
            path_obj = Path(file_path)
            try:
                rel_path = path_obj.relative_to(Path(csv_path))
                parts = rel_path.parts

                if len(parts) >= 3:
                    case_id = parts[0]
                    subject_id = parts[1]
                    reference_id = path_obj.stem  # filename without extension

                    load_waveform_details(conn, schema_name, file_path, case_id, subject_id, reference_id)

            except Exception as e:
                print(f"Error processing file {file_path}: {e}")
                continue

        # Close database connection
        conn.close()
        print("Database connection closed")

    except Exception as e:
        print(f"Error in main execution: {e}")
        rc = 1

    duration = datetime.datetime.now() - duration
    print(f'Run time: {duration}')

    return rc


# -------------

if __name__ == '__main__':
    main()