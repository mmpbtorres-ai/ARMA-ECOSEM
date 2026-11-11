import os
from datetime import datetime, date, timedelta
from functools import wraps
from urllib.parse import urlparse

from flask import Flask, render_template, redirect, url_for, request, flash, jsonify, abort
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager, UserMixin, login_user, logout_user, login_required, current_user
from flask_wtf.csrf import CSRFProtect
from wtforms import StringField, PasswordField, SelectField, IntegerField, FloatField, DateField, TextAreaField, SubmitField
from wtforms.validators import DataRequired, Length, Optional, NumberRange
from werkzeug.security import generate_password_hash, check_password_hash
from sqlalchemy import func, or_

app = Flask(__name__)
app.config["SECRET_KEY"] = os.getenv("SECRET_KEY", "CHANGE-ME-ON-RAILWAY")
db_url = os.getenv("DATABASE_URL", "sqlite:///sigma_fleet.db")
if db_url.startswith("postgres://"):
    db_url = db_url.replace("postgres://", "postgresql://", 1)
app.config["SQLALCHEMY_DATABASE_URI"] = db_url
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
app.config["SESSION_COOKIE_HTTPONLY"] = True
app.config["SESSION_COOKIE_SAMESITE"] = "Lax"
app.config["SESSION_COOKIE_SECURE"] = os.getenv("COOKIE_SECURE", "false").lower() == "true"
app.config["PERMANENT_SESSION_LIFETIME"] = timedelta(hours=10)

csrf = CSRFProtect(app)
db = SQLAlchemy(app)
login_manager = LoginManager(app)
login_manager.login_view = "login"
login_manager.login_message = "Inicia sesión para continuar."
login_manager.login_message_category = "warning"

