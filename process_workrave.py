import os
import re
import sqlite3
import pandas as pd
import matplotlib.pyplot as plt

DATABASE_FILE = '/app/workrave_data.db'
TABLE_NAME = 'workrave_stats'
D_LINE_PATTERN = re.compile(r'D\s+(\d+)\s+(\d+)\s+(\d+)\s+(.+)')

def create_database():
    """Creates the SQLite database and table if they don't exist."""
    conn = sqlite3.connect(DATABASE_FILE)
    cursor = conn.cursor()
    cursor.execute(f"DROP TABLE IF EXISTS {TABLE_NAME}")
    cursor.execute(f"""
        CREATE TABLE IF NOT EXISTS {TABLE_NAME} (
            data_type TEXT,
            date TEXT,
            col1 INTEGER,
            col2 INTEGER,
            col3 INTEGER,
            col4 INTEGER,
            col5 INTEGER,
            col6 INTEGER,
            col7 INTEGER,
            col8 REAL
        )
    """)
    conn.commit()
    conn.close()
    print(f"Database '{DATABASE_FILE}' and table '{TABLE_NAME}' created.")

def insert_data(file_path):
    """Reads the Workrave data and inserts it into the SQLite database."""
    conn = sqlite3.connect(DATABASE_FILE)
    cursor = conn.cursor()
    current_date = None
    try:
        with open(file_path, 'r') as f:
            for line in f:
                line = line.strip()
                if line.startswith('D'):
                    match = D_LINE_PATTERN.match(line)
                    if match:
                        day, month, year_short, rest = match.groups()
                        try:
                            year_int = int(year_short)
                            if 0 <= year_int <= 99:
                                year = 2000 + year_int
                            elif 2100 <= year_int <= 2199: # Handle 21xx years
                                year = year_int - 2000 # Assuming '2123' means 2023
                            else:
                                year = 2000 + year_int # Default to 21st century
                            current_date = f'{year}-{month.zfill(2)}-{day.zfill(2)}'
                            values = [int(x) if x else None for x in rest.split()]
                            print(f"Debug - Inserting 'D' data: data_type='Date', date='{current_date}'")
                            cursor.execute(f'''
                                INSERT INTO {TABLE_NAME} (data_type, date, col1, col2, col3, col4, col5, col6, col7)
                                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                            ''', ['Date', current_date] + values)
                        except ValueError:
                            print(f"Warning: Could not parse year or values from line: {line}")
                elif line.startswith('B'):
                    parts = line.split()
                    if len(parts) > 2:
                        break_type = parts[1]
                        values = [float(x) if x else None for x in parts[2:]]
                        cursor.execute(f'''
                            INSERT INTO {TABLE_NAME} (data_type, date, col1, col2, col3, col4, col5, col6, col7, col8)
                            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                        ''', [f'Break_{break_type}', current_date] + values + [None] * (9 - len([None] + values)))
                elif line.startswith('m'):
                    parts = line.split()
                    if len(parts) > 2:
                        mouse_type = parts[0]
                        values = [int(x) if x else None for x in parts[1:]]
                        cursor.execute(f'''
                            INSERT INTO {TABLE_NAME} (data_type, date, col1, col2, col3, col4, col5, col6, col7, col8)
                            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                        ''', [mouse_type, current_date] + values + [None] * (9 - len([None] + values)))
            conn.commit()
    except FileNotFoundError:
        print(f"Error: File not found at {file_path}")
    except Exception as e:
        conn.rollback()
        print(f"An error occurred during data insertion: {e}")
    finally:
        conn.close()

def plot_mouse_activity_from_db():
    """Queries the database and plots total mouse movement over time."""
    conn = sqlite3.connect(DATABASE_FILE)
    cursor = conn.cursor()
    try:
        print("First few rows of the entire table:")
        df_all = pd.read_sql_query(f"SELECT * FROM {TABLE_NAME} LIMIT 5", conn)
        print(df_all)

        df = pd.read_sql_query(f"SELECT date, col2 FROM {TABLE_NAME} WHERE data_type = 'm' AND date != ''", conn)
        print("\nDataFrame after initial query for 'm' data:")
        print(df)

        if not df.empty:
            df.rename(columns={'col2': 'total_movement'}, inplace=True)
            df['total_movement'] = pd.to_numeric(df['total_movement'], errors='coerce')
            # Attempt to convert to datetime, coerce errors to NaT
            df['date'] = pd.to_datetime(df['date'], errors='coerce')
            # Drop rows with invalid dates (NaT)
            df = df.dropna(subset=['date', 'total_movement'])
            plt.figure(figsize=(12, 6))
            plt.plot(df['date'], df['total_movement'])
            plt.xlabel("Date")
            plt.ylabel("Total Mouse Movement")
            plt.title("Total Mouse Movement Over Time")
            plt.xticks(rotation=45)
            plt.tight_layout()
            plt.savefig("/app/output/mouse_activity.png")
            print("Generated mouse_activity.png from database.")
        else:
            print("Warning: No mouse data found in the database for plotting.")
    except Exception as e:
        print(f"An error occurred while querying and plotting from the database: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    workrave_file = "workrave_stats.txt"
    create_database()
    insert_data(workrave_file)
    plot_mouse_activity_from_db()
