# IAM Service - Authentik Identity Provider

A centralized Identity and Access Management (IAM) service powered by [Authentik](https://goauthentik.io/), providing authentication and authorization for multiple applications.

## Features

- **OAuth 2.0 / OpenID Connect** - Industry-standard authentication protocols
- **Single Sign-On (SSO)** - One login for all applications
- **Multi-factor Authentication** - TOTP, WebAuthn, SMS
- **Role-Based Access Control** - Flexible group and role management
- **User Management** - Self-service and admin-managed users
- **Audit Logging** - Comprehensive security audit trail

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    IAM Service (Authentik)                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Server     │  │   Worker     │  │   Outposts   │          │
│  │  (Main API)  │  │ (Background) │  │  (Optional)  │          │
│  └──────┬───────┘  └──────┬───────┘  └──────────────┘          │
│         │                 │                                      │
│         └────────┬────────┘                                      │
│                  │                                               │
│         ┌───────┴───────┐                                       │
│         │               │                                        │
│    ┌────┴────┐    ┌────┴────┐                                   │
│    │ Redis   │    │ Postgres│                                   │
│    │ (Cache) │    │  (Data) │                                   │
│    └─────────┘    └─────────┘                                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Deployment Options

### Option 1: Railway (Recommended for Demo/Small Scale)

Railway provides a simple PaaS deployment with managed PostgreSQL and Redis.

#### Prerequisites
- Railway account (https://railway.app)
- GitHub account (for repository connection)

#### Deployment Steps

1. **Create a new Railway project**
   ```bash
   # Install Railway CLI
   npm install -g @railway/cli

   # Login to Railway
   railway login

   # Initialize project
   railway init
   ```

2. **Add required services**
   - Add PostgreSQL service from Railway's template
   - Add Redis service from Railway's template

3. **Configure environment variables**
   ```bash
   # Generate secret key
   railway variables set AUTHENTIK_SECRET_KEY=$(openssl rand -base64 36)

   # PostgreSQL variables are auto-linked
   # Redis host needs to be set manually
   railway variables set REDIS_HOST=<redis-service-name>
   ```

4. **Deploy**
   ```bash
   railway up
   ```

5. **Access initial setup**
   - Navigate to `https://<your-railway-url>/if/flow/initial-setup/`
   - Create admin account

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

   # Generate secret key
   echo "AUTHENTIK_SECRET_KEY=$(openssl rand -base64 36)" >> .env
   echo "PG_PASS=$(openssl rand -base64 24)" >> .env

   # Edit other settings
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
           proxy_pass http://localhost:9000;
           proxy_http_version 1.1;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection "upgrade";
       }
   }
   ```

5. **Access initial setup**
   - Navigate to `https://auth.yourdomain.com/if/flow/initial-setup/`

## Configuration

### Creating OAuth2/OIDC Provider

1. **Go to Admin → Applications → Providers**
2. **Create new OAuth2/OpenID Provider**
   - Name: `attendance-app-provider`
   - Authorization flow: `default-authorization-flow`
   - Client type: `Confidential`
   - Redirect URIs:
     ```
     https://your-app.railway.app/api/auth/callback
     http://localhost:5173/auth/callback
     attendance://callback
     ```

3. **Create Application**
   - Name: `Attendance System`
   - Slug: `attendance-system`
   - Provider: `attendance-app-provider`

### Creating Groups

Create these groups in Admin → Directory → Groups:

| Group Name | Attributes | Description |
|------------|------------|-------------|
| `iam-administrators` | `{"iam_level": "administrator"}` | Full system access |
| `iam-users` | `{"iam_level": "user"}` | Standard user access |
| `attendance-admins` | `{"app": "attendance", "app_role": "admin"}` | Attendance admin access |
| `attendance-staff` | `{"app": "attendance", "app_role": "staff"}` | Staff mobile access |
| `attendance-location` | `{"app": "attendance", "app_role": "location"}` | Kiosk access |

### Property Mappings

Create custom property mappings in Admin → Customization → Property Mappings:

**attendance_roles:**
```python
groups = [g.name for g in request.user.ak_groups.all()]
roles = []
if 'iam-administrators' in groups or 'attendance-admins' in groups:
    roles.append('admin')
if 'attendance-location' in groups:
    roles.append('location')
if 'attendance-staff' in groups:
    roles.append('staff')
return roles if roles else ['staff']
```

**iam_level:**
```python
groups = [g.name for g in request.user.ak_groups.all()]
if 'iam-administrators' in groups:
    return 'administrator'
return 'user'
```

## API Endpoints

Once deployed, the following endpoints are available:

| Endpoint | Description |
|----------|-------------|
| `/application/o/authorize/` | OAuth2 Authorization |
| `/application/o/token/` | OAuth2 Token Exchange |
| `/application/o/userinfo/` | OpenID Connect UserInfo |
| `/application/o/<slug>/jwks/` | JWKS Public Keys |
| `/application/o/<slug>/end-session/` | Logout |
| `/api/v3/` | Authentik REST API |
| `/if/admin/` | Admin Interface |

## Monitoring

### Health Checks
- Liveness: `/-/health/live/`
- Readiness: `/-/health/ready/`

### Metrics
Prometheus metrics available at `/-/metrics/` (requires authentication)

## Backup & Recovery

### PostgreSQL Backup
```bash
# Backup
docker exec authentik-postgres pg_dump -U authentik authentik > backup.sql

# Restore
docker exec -i authentik-postgres psql -U authentik authentik < backup.sql
```

### Media Files
```bash
# Backup media directory
docker cp authentik-server:/media ./media-backup
```

## Troubleshooting

### View Logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f server
```

### Common Issues

1. **Database connection failed**
   - Check PostgreSQL is healthy: `docker compose ps`
   - Verify credentials in `.env`

2. **Redis connection failed**
   - Check Redis is healthy: `docker compose ps`
   - Verify REDIS_HOST is correct

3. **HTTPS/SSL issues**
   - Ensure reverse proxy is configured correctly
   - Check certificate validity

## Security Considerations

- Always use HTTPS in production
- Rotate `AUTHENTIK_SECRET_KEY` periodically
- Enable MFA for admin accounts
- Review audit logs regularly
- Keep Authentik updated

## License

This project uses Authentik which is licensed under the [MIT License](https://github.com/goauthentik/authentik/blob/main/LICENSE).

## Support

- [Authentik Documentation](https://goauthentik.io/docs/)
- [Authentik GitHub](https://github.com/goauthentik/authentik)
- [Authentik Discord](https://goauthentik.io/discord)
