# Quick Start Guide

## Prerequisites

1. PostgreSQL database running (via docker-compose)
2. Python environment with required packages
3. Qdrant vector database with music stems data
4. dbt-core and dbt-postgres installed

## Step-by-Step Setup

### 1. Generate Raw Data

Run the get_combinations.py script to generate stem combinations:

```bash
cd /Users/macbook/Desktop/rnd/dbts
python get_combinations.py
```

This will create: `sheets/stem_combinations3.csv`

### 2. Extract Metadata (Optional but Recommended)

Extract track metadata from Qdrant:

```bash
python extract_metadata.py
```

This will create: `music_stems/seeds/track_metadata.csv`

### 3. Prepare Seeds

Copy the generated files to the seeds directory:

```bash
# Copy combinations data (REQUIRED)
cp sheets/stem_combinations3.csv music_stems/seeds/stem_combinations.csv

# If you ran extract_metadata.py, metadata is already in the right place
# Otherwise, manually populate music_stems/seeds/track_metadata.csv
```

### 4. Navigate to Project

```bash
cd music_stems
```

### 5. Load Seeds

Load the CSV files into the database:

```bash
dbt seed
```

This will load:
- `stem_combinations.csv` → raw.stem_combinations
- `track_metadata.csv` → raw.track_metadata
- `stem_family_mapping.csv` → raw.stem_family_mapping

### 6. Run Models

Build all transformation models:

```bash
dbt run
```

This will create:
- Staging layer (views)
- Intermediate layer (views)
- Marts layer (tables)

### 7. Test Data Quality

Run data quality tests:

```bash
dbt test
```

### 8. Query Results

Connect to PostgreSQL and query the marts:

```sql
-- Get actionable recommendations
SELECT * FROM music_stems_marts.mart_replacement_recommendations
WHERE recommendation_priority >= 4
LIMIT 20;
```

## Common Commands

### Full Refresh

Rebuild everything from scratch:

```bash
dbt seed --full-refresh
dbt run --full-refresh
```

### Run Specific Models

```bash
# Run just one model
dbt run --select mart_replacement_recommendations

# Run a model and all its downstream dependencies
dbt run --select stg_stem_combinations+

# Run a model and all its upstream dependencies
dbt run --select +mart_replacement_recommendations
```

### Debug

```bash
# Compile SQL without running
dbt compile

# Show what would run
dbt run --dry-run

# View documentation
dbt docs generate
dbt docs serve
```

## Project Structure at a Glance

```
Seeds (CSV data)
    ↓
stg_stem_combinations (clean)
    ↓
int_combinations_with_metadata (+ genre/mood/key/tempo)
    ↓
int_combinations_with_families (+ stem families)
    ↓
int_quality_scored (+ quality scores)
    ↓
int_best_combinations_per_track (top 3 per stem)
    ↓
Marts (8 analytical tables)
```

## Key Output Tables

1. **mart_replacement_recommendations** ⭐ - Most important, actionable recommendations
2. **mart_best_replacements_per_track** - Top 3 per stem per track
3. **mart_stem_family_compatibility** - Family-level analysis
4. **mart_genre_mood_analysis** - Genre/mood patterns
5. **mart_key_tempo_compatibility** - Key/tempo analysis
6. **mart_stem_compatibility_matrix** - Stem type analysis
7. **mart_track_replacement_options** - Per-track summary
8. **mart_popular_replacements** - Most used stems

## Troubleshooting

### Seeds won't load
- Check CSV format (no extra quotes, proper encoding)
- Ensure track_path is unique in track_metadata.csv
- Check column types in dbt_project.yml

### Models fail
- Check that seeds loaded successfully: `SELECT * FROM raw.stem_combinations LIMIT 10;`
- Run with debug: `dbt run --debug`
- Check logs in `logs/dbt.log`

### No data in marts
- Ensure stem_combinations.csv has data
- Check JOIN conditions in intermediate models
- Verify stem_family_mapping.csv covers your stem types

### Low match rate in joins
- Check that track_paths in stem_combinations match track_metadata
- Verify stem types match stem_family_mapping (case-insensitive)
- Use LOWER(TRIM()) for fuzzy matching

## Next Steps

1. Query the marts to understand your data
2. Customize transformation logic in `int_quality_scored.sql`
3. Add new marts for specific analysis needs
4. Set up dbt Cloud or Airflow for scheduling
5. Create BI dashboards with Metabase/Tableau/Looker
