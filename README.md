# Sales Performance Analysis

A retail sales portfolio project using **Python, Pandas, MySQL, and Power BI** to clean order data, compare sales performance, and summarize customer spending.

**Author:** Saurabh Mohite

## Objectives

- Compare sales across regions and products.
- Explore monthly sales trends.
- Identify repeat customers and customers with high recorded spending.
- Rank products within each recorded category.
- Present analysis through a Power BI report.
- Explain data quality issues and metric definitions clearly in an interview.

## Repository contents

| Path | Purpose |
| --- | --- |
| [dataset/sales_dataset.csv](dataset/sales_dataset.csv) | Source data: 1,000 rows and 9 columns |
| [pandas/sales_project.ipynb](pandas/sales_project.ipynb) | Cleaning, customer totals, spending segments, rolling average, and CSV export |
| [SQL/project.sql](SQL/project.sql) | Seven analytical queries; assumes an imported table |
| [clean_dataset/cleaned_sales.xls](clean_dataset/cleaned_sales.xls) | Committed cleaned export; inspected content is tab-separated text despite its extension |
| [power-bi/sales_dashboard.pbix](power-bi/sales_dashboard.pbix) | Power BI report file |
| README.md | Project explanation and reproduction guide |

No dependency lockfile, database schema/import script, or dashboard screenshots are committed. The setup below supplies manual steps without implying those files already exist.

## Dataset

The source CSV spans **1 January–31 December 2025**. Its origin, generation process, currency, and license are not documented; do not describe it as verified real customer data.

| Column | Interpretation and caveats |
| --- | --- |
| OrderID | Order identifier; unique in the cleaned source data |
| OrderDate | Date text in `DD-MM-YYYY` format |
| CustomerID | Customer identifier; 100 distinct customers after cleaning |
| Region | East, North, South, or West |
| Category | Recorded category: Beauty, Clothing, Electronics, or Home |
| Product | Laptop, Lipstick, Phone, Shirt, Shoes, or Vase |
| Sales | Numeric sales amount; treated as the row/order total for this analysis |
| Quantity | Units recorded per order |
| Hour | Zero in every source row; unsuitable for peak-hour analysis |

The repository does not establish whether `Sales` includes tax, discounts, or returns. Currency is unspecified, so findings use no currency symbol. Do not multiply `Sales` by `Quantity` unless its definition is independently confirmed.

### Data quality

- Missing values: Region **3**, Category **1**, Product **1**, Sales **1**.
- These six missing cells occur across **five rows**.
- Applying the notebook's `dropna()` followed by `drop_duplicates()` retains **995 rows**; no full-row duplicates remain to remove.
- Product/category pairs can be inconsistent: for example, Laptop appears under Clothing. Rankings describe recorded labels, not a validated product taxonomy.
- No age, gender, cost, or profit fields are available.

## Methodology

1. **Inspect:** load the CSV and count missing values.
2. **Clean:** remove rows with any missing source value, then remove exact duplicate rows.
3. **Analyze in Pandas:** aggregate customer spending, classify customers as Low (<1,000), Medium (1,000 to <5,000), or High (>=5,000), and list the top ten by recorded spending.
4. **Analyze in MySQL:** aggregate regional, product, monthly, and repeat-customer metrics; rank products with a window function.
5. **Explore in Power BI:** open the committed report, check its source paths, refresh, and reconcile its metrics with the cleaned data.

**Implementation caveats:** the notebook's `Sales.rolling(window=3).mean()` is a three-row rolling average in file order. It is not a monthly moving average, despite the cell comment. Its “lifetime value” calculation is spending within this dataset's observation period, not a predictive lifetime-value model.

## Setup

Use Python 3 with Pandas and Jupyter, MySQL **8.0+** for `RANK()`, and Power BI Desktop on Windows for the report. Exact package and MySQL versions were not pinned; the notebook records Python 3.13.9 in its metadata. The commands below are a suggested environment, not a verified compatibility matrix.

### 1. Clone and install Python dependencies

```bash
git clone https://github.com/100rabh-mohite/Sales-Performance-Analysis.git
cd Sales-Performance-Analysis
python -m venv .venv
```

Activate the environment:

```powershell
# Windows PowerShell
.\.venv\Scripts\Activate.ps1
```

```bash
# macOS/Linux
source .venv/bin/activate
```

Then install and launch:

```bash
python -m pip install pandas jupyter
jupyter notebook
```

### 2. Run the notebook

Open `pandas/sales_project.ipynb`. The existing input cell references `C:/Users/Rohit/Downloads/sales_dataset.csv`; replace that cell locally with:

