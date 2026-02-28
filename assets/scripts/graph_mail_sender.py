# =============================================================================
# send_report.py
# Author  : Mustafa Nassar
# Version : 4.0
# GitHub  : https://github.com/Nassar-m/GraphAPI
# =============================================================================
#
# Send email via Microsoft Graph API using application (daemon) authentication.
# Supports plain-text and HTML bodies, optional file attachments, and
# multiple recipients. Credentials are read from environment variables so
# nothing sensitive ever lives in source code.
#
# QUICK START
# -----------
#   1. Register an Azure AD app and grant Mail.Send (Application permission).
#      Grant admin consent.
#
#   2. Export credentials as environment variables (or add them to a .env file
#      and load with python-dotenv):
#
#       export GRAPH_CLIENT_ID="<your-client-id>"
#       export GRAPH_CLIENT_SECRET="<your-client-secret>"
#       export GRAPH_TENANT_ID="<your-tenant-id>"
#
#   3. Install dependencies:
#
#       pip install msal requests
#
#   4. Edit the CONFIGURATION BLOCK below and run:
#
#       python send_report.py
#
# AZURE PERMISSIONS REQUIRED
# --------------------------
#   Microsoft Graph > Application permissions > Mail.Send
#   (Admin consent required)
#
# =============================================================================

import os
import base64
import mimetypes
import logging
import msal
import requests

# =============================================================================
# CONFIGURATION BLOCK — edit these values before running
# =============================================================================

# --- Azure AD credentials (read from environment variables) ------------------
# Never hardcode secrets in source code. Set these in your shell or .env file.
CLIENT_ID     = os.environ.get("GRAPH_CLIENT_ID",     "")
CLIENT_SECRET = os.environ.get("GRAPH_CLIENT_SECRET", "")
TENANT_ID     = os.environ.get("GRAPH_TENANT_ID",     "")

# --- Email settings ----------------------------------------------------------
SENDER_EMAIL    = "reports@yourdomain.com"          # Mailbox the app sends FROM
RECIPIENT_EMAIL = ["recipient@yourdomain.com"]       # One address or a list
EMAIL_SUBJECT   = "Automated Report"
EMAIL_BODY      = "Please find the attached report."
EMAIL_BODY_TYPE = "Text"                             # "Text" or "HTML"

# --- Attachment (set to None to send without an attachment) ------------------
ATTACHMENT_PATH = None                               # e.g. "/reports/output.xlsx"

# --- Graph API ---------------------------------------------------------------
GRAPH_ENDPOINT = "https://graph.microsoft.com/v1.0"
SCOPE          = ["https://graph.microsoft.com/.default"]
AUTHORITY      = f"https://login.microsoftonline.com/{TENANT_ID}"

# =============================================================================
# LOGGING
# =============================================================================

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
# Suppress verbose output from underlying HTTP and auth libraries
logging.getLogger("urllib3").setLevel(logging.WARNING)
logging.getLogger("msal").setLevel(logging.WARNING)

log = logging.getLogger(__name__)

# =============================================================================
# FUNCTIONS
# =============================================================================

def validate_config() -> None:
    """
    Fail fast if required environment variables are missing.
    Catches the most common setup mistake before making any network calls.
    """
    missing = [
        name for name, val in {
            "GRAPH_CLIENT_ID":     CLIENT_ID,
            "GRAPH_CLIENT_SECRET": CLIENT_SECRET,
            "GRAPH_TENANT_ID":     TENANT_ID,
        }.items() if not val
    ]
    if missing:
        raise EnvironmentError(
            f"Missing required environment variable(s): {', '.join(missing)}\n"
            "Set them in your shell or a .env file before running this script."
        )


def acquire_token() -> str:
    """
    Authenticate against Microsoft Identity Platform using the
    client credentials flow (application / daemon authentication).

    Returns the raw access token string.
    Raises RuntimeError if authentication fails.
    """
    app = msal.ConfidentialClientApplication(
        CLIENT_ID,
        authority=AUTHORITY,
        client_credential=CLIENT_SECRET,
    )
    result = app.acquire_token_for_client(scopes=SCOPE)

    if "access_token" in result:
        log.info("Access token acquired.")
        return result["access_token"]

    raise RuntimeError(
        f"Authentication failed. Error: {result.get('error')} — "
        f"{result.get('error_description')}"
    )


def build_attachment(file_path: str) -> dict:
    """
    Read a file from disk, Base64-encode it, and return a Graph API
    fileAttachment object ready to include in the message payload.

    Raises FileNotFoundError if the path does not exist.
    """
    if not os.path.isfile(file_path):
        raise FileNotFoundError(f"Attachment not found: {file_path}")

    file_name = os.path.basename(file_path)
    mime_type, _ = mimetypes.guess_type(file_path)
    mime_type = mime_type or "application/octet-stream"

    with open(file_path, "rb") as fh:
        encoded = base64.b64encode(fh.read()).decode("utf-8")

    log.info("Attachment ready: %s (%s)", file_name, mime_type)

    return {
        "@odata.type": "#microsoft.graph.fileAttachment",
        "name":         file_name,
        "contentType":  mime_type,
        "contentBytes": encoded,
    }


def build_payload(attachment: dict | None = None) -> dict:
    """
    Construct the Graph API sendMail request body.

    Accepts a single recipient string or a list of strings for
    RECIPIENT_EMAIL. Includes the attachment only when one is provided.
    """
    recipients = (
        [RECIPIENT_EMAIL] if isinstance(RECIPIENT_EMAIL, str) else RECIPIENT_EMAIL
    )

    message: dict = {
        "subject": EMAIL_SUBJECT,
        "body": {
            "contentType": EMAIL_BODY_TYPE,
            "content":     EMAIL_BODY,
        },
        "toRecipients": [
            {"emailAddress": {"address": addr}} for addr in recipients
        ],
    }

    if attachment:
        message["attachments"] = [attachment]

    return {"message": message, "saveToSentItems": True}


def send_mail(token: str, payload: dict) -> None:
    """
    POST the message payload to the Graph API sendMail endpoint.

    Raises requests.HTTPError on non-2xx responses so the caller can
    handle or log the failure.
    """
    url     = f"{GRAPH_ENDPOINT}/users/{SENDER_EMAIL}/sendMail"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type":  "application/json",
    }

    response = requests.post(url, headers=headers, json=payload, timeout=30)

    if response.status_code == 202:
        log.info("Email sent successfully.")
    else:
        # Surface the Graph API error detail for easier debugging
        try:
            detail = response.json()
        except Exception:
            detail = response.text
        raise requests.HTTPError(
            f"Graph API returned {response.status_code}: {detail}"
        )


# =============================================================================
# ENTRY POINT
# =============================================================================

if __name__ == "__main__":
    try:
        validate_config()

        token      = acquire_token()
        attachment = build_attachment(ATTACHMENT_PATH) if ATTACHMENT_PATH else None
        payload    = build_payload(attachment)

        send_mail(token, payload)

    except EnvironmentError as exc:
        log.error("Configuration error: %s", exc)
        raise SystemExit(1)
    except FileNotFoundError as exc:
        log.error("Attachment error: %s", exc)
        raise SystemExit(1)
    except RuntimeError as exc:
        log.error("Authentication error: %s", exc)
        raise SystemExit(1)
    except requests.HTTPError as exc:
        log.error("Send failed: %s", exc)
        raise SystemExit(1)
