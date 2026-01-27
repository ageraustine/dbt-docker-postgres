# Music Stems DBT Project

This dbt project transforms and analyzes stem combination data generated from the `get_combinations.py` script.

## Overview

The `get_combinations.py` script:
- Connects to a Qdrant vector database containing music track embeddings
- Finds similar tracks based on key, tempo, and audio similarity
- Matches compatible stems (instrument parts) between tracks using a compatibility matrix
- Generates combinations where stems can be replaced while maintaining musical coherence

This dbt project processes the output CSV data to create analytical models for:
- Stem compatibility analysis
- Track replacement options
- Popular replacement stems

## Project Structure

```
music_stems/
├── models/
│   ├── staging/
│   │   ├── stg_stem_combinations.sql              # Cleaned and categorized combinations
│   │   └── schema.yml
│   ├── intermediate/
│   │   ├── int_combinations_with_metadata.sql     # Enriched with track metadata
│   │   ├── int_combinations_with_families.sql     # Added stem family classifications
│   │   ├── int_quality_scored.sql                 # Quality scoring and tiering
│   │   ├── int_best_combinations_per_track.sql    # Top 3 options per stem
│   │   └── schema.yml
│   └── marts/
│       ├── mart_stem_compatibility_matrix.sql     # Stem type compatibility (original)
│       ├── mart_track_replacement_options.sql     # Per-track stats (original)
│       ├── mart_popular_replacements.sql          # Most used stems (original)
│       ├── mart_stem_family_compatibility.sql     # Family-level compatibility
│       ├── mart_genre_mood_analysis.sql           # Genre/mood patterns
│       ├── mart_key_tempo_compatibility.sql       # Key/tempo analysis
│       ├── mart_best_replacements_per_track.sql   # Top 3 per track
│       ├── mart_replacement_recommendations.sql   # Actionable recommendations
│       └── schema.yml
├── seeds/
│   ├── stem_combinations.csv           # Output from get_combinations.py
│   ├── track_metadata.csv             # Track metadata (genre, mood, energy, etc.)
│   └── stem_family_mapping.csv        # Stem type to family mapping
└── dbt_project.yml
```

## Setup

1. Run the `get_combinations.py` script to generate the stem combinations CSV:
   ```bash
   python get_combinations.py
   ```

2. Copy the output CSV file to the seeds directory:
   ```bash
   cp sheets/stem_combinations3.csv music_stems/seeds/stem_combinations.csv
   ```

3. Load the seed data into your database:
   ```bash
   cd music_stems
   dbt seed
   ```

4. Run the dbt models:
   ```bash
   dbt run
   ```

5. Test the models:
   ```bash
   dbt test
   ```

## Models

### Staging Layer

**stg_stem_combinations**
- Cleans and enriches the raw seed data
- Adds similarity categories (high/medium/low)
- Extracts folder information from S3 paths

### Intermediate Layer

**int_combinations_with_metadata**
- Enriches combinations with track metadata (genre, mood, energy, key, tempo)
- Joins with track_metadata seed

**int_combinations_with_families**
- Adds stem family classifications (Keys, Bass, Drums, Guitar, Lead, Pad, Chords)
- Joins with stem_family_mapping seed
- Shows both replaced and replacing stem families

**int_quality_scored**
- Calculates composite quality score (0-100) based on:
  - Similarity score (70% weight)
  - Same-family bonus (30% weight)
- Assigns quality tiers: excellent, good, acceptable, poor
- Flags same-family replacements

**int_best_combinations_per_track**
- Ranks all replacement options per stem per track
- Filters to top 3 options for each stem
- Ordered by composite quality score

### Marts Layer

#### Original Marts
**mart_stem_compatibility_matrix**
- Analyzes which stem types work well as replacements for others
- Calculates average similarity scores per stem type pair
- Shows percentage of high-quality matches

**mart_track_replacement_options**
- Summarizes replacement options available for each track
- Shows number of stems that can be replaced
- Calculates quality metrics for each track's options

**mart_popular_replacements**
- Identifies the most frequently used replacement stems
- Shows which stems are most versatile across tracks
- Ranks by usage frequency and similarity scores

#### New Transformation Marts
**mart_stem_family_compatibility**
- Family-level compatibility analysis (Keys, Bass, Drums, etc.)
- Shows same-family vs cross-family replacements
- Quality distribution by family pair

**mart_genre_mood_analysis**
- Analyzes replacement patterns by genre, mood, and energy
- Shows which genres have more replacement options
- Calculates quality metrics per genre/mood combination

