import os
from flask import Flask, render_template, request, redirect, url_for

app = Flask(__name__)

MENU = [
    {"name": "Espresso",   "price": 3.50},
    {"name": "Flat White", "price": 4.50},
    {"name": "Latte",      "price": 4.50},
    {"name": "Cold Brew",  "price": 5.00},
    {"name": "Mocha",  "price": 5.50},
]

# In-memory for now - replaced by DynamoDB in Phase 3.1
ORDERS = []

@app.route("/")
def index():
    return render_template(
        "index.html",
        menu=MENU,
        orders=ORDERS,
        env=os.getenv("APP_ENV", "local"),
    )

@app.route("/order", methods=["POST"])
def order():
    item = request.form.get("item")
    customer = (request.form.get("customer") or "").strip()
    if item and customer:
        ORDERS.append({"customer": customer, "item": item})
    return redirect(url_for("index"))

@app.route("/health")
def health():
    return {"status": "ok"}, 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", 8080)))
