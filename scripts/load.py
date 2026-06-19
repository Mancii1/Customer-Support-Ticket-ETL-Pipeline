from config import engine

def load_data(df):

    try:
       df.to_sql(
       "tickets", 
       engine, 
       if_exists="replace",
       index=False, 
       chunksize=1000 
       )
       print("[LOAD]  Data loaded successfully into PostgreSQL")
    except Exception as e:
         print(f"[LOAD ERROR] {e}")