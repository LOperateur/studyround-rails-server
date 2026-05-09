# StudyRound Server

A Ruby on Rails API backend powering the StudyRound e-learning platform. Supports course creation and consumption, assessments, trivia, AI-generated performance reports, and multi-provider payments.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Ruby 2.7.8 |
| Framework | Rails 5.2.4 |
| Database | PostgreSQL |
| Job Queue | Sidekiq + Redis |
| File Storage | AWS S3 |
| AI Reports | OpenAI API |
| Payments | Flutterwave, Paystack |
| Auth | JWT (bcrypt + Google OAuth) |
| Email | ZeptoMail (SMTP) |
| Tests | RSpec + FactoryBot |

---

## Prerequisites

- Ruby 2.7.8
- PostgreSQL
- Redis

---

## Setup

**1. Install dependencies**
```bash
bundle install
```

**2. Configure environment variables**

Copy `config/local_env.yml` from the template and fill in the values (see [Environment Variables](#environment-variables) below).

**3. Set up the database**
```bash
rails db:create db:migrate
```

**4. Start background jobs**
```bash
bundle exec sidekiq
```

**5. Start the server**
```bash
rails server
```

---

## Running Tests

```bash
bundle exec rspec
```

Test coverage includes request specs, model specs, job specs, service specs, and mailer specs under `spec/`.

---

## Environment Variables

Set these in `config/local_env.yml` (development) or your platform's environment config (staging/production).

| Variable | Description |
|---|---|
| `RAILS_MASTER_KEY` | Rails credentials master key |
| `DATABASE_URL` | PostgreSQL connection string |
| `OPENAI_ACCESS_TOKEN` | OpenAI API key for AI report generation |
| `GOOGLE_CLIENT_ID` | Google OAuth client ID |
| `GOOGLE_CLIENT_SECRET` | Google OAuth client secret |
| `GOOGLE_REDIRECT_URI` | Google OAuth redirect URI |
| `FLUTTERWAVE_PUBLIC_KEY` | Flutterwave public key |
| `FLUTTERWAVE_SECRET_KEY` | Flutterwave secret key |
| `FLUTTERWAVE_ENCRYPTION_KEY` | Flutterwave encryption key |
| `PAYSTACK_PUBLIC_KEY` | Paystack public key |
| `PAYSTACK_SECRET_KEY` | Paystack secret key |
| `SMTP_SERVER` | SMTP host (e.g. smtp.zeptomail.eu) |
| `SMTP_PORT` | SMTP port (587) |
| `SMTP_USERNAME` | SMTP username |
| `SMTP_PASSWORD` | SMTP password |
| `SENDGRID_API_KEY` | SendGrid API key |
| `TRELLO_API_KEY` | Trello API key |
| `TRELLO_API_TOKEN` | Trello API token |
| `TRELLO_API_SECRET` | Trello API secret |
| `AUTH_URL` | Frontend auth app URL |
| `HOST_URL` | Frontend host URL |
| `CREATOR_URL` | Creator dashboard URL |
| `RAILS_ASSET_HOST` | Asset host URL |
| `ADMIN_CONSENT_EMAIL` | Email address for admin consent notifications |
| `FREE_TEST_SESSION_ACCESS_HOURS` | Hours a free test session remains accessible |
| `TEST_LAG_TIME_SECONDS` | Lag time in seconds before test expiration jobs run |
| `TOP_COURSE_MIN_RATING_COUNT` | Minimum rating count for top courses listing |
| `TOP_TEST_MIN_RATING_COUNT` | Minimum rating count for top tests listing |
| `ONBOARDING_PARAMS` | Pipe-separated list of onboarding step keys |

---

## Core Features

### Authentication
- JWT-based with 1-day access tokens and 1-year refresh tokens
- Password authentication (bcrypt)
- Google OAuth (web and mobile flows)
- OTP email verification (10-minute window)

### Learning Content
- **Courses** — creation, publishing, categorisation, search, trending/top/recent feeds
- **Questions** — CRUD, bulk import, asset management, notes, explanations
- **Course Bundles** — grouped course collections

### Assessments
- **Tests** — invitation-based, leaderboard, session management, expiration
- **Trivia** — sets, invitations, leaderboard, real-time submissions
- **Study Sessions** — start/end tracking, stale session cleanup

### AI Reports
Performance reports generated via OpenAI API after test and trivia completion.

### Payments
Transactions processed through Flutterwave and Paystack. Financial card management included.

### Background Jobs (Sidekiq)
| Job | Purpose |
|---|---|
| `TestResultsEmailSendJob` | Email test results to participants |
| `TriviaResultsEmailSendJob` | Email trivia results to participants |
| `TestExpirationJob` | Expire stale test sessions |
| `TriviaExpirationJob` | Expire stale trivia sessions |
| `CourseSessionSubmissionJob` | Submit completed course sessions |
| `StaleSessionSubmissionJob` | Auto-submit abandoned sessions |
| `DeleteExpiredResultSessionJob` | Clean up expired result sessions |
| `DeleteStaleStudySessionJob` | Clean up stale study sessions |
| `CleanupGuestDataJob` | Remove guest user data |
| `CopyAssetsJob` | Copy question assets between courses |

---

## Deployment

The app ships with a `Dockerfile` and `entrypoint.sh` for container-based deployments. A `Procfile` is included for Heroku.

For EC2 deployments using AWS Parameter Store, ensure all environment variables listed above are stored as parameters and exported into the application's environment before the server starts.

CORS is restricted to `*.studyround.com` in production and staging.
