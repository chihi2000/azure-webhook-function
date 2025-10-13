import azure.functions as func
import hmac
import hashlib
import os
import threading
import requests
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

def trigger_pipeline():
    try:
        org_url = os.environ["AZDO_ORG_URL"]
        project = os.environ["AZDO_PROJECT_NAME"]
        pipeline_id = os.environ["AZDO_PIPELINE_ID"]
        pat = os.environ["AZDO_PAT"]

        url = f"{org_url}/{project}/_apis/pipelines/{pipeline_id}/runs?api-version=7.0"
        headers = {
            "Content-Type": "application/json"
        }

        response = requests.post(
            url,
            auth=("", pat),
            headers=headers,
            json={}
        )

        if response.status_code not in [200, 201]:
            print(f"[ERROR] Failed to trigger pipeline: {response.status_code} - {response.text}")
        else:
            print("[INFO] Pipeline triggered successfully.")

    except Exception as e:
        print(f"[EXCEPTION] Pipeline trigger failed: {e}")

def main(req: func.HttpRequest) -> func.HttpResponse:
    # 1. get signature
    gh_sig = req.headers.get("X-Hub-Signature-256", "")

    # 2. get secret from Key Vault
    kv_client = SecretClient(
        vault_url=f"https://{os.environ['KEY_VAULT_NAME']}.vault.azure.net",
        credential=DefaultAzureCredential()
    )
    secret = kv_client.get_secret(os.environ["GITHUB_WEBHOOK_SECRET_NAME"]).value

    # 3. verify signature
    body = req.get_body()
    expected_sig = "sha256=" + hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()
    if not hmac.compare_digest(expected_sig, gh_sig):
        return func.HttpResponse("Bad signature", status_code=403)

    # 4. trigger pipeline in background
    threading.Thread(target=trigger_pipeline).start()

    # 5. respond to gitHub

    return func.HttpResponse("Webhook processed!", status_code=200)

