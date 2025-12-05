"""
Resumable Upload Server

A Flask-based backend server that supports chunk-based resumable file uploads.
Compatible with the Flutter Resume Upload SDK.

Author: Resume Upload SDK Team
"""

import os
import json
import time
import hashlib
import shutil
from pathlib import Path
from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
from werkzeug.utils import secure_filename

app = Flask(__name__)
CORS(app)

# Configuration
STORAGE_PATH = Path(__file__).parent / 'storage'
UPLOADS_PATH = STORAGE_PATH / 'uploads'
COMPLETED_PATH = STORAGE_PATH / 'completed'
METADATA_PATH = STORAGE_PATH / 'metadata'

# Create directories
UPLOADS_PATH.mkdir(parents=True, exist_ok=True)
COMPLETED_PATH.mkdir(parents=True, exist_ok=True)
METADATA_PATH.mkdir(parents=True, exist_ok=True)

# File status constants
FILE_STATUS_NOT_STARTED = 0
FILE_STATUS_COMPLETED = 1
FILE_STATUS_INCOMPLETE = 2
FILE_STATUS_ABNORMAL = -1

# Block status constants
BLOCK_STATUS_NOT_UPLOADED = 0
BLOCK_STATUS_UPLOADED = 1
BLOCK_STATUS_PARTIAL = 2
BLOCK_STATUS_ERROR = -1


def get_file_metadata_path(fid):
    """Get the metadata file path for a file ID."""
    return METADATA_PATH / f'{fid}.json'


def get_file_upload_dir(fid):
    """Get the upload directory for a file ID."""
    return UPLOADS_PATH / fid


def load_file_metadata(fid):
    """Load file metadata from disk."""
    metadata_path = get_file_metadata_path(fid)
    if metadata_path.exists():
        with open(metadata_path, 'r') as f:
            return json.load(f)
    return None


def save_file_metadata(fid, metadata):
    """Save file metadata to disk."""
    metadata_path = get_file_metadata_path(fid)
    with open(metadata_path, 'w') as f:
        json.dump(metadata, f, indent=2)


def calculate_file_status(metadata):
    """Calculate the overall file status based on block status."""
    block_map = metadata.get('blockMap', {})
    block_count = metadata.get('blockCount', 0)
    
    if not block_map:
        return FILE_STATUS_NOT_STARTED
    
    uploaded_count = sum(
        1 for block in block_map.values() 
        if block.get('status') == BLOCK_STATUS_UPLOADED
    )
    
    if uploaded_count == block_count:
        return FILE_STATUS_COMPLETED
    elif uploaded_count > 0:
        return FILE_STATUS_INCOMPLETE
    else:
        return FILE_STATUS_NOT_STARTED


def merge_file_blocks(fid, metadata):
    """Merge all uploaded blocks into a single file."""
    upload_dir = get_file_upload_dir(fid)
    block_count = metadata.get('blockCount', 0)
    file_ext = metadata.get('fileExt', '')
    
    # Generate output filename
    output_filename = f"{fid}.{file_ext}" if file_ext else fid
    output_path = COMPLETED_PATH / output_filename
    
    # Merge blocks
    with open(output_path, 'wb') as outfile:
        for i in range(block_count):
            block_path = upload_dir / f'block_{i}'
            if block_path.exists():
                with open(block_path, 'rb') as block_file:
                    shutil.copyfileobj(block_file, outfile)
    
    # Verify file size
    expected_size = metadata.get('fileSize', 0)
    actual_size = output_path.stat().st_size
    
    if actual_size != expected_size:
        print(f"Warning: File size mismatch. Expected {expected_size}, got {actual_size}")
    
    # Update metadata with file URL
    metadata['furl'] = f'/storage/completed/{output_filename}'
    metadata['fstatus'] = FILE_STATUS_COMPLETED
    save_file_metadata(fid, metadata)
    
    return output_path, output_filename


def success_response(data=None, message='Success'):
    """Create a success response."""
    return jsonify({
        'rtnCode': '0000000',
        'ts': int(time.time() * 1000),
        'bizData': data,
        'message': message
    })


def error_response(code='9999999', message='Error', data=None):
    """Create an error response."""
    return jsonify({
        'rtnCode': code,
        'ts': int(time.time() * 1000),
        'bizData': data,
        'message': message
    }), 400


