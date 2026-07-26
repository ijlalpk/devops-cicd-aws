from flask import Flask, render_template, request, jsonify
import os
from datetime import datetime
import pymysql

app = Flask(__name__, template_folder='templates')

db_config = {
    'host': os.getenv('DB_HOST', 'db'),
    'port': int(os.getenv('DB_PORT', 3306)),
    'user': os.getenv('DB_USER', 'appuser'),
    'password': os.getenv('DB_PASSWORD', 'localpassword'),
    'database': os.getenv('DB_NAME', 'appdb'),
    'charset': 'utf8mb4',
}

def get_db_connection():
    try:
        conn = pymysql.connect(**db_config)
        return conn
    except Exception as e:
        print(f"Database connection error: {e}")
        return None

def init_db():
    conn = get_db_connection()
    if conn:
        cursor = conn.cursor()
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS feedback (
                id INT AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(100) NOT NULL,
                message TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ''')
        conn.commit()
        conn.close()

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        'status': 'healthy',
        'version': 'v1.0.0',
        'instance': 'aws-ec2',
        'timestamp': datetime.utcnow().isoformat()
    }), 200

@app.route('/api/info', methods=['GET'])
def api_info():
    return jsonify({
        'app_name': 'DevOps CI/CD Demo',
        'version': 'v1.0.0',
        'environment': 'production',
        'timestamp': datetime.utcnow().isoformat()
    }), 200

@app.route('/feedback', methods=['POST'])
def feedback():
    name = request.form.get('name', 'Anonymous')
    message = request.form.get('message', '')
    
    conn = get_db_connection()
    if conn:
        try:
            cursor = conn.cursor()
            cursor.execute(
                'INSERT INTO feedback (name, message) VALUES (%s, %s)',
                (name, message)
            )
            conn.commit()
            conn.close()
            return jsonify({'status': 'success', 'message': 'Saved to Amazon RDS.'}), 200
        except Exception as e:
            return jsonify({'status': 'error', 'message': str(e)}), 500
    
    return jsonify({'status': 'error', 'message': 'Database connection failed'}), 500

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5000, debug=True)
