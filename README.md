# SEO Content Reranker

A web dashboard for SEO content analysis. Give it a **keyword** and it:

1. fetches the **first‑page Google results** via [Serper](https://serper.dev/),
2. **scrapes** the top‑N pages (Serper scrape API) and splits each page into **chunks**,
3. scores every chunk's **relevance to the keyword** with [Voyage AI](https://www.voyageai.com/)
   reranking (`rerank-2.5`),
4. stores everything in SQLite and shows it in a clean **Material‑Design**, RTL (Persian) UI.

A second mode **re‑ranks already‑scraped chunks** of a stored analysis against a *new* keyword —
no re‑scraping, so it doesn't spend Serper credits. Results export to a multi‑sheet **Excel** file.

This is a sibling of the [SEO Title Similarity Ranker](https://github.com/miladshooli/seo-title-similarity-ranker) — same design language, different pipeline (reranking page content instead of scoring titles).

![stack](https://img.shields.io/badge/stack-Flask%20%2B%20gunicorn%20%2B%20nginx-0d9488) ![rerank](https://img.shields.io/badge/rerank-voyage%20rerank--2.5-6366f1)

---

## How it works

```
keyword ─▶ Serper search ─▶ top‑N URLs ─▶ Serper scrape ─▶ markdown ─▶ chunks
                                                                          │
                                                            Voyage rerank (per URL)
                                                                          │
                                              relevance‑scored chunks ─▶ SQLite ─▶ dashboard / Excel

re‑rank mode:  stored chunks  ─▶  Voyage rerank (new keyword)  ─▶  new scored result   (no scrape)
```

Long runs execute in a **background thread**; the dashboard polls `/api/job/<id>` and streams a
live progress log. Reranking calls the **Voyage REST API** directly (with 429 back‑off) — no
`voyageai` SDK needed.

### Endpoints

- `POST /api/analyze` — `{keyword, serper_key, voyage_key, gl, hl, top_n, manual_urls:[{url,title}]}` → `{job_id}`
- `POST /api/rerank` — `{keyword, voyage_key, query_id}` → `{job_id}` (re‑score a stored query)
- `GET  /api/job/<id>` — job status, progress, log, and results
- `GET  /api/history` — stored analyses
- `GET  /api/export/<query_id>` — download the Excel report (chunks / URL summary / top chunks)

## API keys

Entered in the UI and stored in the browser by default. Optional server‑side fallbacks via env:
`SERPER_KEY`, `VOYAGE_API_KEY`.

## Run locally

```bash
pip install -r requirements.txt          # flask, requests, gunicorn, openpyxl
python app.py                            # http://localhost:8001
```

## Deploy (Debian/Ubuntu, behind nginx)

```bash
sudo bash deploy/setup.sh
# optional: bake keys server-side ->  sudo SERPER_KEY=... VOYAGE_API_KEY=... bash deploy/setup.sh
# then HTTPS:  sudo certbot --nginx -d your.domain.com --redirect
```

No domain? A wildcard‑DNS host like `<sub>.<server-ip>.nip.io` gets a valid Let's Encrypt cert.

## Project layout

```
app.py                      Flask backend (search + scrape + chunk + rerank, jobs, SQLite, Excel)
templates/index.html        Material‑Design RTL dashboard
requirements.txt
deploy/
  seo-reranker.service      systemd unit (1 worker, port 8001)
  nginx.conf                reverse proxy (add HTTPS with certbot)
  setup.sh                  one‑shot installer
```

## License

MIT — see [LICENSE](LICENSE).
