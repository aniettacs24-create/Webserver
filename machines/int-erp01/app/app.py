from flask import Flask, request, render_template_string, redirect, session, jsonify
import psycopg2
import requests
import os

app = Flask(__name__)
app.secret_key = "erp_secret_hardcoded_2024"  # Hardcoded secret key — intentional

DB_CONFIG = {'host': 'localhost', 'database': 'erp_db', 'user': 'erp_admin', 'password': 'erp_admin123'}

def get_db():
    return psycopg2.connect(**DB_CONFIG)

LOGIN_HTML = """<!DOCTYPE html><html><body style="font-family:sans-serif;max-width:400px;margin:100px auto">
<h2>VulnCorp ERP Login</h2>
{% if error %}<p style="color:red">{{ error }}</p>{% endif %}
<form method="POST" action="/erp/login">
  <p>Username: <input name="username"></p>
  <p>Password: <input name="password" type="password"></p>
  <input type="submit" value="Login">
</form></body></html>"""

DASHBOARD_HTML = """<!DOCTYPE html><html><body style="font-family:sans-serif;padding:20px">
<h2>VulnCorp ERP — Welcome {{ user }}</h2>
<p><a href="/erp/records">My Records</a> | <a href="/erp/import">Import Doc</a> | <a href="/erp/invoice/create">Create Invoice</a></p>
<p><a href="/erp/logout">Logout</a></p></body></html>"""

@app.route("/")
def index():
    return redirect("/erp/login")

@app.route("/erp/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        u = request.form.get("username", "")
        p = request.form.get("password", "")
        conn = get_db()
        cur = conn.cursor()
        # SQL INJECTION vulnerability — raw string formatting (intentional)
        cur.execute(f"SELECT id, username, role FROM users WHERE username='{u}' AND password='{p}'")
        user = cur.fetchone()
        conn.close()
        if user:
            session['user_id'] = user[0]
            session['username'] = user[1]
            session['role'] = user[2]
            return redirect("/erp/dashboard")
        return render_template_string(LOGIN_HTML, error="Invalid credentials")
    return render_template_string(LOGIN_HTML, error=None)

@app.route("/erp/dashboard")
def dashboard():
    if 'user_id' not in session:
        return redirect("/erp/login")
    return render_template_string(DASHBOARD_HTML, user=session['username'])

@app.route("/erp/records")
def records():
    if 'user_id' not in session:
        return redirect("/erp/login")
    # IDOR — no authorization check, accepts any user id (intentional)
    record_id = request.args.get("id", session['user_id'])
    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT * FROM employee_records WHERE user_id = %s", (record_id,))
    record = cur.fetchone()
    conn.close()
    return f"<pre>Record: {record}\nFlag: VULN{{1d0r_3rp_r3c0rds}}</pre>"

@app.route("/erp/import")
def import_doc():
    if 'user_id' not in session:
        return redirect("/erp/login")
    url = request.args.get("url", "")
    if url:
        try:
            # SSRF — no URL validation (intentional)
            # Try: /erp/import?url=http://192.168.1.50:873/
            # Try: /erp/import?url=file:///etc/passwd
            resp = requests.get(url, timeout=5)
            return f"<pre>{resp.text[:5000]}\n\nFlag: VULN{{ssrf_1nt3rn4l_s4n}}</pre>"
        except Exception as e:
            return f"Error: {e}"
    return "<form method='GET'><input name='url' placeholder='http://...'><input type='submit' value='Fetch'></form>"

@app.route("/erp/invoice/create", methods=["GET", "POST"])
def create_invoice():
    if 'user_id' not in session:
        return redirect("/erp/login")
    if request.method == "POST":
        # Business logic flaw — no validation that amount > 0
        amount = float(request.form.get("amount", 0))
        conn = get_db()
        cur = conn.cursor()
        cur.execute("INSERT INTO invoices (user_id, amount) VALUES (%s, %s) ON CONFLICT DO NOTHING", (session['user_id'], amount))
        conn.commit()
        conn.close()
        return f"Invoice created: ${amount}"
    return "<form method='POST'><input name='amount' placeholder='-9999'><input type='submit' value='Create'></form>"

@app.route("/erp/logout")
def logout():
    session.clear()
    return redirect("/erp/login")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80, debug=True)