@app.route('/api/v1/large_file/upload_file', methods=['POST'])
def upload_file_info():
    """
    Initialize or get file upload information.
    
    Query Parameters:
        fid: File unique identifier (MD5 of deviceId + CRC)
        fcrc: File CRC32 checksum
        fileSize: File size in bytes
        createDate: File creation timestamp
        lastModifyDate: File last modification timestamp
        fileExt: File extension
        blockCount: Number of blocks
        blockSize: Size of each block
    
    Returns:
        File metadata including already uploaded blocks
    """
    # Get parameters from query string
    fid = request.args.get('fid')
    fcrc = request.args.get('fcrc')
    file_size = request.args.get('fileSize', type=int)
    create_date = request.args.get('createDate', type=int)
    last_modify_date = request.args.get('lastModifyDate', type=int)
    file_ext = request.args.get('fileExt', '')
    block_count = request.args.get('blockCount', type=int)
    block_size = request.args.get('blockSize', type=int)
    
    if not all([fid, fcrc, file_size, block_count, block_size]):
        return error_response(message='Missing required parameters')
    
    # Load existing metadata or create new
    metadata = load_file_metadata(fid)
    
    if metadata is None:
        # Create new metadata
        metadata = {
            'fid': fid,
            'fcrc': fcrc,
            'fileSize': file_size,
            'createDate': create_date,
            'lastModifyDate': last_modify_date,
            'fileExt': file_ext,
            'fileName': f'{fid}.{file_ext}' if file_ext else fid,
            'blockCount': block_count,
            'blockSize': block_size,
            'blockMap': {},
            'fstatus': FILE_STATUS_NOT_STARTED,
            'furl': None
        }
        
        # Create upload directory
        upload_dir = get_file_upload_dir(fid)
        upload_dir.mkdir(parents=True, exist_ok=True)
        
        save_file_metadata(fid, metadata)
    else:
        # Update file status
        metadata['fstatus'] = calculate_file_status(metadata)
        save_file_metadata(fid, metadata)
    
    return success_response(metadata)


@app.route('/api/v1/large_file/upload_block', methods=['POST'])
def upload_block():
    """
    Upload a file block.
    
    Query Parameters:
        fid: File unique identifier
        index: Block index (0-based)
        range: Data range (e.g., '0-4194304')
        crc: Block CRC32 checksum
    
    Body:
        Raw binary block data
    
    Returns:
        Updated file metadata
    """
    # Get parameters
    fid = request.args.get('fid')
    index = request.args.get('index', type=int)
    data_range = request.args.get('range', '')
    crc = request.args.get('crc')
    
    if not all([fid, index is not None, crc]):
        return error_response(message='Missing required parameters')
    
    # Load metadata
    metadata = load_file_metadata(fid)
    if metadata is None:
        return error_response(message='File not initialized. Call upload_file first.')
    
    # Parse range
    range_parts = data_range.split('-')
    start_byte = int(range_parts[0]) if len(range_parts) > 0 else 0
    block_size = int(range_parts[1]) if len(range_parts) > 1 else 0
    
    # Get block data from request body
    block_data = request.get_data()
    
    if not block_data:
        return error_response(message='No block data received')
    
    # Save block to disk
    upload_dir = get_file_upload_dir(fid)
    block_path = upload_dir / f'block_{index}'
    
    # Handle partial upload (resume)
    if start_byte > 0 and block_path.exists():
        # Append to existing block
        with open(block_path, 'ab') as f:
            f.write(block_data)
    else:
        # Write new block
        with open(block_path, 'wb') as f:
            f.write(block_data)
    
    # Verify block size
    actual_size = block_path.stat().st_size
    expected_size = metadata.get('blockSize', 0)
    
    # For last block, size might be different
    if index == metadata.get('blockCount', 0) - 1:
        expected_size = metadata.get('fileSize', 0) - (index * metadata.get('blockSize', 0))
    
    # Determine block status
    if actual_size >= expected_size:
        block_status = BLOCK_STATUS_UPLOADED
        block_range = f'{expected_size}-{expected_size}'
    else:
        block_status = BLOCK_STATUS_PARTIAL
        block_range = f'{actual_size}-{expected_size}'
    
    # Update block map
    metadata['blockMap'][str(index)] = {
        'index': index,
        'crc': crc,
        'status': block_status,
        'range': block_range
    }
    
    # Update file status
    metadata['fstatus'] = calculate_file_status(metadata)
    
    # If all blocks uploaded, merge file
    if metadata['fstatus'] == FILE_STATUS_COMPLETED:
        try:
            merge_file_blocks(fid, metadata)
        except Exception as e:
            print(f"Error merging file: {e}")
            metadata['fstatus'] = FILE_STATUS_ABNORMAL
    
    save_file_metadata(fid, metadata)
    
    return success_response(metadata)


