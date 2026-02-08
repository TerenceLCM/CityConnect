from flask import Flask, request, jsonify
from flask_cors import CORS
import base64
import json
from datetime import datetime, timedelta
import os
from dotenv import load_dotenv
import anthropic
import sqlite3
import hashlib
import secrets
import jwt
import re

load_dotenv()

app = Flask(__name__)
CORS(app, supports_credentials=True)

# ==================== CONFIG ====================

# Initialize Anthropic client for vision API
client = anthropic.Anthropic(api_key=os.getenv('ANTHROPIC_API_KEY'))

# JWT Secret
JWT_SECRET = os.getenv('JWT_SECRET', 'your-secret-key-change-in-production')

# Database
DB_PATH = 'cityconne.db'

# In-memory heritage sites (version 2 style)
HERITAGE_SITES_IN_MEMORY = [
    {
        'id': 1,
        'name': 'Sultan Abdul Samad Building',
        'description': 'A historic building in Kuala Lumpur, Malaysia. Built in 1894-1897, it served as the main administrative office of the British colonial government. The building features a distinctive Moorish Revival architecture with a large copper dome.',
        'historicalPeriod': 'Colonial Era (1894-1897)',
        'latitude': 3.1413,
        'longitude': 101.6964,
        'isWheelchairAccessible': True,
        'imageUrl': 'https://example.com/sultan-abdul-samad.jpg'
    },
    {
        'id': 2,
        'name': 'Petronas Twin Towers',
        'description': 'The iconic twin towers of Kuala Lumpur, completed in 1998. Standing at 452 meters, they were the tallest buildings in the world at the time. The towers feature a unique postmodern style inspired by Islamic architecture.',
        'historicalPeriod': 'Modern Era (1998)',
        'latitude': 3.1578,
        'longitude': 101.7123,
        'isWheelchairAccessible': True,
        'imageUrl': 'https://example.com/petronas.jpg'
    },
    {
        'id': 3,
        'name': 'Batu Caves',
        'description': 'A limestone hill with a series of caves and cave temples in Gombak, Selangor. The main cave is a massive natural cavern, and the site is home to a large statue of Lord Murugan. It is one of the oldest Hindu temples in Southeast Asia.',
        'historicalPeriod': 'Ancient (Pre-1800s)',
        'latitude': 3.2426,
        'longitude': 101.6853,
        'isWheelchairAccessible': False,
        'imageUrl': 'https://example.com/batu-caves.jpg'
    }
]

# In-memory issue storage (version 2 style)
issue_reports_in_memory = []
next_issue_id_in_memory = 1

# ==================== HELPERS ====================

def extract_json(text):
    """Extract JSON from Claude response"""
    match = re.search(r'\{.*\}', text, re.DOTALL)
    if not match:
        raise ValueError("No JSON object found in response")
    return match.group(0)

