"""
Main Server Entry Point (Flask version)
"""

import os
from flask import Flask, jsonify
from datetime import datetime

app = Flask(__name__)

@app.route('/')
def root():
    """Root endpoint for App Hosting health checks"""
    return 'Hello from Firebase App Hosting backend!'

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'OK',
        'timestamp': datetime.utcnow().isoformat(),
        'environment': os.getenv('FLASK_ENV', 'production'),
        'config': {
            'debug': app.debug
        }
    })

if __name__ == '__main__':
    # Get port from environment variable or default to 8080
    port = int(os.environ.get('PORT', 8080))
    
    # Run the app on the specified port
    app.run(
        host='0.0.0.0',  # Listen on all available interfaces
        port=port,
        debug=False  # Disable debug mode in production
    ) 