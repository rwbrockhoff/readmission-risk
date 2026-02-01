# 30-Day Readmission Analysis

Analysis of 30-day hospital readmission patterns for heart failure patients using synthetic EHR data.

## Business Question

Hospital readmissions within 30 days are a key quality metric—CMS penalizes hospitals for excess readmissions on certain conditions including heart failure. This project explores: **What patient characteristics are associated with higher 30-day readmission rates?**

## Key Findings

- **21.6% overall readmission rate** for the heart failure cohort (1,068 of 4,949 admissions)
- **Age 75-84 has highest risk** at ~30% readmission rate
- **Condition count matters**: Patients with 16+ conditions have 24% readmission rate vs 3.5% for those with 6-10
- **Prior admissions predict future admissions**: Rate climbs from 5% (1st admission) to 13%+ (5th admission)

## Data

**Source:** [Synthea](https://synthetichealth.github.io/synthea/) synthetic EHR data

- 1,197 heart failure patients (SNOMED 88805009)
- 4,949 inpatient admissions
- Realistic patient records without HIPAA concerns

Synthea is industry-standard for demonstrating healthcare data skills with EHR-structured data.

## Tools

- **Python** (pandas, matplotlib, seaborn) - Exploratory data analysis
- **PostgreSQL** - Cohort building and readmission logic with window functions
- **Tableau** - Dashboard visualization

## Project Structure

- **sql/** - Database schema, data import, analysis queries, Tableau exports
- **notebooks/** - Python EDA on Synthea data
- **dashboards/** - Dashboard screenshots
- **case-study.md** - Full analysis writeup

## Dashboard

[View on Tableau Public](https://public.tableau.com/app/profile/ryan.brockhoff/viz/30-DayReadmissions/30-DayReadmissions)

## SQL Highlights

The core readmission logic uses `LEAD()` to find each patient's next admission:

```sql
SELECT
    patient_id,
    discharge_date,
    LEAD(admission_date) OVER (
        PARTITION BY patient_id
        ORDER BY admission_date
    ) as next_admission_date
FROM inpatient_encounters
```

Then calculates days between discharge and next admission to flag 30-day readmissions.

## Limitations

- Synthetic data may have differences from real EHR data
- Synthea data is simplified compared to production EHR systems
- Single condition cohort (heart failure only)

See [case-study.md](case-study.md) for full methodology and findings.