**mart_key_tempo_compatibility**
- Groups tracks by musical key and tempo ranges
- Analyzes replacement quality by key/tempo
- Tempo ranges: Slow (<80), Medium (80-110), Upbeat (110-140), Fast (>=140)

**mart_best_replacements_per_track**
- Top 3 replacement options for each stem in each track
- Includes full metadata and quality scores
- Actionable view for track producers

**mart_replacement_recommendations**
- **Most Important Mart** - Filtered to only high-quality recommendations
- Shows only rank 1 (best) option per stem
- Includes human-readable recommendation text
- Priority ranking (1-5) for easy sorting

## Data Flow

```
get_combinations.py
    ↓
Seeds:
├── stem_combinations.csv (raw combinations)
├── track_metadata.csv (genre, mood, energy, key, tempo)
└── stem_family_mapping.csv (stem type → family mapping)
    ↓
Staging:
└── stg_stem_combinations (clean + categorize)
    ↓
Intermediate Transformations:
├── int_combinations_with_metadata (add genre/mood/key/tempo)
    ↓
├── int_combinations_with_families (add stem families)
    ↓
├── int_quality_scored (calculate quality scores + tiers)
    ↓
└── int_best_combinations_per_track (rank + filter top 3)
    ↓
Marts (Analytics):
├── mart_stem_compatibility_matrix (stem type analysis)
├── mart_stem_family_compatibility (family analysis)
├── mart_genre_mood_analysis (genre/mood patterns)
├── mart_key_tempo_compatibility (key/tempo analysis)
├── mart_track_replacement_options (per-track summary)
├── mart_popular_replacements (most used stems)
├── mart_best_replacements_per_track (top 3 per stem)
└── mart_replacement_recommendations ⭐ (actionable recs)
```

## Configuration

The project uses the following materialization strategy:
- **Staging models**: Views (fast, always fresh)
- **Marts models**: Tables (optimized for queries)

All schemas are namespaced under `music_stems` in the database.

## Dependencies

- PostgreSQL database (configured in docker-compose.yaml)
- dbt-core
- dbt-postgres
- Python dependencies for get_combinations.py (see ../requirements.txt)

## Usage Examples

After running the models, you can query the marts:

```sql
-- ⭐ MOST USEFUL: Get actionable recommendations for all tracks
SELECT
    track_path,
    genre,
    mood,
    replaced_stem_type,
    replacing_stem_type,
    recommendation,
    recommendation_priority,
    composite_quality_score
FROM music_stems_marts.mart_replacement_recommendations
WHERE recommendation_priority >= 4
ORDER BY recommendation_priority DESC, composite_quality_score DESC
LIMIT 50;

-- Find best replacements for a specific track
SELECT *
FROM music_stems_marts.mart_best_replacements_per_track
WHERE track_path = 's3://rtsy-gramosynth/folder1/track1.wav'
ORDER BY replaced_stem_type, rank_within_stem;

-- Analyze stem family compatibility (which families work together)
SELECT
    replaced_stem_family,
    replacing_stem_family,
    replacement_type,
    total_combinations,
    avg_quality_score,
    pct_high_quality
FROM music_stems_marts.mart_stem_family_compatibility
WHERE pct_high_quality > 50
ORDER BY avg_quality_score DESC;

-- Find replacement patterns by genre
SELECT
    genre,
    mood,
    total_combinations,
    unique_tracks,
    pct_high_quality
FROM music_stems_marts.mart_genre_mood_analysis
ORDER BY total_combinations DESC;

-- Analyze by key and tempo
SELECT
    key,
    tempo_range,
    total_combinations,
    pct_high_quality
FROM music_stems_marts.mart_key_tempo_compatibility
ORDER BY key, tempo_range;

-- Find the most compatible stem replacements (original)
SELECT * FROM music_stems_marts.mart_stem_compatibility_matrix
ORDER BY avg_similarity DESC
LIMIT 10;

-- Find tracks with the most replacement options (original)
SELECT * FROM music_stems_marts.mart_track_replacement_options
ORDER BY total_replacement_options DESC
LIMIT 10;

-- Find the most popular replacement stems (original)
SELECT * FROM music_stems_marts.mart_popular_replacements
LIMIT 20;
```

## Updating Data

To refresh the analysis with new data:

1. Run `get_combinations.py` with updated parameters
2. Replace the CSV in `seeds/stem_combinations.csv`
3. Run `dbt seed --full-refresh` to reload the seed data
4. Run `dbt run` to rebuild all models

## Notes

- The similarity_score ranges from 0.0 to 1.0
- High similarity is defined as >= 0.9
- Medium similarity is defined as >= 0.75
- The compatibility matrix is loaded from `sheets/matrix.csv` in get_combinations.py
