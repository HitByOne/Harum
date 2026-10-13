# Harim

Harim is a product information management (PIM) app in a single HTML page. It comes with sample data for a made-up lifestyle retailer (apparel, footwear, drinks, coffee, snacks, home, outdoor, fitness, beauty). Every company, brand and person in it is made up.

**Open the live demo:** use the GitHub Pages link for this repository (Settings > Pages).

## What it does
- **Products:** browse, search and review 10,000 items, organized into item groups, taxonomy, vendors and attributes.
- **Channel readiness:** shows, for each sales channel, which items have everything the channel needs, and what's blocking the rest.
- **Requests and approvals:** every change goes through a draft, then submission, then approval, then a change file. Each item keeps a full history, and approved changes can be undone.
- **Spreadsheet round trip:** download items to Excel, edit them, and upload the file. Harim shows exactly what changed.
- **Item load:** checks a supplier's new-item file and suggests item numbers.
- **Home dashboard:** shows what's waiting on you, the top launch blockers, and the data quality trend.

## Two ways to run it
- **On its own (the default).** Sign in as **Administrator** and choose a password. The sample data in `demo/` loads automatically. Everything you do is saved **in your own browser only**.
- **Shared (Supabase).** Your team signs in with real accounts and works on the same requests and data, live. A **Try the demo** button opens a shared sandbox that resets every night. Setup takes about 15 minutes: see [SETUP-SHARED.md](SETUP-SHARED.md). It switches on once `config.json` has your project's details.

## Files
| Path | What it is |
|---|---|
| `index.html` | The whole app |
| `config.json` | Supabase project details for shared mode (placeholders = run on its own) |
| `backend/harim_setup.sql` | One-time database setup for shared mode |
| `SETUP-SHARED.md` | Step-by-step shared-mode setup |
| `demo/` | Data loaded automatically (listed in `demo/manifest.json`) |
| `samples/Sample_New_Items_from_Supplier.xlsx` | Drop into Product Data Management > Item load to try a new item load |
| `samples/Team.csv` | A sample team. Load it on Admin > Data import > Upload everything |

To use your own data, change the files in `demo/` and the list in `manifest.json`. You can also remove the `demo/` folder and load files by hand on Admin > Data import. In shared mode, use **Shared data files** on that page instead.
