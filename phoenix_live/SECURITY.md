# 🔐 Security Documentation

This document outlines the security measures implemented in the Phoenix Live Application.

## Environment Variables Required

### Production Setup

```bash
# Generate a secure encryption key
openssl rand -base64 32

# Set environment variables
export ADMIN_PASSWORD="your_secure_admin_password"
export ENCRYPTION_KEY_BASE="your_generated_key_here"
export BACKBLAZE_KEY_ID="your_backblaze_key_id"
export BACKBLAZE_APP_KEY="your_backblaze_app_key"
export BACKBLAZE_BUCKET="your_bucket_name"
```

### Development Setup

For development, the application will use default values if environment variables are not set:

- `ADMIN_PASSWORD`: "testeadm2323@"
- `ENCRYPTION_KEY_BASE`: "phoenix_live_secure_key_2024"

**⚠️ WARNING:** Never use these default values in production!

## Security Features

### 1. Data Encryption

All application data is encrypted using AES-256-GCM before storage:

```elixir
# Encryption process
iv = :crypto.strong_rand_bytes(16)
{ciphertext, tag} = :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, data, <<>>, true)
encrypted_data = iv <> tag <> ciphertext
Base.encode64(encrypted_data)
```

**Files:** Stored as `.enc` files with Base64 encoded encrypted content.

### 2. Rate Limiting

- **Limit:** 5 form submissions per minute per IP
- **Storage:** ETS table (in-memory)
- **Reset:** Automatic cleanup every minute
- **Error:** Clear message when limit exceeded

### 3. Input Sanitization

- **HTML/XSS:** Script tag removal, dangerous attribute filtering
- **Length:** Maximum 10,000 characters per input
- **URLs:** HTTPS enforcement for GitHub/LinkedIn links
- **Trimming:** Automatic whitespace removal

### 4. Admin Access Security

- **Hidden UI:** Admin login not visible in public interface
- **Trigger:** Small gear icon (⚙️) requires 3 clicks to access
- **Session:** Secure session-based authentication
- **Timeout:** Sessions remain active until manual logout

### 5. CSRF Protection

- **Automatic:** Phoenix LiveView built-in CSRF protection
- **Tokens:** Cryptographically secure random tokens
- **Validation:** Automatic verification on all form submissions

## File Storage Security

### Local Storage
- **Encryption:** All data encrypted before file write
- **Permissions:** Application manages file access
- **Naming:** Timestamp + email hash for unique filenames
- **Extension:** `.enc` for encrypted files

### Cloud Storage (Blackblaze B2)
- **ACL:** `public_read` for resume downloads
- **Naming:** Timestamp + random suffix
- **Validation:** URL format verification
- **Security:** Public access through signed URLs (recommended)

## Production Deployment

### Fly.io Configuration

```bash
# Set secrets
fly secrets set ADMIN_PASSWORD="your_secure_password"
fly secrets set ENCRYPTION_KEY_BASE="$(openssl rand -base64 32)"
fly secrets set BACKBLAZE_KEY_ID="your_key_id"
fly secrets set BACKBLAZE_APP_KEY="your_app_key"
fly secrets set BACKBLAZE_BUCKET="your_bucket"

# Deploy
fly deploy
```

### Security Checklist

- [ ] Generate unique `ENCRYPTION_KEY_BASE` for production
- [ ] Set strong `ADMIN_PASSWORD`
- [ ] Configure Blackblaze B2 credentials
- [ ] Enable HTTPS in production
- [ ] Set up proper logging/monitoring
- [ ] Regular security updates of dependencies

## Data Recovery

### Decrypting Application Data

```elixir
# In IEx console
alias PhoenixLive.Security

# Read encrypted file
encrypted_data = File.read!("applications/timestamp_email.enc")

# Decrypt (requires ENCRYPTION_KEY_BASE env var)
{:ok, json_data} = Security.decrypt_data(encrypted_data)

# Parse JSON
{:ok, application} = Jason.decode(json_data)
```

## Monitoring

### Rate Limiting Stats

```elixir
# Check rate limiting table
:ets.tab2list(:rate_limit_data)
```

### Security Logs

Monitor application logs for:
- Rate limiting violations
- Authentication failures
- Encryption/decryption errors
- File upload issues

## Emergency Procedures

### Change Admin Password

```bash
# Update environment variable
export ADMIN_PASSWORD="new_secure_password"
# Restart application
```

### Regenerate Encryption Key

⚠️ **WARNING:** This will make all existing encrypted data inaccessible!

```bash
# Generate new key
export ENCRYPTION_KEY_BASE="$(openssl rand -base64 32)"
# Restart application
# Migrate existing data if needed
```

## Compliance

- **GDPR:** Data encryption and minimization
- **Data Retention:** Files stored locally (consider backup policies)
- **Access Control:** Admin-only data access
- **Input Validation:** XSS and injection protection
