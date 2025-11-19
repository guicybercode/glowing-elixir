# Phoenix Live Resume Upload

Phoenix LiveView application for resume uploads with retro Windows 96/Linux UI and secure Backblaze B2 storage.

## Tech Stack

- **Framework**: Phoenix 1.8+ with LiveView
- **Storage**: Backblaze B2 (PDF/DOCX files)
- **Deployment**: Fly.io

## Features

- Complete form with robust validations
- Resume upload (PDF/DOCX up to 10MB)
- Retro Windows 96/Linux aesthetic
- Secure cloud storage (Backblaze B2)
- Local data persistence (encrypted JSON)
- Responsive interface for mobile/desktop
- Comprehensive error handling
- Detailed validation messages
- Loading states with progress bars
- Visual feedback during processing
- AES-256-GCM data encryption
- Rate limiting (5 requests/min per IP)
- XSS input sanitization
- CSRF protection
- Server-side file size validation
- **Admin Dashboard** with authentication
- **Application Management** (view, filter, sort)
- **Resume Download** functionality
- **Hidden Admin Access** (`/admin/login`)

## Form Fields

**Required:**
- Name, Email, Phone, ZIP Code
- Skills, Cover Letter, Education
- Resume Attachment (PDF/DOCX)

**Optional:**
- GitHub, LinkedIn

## Data Storage

### JSON Files (Form Data)
**Location:** `applications/[timestamp]_[email].enc`
**Content:** All form data + metadata
**Format:** AES-256-GCM encrypted JSON

### Cloud Files (Resumes)
**Service:** Backblaze B2
**Location:** https://f002.backblazeb2.com/file/[bucket]/[file]
**Access:** Public via URL

## Security Features

### Data Encryption
- **Algorithm:** AES-256-GCM (Authenticated Encryption)
- **Storage:** Encrypted at rest
- **Key Management:** Environment-based secure keys
- **Tamper Protection:** Cryptographic integrity checks

### Rate Limiting
- **Limit:** 5 submissions per minute per IP
- **Storage:** In-memory ETS (production: Redis)
- **Protection:** Prevents spam and abuse
- **Feedback:** Clear wait time messages

### Input Sanitization
- **XSS Protection:** HTML tag removal and sanitization
- **Script Injection:** JavaScript removal
- **Event Handlers:** Dangerous attribute removal
- **Length Limits:** DoS prevention (10KB max per field)

### File Security
- **Server Validation:** Size validation on server side
- **Type Verification:** MIME type and extension checks
- **Path Security:** Safe filename generation
- **Size Limits:** 10MB maximum enforced server-side

### CSRF Protection
- **Tokens:** Cryptographically secure random tokens
- **Validation:** Base64 URL-safe format verification
- **Session-based:** Per-request token generation

### Admin Panel
- **Authentication:** Password-based (environment variable)
- **Access:** Hidden route (`/admin/login`) - not linked in public UI
- **Admin Button:** Small blue button with gear icon (⚙️) in bottom-right corner (3 clicks to access)
- **Dashboard:** Complete application management interface
- **Features:**
  - List all applications with pagination-ready structure
  - Search by email (real-time filtering)
  - Sort by name, email, or submission date
  - View detailed application information
  - Direct resume download links
  - Session-based logout
- **Security:** Protected routes with session validation

## Error Handling

### Form Validations
- **Required fields:** Name, email, phone, ZIP code, education, skills, cover letter
- **Email format:** Basic validation for "@" presence
- **Phone:** Brazilian format (11) 99999-9999
- **ZIP code:** Brazilian format 12345-678
- **URLs:** HTTPS validation for GitHub/LinkedIn
- **Minimum length:** Cover letter (50 chars), skills (10 chars)

### Backend Validations
- **Required fields:** Strict validation against nulls and empty strings
- **Email:** Full regex, min/max length, valid format
- **Phone:** Digit count (10-11), strict Brazilian format
- **ZIP code:** Exactly 8 digits, format XXXXX-XXX
- **Text:** Character limits per field
- **URLs:** HTTPS validation, length, format
- **Resume:** Backblaze B2 URL validation, safe filename
- **Date:** Valid ISO8601 format
- **Sanitization:** Trim, lowercase for emails, data cleaning

### Upload Handling
- **File size:** Maximum 10MB
- **Accepted types:** PDF and DOCX only
- **Network errors:** Timeout, connection, DNS
- **Server errors:** Credentials, quota, permissions
- **Helper function:** `error_to_string/1` integrated in template

### Error Messages
- **Specific:** Each error has its own message
- **User-friendly:** Clear and actionable language
- **Formatted:** Emojis and visual formatting
- **Guiding:** Suggest solutions for users
- **Template integration:** Function assigned to socket for use in HEEx

### Loading States
- **Initial Load:** Spinner and progress bar when entering application
- **Form Processing:** Overlay with progress bar during submission
- **Progress Tracking:** Real-time updates (10% → 25% → 50% → 75% → 100%)
- **User Feedback:** Contextual messages for each processing stage
- **Visual Design:** Windows 96 style spinners and progress bars