def init_db():
    """Initialize SQLite database"""
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    
    # Users table
    c.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            username TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # Heritage sites table
    c.execute('''
        CREATE TABLE IF NOT EXISTS heritage_sites (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            historical_period TEXT,
            latitude REAL,
            longitude REAL,
            is_wheelchair_accessible BOOLEAN DEFAULT 0,
            image_url TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # Issue reports table
    c.execute('''
        CREATE TABLE IF NOT EXISTS issue_reports (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            category TEXT NOT NULL,
            photo_base64 LONGTEXT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            address TEXT,
            description TEXT,
            status TEXT DEFAULT 'pending',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id)
        )
    ''')
    
    conn.commit()
    conn.close()

def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def hash_password(password):
    salt = secrets.token_hex(16)
    password_hash = hashlib.pbkdf2_hmac('sha256', password.encode(), salt.encode(), 100000)
    return f"{salt}${password_hash.hex()}"

def verify_password(password, password_hash):
    try:
        salt, hash_val = password_hash.split('$')
        password_check = hashlib.pbkdf2_hmac('sha256', password.encode(), salt.encode(), 100000)
        return password_check.hex() == hash_val
    except:
        return False

def create_token(user_id, email, username):
    payload = {
        'user_id': user_id,
        'email': email,
        'username': username,
        'exp': datetime.utcnow() + timedelta(days=30)
    }
    return jwt.encode(payload, JWT_SECRET, algorithm='HS256')

def verify_token(token):
    try:
        return jwt.decode(token, JWT_SECRET, algorithms=['HS256'])
    except:
        return None

def get_current_user():
    auth_header = request.headers.get('Authorization')
    if not auth_header:
        return None
    try:
        token = auth_header.split(' ')[1]
        return verify_token(token)
    except:
        return None

# ==================== INITIALIZATION ====================

init_db()

# ==================== AUTHENTICATION ENDPOINTS ====================

@app.route('/api/auth/login', methods=['POST'])
def login():
    """Login user"""
    try:
        data = request.get_json()
        email = data.get('email')
        password = data.get('password')
        
        if not email or not password:
            return jsonify({'success': False, 'message': 'Email and password required'}), 400
        
        conn = get_db()
        c = conn.cursor()
        c.execute('SELECT * FROM users WHERE email = ?', (email,))
        user = c.fetchone()
        conn.close()
        
        if not user or not verify_password(password, user['password_hash']):
            return jsonify({'success': False, 'message': 'Invalid credentials'}), 401
        
        token = create_token(user['id'], user['email'], user['username'])
        return jsonify({
            'success': True,
            'token': token,
            'userId': user['id'],
            'username': user['username'],
            'email': user['email']
        }), 200
    
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/api/auth/signup', methods=['POST'])
def signup():
    """Sign up new user"""
    try:
        data = request.get_json()
        email = data.get('email')
        password = data.get('password')
        
        if not email or not password:
            return jsonify({'success': False, 'message': 'Email and password required'}), 400
        
        password_hash = hash_password(password)
        
        conn = get_db()
        c = conn.cursor()
        
        try:
            c.execute('''
                INSERT INTO users (email, password_hash, username)
                VALUES (?, ?, ?)
            ''', (email, password_hash, email.split('@')[0]))
            conn.commit()
            
            user_id = c.lastrowid
            token = create_token(user_id, email, email.split('@')[0])
            
            return jsonify({
                'success': True,
                'token': token,
                'userId': user_id,
                'username': email.split('@')[0],
                'email': email
            }), 201
        
        except sqlite3.IntegrityError:
            return jsonify({'success': False, 'message': 'Email already exists'}), 409
        
        finally:
            conn.close()
    
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

# ==================== HERITAGE ENDPOINTS ====================

@app.route('/api/heritage/detect', methods=['POST'])
def detect_heritage():
    """
    Hybrid: Use in-memory sites for matching, Claude for detection
    """
    try:
        data = request.get_json()
        image_base64 = data.get('imageBase64')

        if not image_base64:
            return jsonify({'error': 'Image data required'}), 400

        # Call Claude Vision API
        message = client.messages.create(
            model="claude-sonnet-4-5-20250929",
            max_tokens=1024,
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": data.get("mimeType", "image/jpeg"),
                                "data": image_base64,
                            },
                        },
                        {
                            "type": "text",
                            "text": """Analyze this image and respond ONLY in JSON:
                            {
                                "detected": true/false,
                                "siteName": "name",
                                "confidence": 0.95,
                                "description": "text"
                            }"""
                        }
                    ],
                }
            ],
        )

        response_text = ""
        for block in message.content:
            if block.type == "text":
                response_text += block.text

        json_text = extract_json(response_text)
        detection_result = json.loads(json_text)

        if detection_result.get('detected'):
            site_name = detection_result.get('siteName', '')
            matching_site = next(
                (s for s in HERITAGE_SITES_IN_MEMORY if s['name'].lower() in site_name.lower() or site_name.lower() in s['name'].lower()),
                None
            )
            if matching_site:
                return jsonify({'detected': True, 'site': matching_site}), 200
            else:
                return jsonify({'detected': True, 'site': {
                    'id': 999,
                    'name': detection_result.get('siteName', 'Heritage Site'),
                    'description': detection_result.get('description', 'A historic landmark'),
                    'historicalPeriod': 'Historic',
                    'isWheelchairAccessible': False,
                    'latitude': 3.1413,
                    'longitude': 101.6964
                }}), 200
        else:
            return jsonify({'detected': False, 'message': 'No heritage site detected'}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/heritage/list', methods=['GET'])
def get_heritage_list():
    wheelchair_only = request.args.get('wheelchairOnly', 'false').lower() == 'true'
    if wheelchair_only:
        sites = [s for s in HERITAGE_SITES_IN_MEMORY if s['isWheelchairAccessible']]
    else:
        sites = HERITAGE_SITES_IN_MEMORY
    return jsonify({'sites': sites, 'total': len(sites)}), 200

@app.route('/api/heritage/<int:site_id>', methods=['GET'])
def get_heritage_details(site_id):
    site = next((s for s in HERITAGE_SITES_IN_MEMORY if s['id'] == site_id), None)
    if not site:
        return jsonify({'error': 'Heritage site not found'}), 404
    return jsonify(site), 200


# ==================== ISSUE ENDPOINTS ====================

@app.route('/api/issues/create', methods=['POST'])
def create_issue():
    """Create a new issue report"""
    try:
        data = request.get_json()
        
        if not data.get('category') or not data.get('photoBase64'):
            return jsonify({'error': 'Category and photo are required'}), 400
        
        if data.get('latitude') is None or data.get('longitude') is None:
            return jsonify({'error': 'Location coordinates are required'}), 400
        
        user = get_current_user()
        user_id = user['user_id'] if user else None
        
        conn = get_db()
        c = conn.cursor()
        
        c.execute('''
            INSERT INTO issue_reports (user_id, category, photo_base64, latitude, longitude, address, description, status)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            user_id,
            data.get('category'),
            data.get('photoBase64'),
            data.get('latitude'),
            data.get('longitude'),
            data.get('address'),
            data.get('description'),
            'pending'
        ))
        
        conn.commit()
        issue_id = c.lastrowid
        
        c.execute('SELECT * FROM issue_reports WHERE id = ?', (issue_id,))
        issue = c.fetchone()
        conn.close()
        
        return jsonify({
            'success': True,
            'issue': {
                'id': issue['id'],
                'category': issue['category'],
                'latitude': issue['latitude'],
                'longitude': issue['longitude'],
                'address': issue['address'],
                'description': issue['description'],
                'status': issue['status'],
                'createdAt': issue['created_at']
            },
            'message': 'Issue report created successfully'
        }), 201
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/issues/list', methods=['GET'])
def get_issues_list():
    """Get list of all issue reports"""
    try:
        status = request.args.get('status')
        category = request.args.get('category')
        
        conn = get_db()
        c = conn.cursor()
        
        query = 'SELECT * FROM issue_reports WHERE 1=1'
        params = []
        
        if status:
            query += ' AND status = ?'
            params.append(status)
        
        if category:
            query += ' AND category = ?'
            params.append(category)
        
        query += ' ORDER BY created_at DESC'
        
        c.execute(query, params)
        
        issues = []
        for row in c.fetchall():
            issues.append({
                'id': row['id'],
                'category': row['category'],
                'latitude': row['latitude'],
                'longitude': row['longitude'],
                'address': row['address'],
                'description': row['description'],
                'status': row['status'],
                'photoBase64': row['photo_base64'][:100] if row['photo_base64'] else None,  # First 100 chars
                'createdAt': row['created_at'],
                'updatedAt': row['updated_at']
            })
        
        conn.close()
        
        return jsonify({
            'issues': issues,
            'total': len(issues)
        }), 200
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/issues/<int:issue_id>', methods=['GET'])
def get_issue_details(issue_id):
    """Get details of a specific issue report"""
    try:
        conn = get_db()
        c = conn.cursor()
        c.execute('SELECT * FROM issue_reports WHERE id = ?', (issue_id,))
        issue = c.fetchone()
        conn.close()
        
        if not issue:
            return jsonify({'error': 'Issue report not found'}), 404
        
        return jsonify({
            'id': issue['id'],
            'category': issue['category'],
            'latitude': issue['latitude'],
            'longitude': issue['longitude'],
            'address': issue['address'],
            'description': issue['description'],
            'status': issue['status'],
            'photoBase64': issue['photo_base64'],
            'createdAt': issue['created_at'],
            'updatedAt': issue['updated_at']
        }), 200
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/issues/<int:issue_id>/status', methods=['PUT'])
def update_issue_status(issue_id):
    """Update status of an issue report"""
    try:
        data = request.get_json()
        new_status = data.get('status')
        
        if not new_status:
            return jsonify({'error': 'Status is required'}), 400
        
        conn = get_db()
        c = conn.cursor()
        
        c.execute('''
            UPDATE issue_reports 
            SET status = ?, updated_at = CURRENT_TIMESTAMP
            WHERE id = ?
        ''', (new_status, issue_id))
        
        conn.commit()
        
        c.execute('SELECT * FROM issue_reports WHERE id = ?', (issue_id,))
        issue = c.fetchone()
        conn.close()
        
        if not issue:
            return jsonify({'error': 'Issue not found'}), 404
        
        return jsonify({
            'success': True,
            'issue': {
                'id': issue['id'],
                'status': issue['status'],
                'updatedAt': issue['updated_at']
            },
            'message': 'Issue status updated successfully'
        }), 200
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500



# ==================== HEALTH & ROOT ====================

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({'status': 'healthy', 'timestamp': datetime.now().isoformat()}), 200

@app.route('/', methods=['GET'])
def root():
    return jsonify({
        'app': 'CityConnect Backend API',
        'version': '2.0.0 (Hybrid)',
        'status': 'running',
        'features': ['Authentication', 'Heritage Detection', 'Issue Reporting'],
    }), 200

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=6000)
