import azure.functions as func
import random
import json

# Initialize the function app with anonymous access for the frontend
app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

@app.route(route="generate-data", methods=["GET"])
def generate_data(req: func.HttpRequest) -> func.HttpResponse:
    # 1. Generate random data
    mock_data = {
        "transaction_id": random.randint(10000, 99999),
        "status": "success",
        "metric_value": round(random.uniform(10.5, 99.9), 2),
        "message": "Data generated locally by Python!"
    }

    # 2. Return data as JSON
    return func.HttpResponse(
        body=json.dumps(mock_data),
        mimetype="application/json",
        status_code=200
    )