## Setup

### Prerequisites

- Elixir 1.17+
- Erlang 27+
- Node.js 18+
- Fly.io account
- Backblaze B2 account

### Backblaze B2 Configuration

1. Access [Backblaze B2](https://www.backblaze.com/b2/)
2. Create a new bucket (make it public)
3. Go to "App Keys" and create a new key
4. Note:
   - `keyID` (BACKBLAZE_KEY_ID)
   - `applicationKey` (BACKBLAZE_APP_KEY)
   - Bucket name (BACKBLAZE_BUCKET)

### Fly.io Configuration

1. Install Fly CLI:
   ```bash
   curl -L https://fly.io/install.sh | sh
   ```

2. Login:
   ```bash
   fly auth login
   ```

### Deployment

1. Clone and configure the project:
   ```bash
   git clone <your-repo>
   cd phoenix-live
   mix deps.get
   mix compile
   ```

2. Configure secrets on Fly.io:
   ```bash
   fly secrets set SECRET_KEY_BASE="$(mix phx.gen.secret)"
   fly secrets set BACKBLAZE_KEY_ID="your-key-id"
   fly secrets set BACKBLAZE_APP_KEY="your-app-key"
   fly secrets set BACKBLAZE_BUCKET="your-bucket-name"
   ```

3. Deploy:
   ```bash
   fly launch
   fly deploy
   ```

## Local Development

1. Install dependencies:
   ```bash
   mix setup
   ```

2. Configure environment variables:
   ```bash
   export BACKBLAZE_KEY_ID="your-key-id"
   export BACKBLAZE_APP_KEY="your-app-key"
   export BACKBLAZE_BUCKET="your-bucket"
   export ADMIN_PASSWORD="testeadm2323@"
   ```

3. Start the server:
   ```bash
   mix phx.server
   ```

4. Access [http://localhost:4000](http://localhost:4000)

### Admin Panel Access

#### **Option 1 - Direct Route:**
1. Navigate to: `http://localhost:4000/admin/login`
2. Enter the `ADMIN_PASSWORD`
3. Access granted to dashboard

#### **Option 2 - Admin Button (Main Page):**
1. On the main page, look for the small blue button (⚙️) in the bottom-right corner
2. Click it 3 times quickly
3. Automatically redirected to `/admin/login`
4. Enter the `ADMIN_PASSWORD`
5. Access granted to dashboard

**Features:**
- View all applications with encrypted data
- Search by email (real-time filtering)
- Sort by name, email, or submission date
- View detailed application information
- Download resumes directly from Backblaze B2
- Secure session-based logout

## Project Structure

```
lib/phoenix_live/
├── application.ex        # OTP Application
├── storage/b2.ex         # Backblaze B2 integration
└── .ex                   # Main module

lib/phoenix_live_web/
├── live/                 # LiveViews (form + upload)
├── components/           # UI components (layouts + core)
├── controllers/          # Controllers (pages + errors)
├── endpoint.ex           # Web server
├── router.ex             # Application routes
├── telemetry.ex          # Telemetry
└── gettext.ex            # Internationalization

assets/css/
└── app.css              # Windows 96 style
```

## Job Information

**Position:** Fullstack Developer
**Location:** São Paulo - SP, Pinheiros
**Schedule:** Monday to Friday (on-site)

### About the Position

We are looking for a Fullstack Developer to join our development team. The position involves working on both frontend and backend, integrating both parts and developing complete web applications from start to finish.

We value professionals who have good social interaction, collaborative spirit, and ability to work in a dynamic team.

### Required Qualifications
- **Location:** Must reside in São Paulo or be able to commute to Pinheiros (Mandatory)
- **Fullstack:** Experience in both Frontend and Backend development
- **APIs:** Knowledge in RESTful and GraphQL API integration
- **Languages:** Proficiency in fundamental programming languages
- **End-to-End:** Ability to create complete applications
- **Soft Skills:** Good social interaction and communication
- **Version Control:** Git knowledge

### Differentiators
- **Stack:** Experience with Flutter and mobile development
- **Backend:** Knowledge in Serverpod (Dart on Backend)
- **OS:** Linux and command line proficiency
- **Infrastructure:** Docker and Kubernetes
- **Design:** UI/UX aesthetic sense and Tailwind CSS
- **Certifications:** Relevant technical certifications
- **Data:** Data manipulation skills
- **Mindset:** Ownership, proactivity, and creativity

## Support

For questions or issues, consult the Phoenix documentation or open an issue in the repository.

---

**성경 구절 (聖經 句節)**

> 너희는 먼저 그의 나라와 그의 의를 구하라 그리하면 이 모든 것을 너희에게 더하시리라

> 

> *마태복음 6:33*

> 

> *But seek first his kingdom and his righteousness, and all these things will be given to you as well.*

> 

> *Matthew 6:33*