```python
from pathlib import Path

# Works when the kernel starts in the repository root or pandas directory.
root = Path.cwd()
if not (root / "dataset" / "sales_dataset.csv").exists():
    root = root.parent
assert (root / "dataset" / "sales_dataset.csv").exists(), "Start from the repository root or pandas folder."

df = pd.read_csv(root / "dataset" / "sales_dataset.csv")
```

Restart the kernel and run all cells in order. The existing export cell writes `cleaned_sales.csv` into the kernel's working directory. For a predictable output location, replace that export cell locally with:

```python
output = root / "clean_dataset" / "cleaned_sales.csv"
df.to_csv(output, index=False)
print(output)
```

These are documented local adjustments; the committed notebook itself still contains the original path and export cell. The generated CSV is separate from the committed `cleaned_sales.xls` file. Do not remove rows merely because `Moving_Avg` is missing: its first two values are expected to be empty after rolling.

### 3. Prepare MySQL

The committed SQL file creates/selects database `project`, but does **not** create or load `sales_dataset`. To reproduce the cleaned analysis:

1. Export the cleaned CSV using the notebook steps above.
2. In MySQL Workbench, create/select database `project`.
3. Use **Table Data Import Wizard** to import that CSV as `sales_dataset`.
4. Map OrderID, CustomerID, Quantity, and Hour to integer types; Sales and Moving_Avg to DOUBLE; Region, Category, and Product to text. Import OrderDate as text to preserve `DD-MM-YYYY`.
5. Run these checks before the analysis:

```sql
USE project;

SELECT COUNT(*) AS row_count,
       COUNT(DISTINCT OrderID) AS orders,
       COUNT(DISTINCT CustomerID) AS customers,
       ROUND(SUM(Sales), 2) AS total_sales
FROM sales_dataset;
-- Expected for the cleaned source: 995, 995, 100, 258570.44

SELECT COUNT(*) AS invalid_dates
FROM sales_dataset
WHERE STR_TO_DATE(OrderDate, '%d-%m-%Y') IS NULL;
-- Expected: 0
```

For an existing database, skip the SQL file's unconditional `CREATE DATABASE project;` statement, or replace it locally with `CREATE DATABASE IF NOT EXISTS project;`.

## SQL analysis

[SQL/project.sql](SQL/project.sql) contains these seven questions:

| Question | SQL technique | Interpretation |
| --- | --- | --- |
| Total sales per region | SUM, GROUP BY | Compare regional sales totals |
| Top five products | SUM, ORDER BY, LIMIT | Ranked by sales amount, not units |
| Monthly revenue | MONTH, SUM | Requires a valid date representation |
| Repeat customers | COUNT, HAVING | More than one recorded order |
| Average order value by region | AVG | Valid here because cleaned OrderID is unique |
| Peak sales hour | GROUP BY Hour | Query exists, but the constant Hour field prevents a useful conclusion |
| Product ranking within category | RANK, PARTITION BY | MySQL 8.0+; subject to category-label quality |

### Example: regional sales

```sql
SELECT Region, ROUND(SUM(Sales), 2) AS total_sales
FROM sales_dataset
GROUP BY Region
ORDER BY total_sales DESC;
```

### Example: top five products by sales amount

```sql
SELECT Product, ROUND(SUM(Sales), 2) AS total_sales
FROM sales_dataset
GROUP BY Product
ORDER BY total_sales DESC
LIMIT 5;
```

### Example: monthly sales with explicit date parsing

The original `MONTH(OrderDate)` query needs adjustment when dates are imported as text. This variant matches the import instructions and keeps year and month together:

```sql
SELECT DATE_FORMAT(STR_TO_DATE(OrderDate, '%d-%m-%Y'), '%Y-%m') AS sales_month,
       ROUND(SUM(Sales), 2) AS revenue
FROM sales_dataset
GROUP BY sales_month
ORDER BY sales_month;
```

### Example: repeat customers

```sql
SELECT CustomerID, COUNT(DISTINCT OrderID) AS total_orders
FROM sales_dataset
GROUP BY CustomerID
HAVING COUNT(DISTINCT OrderID) > 1
ORDER BY total_orders DESC, CustomerID;
```

These examples document the existing analysis and necessary date handling; they do not modify the committed SQL script.

## Findings

The following values were recalculated from the committed source CSV after dropping missing rows and exact duplicates, following the notebook's cleaning order. They are **not** verified Power BI outputs.

| Metric | Result |
| --- | ---: |
| Retained orders | 995 |
| Distinct customers | 100 |
| Total recorded sales | 258,570.44 |
| South sales | 66,982.14 |
| North sales | 66,746.02 |
| West sales | 66,611.02 |
| East sales | 58,231.26 |
| Highest-selling product by sales amount | Lipstick: 46,261.62 |

