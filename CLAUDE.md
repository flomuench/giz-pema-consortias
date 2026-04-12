# CLAUDE.md - Female Export Consortia RCT

## What this project is

Randomized controlled trial testing female-only export consortia for small firm internationalization in Tunisia. 176 firms across treatment/control groups, three survey rounds (baseline, midline, endline). GIZ/PEMA intervention. Paper by Munch, Bouziri, and Scheifele, targeting AEJ: Applied Economics.

Core outcomes: export performance, sales, business networks, management practices. Theoretical framework combines Melitz (2003) heterogeneous firms with Bandiera et al. (2022) poverty trap dynamics.

## Repo structure

**Code lives on GitHub** (`flomuench/giz-pema-consortias`), **data lives on Google Drive**.

Key folders:
- `master/` - main analysis pipeline (merge, clean, correct, generate, visualize, regress, heterogeneity)
- `Surveys/Baseline/`, `Surveys/Midline/`, `Surveys/Endline/` - survey-level do-files (import, clean, correct, generate)
- `ado_files/` - user-written ado files loaded via `sysdir set PLUS`

LaTeX output goes to a separate repo (`cf_paper`) via globals `${tables_latex}` and `${figures_latex}`.

**Master file:** `master/master_consortia.do` - always read this first. It defines all globals and runs the pipeline.

## Pipeline order (from master_consortia.do)

1. `consortia_merge.do` - merge PII and analysis data across survey rounds
2. `consortia_list_experiment.do` - list experiment randomization
3. `consortia_clean.do` - clean intermediate data
4. `consortia_correct.do` - correct intermediate data
5. `consortia_generate.do` - generate analysis variables
6. `consortia_visualisations_{bl,ml,el}.do` - descriptive figures
7. `consortia_regressions_{ml,el}.do` - treatment effect estimation
8. `consortia_heterogeneity_{ml,el}.do` - heterogeneity analysis

Survey-level do-files follow the same pattern per round: `{bl,ml,el}_{import,clean,correct,generate}.do`

Files are toggled on/off in the master with `if (1)` / `if (0)`.

## Data files

- `consortium_final.dta` - main analysis file (includes `ca_w95` winsorized sales)
- `bl_final.dta`, `ml_final.dta`, `el_final.dta` - round-level final files
- Raw survey data in Excel on Google Drive

**Data naming:** `{prefix}_raw.dta` -> `{prefix}_inter.dta` -> `{prefix}_final.dta`
**PII files:** `consortia_{prefix}_pii.dta` (always a separate track, never merged into analysis data)

## Key identifiers

- `id_plateforme` - firm panel unit (primary ID)
- `surveyround` - panel time variable (1=BL, 2=ML, 3=EL)
- `treatment` - treatment assignment (0/1)
- `take_up` - consortium participation (0/1, treatment group only)
- `strata_final` - randomization strata
- `consortia_cluster` - clustering variable for SEs

## Globals structure

Two-level globals: `{prefix}_gdrive` for data, `{prefix}_github` for code.

Within gdrive: `${prefix_raw}`, `${prefix_intermediate}`, `${prefix_final}`, `${prefix_checks}`, `${prefix_output}`

LaTeX globals: `${tables_latex}` with subfolders (empowerment, export, network, business, descriptives, attrition), `${figures_latex}` with subfolders (Empowerment, Exports, Management Practices, network)

## Coding conventions

### Do-file headers

Every do-file starts with a star-box header specifying PURPOSE, OUTLINE (PART numbering), Author, ID variable, Requires, Creates.

### Section organization

- PART headers with star-line separators for major sections
- Sub-parts with `/*--- PART 3.1: ... ---*/` comment blocks
- Curly braces `{ }` for code folding in Stata editor

### Formatting

- Tabs for indentation (not spaces)
- `///` for line continuation
- `*` at start of lines or `//` inline for comments

### Settings (from master)

```stata
version 15
set varabbrev off
set seed 8413195
set sortseed 8413195
```

Graph font: Times New Roman. Scheme: `stcolor` (Munch), `s1color` (others).

## Regression specifications

### Main estimator

`areg` with `absorb(strata_final)` for strata FE, `cluster(consortia_cluster)` for SEs.

```stata
eststo model, r: areg outcome i.treatment y0_outcome if outcome != . & y0_outcome != ., ///
    absorb(strata_final) cluster(consortia_cluster)
estadd local strata_final "Yes"
estadd local bl_control "Yes"
sum outcome if treatment == 0 & outcome != .
estadd scalar ctrl_mean = r(mean)
estadd scalar ctrl_sd = r(sd)
```

### Estimators used

- OLS ITT: `areg` as above
- OLS TOT: `ivreg2` with `take_up` instrumented by `i.treatment`
- Poisson QMLE: for count/export outcomes
- Heterogeneity: `i.treatment##i.het_var` or `i.treatment##c.het_var`

### Table export

`esttab` with full LaTeX wrapper (`prehead`/`postfoot`), `adjustbox`, `tabularx`, `booktabs`. Stars: `* 0.1 ** 0.05 *** 0.01`. Always drop `_cons`.

### Key technical details

- Treatment effect as % of control endline mean: computed for OLS columns only (not Poisson). Division-by-zero guard required.
- Blank IV Poisson columns (non-convergence): use `ereturn post` with zero matrix named `_cons` plus conformable variance matrix. Redefine matrices before each call. Retrieve `e(N)` via `estimates restore` on the ITT model.
- `esttab` Yes/No rows: always use `estadd local` + `stats()`, never `indicate()` (breaks with factor variables).
- Dropping FE coefficients: add `*.varname` and `*.var1#*.var2` to `drop()`.
- LaTeX labels: use hyphens not underscores (e.g., `tab:sales-robustness`) to avoid esttab escaping issues.

## Variable naming conventions

- `ihs_ca` - IHS of sales (chiffre d'affaires)
- `lcapl1` - log(sales + 1)
- `ca_w95` - sales winsorized at 95th percentile
- `pole` - sector
- `region` - region
- `*_y0` or `y0_*` - baseline value of variable (ANCOVA control)

Transformations: IHS via `ln(x + sqrt(x^2 + 1))`, winsorize via `winsor2`, z-score indices via `zscore` or manual standardization.

## Multiple hypothesis testing

Benjamini-Krieger-Yekutieli (2006) sharpened q-values, implemented as custom `qvalues` program. Standalone version in `fdr_sharpened_qvalues.do`. Applied to heterogeneity analysis; not needed for main effects per David McKenzie.

## Common packages

estout, iebaltab (ietoolkit), winsor2, coefplot, betterbar, blindschemes/scheme-burd, ihstrans, ranktest/ivreg2, putpdf

## Theoretical model

R simulation (`model_simulate.R`). Combines Melitz heterogeneous firms with poverty trap dynamics. Calibration status: control group matches data well (~33.5% simulated vs ~33.9% empirical export rate), but treatment effect overshoots. Known issues: consortium threshold below domestic steady state, trap condition does not bind. Fixes identified: raise threshold, incorporate partial take-up (~45%), shorter simulation horizon.

## Paper and presentation

- Paper: LaTeX, compiled with pdfLaTeX. Author encoding: `M\"unch`.
- Presentation: LaTeX Beamer.
- Both maintained in a separate `cf_paper` repo.
- GitHub hosting of PDF: use raw URL format for direct access; consider commit-specific permalinks for citation stability.
