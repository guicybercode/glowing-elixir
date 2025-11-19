# Phoenix Live Resume Upload

A Phoenix LiveView application for resume uploads with retro Windows 96/Linux UI and secure Backblaze B2 storage.

## Tech Stack

- Phoenix 1.8+ with LiveView
- Backblaze B2 for file storage
- Fly.io for deployment
- Retro Windows 96/Linux styling

## Features

- Resume upload form (PDF/DOCX up to 10MB)
- Retro aesthetic interface
- Secure cloud storage
- Local JSON data persistence
- Responsive design

## Quick Start

### Prerequisites
- Elixir 1.17+
- Node.js 18+

### Local Development

```bash
# Install dependencies
mix setup

# Start server
mix phx.server
```

Visit [http://localhost:4000](http://localhost:4000)

### Deploy to Fly.io

```bash
# Configure secrets
fly secrets set SECRET_KEY_BASE="$(mix phx.gen.secret)"
fly secrets set BACKBLAZE_KEY_ID="your-key-id"
fly secrets set BACKBLAZE_APP_KEY="your-app-key"
fly secrets set BACKBLAZE_BUCKET="your-bucket-name"

# Deploy
fly launch
fly deploy
```
