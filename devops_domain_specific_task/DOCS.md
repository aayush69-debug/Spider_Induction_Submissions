# Containerization Architecture: cr45-reduced

## 1. Setup & Deployment
To bring up the full stack, run:
`docker-compose up --build -d`

## 2. Port Bindings & Services
* **Frontend (React + Nginx):** Mapped to `localhost:3000`. Serves static Vite assets and proxies API calls.
* **Backend (Go):** Mapped to `localhost:8080`. Handles authentication and timetable logic.
* **Database (PostgreSQL):** Mapped to `localhost:5432`.

## 3. Networking & Reverse Proxy
The frontend and backend do not communicate via localhost. They are bridged on Docker's internal network. Nginx (inside the frontend container) intercepts any request starting with `/api/` and reverse-proxies it to `http://backend:8080`. The SPA fallback `try_files $uri /index.html` ensures React Router can handle client-side routing without Nginx throwing 404s.

## 4. Database & Migrations
The Go backend is designed to run `migrations.Up(db)` directly in `main.go`. By setting `depends_on: db` in compose, we ensure the Postgres container is initialized first. Once the backend connects via the injected `DATABASE_URL`, it automatically provisions the schemas. Data persistence is achieved via a named Docker volume (`pgdata`).

## 5. Common Debugging
* **Migrations failing on startup:** Sometimes the backend boots slightly faster than Postgres is ready to accept connections. Restarting the backend container (`docker-compose restart backend`) allows it to reconnect and run migrations successfully.
* **CORS / API 502 Errors:** Usually indicates the Nginx proxy is misconfigured or the backend container crashed. Check logs via `docker-compose logs backend`.