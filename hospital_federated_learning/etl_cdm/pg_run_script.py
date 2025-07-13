#
# Run multi-query script in PostgreSQL
#

import os
import sys
import getopt
import json
import datetime
import subprocess
import tempfile

# ----------------------------------------------------
# default config values
# To override default config values, copy the keys to be overridden to a json file,
# and indicate this file as --config parameter
# ----------------------------------------------------

config_default = {
    "variables": {
        "@variable_1": "No database replacement by default",
        "@variable_2": "No schema replacement by default",
        "@pg_host": "localhost",
        "@pg_port": "5432",
        "@pg_database": "postgres",
        "@pg_user": "postgres",
        "@pg_password": "password"
    },

    "escaping_chars": {
        '"': '\\"'
        # '`': '\\`' # don't replace in windows OS
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
        if len(args) == 0:
            raise getopt.GetoptError("read_params() error", "Mandatory argument is missing.")

    except getopt.GetoptError as err:
        print(err.args)
        print("Please indicate correct params:")
        print("etlconf_file:   optional: indicate '-e' for 'etlconf', global config json file")
        print("config_file:    optional: indicate '-c' for 'config', local config json file")
        print("script_files:   [mandatory: indicate at least one script name as unnamed argument]")
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
# trim_queries()
# ----------------------------------------------------

def trim_queries(s_queries):
    s_result = []
    for q in s_queries:
        q = remove_comments(q)
        if len(q.strip()) > 2:
            s_result.append(q)
    return s_result


# ----------------------------------------------------
# remove_comments()
# ----------------------------------------------------

def remove_comments(s_query):
    print('Remove_comments()...')

    s_lines_src = s_query.split('\n')
    s_result = ""

    for s in s_lines_src:
        s_stripped = s.replace(' ', '')
        if len(s_stripped) > 0:
            comment_flag = s_stripped[0:2]

            if comment_flag != '--' and len(s) > 0:
                s_result = s_result + s + '\n'
        elif len(s) == 0:
            s_result = s_result + s + '\n'  # preserve empty lines

    return s_result


# ----------------------------------------------------
# format_query()
# ----------------------------------------------------

def format_query(s_query, config):
    print('Formatting query...')

    s_result = s_query

    # Apply escaping characters
    for var, val in config['escaping_chars'].items():
        s_result = s_result.replace(var, val)

    # Apply variable substitutions
    for var, val in config['variables'].items():
        s_result = s_result.replace(var, str(val))

    print(s_result)
    return s_result


# ----------------------------------------------------
# build_psql_connection_string()
# ----------------------------------------------------

def build_psql_connection_string(config):
    """Build PostgreSQL connection string for psql command"""
    conn_params = []

    host = config['variables'].get('@pg_host', 'localhost')
    port = config['variables'].get('@pg_port', '5432')
    database = config['variables'].get('@pg_database', 'postgres')
    user = config['variables'].get('@pg_user', 'postgres')

    conn_params.extend(['-h', host])
    conn_params.extend(['-p', str(port)])
    conn_params.extend(['-d', database])
    conn_params.extend(['-U', user])

    return conn_params


# ----------------------------------------------------
# execute_postgres_query()
# ----------------------------------------------------

def execute_postgres_query(query, config):
    """Execute a PostgreSQL query using psql command"""

    # Build connection parameters
    conn_params = build_psql_connection_string(config)

    # Create temporary file for the query
    with tempfile.NamedTemporaryFile(mode='w', suffix='.sql', delete=False) as temp_file:
        temp_file.write(query)
        temp_file_path = temp_file.name

    try:
        # Build psql command
        psql_cmd = ['psql'] + conn_params + ['-f', temp_file_path, '-v', 'ON_ERROR_STOP=1']

        # Set environment variable for password
        env = os.environ.copy()
        password = config['variables'].get('@pg_password', '')
        if password:
            env['PGPASSWORD'] = password

        print(f'Executing psql command: {" ".join(psql_cmd[:-2])} -f [temp_file]')

        # Execute the command
        result = subprocess.run(psql_cmd, env=env, capture_output=True, text=True)

        if result.stdout:
            print("STDOUT:", result.stdout)
        if result.stderr:
            print("STDERR:", result.stderr)

        return result.returncode

    except Exception as e:
        print(f"Error executing PostgreSQL query: {e}")
        return 1
    finally:
        # Clean up temporary file
        try:
            os.unlink(temp_file_path)
        except OSError:
            pass


# ----------------------------------------------------
# troubleshooting_query_format()
# ----------------------------------------------------

def troubleshooting_query_format(query):
    """
    Clean up query format:
    1) Remove trailing comments at the end of lines
    2) Preserve line structure for PostgreSQL
    """
    print('Troubleshooting_query_format()...')

    s_lines_src = query.split('\n')
    s_result_lines = []

    for s in s_lines_src:
        # remove trailing comment
        comment_pos = s.find('--')
        if comment_pos > -1:
            s = s[0:comment_pos].rstrip()

        # keep the line (even if empty, for SQL structure)
        s_result_lines.append(s)

    return '\n'.join(s_result_lines)


# ----------------------------------------------------
# nice_message()
# ----------------------------------------------------

def nice_message(s_filename, status, msg):
    """
    Nice output about execution result

    s_filename: script executed
    status:     0 = ok, !0 = error
    msg:        additional info if there is any
    """
    time = datetime.datetime.now()
    file = s_filename.ljust(35, ' ')
    result = 'Done.' if status == 0 else 'Error'
    message = '' if len(msg) == 0 else ': ' + msg if len(msg.split('\n')) == 1 \
        else '\n' + '\n'.join(map(lambda x: ''.ljust(4) + x, msg.split('\n')))

    return '{0} | {1} | {2}{3}'.format(time, file, result, message)


# ----------------------------------------------------
# main()
# return codes: 0 = ok, !0 = error
# ----------------------------------------------------

def main():
    rc = 0
    duration = datetime.datetime.now()
    params = read_params()
    config = read_config(params['etlconf_file'], params['config_file'])

    # stop if any files are not found
    if len(params['files_not_found']) > 0:
        rc = 2  # No such file or directory # Linux OS error code
        for s_filename in params['files_not_found']:
            print('No such file or directory: {file}\n'.format(file=s_filename))

    else:
        s_done = []
        s_done.append(nice_message('start...', 0, ''))

        for s_filename in params['script_files']:
            print('Run script {file}\n'.format(file=s_filename))

            # Read and split queries
            with open(s_filename, 'r') as f:
                file_content = f.read()

            s_queries = file_content.split(';')
            s_queries = trim_queries(s_queries)

            query_no = 0
            for s_query in s_queries:
                if s_query.strip():  # Only process non-empty queries
                    formatted_query = format_query(s_query, config)
                    clean_query = troubleshooting_query_format(formatted_query)

                    query_no += 1
                    print(f'Starting query {query_no}...')

                    rc = execute_postgres_query(clean_query, config)

                    if rc != 0:
                        break

            s_done.append(
                nice_message(s_filename, rc, '' if rc == 0 else 'See query No {0}'.format(query_no)))

            if rc != 0:
                break

        print('\nScripts executed:')
        for a in s_done:
            print(a)
        duration = datetime.datetime.now() - duration
        print('Run time: {0}'.format(duration))  # timedelta HH:MM:SS.f

    return rc


# ----------------------------------------------------
# run
# ----------------------------------------------------

if __name__ == '__main__':
    return_code = main()
    print('pg_run_script.exit()', return_code)
    exit(return_code)