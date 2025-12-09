from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import mysql.connector
from mysql.connector import Error
import os
from datetime import datetime, timedelta, date, time
import json
from werkzeug.utils import secure_filename
import uuid

app = Flask(__name__)
CORS(app, supports_credentials=True)

# Konfigurasi database
db_config = {
    'host': 'localhost',
    'user': 'root',
    'password': '', 
    'database': 'attendance'
}

# Konfigurasi upload file
UPLOAD_FOLDER = 'uploads'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def get_db_connection():
    try:
        connection = mysql.connector.connect(**db_config)
        return connection
    except Error as e:
        print(f"Error connecting to MySQL: {e}")
        return None

# ==================== AUTH ROUTES ====================
@app.route('/api/login', methods=['POST'])
def login():
    data = request.json
    username = data.get('username')
    password = data.get('password')
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM users WHERE username = %s AND password = %s", (username, password))
    user = cursor.fetchone()
    
    cursor.close()
    conn.close()
    
    if user:
        # Remove password from response
        user.pop('password')
        return jsonify({
            'success': True,
            'user': user,
            'message': 'Login successful'
        })
    else:
        return jsonify({
            'success': False,
            'message': 'Invalid username or password'
        }), 401

@app.route('/api/change-password', methods=['POST'])
def change_password():
    data = request.json
    user_id = data.get('user_id')
    old_password = data.get('old_password')
    new_password = data.get('new_password')
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    cursor = conn.cursor()
    
    # Check old password
    cursor.execute("SELECT id FROM users WHERE id = %s AND password = %s", (user_id, old_password))
    if cursor.fetchone():
        cursor.execute("UPDATE users SET password = %s WHERE id = %s", (new_password, user_id))
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({'success': True, 'message': 'Password updated successfully'})
    else:
        cursor.close()
        conn.close()
        return jsonify({'success': False, 'message': 'Old password is incorrect'}), 400

# ==================== EMPLOYEE ROUTES ====================
@app.route('/api/employees', methods=['GET'])
def get_employees():
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT id, username, role, nama, umur, domisili, jabatan, foto FROM users")
    employees = cursor.fetchall()
    
    cursor.close()
    conn.close()
    for e in employees:
        if e["foto"]:
            e["foto"] = request.host_url + "uploads/" + e["foto"]

    return jsonify(employees)

@app.route('/api/employees', methods=['POST'])
def create_employee():
    data = request.form
    username = data.get('username')
    password = data.get('password')
    nama = data.get('nama')
    umur = data.get('umur')
    domisili = data.get('domisili')
    jabatan = data.get('jabatan')
    role = 'karyawan'
    
    # Handle file upload
    foto = None
    if 'foto' in request.files:
        file = request.files['foto']
        if file and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            unique_filename = f"{uuid.uuid4().hex}_{filename}"
            file.save(os.path.join(app.config['UPLOAD_FOLDER'], unique_filename))
            foto = unique_filename
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    cursor = conn.cursor()
    try:
        cursor.execute('''
            INSERT INTO users (username, password, role, nama, umur, domisili, jabatan, foto)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        ''', (username, password, role, nama, umur, domisili, jabatan, foto))
        conn.commit()
        employee_id = cursor.lastrowid
        cursor.close()
        conn.close()
        
        return jsonify({'success': True, 'id': employee_id}), 201
    except Error as e:
        cursor.close()
        conn.close()
        return jsonify({'error': str(e)}), 400

@app.route('/api/employees/<int:employee_id>', methods=['PUT'])
def update_employee(employee_id):
    data = request.form
    nama = data.get('nama')
    umur = data.get('umur')
    domisili = data.get('domisili')
    jabatan = data.get('jabatan')
    
    # Handle file upload
    foto = None
    if 'foto' in request.files:
        file = request.files['foto']
        if file and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            unique_filename = f"{uuid.uuid4().hex}_{filename}"
            file.save(os.path.join(app.config['UPLOAD_FOLDER'], unique_filename))
            foto = unique_filename
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    cursor = conn.cursor()
    
    if foto:
        cursor.execute('''
            UPDATE users SET nama = %s, umur = %s, domisili = %s, jabatan = %s, foto = %s
            WHERE id = %s
        ''', (nama, umur, domisili, jabatan, foto, employee_id))
    else:
        cursor.execute('''
            UPDATE users SET nama = %s, umur = %s, domisili = %s, jabatan = %s
            WHERE id = %s
        ''', (nama, umur, domisili, jabatan, employee_id))
    
    conn.commit()
    cursor.close()
    conn.close()
    
    return jsonify({'success': True})

@app.route('/api/employees/<int:employee_id>', methods=['DELETE'])
def delete_employee(employee_id):
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    cursor = conn.cursor()

    try:
        cursor.execute("DELETE FROM attendance WHERE user_id = %s", (employee_id,))
        cursor.execute("DELETE FROM users WHERE id = %s AND role = 'karyawan'", (employee_id,))
        conn.commit()

        if cursor.rowcount > 0:
            return jsonify({'success': True})
        else:
            return jsonify({'error': 'Employee not found'}), 404

    except Error as e:
        return jsonify({'error': str(e)}), 400
    finally:
        cursor.close()
        conn.close()

