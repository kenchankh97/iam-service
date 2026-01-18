#!/usr/bin/env python3
"""
User Migration Script: Attendance System → Authentik IAM

This script migrates users from the Attendance System MySQL database
to Authentik IAM service via the Authentik API.

Usage:
    python migrate_users.py

Environment Variables Required:
    MYSQL_HOST - MySQL host
    MYSQL_USER - MySQL username
    MYSQL_PASSWORD - MySQL password
    MYSQL_DATABASE - MySQL database name
    AUTHENTIK_URL - Authentik server URL (e.g., https://auth.yourdomain.com)
    AUTHENTIK_API_TOKEN - Authentik API token (created in Admin UI)

Prerequisites:
    pip install mysql-connector-python requests python-dotenv
"""

import os
import sys
import json
import requests
import mysql.connector
from datetime import datetime
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configuration
MYSQL_CONFIG = {
    'host': os.getenv('MYSQL_HOST', 'localhost'),
    'user': os.getenv('MYSQL_USER', 'root'),
    'password': os.getenv('MYSQL_PASSWORD', ''),
    'database': os.getenv('MYSQL_DATABASE', 'attendance_db'),
}

AUTHENTIK_URL = os.getenv('AUTHENTIK_URL', 'https://auth.yourdomain.com')
AUTHENTIK_TOKEN = os.getenv('AUTHENTIK_API_TOKEN', '')

# API headers
headers = {
    'Authorization': f'Bearer {AUTHENTIK_TOKEN}',
    'Content-Type': 'application/json',
}

# Group name to PK mapping (will be populated)
group_cache = {}


def log(message, level='INFO'):
    """Print log message with timestamp."""
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    print(f'[{timestamp}] [{level}] {message}')


def get_or_create_group(name, attributes=None):
    """Get existing group or create new one in Authentik."""
    if name in group_cache:
        return group_cache[name]

    # Search for existing group
    response = requests.get(
        f'{AUTHENTIK_URL}/api/v3/core/groups/',
        headers=headers,
        params={'name': name}
    )
    response.raise_for_status()
    groups = response.json().get('results', [])

    if groups:
        group_pk = groups[0]['pk']
        group_cache[name] = group_pk
        log(f'Found existing group: {name} (pk={group_pk})')
        return group_pk

    # Create new group
    group_data = {
        'name': name,
        'attributes': attributes or {}
    }
    response = requests.post(
        f'{AUTHENTIK_URL}/api/v3/core/groups/',
        headers=headers,
        json=group_data
    )
    response.raise_for_status()
    group_pk = response.json()['pk']
    group_cache[name] = group_pk
    log(f'Created group: {name} (pk={group_pk})')
    return group_pk


def create_required_groups():
    """Create all required groups for the Attendance system."""
    groups_config = [
        ('iam-administrators', {'iam_level': 'administrator'}),
        ('iam-users', {'iam_level': 'user'}),
        ('attendance-admins', {'app': 'attendance', 'app_role': 'admin'}),
        ('attendance-staff', {'app': 'attendance', 'app_role': 'staff'}),
        ('attendance-location', {'app': 'attendance', 'app_role': 'location'}),
    ]

    log('Creating required groups...')
    for name, attributes in groups_config:
        get_or_create_group(name, attributes)
    log('All groups ready')


def get_user_groups(user_type):
    """Determine which groups a user should belong to based on their type."""
    groups = [group_cache['iam-users']]

    if user_type == 'admin':
        groups.append(group_cache['attendance-admins'])
    elif user_type == 'staff':
        groups.append(group_cache['attendance-staff'])
    elif user_type == 'location':
        groups.append(group_cache['attendance-location'])

    return groups


