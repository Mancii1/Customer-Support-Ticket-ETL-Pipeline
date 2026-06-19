import pandas as pd

def extract_data(file_path: str):
    try:
        df = pd.read_csv(file_path)
        print(f"[EXTRACT] Loaded {len(df)} rows from {file_path}")
        return df
    except Exception as e:
        print(f"[EXTRACT ERROR] {e}")
        return None