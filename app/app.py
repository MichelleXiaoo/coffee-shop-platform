import logging
import os
import uuid
from datetime import datetime, timezone

from flask import Flask, render_template, request, redirect, url_for

logging.basicConfig(level=logging.INFO)
log = logging.getLogger(__name__)

app = Flask(__name__)

from prometheus_flask_exporter import PrometheusMetrics
metrics = PrometheusMetrics(app)

MENU = [
    {"name": "Espresso",   "price": 3.50},
    {"name": "Flat White", "price": 4.50},
    {"name": "Latte",      "price": 4.50},
    {"name": "Cold Brew",  "price": 5.00},
    {"name": "Mocha",      "price": 5.50},
]

ORDERS_TABLE = os.getenv("ORDERS_TABLE")                      # set in AWS, unset locally
AWS_REGION = os.getenv("AWS_DEFAULT_REGION", "ap-southeast-2")

_memory_orders = []        # local fallback so the app runs without AWS
_table_cache = None

def _table():
    """Lazily create one DynamoDB Table resource and reuse it."""
    global _table_cache
    if _table_cache is None:
        import boto3
        _table_cache = boto3.resource("dynamodb", region_name=AWS_REGION).Table(ORDERS_TABLE)
    return _table_cache

def save_order(customer, item):
    record = {
        "order_id": str(uuid.uuid4()),
        "customer": customer,
        "item": item,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    if ORDERS_TABLE:
        _table().put_item(Item=record)      # let failures surface - we want to see them
    else:
        _memory_orders.append(record)

def list_orders(limit=10):
    if ORDERS_TABLE:
        try:
            items = _table().scan(Limit=limit).get("Items", [])
        except Exception:
            log.exception("Could not read orders from DynamoDB")
            items = []
    else:
        items = list(_memory_orders)
    return sorted(items, key=lambda o: o.get("created_at", ""), reverse=True)[:limit]

@app.route("/")
def index():
    return render_template(
        "index.html",
        menu=MENU,
        orders=list_orders(),
        env=os.getenv("APP_ENV", "local"),
    )

@app.route("/order", methods=["POST"])
def order():
    item = request.form.get("item")
    customer = (request.form.get("customer") or "").strip()
    if item and customer:
        save_order(customer, item)
    return redirect(url_for("index"))

@app.route("/health")
def health():
    return {"status": "ok", "storage": "dynamodb" if ORDERS_TABLE else "memory"}, 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", 8080)))