def migrate_user(user):
    """Migrate a single user to Authentik."""
    email = user['email']

    # Check if user already exists
    response = requests.get(
        f'{AUTHENTIK_URL}/api/v3/core/users/',
        headers=headers,
        params={'username': email}
    )
    response.raise_for_status()
    existing_users = response.json().get('results', [])

    if existing_users:
        log(f'User already exists: {email}', 'SKIP')
        return False, 'already_exists'

    # Build user attributes
    attributes = {
        'staff_number': user['staff_number'] or '',
        'it_code': user['it_code'] or '',
        'attendance_user_id': str(user['id']),  # Keep reference to old ID
    }

    if user['team_id']:
        attributes['team_id'] = str(user['team_id'])

    if user['user_type'] == 'location' and user['location_id']:
        attributes['attendance'] = {
            'location_id': str(user['location_id'])
        }

    # Get groups for this user
    groups = get_user_groups(user['user_type'])

    # Create user data
    user_data = {
        'username': email,
        'email': email,
        'name': user['staff_name'] or email.split('@')[0],
        'is_active': bool(user['is_active']),
        'groups': groups,
        'attributes': attributes,
    }

    # Create user
    response = requests.post(
        f'{AUTHENTIK_URL}/api/v3/core/users/',
        headers=headers,
        json=user_data
    )

    if response.status_code == 201:
        authentik_user = response.json()
        user_pk = authentik_user['pk']

        # Set temporary password (users must reset on first login)
        password_response = requests.post(
            f'{AUTHENTIK_URL}/api/v3/core/users/{user_pk}/set_password/',
            headers=headers,
            json={'password': 'ChangeMe123!'}
        )

        if password_response.status_code in [200, 204]:
            log(f'Migrated: {email} (pk={user_pk})')
            return True, 'success'
        else:
            log(f'Password set failed for {email}: {password_response.text}', 'WARN')
            return True, 'password_failed'
    else:
        log(f'Failed to create {email}: {response.text}', 'ERROR')
        return False, response.text


def migrate_users():
    """Main migration function."""
    log('=' * 60)
    log('Starting User Migration: Attendance → Authentik')
    log('=' * 60)

    # Validate configuration
    if not AUTHENTIK_TOKEN:
        log('AUTHENTIK_API_TOKEN is required', 'ERROR')
        sys.exit(1)

    # Test Authentik connection
    log('Testing Authentik connection...')
    try:
        response = requests.get(
            f'{AUTHENTIK_URL}/api/v3/core/users/',
            headers=headers,
            params={'page_size': 1}
        )
        response.raise_for_status()
        log('Authentik connection successful')
    except Exception as e:
        log(f'Authentik connection failed: {e}', 'ERROR')
        sys.exit(1)

    # Create required groups
    create_required_groups()

    # Connect to MySQL
    log('Connecting to MySQL...')
    try:
        db = mysql.connector.connect(**MYSQL_CONFIG)
        cursor = db.cursor(dictionary=True)
        log('MySQL connection successful')
    except Exception as e:
        log(f'MySQL connection failed: {e}', 'ERROR')
        sys.exit(1)

    # Fetch users from Attendance database
    log('Fetching users from Attendance database...')
    cursor.execute('''
        SELECT id, email, staffName as staff_name, staffNumber as staff_number,
               itCode as it_code, userType as user_type, isActive as is_active,
               teamId as team_id, locationId as location_id, createdAt as created_at
        FROM User
        ORDER BY id
    ''')
    users = cursor.fetchall()
    log(f'Found {len(users)} users to migrate')

    # Migrate users
    stats = {
        'total': len(users),
        'success': 0,
        'skipped': 0,
        'failed': 0,
    }

    for i, user in enumerate(users, 1):
        log(f'[{i}/{len(users)}] Processing: {user["email"]}')
        success, result = migrate_user(user)

        if success:
            stats['success'] += 1
        elif result == 'already_exists':
            stats['skipped'] += 1
        else:
            stats['failed'] += 1

    # Close connections
    cursor.close()
    db.close()

    # Print summary
    log('=' * 60)
    log('Migration Complete')
    log('=' * 60)
    log(f'Total Users:  {stats["total"]}')
    log(f'Migrated:     {stats["success"]}')
    log(f'Skipped:      {stats["skipped"]}')
    log(f'Failed:       {stats["failed"]}')
    log('=' * 60)

    if stats['success'] > 0:
        log('NOTE: All migrated users have password "ChangeMe123!"')
        log('Users should reset their password on first login.')


if __name__ == '__main__':
    migrate_users()
