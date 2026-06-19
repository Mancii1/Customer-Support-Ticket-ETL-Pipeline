from extract import extract_data
from transform import transform_data
from load import load_data

FILE_PATH = "data/customer_support_tickets.csv"

def run_pipeline():

    print("=== Starting ETL Pipeline ===")

    # Extract
    df = extract_data(FILE_PATH)

    if df is None:
        print("[PIPELINE] Extraction failed. Exiting pipeline.")
        return
    
    # Transform
    df_clean = transform_data(df)

    # Load
    load_data(df_clean)

    print("=== ETL Pipeline Completed ===")

if __name__ == "__main__":
    run_pipeline()