# ==================== ATTENDANCE ROUTES ====================
@app.route('/api/attendance/check-in', methods=['POST'])
def check_in():
    data = request.json
    user_id = data.get('user_id')
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    cursor = conn.cursor(dictionary=True)
    today = datetime.now().date()
    
    # Check if already checked in today
    cursor.execute("SELECT * FROM attendance WHERE user_id = %s AND tanggal = %s", (user_id, today))
    existing = cursor.fetchone()
    
    if existing:
        cursor.close()
        conn.close()
        return jsonify({'success': False, 'message': 'Already checked in today'}), 400
    
    # Insert check-in record
    check_in_time = datetime.now().time()
    cursor.execute('''
        INSERT INTO attendance (user_id, tanggal, check_in, status)
        VALUES (%s, %s, %s, 'hadir')
    ''', (user_id, today, check_in_time))
    
    conn.commit()
    cursor.close()
    conn.close()
    
    return jsonify({'success': True, 'message': 'Check-in successful'})

@app.route('/api/attendance/check-out', methods=['POST'])
def check_out():
    data = request.json
    user_id = data.get('user_id')
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    cursor = conn.cursor(dictionary=True)
    today = datetime.now().date()
    
    # Get today's attendance
    cursor.execute("SELECT * FROM attendance WHERE user_id = %s AND tanggal = %s", (user_id, today))
    attendance = cursor.fetchone()
    
    if not attendance:
        cursor.close()
        conn.close()
        return jsonify({'success': False, 'message': 'No check-in record found'}), 400
    
    if attendance['check_out']:
        cursor.close()
        conn.close()
        return jsonify({'success': False, 'message': 'Already checked out today'}), 400
    
    # Update check-out time
    check_out_time = datetime.now().time()
    cursor.execute("UPDATE attendance SET check_out = %s WHERE id = %s", (check_out_time, attendance['id']))
    
    conn.commit()
    cursor.close()
    conn.close()
    
    return jsonify({'success': True, 'message': 'Check-out successful'})

@app.route('/api/attendance/leave', methods=['POST'])
def request_leave():
    data = request.json
    user_id = data.get('user_id')
    status = data.get('status')  # 'izin' or 'cuti'
    keterangan = data.get('keterangan')
    tanggal = data.get('tanggal', datetime.now().date())
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    cursor = conn.cursor(dictionary=True)
    
    # Check if already has attendance for this date
    cursor.execute("SELECT * FROM attendance WHERE user_id = %s AND tanggal = %s", (user_id, tanggal))
    existing = cursor.fetchone()
    
    if existing:
        cursor.close()
        conn.close()
        return jsonify({'success': False, 'message': 'Kamu sudah memiliki absensi untuk hari ini, tidak bisa mengajukan cuti!'}), 400
    
    # Insert leave record
    cursor.execute('''
        INSERT INTO attendance (user_id, tanggal, status, keterangan)
        VALUES (%s, %s, %s, %s)
    ''', (user_id, tanggal, status, keterangan))
    
    conn.commit()
    cursor.close()
    conn.close()
    
    return jsonify({'success': True, 'message': 'Leave request submitted'})

@app.route('/api/attendance/history/<int:user_id>', methods=['GET'])
def get_attendance_history(user_id):
    start_date = request.args.get('start_date')
    end_date = request.args.get('end_date')
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    cursor = conn.cursor(dictionary=True)
    
    query = "SELECT * FROM attendance WHERE user_id = %s"
    params = [user_id]
    
    if start_date and end_date:
        query += " AND tanggal BETWEEN %s AND %s"
        params.extend([start_date, end_date])
    
    query += " ORDER BY tanggal DESC"
    
    cursor.execute(query, tuple(params))
    history = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    for item in history:
        for key, value in item.items():
            if isinstance(value, (datetime, date, time, timedelta)):
                item[key] = str(value)

    return jsonify(history)

@app.route('/api/attendance/report', methods=['GET'])
def get_attendance_report():
    start_date = request.args.get('start_date')
    end_date = request.args.get('end_date')
    employee_id = request.args.get('employee_id')
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    cursor = conn.cursor(dictionary=True)
    
    query = '''
        SELECT a.*, u.nama, u.jabatan 
        FROM attendance a
        JOIN users u ON a.user_id = u.id
        WHERE u.role = 'karyawan'
    '''
    params = []
    
    if employee_id:
        query += " AND a.user_id = %s"
        params.append(employee_id)
    
    if start_date and end_date:
        query += " AND a.tanggal BETWEEN %s AND %s"
        params.extend([start_date, end_date])
    
    query += " ORDER BY a.tanggal DESC"
    
    cursor.execute(query, tuple(params))
    report = cursor.fetchall()
    
    cursor.close()
    conn.close()

    for item in report:
        for key, value in item.items():
            if isinstance(value, (datetime, date, time, timedelta)):
                item[key] = str(value)

    return jsonify(report)

@app.route('/api/user/<int:user_id>', methods=['GET'])
def get_user(user_id):
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT id, username, role, nama, umur, domisili, jabatan, foto FROM users WHERE id = %s", (user_id,))
    user = cursor.fetchone()
    
    cursor.close()
    conn.close()
    
    if user:
        if user["foto"]:
            user["foto"] = request.host_url + "uploads/" + user["foto"]

        return jsonify(user)
    else:
        return jsonify({'error': 'User not found'}), 404

@app.route('/api/user/<int:user_id>', methods=['PUT'])
def update_user_profile(user_id):
    data = request.json
    username = data.get('username')
    nama = data.get('nama')
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    cursor = conn.cursor()
    
    try:
        cursor.execute("UPDATE users SET username = %s, nama = %s WHERE id = %s", (username, nama, user_id))
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({'success': True, 'message': 'Profile updated successfully'})
    except Error as e:
        cursor.close()
        conn.close()
        return jsonify({'error': str(e)}), 400

@app.route('/uploads/<filename>')
def uploaded_file(filename):
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)