@app.route('/api/v1/uploadFileForLargeFile', methods=['POST'])
def finalize_upload():
    """
    Finalize the upload and get the final file URL.
    
    Query Parameters:
        fid: File unique identifier
        dirId: Directory ID (optional)
        userId: User ID (optional)
        productCode: Product code (optional)
        bizSystem: Business system (optional)
        isRandomName: Whether to use random name (optional)
    
    Returns:
        Final file information including download URL
    """
    fid = request.args.get('fid')
    dir_id = request.args.get('dirId', '0')
    user_id = request.args.get('userId', '0')
    product_code = request.args.get('productCode', '')
    biz_system = request.args.get('bizSystem', '')
    is_random_name = request.args.get('isRandomName', 'false').lower() == 'true'
    
    if not fid:
        return error_response(message='Missing fid parameter')
    
    # Load metadata
    metadata = load_file_metadata(fid)
    if metadata is None:
        return error_response(message='File not found')
    
    # Check if file is completed
    if metadata['fstatus'] != FILE_STATUS_COMPLETED:
        return error_response(message='File upload not completed')
    
    # Generate file URL
    file_ext = metadata.get('fileExt', '')
    filename = f'{fid}.{file_ext}' if file_ext else fid
    file_path = COMPLETED_PATH / filename
    
    if not file_path.exists():
        # Try to merge blocks if file doesn't exist
        try:
            file_path, filename = merge_file_blocks(fid, metadata)
        except Exception as e:
            return error_response(message=f'Failed to merge file: {e}')
    
    # Build response
    file_url = f'/storage/completed/{filename}'
    
    response_data = {
        'result': 1,
        'des': 'Operation successful',
        'file': {
            'id': hash(fid) % 1000000,  # Generate a numeric ID
            'fileKey': filename,
            'fileName': filename,
            'fileUrl': file_url,
            'fileSize': metadata.get('fileSize', 0),
            'fileType': get_file_type(file_ext),
            'userId': user_id,
            'productCode': product_code,
            'bizSystem': biz_system,
            'status': 10,  # Uploaded status
            'isDir': 0,
            'pid': dir_id,
            'level': 1,
            'flag': 0,
            'creator': 0,
            'lastModifier': 0,
            'createDate': int(time.time() * 1000),
            'lastModDate': int(time.time() * 1000),
            'createDateAsDate': int(time.time() * 1000),
            'lastModDateAsDate': int(time.time() * 1000)
        }
    }
    
    return success_response(response_data)


def get_file_type(ext):
    """Determine file type from extension."""
    ext = ext.lower()
    if ext in ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg']:
        return 'image'
    elif ext in ['mp4', 'avi', 'mov', 'wmv', 'flv', 'mkv', 'webm']:
        return 'video'
    elif ext in ['mp3', 'wav', 'ogg', 'flac', 'aac', 'm4a']:
        return 'audio'
    elif ext in ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt']:
        return 'document'
    elif ext in ['zip', 'rar', '7z', 'tar', 'gz']:
        return 'archive'
    else:
        return 'other'


@app.route('/storage/completed/<path:filename>')
def download_file(filename):
    """Serve completed files for download."""
    return send_from_directory(COMPLETED_PATH, filename)


@app.route('/api/v1/files/<fid>', methods=['GET'])
def get_file_info(fid):
    """Get file information by file ID."""
    metadata = load_file_metadata(fid)
    if metadata is None:
        return error_response(message='File not found')
    return success_response(metadata)


@app.route('/api/v1/files/<fid>', methods=['DELETE'])
def delete_file(fid):
    """Delete a file by file ID."""
    metadata_path = get_file_metadata_path(fid)
    upload_dir = get_file_upload_dir(fid)
    
    metadata = load_file_metadata(fid)
    if metadata:
        # Delete completed file
        file_ext = metadata.get('fileExt', '')
        filename = f'{fid}.{file_ext}' if file_ext else fid
        completed_file = COMPLETED_PATH / filename
        if completed_file.exists():
            completed_file.unlink()
    
    # Delete metadata
    if metadata_path.exists():
        metadata_path.unlink()
    
    # Delete upload directory
    if upload_dir.exists():
        shutil.rmtree(upload_dir)
    
    return success_response({'deleted': True})


@app.route('/api/v1/files', methods=['GET'])
def list_files():
    """List all files."""
    files = []
    for metadata_file in METADATA_PATH.glob('*.json'):
        with open(metadata_file, 'r') as f:
            metadata = json.load(f)
            files.append({
                'fid': metadata.get('fid'),
                'fileName': metadata.get('fileName'),
                'fileSize': metadata.get('fileSize'),
                'fstatus': metadata.get('fstatus'),
                'furl': metadata.get('furl')
            })
    return success_response(files)


@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint."""
    return jsonify({
        'status': 'healthy',
        'timestamp': int(time.time() * 1000),
        'storage': {
            'uploads': str(UPLOADS_PATH),
            'completed': str(COMPLETED_PATH)
        }
    })


@app.route('/')
def index():
    """Root endpoint with API information."""
    return jsonify({
        'name': 'Resume Upload Server',
        'version': '1.0.0',
        'description': 'A server for resumable chunk-based file uploads',
        'endpoints': {
            'POST /api/v1/large_file/upload_file': 'Initialize or get file upload info',
            'POST /api/v1/large_file/upload_block': 'Upload a file block',
            'POST /api/v1/uploadFileForLargeFile': 'Finalize upload and get file URL',
            'GET /api/v1/files': 'List all files',
            'GET /api/v1/files/<fid>': 'Get file info by ID',
            'DELETE /api/v1/files/<fid>': 'Delete a file',
            'GET /storage/completed/<filename>': 'Download a completed file',
            'GET /health': 'Health check'
        }
    })


if __name__ == '__main__':
    print("=" * 60)
    print("Resume Upload Server")
    print("=" * 60)
    print(f"Storage path: {STORAGE_PATH}")
    print(f"Uploads path: {UPLOADS_PATH}")
    print(f"Completed path: {COMPLETED_PATH}")
    print("=" * 60)
    print("Starting server on http://0.0.0.0:8080")
    print("=" * 60)
    
    app.run(host='0.0.0.0', port=8080, debug=True)

