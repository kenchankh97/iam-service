# IAM Service - Keycloak Identity Provider

A centralized Identity and Access Management (IAM) service powered by [Keycloak](https://www.keycloak.org/), providing authentication and authorization for multiple applications.

## Features

- **OAuth 2.0 / OpenID Connect** - Industry-standard authentication protocols
- **Single Sign-On (SSO)** - One login for all applications
- **Multi-factor Authentication** - TOTP, WebAuthn
- **Role-Based Access Control** - Flexible realm roles and client roles
- **User Management** - Self-service and admin-managed users
- **Audit Logging** - Comprehensive security audit trail
- **Unlimited Users** - No user limit (fully open source)

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    IAM Service (Keycloak)                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────────────────────────────────────────┐       │
│  │              Keycloak Server (Quarkus)               │       │
│  │  - Admin Console                                     │       │
│  │  - OAuth2/OIDC Provider                              │       │
│  │  - User Federation                                   │       │
│  │  - Identity Brokering                                │       │
│  └──────────────────┬───────────────────────────────────┘       │
│                     │                                            │
│            ┌────────┴────────┐                                  │
│            │    PostgreSQL   │                                  │
│            │    (Database)   │                                  │
│            └─────────────────┘                                  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Deployment Options

### Option 1: Railway (Recommended for Demo/Small Scale)

Railway provides a simple PaaS deployment with managed PostgreSQL.

#### Prerequisites
- Railway account (https://railway.app)
- GitHub account (for repository connection)

#### Deployment Steps

1. **Create a new Railway project**
   - Go to https://railway.app/new
   - Select "Deploy from GitHub repo"
   - Connect this repository

2. **Add PostgreSQL service**
   - Click "New" → "Database" → "PostgreSQL"
   - Railway will auto-provision the database

3. **Configure environment variables in Railway**

   Click on your Keycloak service and add these variables:

   ```
   KC_DB=postgres
   KC_DB_URL=jdbc:postgresql://${{Postgres.PGHOST}}:${{Postgres.PGPORT}}/${{Postgres.PGDATABASE}}
   KC_DB_USERNAME=${{Postgres.PGUSER}}
   KC_DB_PASSWORD=${{Postgres.PGPASSWORD}}
   KC_HOSTNAME=${{RAILWAY_PUBLIC_DOMAIN}}
   KC_BOOTSTRAP_ADMIN_USERNAME=admin
   KC_BOOTSTRAP_ADMIN_PASSWORD=YourSecurePassword123!
   ```

4. **Deploy**
   - Railway will automatically build and deploy
   - Wait for the deployment to complete (may take 3-5 minutes)

5. **Access Keycloak Admin Console**
   - Navigate to `https://<your-railway-url>/admin`
   - Login with admin credentials you set above

### Option 2: Docker Compose (Self-Hosted)

For production or self-hosted environments with more control.

#### Prerequisites
- Linux server (Ubuntu 22.04+ recommended)
- Docker & Docker Compose installed
- Domain name with SSL certificate

#### Deployment Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-org/iam-service.git
   cd iam-service
   ```

2. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your settings
   nano .env
   ```

3. **Start services**
   ```bash
   docker compose up -d
   ```

4. **Configure reverse proxy (Nginx example)**
   ```nginx
   server {
       listen 443 ssl http2;
       server_name auth.yourdomain.com;

       ssl_certificate /path/to/cert.pem;
       ssl_certificate_key /path/to/key.pem;

       location / {
           proxy_pass http://localhost:8080;
           proxy_http_version 1.1;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
           proxy_set_header X-Forwarded-Host $host;
       }
   }
   ```

5. **Access Admin Console**
   - Navigate to `https://auth.yourdomain.com/admin`

## Configuration

### Creating a Realm for Attendance System

1. **Login to Admin Console** at `/admin`

2. **Create a new Realm**
   - Click the realm dropdown (top-left, shows "master")
   - Click "Create realm"
   - Name: `attendance`
   - Click "Create"

3. **Create Client (OAuth2 Application)**
   - Go to Clients → Create client
   - Client ID: `attendance-app`
   - Client Protocol: `openid-connect`
   - Click "Next"
   - Client authentication: `On`
   - Click "Next"
   - Valid redirect URIs:
     ```
     https://your-app.railway.app/api/auth/callback
     http://localhost:5173/auth/callback
     http://localhost:3000/api/auth/callback
     attendance://callback
     ```
   - Web origins: `+` (allows all origins from redirect URIs)
   - Click "Save"

4. **Get Client Secret**
   - Go to Clients → attendance-app → Credentials
   - Copy the Client Secret (you'll need this for your backend)

### Creating Realm Roles

Go to Realm roles → Create role:

| Role Name | Description |
|-----------|-------------|
| `admin` | Full admin access to attendance system |
| `staff` | Staff user - can clock in/out via mobile |
| `location` | Location kiosk - can display QR codes |

### Creating Users

1. Go to Users → Add user
2. Fill in details:
   - Username (email recommended)
   - Email
   - First/Last Name
3. Click "Create"
4. Go to Credentials tab → Set password
5. Go to Role mapping → Assign roles

### Custom User Attributes

Add custom attributes for attendance system:

1. Go to Realm settings → User profile
2. Add attributes:
   - `staffNumber` - Staff ID number
   - `itCode` - IT department code
   - `teamId` - Team identifier
   - `locationId` - Assigned location (for location users)

### Adding Attributes to Token

1. Go to Client scopes → Create client scope
   - Name: `attendance-profile`
   - Type: `Default`

2. Add mappers:
   - Click "Add mapper" → "By configuration" → "User Attribute"
   - Name: `staffNumber`
   - User Attribute: `staffNumber`
   - Token Claim Name: `staff_number`
   - Claim JSON Type: `String`
   - Add to ID token: `On`
   - Add to access token: `On`

   Repeat for other attributes.

3. Go to Clients → attendance-app → Client scopes
   - Add `attendance-profile` to default scopes

## API Endpoints

Once deployed, the following endpoints are available:

| Endpoint | Description |
|----------|-------------|
| `/realms/{realm}/protocol/openid-connect/auth` | OAuth2 Authorization |
| `/realms/{realm}/protocol/openid-connect/token` | OAuth2 Token Exchange |
| `/realms/{realm}/protocol/openid-connect/userinfo` | OpenID Connect UserInfo |
| `/realms/{realm}/protocol/openid-connect/certs` | JWKS Public Keys |
| `/realms/{realm}/protocol/openid-connect/logout` | Logout |
| `/admin` | Admin Console |

Replace `{realm}` with your realm name (e.g., `attendance`).

## Monitoring

### Health Checks
- Health: `/health`
- Ready: `/health/ready`
- Live: `/health/live`

### Metrics
Prometheus metrics available at `/metrics` (if enabled)

## Backup & Recovery

### PostgreSQL Backup
```bash
# Backup
docker exec keycloak-postgres pg_dump -U keycloak keycloak > backup.sql

# Restore
docker exec -i keycloak-postgres psql -U keycloak keycloak < backup.sql
```

### Export Realm Configuration
```bash
# Export realm (from admin console or CLI)
/opt/keycloak/bin/kc.sh export --dir /tmp/export --realm attendance
```

## Troubleshooting

### View Logs
```bash
# Docker logs
docker logs keycloak-server -f

# Railway logs
railway logs
```

### Common Issues

1. **Database connection failed**
   - Check PostgreSQL is healthy
   - Verify KC_DB_URL format is correct
   - Ensure credentials are correct

2. **Admin console not loading**
   - Check KC_HOSTNAME matches your domain
   - Verify KC_HTTP_ENABLED=true if behind proxy
   - Check KC_PROXY_HEADERS=xforwarded

3. **Login redirect issues**
   - Verify redirect URIs in client settings
   - Check Web Origins setting

## Security Considerations

- Always use HTTPS in production
- Use strong admin passwords
- Enable MFA for admin accounts
- Review audit logs regularly in Events → Admin events
- Keep Keycloak updated

## Comparison with Other Solutions

| Feature | Keycloak | Authentik | Clerk |
|---------|----------|-----------|-------|
| User Limit | Unlimited | Unlimited | 5 (free) |
| Self-hosted | Yes | Yes | No |
| License | Apache 2.0 | MIT | Proprietary |
| Maturity | Very High | Medium | Medium |
| Resource Usage | Medium-High | Medium | N/A |
| Enterprise Support | Red Hat | Community | Yes |

## License

Keycloak is licensed under the [Apache License 2.0](https://github.com/keycloak/keycloak/blob/main/LICENSE.txt).

## Support

- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [Keycloak GitHub](https://github.com/keycloak/keycloak)
- [Keycloak Community](https://www.keycloak.org/community)
