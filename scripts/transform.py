import pandas as pd

def transform_data(df: pd.DataFrame):
    # Remove duplicates
    df = df.drop_duplicates()

    # Standardise column names
    df.columns = (
        df.columns
        .str.strip()
        .str.lower()
        .str.replace(" ", "_")
    )

    df["date_of_purchase"] = pd.to_datetime(df["date_of_purchase"], errors='coerce')
    df["first_response_time"] = pd.to_datetime(df["first_response_time"], errors='coerce')
    df["time_to_resolution"] = pd.to_datetime(df["time_to_resolution"], errors='coerce')

    # Compute durations
    df["first_response_duration"] = df["first_response_time"] - df["date_of_purchase"]
    df["resolution_duration"] = df["time_to_resolution"] - df["date_of_purchase"]

    # Replace the original timestamp columns with the computed durations
    df.drop(columns=["first_response_time", "time_to_resolution"], inplace=True)
    df.rename(columns={
        "first_response_duration": "first_response_time",
        "resolution_duration": "time_to_resolution"
    }, inplace=True)

    # Remove rows missing critical IDs
    df = df.dropna(subset=["ticket_id", "customer_email"])

    # Derived metric: SLA breach (resolution > 48 hours)
    df["is_sla_breached"] = (
        df["time_to_resolution"].dt.total_seconds() > (48 * 3600)
    )

    # Response speed category (based on first response duration)
    df["response_speed_category"] = (
        df["first_response_time"]
        .dt.total_seconds()
        .apply(
            lambda x:
            "fast" if x < 3600
            else "medium" if x < 21600
            else "slow"
        )
    )

    print(f"[TRANSFORM] Cleaned dataset: {len(df)} rows")
    return df