South has the largest recorded regional total, while East has the smallest. Lipstick leads products by sales amount. These are descriptive comparisons; the data does not establish why performance differs or demonstrate a business improvement caused by this project.

A meaningful peak sales hour cannot be identified because every Hour value is zero. No profit, demographic, or causal conclusions can be supported from the available fields.

### Reproduce the findings in Python

Run this in the notebook after setting `root` as above:

```python
source = pd.read_csv(root / "dataset" / "sales_dataset.csv")
clean = source.dropna().drop_duplicates().copy()
clean["OrderDate"] = pd.to_datetime(clean["OrderDate"], format="%d-%m-%Y")

print("Rows before/after:", len(source), len(clean))
print("Customers:", clean["CustomerID"].nunique())
print("Orders:", clean["OrderID"].nunique())
print("Total sales:", round(clean["Sales"].sum(), 2))
print(clean.groupby("Region")["Sales"].sum().sort_values(ascending=False).round(2))
print(clean.groupby("Product")["Sales"].sum().sort_values(ascending=False).round(2))
print(clean.groupby(clean["OrderDate"].dt.to_period("M"))["Sales"].sum().round(2))
print("Hour values:", sorted(clean["Hour"].unique()))
```

## Dashboard visuals

Open [power-bi/sales_dashboard.pbix](power-bi/sales_dashboard.pbix) in Power BI Desktop. The report file is present, but its pages, visuals, DAX measures, filters, and data connections have not been verified here. The earlier README described revenue trends, product performance, customer segmentation, a regional heatmap, and KPIs; treat those as intended scope until checked in Desktop.

Suggested checks when reviewing the report:

| Visual | Data/metric to verify |
| --- | --- |
| Monthly sales line chart | Parsed OrderDate, year-month, SUM(Sales) |
| Product sales bar chart | Product and SUM(Sales) |
| Regional comparison/heatmap | Region and SUM(Sales) |
| Customer spending segments | Customer totals and the notebook's thresholds |
| KPI cards | Total sales, distinct orders, distinct customers, average order value |

Do not add age/gender segmentation from this dataset. A repeat-customer rate needs an explicit definition; for example, customers with >1 distinct order divided by distinct customers in the same period/filter context.

### Refresh the report

1. Open the PBIX in Power BI Desktop.
2. Inspect **Transform data → Data source settings** and the query's Source step.
3. Repoint local file sources to your exported cleaned CSV if appropriate. If the report uses another source, inspect its schema before changing it.
4. Set OrderDate using a day/month/year locale; confirm Sales is numeric.
5. Refresh and compare the unfiltered metrics with the findings above.
6. Check whether the report uses the same cleaning rules and whether any filters explain differences.

The exact refresh procedure depends on the PBIX's existing connections; a successful refresh has not been verified. The committed `.xls` export is tab-separated text, so inspect it as text rather than assuming it is a native Excel workbook.

## Screenshots checklist

No screenshots are currently committed. After verifying the report, capture and add:

- [ ] Full dashboard overview with readable titles and KPI cards.
- [ ] Monthly sales trend with date range visible.
- [ ] Product sales comparison with units/metric clearly labeled.
- [ ] Regional sales comparison.
- [ ] Customer spending segmentation, if implemented.
- [ ] One SQL result with the corresponding query visible.

Suggested future location: `screenshots/`. Add relative Markdown image links only after the image files exist. Include filter context in captions and ensure displayed totals reconcile with the chosen data version.

## How to run the project

1. Clone the repository and set up Python dependencies.
2. Replace the notebook's input path and use the explicit output path above.
3. Restart the kernel and run all notebook cells.
4. Run the findings verification snippet; confirm 995 cleaned orders and total sales of 258,570.44.
5. Import the cleaned CSV into MySQL as `project.sales_dataset`.
6. Run the SQL analysis, using the explicit date-parsing variant for text dates.
7. Open the PBIX, inspect/repoint its sources, refresh, and reconcile totals.
8. Capture verified dashboard screenshots.

**Reproducibility status:** the source CSV and notebook logic support the documented recalculations. A complete MySQL execution and Power BI refresh were not performed for this documentation update. Exact dependencies, source provenance, and dashboard screenshots remain to be documented.

## Interview discussion

Be ready to explain why missing rows were removed, how that choice affects the sample, why Sales is treated as an order total, and how Python/SQL/dashboard totals are reconciled. Discuss the constant Hour field, inconsistent category labels, and the difference between a three-row rolling average and a true monthly moving average. Customer spending here covers only the observed dataset; it should not be presented as validated lifetime value.

## Author

**Saurabh Mohite** · [GitHub](https://github.com/100rabh-mohite)
