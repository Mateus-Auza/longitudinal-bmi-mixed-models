# Linear Mixed Models: Longitudinal BMI Analysis

## Overview

This project applies **linear mixed-effects models (LMMs)** to analyze longitudinal BMI measurements from approximately 1,000 overweight students in Belgium.

The objective is to evaluate how BMI evolves over one academic year under three different prevention approaches, while accounting for baseline characteristics and the correlation induced by repeated measurements from the same student.

The analysis was conducted in **R** using the `nlme`, `emmeans`, `tidyverse`, and `gt` packages.

---

## Research Question

> How does BMI change over time under each prevention approach, after adjusting for baseline characteristics?

The study compares three prevention approaches:

1. **Approach 1:** Information booklet on healthy lifestyle and overweight prevention.
2. **Approach 2:** Information sessions, booklets, and sports activity discounts.
3. **Approach 3:** Approach 2 combined with a health coaching application providing tracking and guidance.

BMI was measured repeatedly for each student at:

- Baseline
- T1
- T2
- T3
- T4
- T5

Because repeated observations from the same student are correlated, a linear mixed-effects model was used instead of ordinary linear regression.

---

## Data

The dataset contains longitudinal BMI measurements together with baseline characteristics.

### Main variables

| Variable | Description |
|---|---|
| `ID` | Student identifier |
| `GROUP` | Prevention approach (1–3) |
| `GENDER` | Gender |
| `SMOKE` | Smoking status |
| `LIVE` | Physical activity |
| `BMIb` | Baseline BMI |
| `BMI_T1`–`BMI_T5` | BMI measurements during follow-up |

The original data are provided in the `data/` directory.

---

## Methodology

### 1. Data preprocessing

The original BMI measurements were provided in wide format. The data were transformed into long format to facilitate longitudinal modelling.

```text
Wide format

ID | Group | BMIb | BMI_T1 | BMI_T2 | ...

↓

Long format

ID | Group | Time | BMI
