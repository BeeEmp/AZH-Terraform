import azure.functions as func
import random
import json
import os
import uuid
from datetime import datetime

# Import Azure SDKs
try:
    from azure.storage.blob import BlobServiceClient
    from azure.cosmos import CosmosClient, PartitionKey
    from azure.identity import DefaultAzureCredential
    SDKs_AVAILABLE = True
except ImportError:
    SDKs_AVAILABLE = False

# Initialize the function app with anonymous access for the frontend
app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

# Helper function to get Blob Service Client
def get_blob_service_client():
    if not SDKs_AVAILABLE:
        return None
    
    # 1. Try local connection string (typically UseDevelopmentStorage=true)
    conn_str = os.environ.get("BLOB_STORAGE_CONNECTION_STRING")
    if conn_str:
        try:
            return BlobServiceClient.from_connection_string(conn_str)
        except Exception as e:
            print(f"Failed to create blob client from connection string: {e}")
            
    # 2. Try managed identity endpoint
    endpoint = os.environ.get("BLOB_STORAGE_ENDPOINT")
    if endpoint:
        try:
            credential = DefaultAzureCredential()
            return BlobServiceClient(account_url=endpoint, credential=credential)
        except Exception as e:
            print(f"Failed to create blob client from Managed Identity endpoint: {e}")
            
    return None

# Helper function to get Cosmos Client
def get_cosmos_client():
    if not SDKs_AVAILABLE:
        return None
        
    endpoint = os.environ.get("COSMOS_DB_ENDPOINT")
    key = os.environ.get("COSMOS_DB_KEY")
    
    if not endpoint:
        return None
        
    # 1. Try with Master Key (useful for emulator / direct key)
    if key:
        try:
            return CosmosClient(endpoint, credential=key)
        except Exception as e:
            print(f"Failed to create Cosmos client with key: {e}")
            
    # 2. Try with Managed Identity
    try:
        credential = DefaultAzureCredential()
        return CosmosClient(endpoint, credential=credential)
    except Exception as e:
        print(f"Failed to create Cosmos client with Managed Identity: {e}")
        
    return None

@app.route(route="generate-data", methods=["GET", "POST"])
def generate_data(req: func.HttpRequest) -> func.HttpResponse:
    # 1. Generate random data
    tx_id = random.randint(10000, 99999)
    event_id = str(uuid.uuid4())
    timestamp = datetime.utcnow().isoformat() + "Z"
    
    # Random metric value and details
    metric_val = round(random.uniform(10.5, 99.9), 2)
    temp = round(random.uniform(18.0, 35.0), 1)
    hum = round(random.uniform(30.0, 80.0), 1)
    
    mock_data = {
        "id": event_id,
        "transaction_id": tx_id,
        "status": "success",
        "metric_value": metric_val,
        "timestamp": timestamp,
        "partitionKey": "transaction",
        "source": "python-backend-generator",
        "details": {
            "temperature": temp,
            "humidity": hum
        },
        "message": "Data generated locally by Python!"
    }

    storage_status = "Skipped (SDKs not available)"
    cosmos_status = "Skipped (SDKs not available)"
    fallback_used = False

    if SDKs_AVAILABLE:
        # --- BLOB STORAGE WRITE ---
        blob_client = get_blob_service_client()
        container_name = os.environ.get("BLOB_STORAGE_CONTAINER", "project-data")
        
        if blob_client:
            try:
                container_client = blob_client.get_container_client(container_name)
                # Ensure container exists (useful for local Azurite)
                try:
                    blob_name = f"transactions/tx-{tx_id}.json"
                    blob_client_instance = container_client.get_blob_client(blob_name)
                    blob_client_instance.upload_blob(json.dumps(mock_data), overwrite=True)
                    storage_status = f"Saved successfully as blob: {blob_name}"
                except Exception:
                    # In local emulator, container might need to be created first
                    try:
                        container_client = blob_client.create_container(container_name)
                        blob_name = f"transactions/tx-{tx_id}.json"
                        blob_client_instance = container_client.get_blob_client(blob_name)
                        blob_client_instance.upload_blob(json.dumps(mock_data), overwrite=True)
                        storage_status = f"Saved successfully as blob: {blob_name} (container created)"
                    except Exception as create_err:
                        storage_status = f"Failed (Container creation/access failed: {create_err})"
            except Exception as e:
                storage_status = f"Failed (Error uploading blob: {e})"
        else:
            storage_status = "Failed (Blob client could not be initialized. Is Azurite running?)"

        # --- COSMOS DB WRITE ---
        cosmos_client = get_cosmos_client()
        db_name = os.environ.get("COSMOS_DB_DATABASE", "BackendDB")
        container_name_db = os.environ.get("COSMOS_DB_CONTAINER", "transactions")
        
        if cosmos_client:
            try:
                # Get database
                try:
                    db = cosmos_client.get_database_client(db_name)
                    # Get or create container
                    container = db.get_container_client(container_name_db)
                    container.upsert_item(mock_data)
                    cosmos_status = f"Saved successfully to database: {db_name}, container: {container_name_db}"
                except Exception:
                    # Try creating database and container if they don't exist
                    try:
                        db = cosmos_client.create_database_if_not_exists(id=db_name)
                        container = db.create_container_if_not_exists(
                            id=container_name_db,
                            partition_key=PartitionKey(path="/partitionKey")
                        )
                        container.upsert_item(mock_data)
                        cosmos_status = f"Saved successfully (database/container created if not existed)"
                    except Exception as create_db_err:
                        cosmos_status = f"Failed (Cosmos DB creation failed: {create_db_err})"
            except Exception as e:
                cosmos_status = f"Failed (Error writing to Cosmos: {e})"
        else:
            cosmos_status = "Failed (Cosmos client could not be initialized. Emulator running?)"
            
    # --- FALLBACK TO LOCAL WORKSPACE FILES ---
    if "Failed" in storage_status or "Failed" in cosmos_status or not SDKs_AVAILABLE:
        try:
            fallback_dir = os.path.join(os.getcwd(), "local_data_fallback")
            os.makedirs(fallback_dir, exist_ok=True)
            fallback_file = os.path.join(fallback_dir, f"tx-{tx_id}.json")
            with open(fallback_file, "w") as f:
                json.dump(mock_data, f, indent=2)
            fallback_used = True
        except Exception as e:
            print(f"Fallback write failed: {e}")

    # Add confirmation details into the message returned to the frontend
    status_msg = f"Data generated! Blob: {storage_status} | Cosmos: {cosmos_status}"
    if fallback_used:
        status_msg += " (Local fallback file written)"
        
    mock_data["message"] = status_msg

    # 2. Return data as JSON with CORS headers
    return func.HttpResponse(
        body=json.dumps(mock_data),
        mimetype="application/json",
        status_code=200,
        headers={
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type"
        }
    )