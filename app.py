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

load_dotenv()

app = Flask(__name__)
CORS(app, supports_credentials=True)

# Initialize Anthropic client for vision API
client = anthropic.Anthropic(api_key=os.getenv('ANTHROPIC_API_KEY'))

# JWT Secret
JWT_SECRET = os.getenv('JWT_SECRET', 'your-secret-key-change-in-production')

# Database setup
DB_PATH = 'cityconne.db'

def init_db():
    """Initialize SQLite database with tables"""
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
    """Get database connection"""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def hash_password(password):
    """Hash password with salt"""
    salt = secrets.token_hex(16)
    password_hash = hashlib.pbkdf2_hmac('sha256', password.encode(), salt.encode(), 100000)
    return f"{salt}${password_hash.hex()}"

def verify_password(password, password_hash):
    """Verify password"""
    try:
        salt, hash_val = password_hash.split('$')
        password_check = hashlib.pbkdf2_hmac('sha256', password.encode(), salt.encode(), 100000)
        return password_check.hex() == hash_val
    except:
        return False

def create_token(user_id, email, username):
    """Create JWT token"""
    payload = {
        'user_id': user_id,
        'email': email,
        'username': username,
        'exp': datetime.utcnow() + timedelta(days=30)
    }
    return jwt.encode(payload, JWT_SECRET, algorithm='HS256')

def verify_token(token):
    """Verify JWT token"""
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=['HS256'])
        return payload
    except:
        return None

def get_current_user():
    """Get current user from request"""
    auth_header = request.headers.get('Authorization')
    if not auth_header:
        return None
    
    try:
        token = auth_header.split(' ')[1]
        return verify_token(token)
    except:
        return None

# Initialize database
init_db()

# Seed sample data
def seed_sample_data():
    """Add sample heritage sites if not exists"""
    conn = get_db()
    c = conn.cursor()
    
    c.execute('SELECT COUNT(*) FROM heritage_sites')
    if c.fetchone()[0] == 0:
        sample_sites = [
            ('Sultan Abdul Samad Building', 'A historic building in Kuala Lumpur, Malaysia. Built in 1894-1897, it served as the main administrative office of the British colonial government. The building features a distinctive Moorish Revival architecture with a large copper dome.', 'Colonial Era (1894-1897)', 3.1413, 101.6964, 1, None),
            ('Petronas Twin Towers', 'The iconic twin towers of Kuala Lumpur, completed in 1998. Standing at 452 meters, they were the tallest buildings in the world at the time. The towers feature a unique postmodern style inspired by Islamic architecture.', 'Modern Era (1998)', 3.1578, 101.7123, 1, None),
            ('Batu Caves', 'A limestone hill with a series of caves and cave temples in Gombak, Selangor. The main cave is a massive natural cavern, and the site is home to a large statue of Lord Murugan. It is one of the oldest Hindu temples in Southeast Asia.', 'Ancient (Pre-1800s)', 3.2426, 101.6853, 0, None),
        ]
        c.executemany('''
            INSERT INTO heritage_sites (name, description, historical_period, latitude, longitude, is_wheelchair_accessible, image_url)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ''', sample_sites)
    
    # Add demo user
    c.execute('SELECT COUNT(*) FROM users WHERE email = ?', ('demo@example.com',))
    if c.fetchone()[0] == 0:
        password_hash = hash_password('demo123')
        c.execute('''
            INSERT INTO users (email, password_hash, username)
            VALUES (?, ?, ?)
        ''', ('demo@example.com', password_hash, 'Demo User'))
    
    conn.commit()
    conn.close()

seed_sample_data()


def seed_sample_issues():
    """Add sample issue reports if none exist"""
    conn = get_db()
    c = conn.cursor()

    # Get demo user id
    c.execute('SELECT id FROM users WHERE email = ?', ('demo@example.com',))
    user = c.fetchone()
    user_id = user['id'] if user else None

    # Only add sample issues if none exist
    c.execute('SELECT COUNT(*) FROM issue_reports')
    if c.fetchone()[0] == 0 and user_id:
        sample_issues = [
            (
                user_id,
                'Pothole',
                None,  # photo_base64 placeholder
                3.1415,
                101.6860,
                'Jalan Raja, Kuala Lumpur',
                'Large pothole causing traffic disruptions',
                'pending'
            ),
            (
                user_id,
                'Street Light',
                None,
                3.1420,
                101.6880,
                'Bukit Bintang',
                'Street light not working for 3 nights',
                'in_progress'
            ),
            (
                user_id,
                'Garbage',
                None,
                3.1400,
                101.6900,
                'KLCC Park',
                'Overflowing trash bins',
                'resolved'
            ),
        ]

        c.executemany('''
            INSERT INTO issue_reports 
            (user_id, category, photo_base64, latitude, longitude, address, description, status)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''', sample_issues)
        conn.commit()

    conn.close()

