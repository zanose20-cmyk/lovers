Deploy Jitsi (Free, Professional) — Quick Guide

Recommendation
--------------
For a free, professional, and controllable voice engine for "Lovers" use a self-hosted Jitsi deployment (docker-jitsi-meet). It offers WebRTC audio, good audio quality, privacy (you host data), and integrates with mobile via the `jitsi_meet` plugin.

High-level steps
-----------------
1. Prepare a server (VM) with a public domain (e.g., `meet.example.com`).
2. Install Docker & Docker Compose on the server.
3. Clone `docker-jitsi-meet`, configure `.env` (PUBLIC_URL, Let's Encrypt, TURN, ENABLE_AUTH/JWT), create volumes, and run `docker-compose up -d`.
4. Configure JWT (optional) for secure rooms or use internal auth.
5. Point your backend to the Jitsi server: set `VOICE_ENGINE=jitsi` and `JITSI_SERVER=https://meet.example.com` in your backend `.env`.

Prerequisites
-------------
- Domain (DNS A record pointing to the server IP).
- Server with enough resources (see notes below).
- Open ports: TCP 80,443 and UDP 10000 (media). For TURN: UDP/TCP 3478.

Quick install (Linux)
---------------------
Run these commands on your server (Linux):

```bash
# install docker & docker-compose (if not present)
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo apt install -y docker-compose

# clone jitsi docker project
git clone https://github.com/jitsi/docker-jitsi-meet.git
cd docker-jitsi-meet
cp env.example .env
# edit .env: set PUBLIC_URL, ENABLE_LETSENCRYPT=1, LETSENCRYPT_DOMAIN, LETSENCRYPT_EMAIL
# enable auth if needed: ENABLE_AUTH=1; for JWT set AUTH_TYPE=jwt and configure prosody/jicofo accordingly
mkdir -p ~/.jitsi-meet-cfg/{web,transcripts,prosody,jicofo,jvb,jibri,libs}

# run
docker-compose up -d
```

Quick steps (Windows PowerShell)
--------------------------------
```powershell
git clone https://github.com/jitsi/docker-jitsi-meet.git
cd docker-jitsi-meet
Copy-Item env.example .env
# edit .env in notepad: set PUBLIC_URL and other values
docker-compose up -d
```

Important `.env` values to set
-----------------------------
- `PUBLIC_URL=https://meet.example.com`
- `ENABLE_LETSENCRYPT=1`
- `LETSENCRYPT_DOMAIN=meet.example.com`
- `LETSENCRYPT_EMAIL=you@example.com`
- `ENABLE_AUTH=1` and `AUTH_TYPE=internal` (or `jwt` for token-based auth)
- `ENABLE_TURNSERVER=1` and related `TURNSERVER_SECRET` if using your own TURN

Notes on TURN (recommended)
---------------------------
- For reliable mobile connectivity behind NAT, configure a TURN server (coturn). docker-jitsi-meet supports configuring TURN via `.env` (ENABLE_TURNSERVER=1).

Resource & scaling guidance
---------------------------
- Small tests / low concurrency (audio-only): 2 vCPU, 4 GB RAM may be enough.
- Production (many concurrent rooms): 4+ vCPU, 8–16 GB RAM; scale JVBs horizontally behind a load balancer.
- For large-scale (thousands concurrent): use multiple JVBs, autoscaling, and a load balancer for signalling.

Security / Production tips
--------------------------
- Use `AUTH_TYPE=jwt` and mint short-lived JWT for private rooms (configure Prosody module `mod_auth_token`).
- Use Let's Encrypt for TLS (the docker project can obtain certs for you).
- Monitor logs and resource usage; configure Prometheus/Grafana if needed.

Integration with this repo
--------------------------
- Set in backend `.env`:
  - `VOICE_ENGINE=jitsi`
  - `JITSI_SERVER=https://meet.example.com`
- Backend endpoint `/api/rooms/:roomId/voice-access` will return `{ engine: 'jitsi', server, roomName }`.
- Flutter client already includes `jitsi_meet` support; `Room` flow will use the returned server/room to join via the plugin.

When to choose Agora instead
---------------------------
- If you prefer a fully-managed SDK, guaranteed global low-latency, and advanced audio features with minimal ops, choose Agora (paid). Use Jitsi first for cost-savings and full control, then switch or hybridize with Agora for high-scale worldwide delivery.

If you want, I can now:
- (A) Add a `deploy/jitsi/setup.sh` script to this repo to automate the clone and initial `.env` edits, or
- (B) Create a Docker Compose snapshot here (not recommended — prefer upstream repo), or
- (C) Walk you through setting JWT auth and TURN configuration and update backend to mint room tokens.

اختر أحد الخيارات (A/B/C) أو قل "ابدأ" وسأنفّذ الخيار الأنسب تلقائياً.
