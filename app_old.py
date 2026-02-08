from flask import Flask, request, jsonify
from flask_cors import CORS
import base64
import json
from datetime import datetime
import os
from dotenv import load_dotenv
import anthropic

load_dotenv()

app = Flask(__name__)
CORS(app)

# Initialize Anthropic client for vision API
client = anthropic.Anthropic(api_key=os.getenv('ANTHROPIC_API_KEY'))

# In-memory storage (replace with database for production)
heritage_sites = [
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

issue_reports = []
next_issue_id = 1

# Heritage APIs
@app.route('/api/heritage/detect', methods=['POST'])
def detect_heritage():
    """
    Detect heritage site from image using Claude Vision API
    """
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

        # Parse response
        response_text = message.content[0].text
        detection_result = json.loads(response_text)

        if detection_result.get('detected'):
            # Find matching site from database or return generic info
            site_name = detection_result.get('siteName', '')
            matching_site = next(
                (s for s in heritage_sites if s['name'].lower() in site_name.lower() or site_name.lower() in s['name'].lower()),
                None
            )

            if matching_site:
                return jsonify({
                    'detected': True,
                    'site': matching_site
                }), 200
            else:
                # Return generic heritage site info
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
        print(f'Detection error: {str(e)}')
        return jsonify({'error': f'Detection failed: {str(e)}'}), 500


@app.route('/api/heritage/list', methods=['GET'])
def get_heritage_list():
    """
    Get list of all heritage sites
    """
    try:
        wheelchair_only = request.args.get('wheelchairOnly', 'false').lower() == 'true'

        if wheelchair_only:
            sites = [s for s in heritage_sites if s['isWheelchairAccessible']]
        else:
            sites = heritage_sites

        return jsonify({
            'sites': sites,
            'total': len(sites)
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/heritage/<int:site_id>', methods=['GET'])
def get_heritage_details(site_id):
    """
    Get details of a specific heritage site
    """
    try:
        site = next((s for s in heritage_sites if s['id'] == site_id), None)

        if not site:
            return jsonify({'error': 'Heritage site not found'}), 404

        return jsonify(site), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# Issue APIs
@app.route('/api/issues/create', methods=['POST'])
def create_issue():
    """
    Create a new issue report
    """
    global next_issue_id

    try:
        data = request.get_json()

        # Validate required fields
        if not data.get('category') or not data.get('photoBase64'):
            return jsonify({'error': 'Category and photo are required'}), 400

        if data.get('latitude') is None or data.get('longitude') is None:
            return jsonify({'error': 'Location coordinates are required'}), 400

        # Create issue report
        issue = {
            'id': next_issue_id,
            'category': data.get('category'),
            'photoBase64': data.get('photoBase64'),  # In production, upload to S3
            'latitude': data.get('latitude'),
            'longitude': data.get('longitude'),
            'address': data.get('address', ''),
            'description': data.get('description', ''),
            'status': 'pending',
            'createdAt': datetime.now().isoformat(),
            'updatedAt': datetime.now().isoformat()
        }

        issue_reports.append(issue)
        next_issue_id += 1

        return jsonify({
            'success': True,
            'issue': issue,
            'message': 'Issue report created successfully'
        }), 201

    except Exception as e:
        print(f'Create issue error: {str(e)}')
        return jsonify({'error': str(e)}), 500


@app.route('/api/issues/list', methods=['GET'])
def get_issues_list():
    """
    Get list of all issue reports
    """
    try:
        status = request.args.get('status')
        category = request.args.get('category')

        filtered_issues = issue_reports

        if status:
            filtered_issues = [i for i in filtered_issues if i['status'] == status]

        if category:
            filtered_issues = [i for i in filtered_issues if i['category'] == category]

        return jsonify({
            'issues': filtered_issues,
            'total': len(filtered_issues)
        }), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/issues/<int:issue_id>', methods=['GET'])
def get_issue_details(issue_id):
    """
    Get details of a specific issue report
    """
    try:
        issue = next((i for i in issue_reports if i['id'] == issue_id), None)

        if not issue:
            return jsonify({'error': 'Issue report not found'}), 404

        return jsonify(issue), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/issues/<int:issue_id>/status', methods=['PUT'])
def update_issue_status(issue_id):
    """
    Update status of an issue report
    """
    try:
        data = request.get_json()
        new_status = data.get('status')

        if not new_status:
            return jsonify({'error': 'Status is required'}), 400

        issue = next((i for i in issue_reports if i['id'] == issue_id), None)

        if not issue:
            return jsonify({'error': 'Issue report not found'}), 404

        issue['status'] = new_status
        issue['updatedAt'] = datetime.now().isoformat()

        return jsonify({
            'success': True,
            'issue': issue,
            'message': 'Issue status updated successfully'
        }), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


# Health check
@app.route('/health', methods=['GET'])
def health_check():
    """
    Health check endpoint
    """
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat()
    }), 200


# Root endpoint
@app.route('/', methods=['GET'])
def root():
    """
    Root endpoint
    """
    return jsonify({
        'app': 'CityConnect Backend API',
        'version': '1.0.0',
        'status': 'running',
        'endpoints': {
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
