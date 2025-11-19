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
- Local data persistence (JSON)
- Responsive interface for mobile/desktop
- Comprehensive error handling
- Detailed validation messages

## Form Fields

**Required:**
- Name, Email, Phone, ZIP Code
- Skills, Cover Letter, Education
- Resume Attachment (PDF/DOCX)

**Optional:**
- GitHub, LinkedIn

## Data Storage

### JSON Files (Form Data)
**Location:** `applications/[timestamp]_[email].json`
**Content:** All form data + metadata
**Format:** Structured and readable JSON

### Cloud Files (Resumes)
**Service:** Backblaze B2
**Location:** https://f002.backblazeb2.com/file/[bucket]/[file]
**Access:** Public via URL

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
   ```

3. Start the server:
   ```bash
   mix phx.server
   ```

4. Access [http://localhost:4000](http://localhost:4000)

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

We are looking for an experienced Fullstack Developer to join our development team. The position involves working on both frontend and backend, integrating both parts and developing complete web applications from start to finish, from conception to production deployment.

The position is for on-site work in São Paulo, in the Pinheiros neighborhood, with business hours Monday through Friday. We value professionals who have good social interaction, collaborative spirit, and ability to work in a dynamic team.

### Required Qualifications
- **Frontend:** Solid experience in HTML, CSS, JavaScript
- **Backend:** Knowledge in Node.js, Python, Java, or similar technologies
- **APIs:** Experience with RESTful and GraphQL API integration
- **Basic Languages:** Proficiency in JavaScript, Python, SQL
- **Fullstack:** Ability to create complete end-to-end applications
- **Soft Skills:** Good social interaction and teamwork
- **Version Control:** Git knowledge
- **Methodologies:** Experience with agile methodologies

### Differentiators
- **Certifications:** AWS, Google Cloud, Microsoft, or similar
- **Containerization:** Advanced Docker
- **Orchestration:** Kubernetes and containers
- **Operating System:** Linux proficiency
- **Databases:** NoSQL (MongoDB, Redis)
- **DevOps:** CI/CD and automation
- **UI/UX:** Aesthetic sense for interfaces
- **Testing:** Experience with automated tests

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