# Seed sample issues
seed_sample_issues()


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
    """Detect heritage site from image using Claude Vision API"""
    try:
        data = request.get_json()
        image_base64 = data.get('imageBase64')

        if not image_base64:
            return jsonify({'error': 'Image data required'}), 400

        # Call Claude Vision API
        message = client.messages.create(
            model="claude-3-5-sonnet-20241022",
            max_tokens=1024,
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": image_base64,
                            },
                        },
                        {
                            "type": "text",
                            "text": """Analyze this image and determine if it contains a heritage site or historical landmark. 
                            If it does, respond with JSON in this exact format:
                            {
                                "detected": true,
                                "siteName": "name of the site",
                                "confidence": 0.95,
                                "description": "brief description"
                            }
                            If it doesn't contain a heritage site, respond with:
                            {
                                "detected": false,
                                "confidence": 0.0
                            }
                            Only respond with valid JSON, no other text."""
                        }
                    ],
                }
            ],
        )

        response_text = message.content[0].text
        detection_result = json.loads(response_text)

        if detection_result.get('detected'):
            conn = get_db()
            c = conn.cursor()
            site_name = detection_result.get('siteName', '')
            c.execute('SELECT * FROM heritage_sites WHERE name LIKE ?', (f'%{site_name}%',))
            matching_site = c.fetchone()
            conn.close()

            if matching_site:
                return jsonify({
                    'detected': True,
                    'site': {
                        'id': matching_site['id'],
                        'name': matching_site['name'],
                        'description': matching_site['description'],
                        'historicalPeriod': matching_site['historical_period'],
                        'isWheelchairAccessible': bool(matching_site['is_wheelchair_accessible']),
                        'latitude': matching_site['latitude'],
                        'longitude': matching_site['longitude']
                    }
                }), 200
            else:
                return jsonify({
                    'detected': True,
                    'site': {
                        'id': 999,
                        'name': detection_result.get('siteName', 'Heritage Site'),
                        'description': detection_result.get('description', 'A historic landmark'),
                        'historicalPeriod': 'Historic',
                        'isWheelchairAccessible': False,
                        'latitude': 3.1413,
                        'longitude': 101.6964
                    }
                }), 200
        else:
            return jsonify({
                'detected': False,
                'message': 'No heritage site detected in the image'
            }), 200

    except json.JSONDecodeError:
        return jsonify({'error': 'Failed to parse detection response'}), 500
    except Exception as e:
        return jsonify({'error': f'Detection failed: {str(e)}'}), 500

@app.route('/api/heritage/list', methods=['GET'])
def get_heritage_list():
    """Get list of all heritage sites"""
    try:
        wheelchair_only = request.args.get('wheelchairOnly', 'false').lower() == 'true'
        
        conn = get_db()
        c = conn.cursor()
        
        if wheelchair_only:
            c.execute('SELECT * FROM heritage_sites WHERE is_wheelchair_accessible = 1')
        else:
            c.execute('SELECT * FROM heritage_sites')
        
        sites = []
        for row in c.fetchall():
            sites.append({
                'id': row['id'],
                'name': row['name'],
                'description': row['description'],
                'historicalPeriod': row['historical_period'],
                'latitude': row['latitude'],
                'longitude': row['longitude'],
                'isWheelchairAccessible': bool(row['is_wheelchair_accessible']),
                'imageUrl': row['image_url']
            })
        
        conn.close()
        
        return jsonify({
            'sites': sites,
            'total': len(sites)
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/heritage/<int:site_id>', methods=['GET'])
def get_heritage_details(site_id):
    """Get details of a specific heritage site"""
    try:
        conn = get_db()
        c = conn.cursor()
        c.execute('SELECT * FROM heritage_sites WHERE id = ?', (site_id,))
        site = c.fetchone()
        conn.close()
        
        if not site:
            return jsonify({'error': 'Heritage site not found'}), 404
        
        return jsonify({
            'id': site['id'],
            'name': site['name'],
            'description': site['description'],
            'historicalPeriod': site['historical_period'],
            'latitude': site['latitude'],
            'longitude': site['longitude'],
            'isWheelchairAccessible': bool(site['is_wheelchair_accessible']),
            'imageUrl': site['image_url']
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

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

# Health check
@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat()
    }), 200

# Root endpoint
@app.route('/', methods=['GET'])
def root():
    """Root endpoint"""
    return jsonify({
        'app': 'CityConnect Backend API',
        'version': '2.0.0',
        'status': 'running',
        'features': ['Authentication', 'Heritage Detection', 'Issue Reporting'],
        'endpoints': {
            'auth': {
                'login': 'POST /api/auth/login',
                'signup': 'POST /api/auth/signup'
            },
            'heritage': {
                'detect': 'POST /api/heritage/detect',
                'list': 'GET /api/heritage/list',
                'details': 'GET /api/heritage/<id>'
            },
            'issues': {
                'create': 'POST /api/issues/create',
                'list': 'GET /api/issues/list',
                'details': 'GET /api/issues/<id>',
                'updateStatus': 'PUT /api/issues/<id>/status'
            }
        }
    }), 200

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=6000)