class User(UserMixin, db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    full_name = db.Column(db.String(120), nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    role = db.Column(db.String(20), default="tecnico", nullable=False)
    active = db.Column(db.Boolean, default=True, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

class Vehicle(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    code = db.Column(db.String(40), unique=True, nullable=False)
    plate = db.Column(db.String(30), unique=True, nullable=False)
    brand = db.Column(db.String(80), nullable=False)
    model = db.Column(db.String(80), nullable=False)
    year = db.Column(db.Integer)
    category = db.Column(db.String(30), default="Liviano")
    km = db.Column(db.Integer, default=0)
    hours = db.Column(db.Integer, default=0)
    status = db.Column(db.String(40), default="Operativo")
    area = db.Column(db.String(100))
    notes = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class PMPlan(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    vehicle_id = db.Column(db.Integer, db.ForeignKey("vehicle.id"), nullable=False)
    task = db.Column(db.String(180), nullable=False)
    interval_km = db.Column(db.Integer, default=0)
    interval_hours = db.Column(db.Integer, default=0)
    interval_days = db.Column(db.Integer, default=0)
    last_km = db.Column(db.Integer, default=0)
    last_hours = db.Column(db.Integer, default=0)
    last_date = db.Column(db.Date)
    responsible = db.Column(db.String(120))
    active = db.Column(db.Boolean, default=True)
    vehicle = db.relationship("Vehicle", backref="pm_plans")

class WorkOrder(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    number = db.Column(db.String(50), unique=True, nullable=False)
    vehicle_id = db.Column(db.Integer, db.ForeignKey("vehicle.id"), nullable=False)
    kind = db.Column(db.String(30), default="Correctivo")
    description = db.Column(db.Text, nullable=False)
    priority = db.Column(db.String(20), default="Media")
    status = db.Column(db.String(30), default="Abierta")
    responsible = db.Column(db.String(120))
    opened_at = db.Column(db.DateTime, default=datetime.utcnow)
    closed_at = db.Column(db.DateTime)
    labor_cost = db.Column(db.Float, default=0)
    parts_cost = db.Column(db.Float, default=0)
    downtime_hours = db.Column(db.Float, default=0)
    vehicle = db.relationship("Vehicle", backref="work_orders")

class Part(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    sku = db.Column(db.String(60), unique=True, nullable=False)
    name = db.Column(db.String(160), nullable=False)
    quantity = db.Column(db.Integer, default=0)
    min_quantity = db.Column(db.Integer, default=0)
    unit = db.Column(db.String(30), default="unidad")
    unit_cost = db.Column(db.Float, default=0)
    supplier = db.Column(db.String(120))

@login_manager.user_loader
def load_user(user_id):
    return db.session.get(User, int(user_id))

def admin_required(fn):
    @wraps(fn)
    @login_required
    def wrapped(*args, **kwargs):
        if current_user.role != "admin":
            abort(403)
        return fn(*args, **kwargs)
    return wrapped

def pm_status(plan):
    v = plan.vehicle
    due = []
    if plan.interval_km and v.km >= plan.last_km + plan.interval_km:
        due.append("VENCIDO")
    elif plan.interval_km and v.km >= plan.last_km + plan.interval_km * 0.9:
        due.append("PRÓXIMO")
    if plan.interval_hours and v.hours >= plan.last_hours + plan.interval_hours:
        due.append("VENCIDO")
    elif plan.interval_hours and v.hours >= plan.last_hours + plan.interval_hours * 0.9:
        due.append("PRÓXIMO")
    if plan.interval_days and plan.last_date:
        next_date = plan.last_date + timedelta(days=plan.interval_days)
        if date.today() > next_date:
            due.append("VENCIDO")
        elif (next_date - date.today()).days <= max(1, int(plan.interval_days * .1)):
            due.append("PRÓXIMO")
    return "VENCIDO" if "VENCIDO" in due else ("PRÓXIMO" if due else "AL DÍA")

@app.context_processor
def inject_globals():
    return {"today": date.today(), "pm_status": pm_status}

@app.route("/")
@login_required
def dashboard():
    vehicles = Vehicle.query.count()
    operational = Vehicle.query.filter_by(status="Operativo").count()
    open_orders = WorkOrder.query.filter(WorkOrder.status != "Cerrada").count()
    plans = PMPlan.query.filter_by(active=True).all()
    due_count = sum(1 for p in plans if pm_status(p) == "VENCIDO")
    upcoming_count = sum(1 for p in plans if pm_status(p) == "PRÓXIMO")
    low_stock = Part.query.filter(Part.quantity <= Part.min_quantity).count()
    total_cost = db.session.query(func.coalesce(func.sum(WorkOrder.labor_cost + WorkOrder.parts_cost), 0)).scalar() or 0
    completed = WorkOrder.query.filter_by(status="Cerrada").count()
    total = WorkOrder.query.count()
    pm_compliance = round(completed / total * 100, 1) if total else 0
    recent = WorkOrder.query.order_by(WorkOrder.opened_at.desc()).limit(8).all()
    return render_template("dashboard.html", vehicles=vehicles, operational=operational,
        open_orders=open_orders, due_count=due_count, upcoming_count=upcoming_count,
        low_stock=low_stock, total_cost=total_cost, pm_compliance=pm_compliance,
        recent=recent)

@app.route("/login", methods=["GET", "POST"])
def login():
    if current_user.is_authenticated:
        return redirect(url_for("dashboard"))
    if request.method == "POST":
        username = request.form.get("username", "").strip()
        password = request.form.get("password", "")
        user = User.query.filter_by(username=username, active=True).first()
        if user and user.check_password(password):
            login_user(user, remember=False)
            flash("Bienvenido a SIGMA Fleet.", "success")
            return redirect(request.args.get("next") or url_for("dashboard"))
        flash("Usuario o contraseña incorrectos, o cuenta desactivada.", "danger")
    return render_template("login.html")

@app.route("/logout")
@login_required
def logout():
    logout_user()
    flash("Sesión cerrada.", "info")
    return redirect(url_for("login"))

@app.route("/vehicles", methods=["GET", "POST"])
@login_required
def vehicles():
    if request.method == "POST":
        try:
            v = Vehicle(code=request.form["code"].strip(), plate=request.form["plate"].strip().upper(),
                brand=request.form["brand"].strip(), model=request.form["model"].strip(),
                year=int(request.form.get("year") or 0) or None,
                category=request.form.get("category", "Liviano"),
                km=int(request.form.get("km") or 0), hours=int(request.form.get("hours") or 0),
                status=request.form.get("status", "Operativo"), area=request.form.get("area"),
                notes=request.form.get("notes"))
            db.session.add(v); db.session.commit(); flash("Vehículo registrado.", "success")
        except Exception as e:
            db.session.rollback(); flash("No se pudo guardar. Verifica que el código y la placa no estén repetidos.", "danger")
        return redirect(url_for("vehicles"))
    return render_template("vehicles.html", items=Vehicle.query.order_by(Vehicle.code).all())

@app.route("/vehicles/<int:item_id>/delete", methods=["POST"])
@admin_required
def delete_vehicle(item_id):
    v = db.get_or_404(Vehicle, item_id)
    if v.work_orders or v.pm_plans:
        flash("No se puede eliminar: el vehículo tiene planes u órdenes vinculados.", "warning")
    else:
        db.session.delete(v); db.session.commit(); flash("Vehículo eliminado.", "success")
    return redirect(url_for("vehicles"))

@app.route("/vehicles/<int:item_id>/update", methods=["POST"])
@login_required
def update_vehicle(item_id):
    v = db.get_or_404(Vehicle, item_id)
    for key in ["brand","model","category","status","area","notes"]:
        setattr(v, key, request.form.get(key, getattr(v,key)))
    for key in ["km","hours","year"]:
        raw = request.form.get(key)
        if raw not in (None, ""):
            try:
                value = int(raw)
                setattr(v, key, (value or None) if key == "year" else value)
            except ValueError:
                pass
    db.session.commit(); flash("Vehículo actualizado.", "success")
    return redirect(url_for("vehicles"))

@app.route("/pm", methods=["GET", "POST"])
@login_required
def pm():
    if request.method == "POST":
        try:
            p = PMPlan(vehicle_id=int(request.form["vehicle_id"]), task=request.form["task"],
                interval_km=int(request.form.get("interval_km") or 0),
                interval_hours=int(request.form.get("interval_hours") or 0),
                interval_days=int(request.form.get("interval_days") or 0),
                last_km=int(request.form.get("last_km") or 0),
                last_hours=int(request.form.get("last_hours") or 0),
                last_date=datetime.strptime(request.form["last_date"], "%Y-%m-%d").date() if request.form.get("last_date") else None,
                responsible=request.form.get("responsible"))
            db.session.add(p); db.session.commit(); flash("Plan preventivo creado.", "success")
        except Exception:
            db.session.rollback(); flash("Revisa los datos del plan preventivo.", "danger")
        return redirect(url_for("pm"))
    return render_template("pm.html", items=PMPlan.query.order_by(PMPlan.id.desc()).all(), vehicles=Vehicle.query.order_by(Vehicle.code).all())

@app.route("/pm/<int:item_id>/complete", methods=["POST"])
@login_required
def complete_pm(item_id):
    p = db.get_or_404(PMPlan, item_id)
    p.last_km = p.vehicle.km; p.last_hours = p.vehicle.hours; p.last_date = date.today()
    db.session.commit(); flash("Mantenimiento marcado como realizado; se reinició su ciclo.", "success")
    return redirect(url_for("pm"))

@app.route("/pm/<int:item_id>/delete", methods=["POST"])
@admin_required
def delete_pm(item_id):
    db.session.delete(db.get_or_404(PMPlan,item_id)); db.session.commit()
    flash("Plan eliminado.", "success"); return redirect(url_for("pm"))

@app.route("/orders", methods=["GET", "POST"])
@login_required
def orders():
    if request.method == "POST":
        try:
            count = WorkOrder.query.count() + 1
            number = request.form.get("number") or f"OT-{datetime.utcnow():%Y%m%d}-{count:04d}"
            o = WorkOrder(number=number, vehicle_id=int(request.form["vehicle_id"]),
                kind=request.form.get("kind","Correctivo"), description=request.form["description"],
                priority=request.form.get("priority","Media"), responsible=request.form.get("responsible"),
                status=request.form.get("status","Abierta"), labor_cost=float(request.form.get("labor_cost") or 0),
                parts_cost=float(request.form.get("parts_cost") or 0), downtime_hours=float(request.form.get("downtime_hours") or 0))
            db.session.add(o); db.session.commit(); flash(f"Orden {number} creada.", "success")
        except Exception:
            db.session.rollback(); flash("No se pudo crear la OT. Revisa los campos.", "danger")
        return redirect(url_for("orders"))
    return render_template("orders.html", items=WorkOrder.query.order_by(WorkOrder.opened_at.desc()).all(), vehicles=Vehicle.query.order_by(Vehicle.code).all())

@app.route("/orders/<int:item_id>/status", methods=["POST"])
@login_required
def order_status(item_id):
    o = db.get_or_404(WorkOrder,item_id)
    o.status=request.form.get("status","Abierta")
    if o.status == "Cerrada" and not o.closed_at: o.closed_at=datetime.utcnow()
    db.session.commit(); flash("Estado de OT actualizado.", "success")
    return redirect(url_for("orders"))

@app.route("/orders/<int:item_id>/delete", methods=["POST"])
@admin_required
def delete_order(item_id):
    db.session.delete(db.get_or_404(WorkOrder,item_id)); db.session.commit()
    flash("Orden eliminada.", "success"); return redirect(url_for("orders"))

@app.route("/parts", methods=["GET", "POST"])
@login_required
def parts():
    if request.method == "POST":
        try:
            p=Part(sku=request.form["sku"].strip(),name=request.form["name"].strip(),
                quantity=int(request.form.get("quantity") or 0),min_quantity=int(request.form.get("min_quantity") or 0),
                unit=request.form.get("unit","unidad"),unit_cost=float(request.form.get("unit_cost") or 0),
                supplier=request.form.get("supplier"))
            db.session.add(p); db.session.commit(); flash("Repuesto registrado.", "success")
        except Exception:
            db.session.rollback(); flash("No se pudo guardar. Verifica que el SKU no esté repetido.", "danger")
        return redirect(url_for("parts"))
    return render_template("parts.html", items=Part.query.order_by(Part.name).all())

@app.route("/parts/<int:item_id>/stock", methods=["POST"])
@login_required
def adjust_stock(item_id):
    p=db.get_or_404(Part,item_id)
    try: p.quantity=max(0,p.quantity+int(request.form.get("change") or 0)); db.session.commit(); flash("Stock actualizado.", "success")
    except ValueError: flash("Cantidad no válida.", "danger")
    return redirect(url_for("parts"))

@app.route("/parts/<int:item_id>/delete", methods=["POST"])
@admin_required
def delete_part(item_id):
    db.session.delete(db.get_or_404(Part,item_id)); db.session.commit()
    flash("Repuesto eliminado.", "success"); return redirect(url_for("parts"))

@app.route("/users", methods=["GET", "POST"])
@admin_required
def users():
    if request.method == "POST":
        username=request.form["username"].strip()
        if User.query.filter_by(username=username).first():
            flash("Ese usuario ya existe.", "danger")
        else:
            u=User(username=username,full_name=request.form["full_name"].strip(),role=request.form.get("role","tecnico"))
            u.set_password(request.form["password"]); db.session.add(u); db.session.commit()
            flash("Usuario creado.", "success")
        return redirect(url_for("users"))
    return render_template("users.html", items=User.query.order_by(User.id).all())

@app.route("/users/<int:item_id>/reset", methods=["POST"])
@admin_required
def reset_user(item_id):
    u=db.get_or_404(User,item_id); password=request.form.get("password","")
    if len(password)<10: flash("La contraseña debe tener al menos 10 caracteres.", "danger")
    else: u.set_password(password); db.session.commit(); flash("Contraseña actualizada.", "success")
    return redirect(url_for("users"))

@app.route("/users/<int:item_id>/toggle", methods=["POST"])
@admin_required
def toggle_user(item_id):
    u=db.get_or_404(User,item_id)
    if u.id==current_user.id: flash("No puedes desactivar tu propia cuenta.", "warning")
    else: u.active=not u.active; db.session.commit(); flash("Estado de usuario actualizado.", "success")
    return redirect(url_for("users"))

@app.route("/api/health")
def health():
    return jsonify({"status":"ok","app":"SIGMA Fleet","database":"connected"})

@app.route("/api/dashboard")
@login_required
def api_dashboard():
    return jsonify({"vehicles":Vehicle.query.count(),"open_work_orders":WorkOrder.query.filter(WorkOrder.status!="Cerrada").count(),
        "pm_overdue":sum(pm_status(p)=="VENCIDO" for p in PMPlan.query.filter_by(active=True).all()),
        "low_stock":Part.query.filter(Part.quantity<=Part.min_quantity).count()})

@app.errorhandler(403)
def forbidden(e): return render_template("error.html", code=403, message="No tienes permisos para esta acción."),403
@app.errorhandler(404)
def not_found(e): return render_template("error.html", code=404, message="No se encontró el recurso solicitado."),404

def initialize():
    with app.app_context():
        db.create_all()
        admin_name=os.getenv("ADMIN_USERNAME","admin")
        admin_password=os.getenv("ADMIN_PASSWORD","SigmaFleet2026!")
        if not User.query.filter_by(username=admin_name).first():
            admin=User(username=admin_name,full_name=os.getenv("ADMIN_FULL_NAME","Administrador SIGMA"),role="admin")
            admin.set_password(admin_password); db.session.add(admin); db.session.commit()
            print(f"[SIGMA] Usuario administrador inicial creado: {admin_name}")
        print("[SIGMA] Base de datos inicializada.")

initialize()

if __name__ == "__main__":
    app.run(host="0.0.0.0",port=int(os.getenv("PORT",5000)),debug=False)
