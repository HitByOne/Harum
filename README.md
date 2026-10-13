# PIM demo

A product information management (PIM) app in a single HTML page, with sample data for a fictional lifestyle retailer
(apparel, footwear, drinks, coffee, snacks, home, outdoor, fitness, beauty). All companies, brands and people are made up.

**Open the live demo:** the GitHub Pages link for this repository (Settings > Pages).

## How it works
- Sign in as **Administrator** and create a password (it is stored only in your browser).
- The sample data in `demo/` loads automatically: 10,000 products, the attribute model, category tree, suppliers and brands.
- Everything you do (requests, edits, groups, settings) is saved **in your own browser only**. Other visitors don't see it.

## Files
| Path | What it is |
|---|---|
| `index.html` | The whole app |
| `demo/` | Data loaded automatically (listed in `demo/manifest.json`) |
| `samples/Sample_New_Items_from_Supplier.xlsx` | Drop into Product Data Management > Item load to try a new item load |
| `samples/Team.csv` | A sample team. Load it on Admin > Data import > Upload everything |

To use your own data, change the files in `demo/` (and the list in `manifest.json`), or remove the `demo/` folder and load files by hand on Admin > Data import.
