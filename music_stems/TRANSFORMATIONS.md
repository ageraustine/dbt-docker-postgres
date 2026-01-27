# Transformation Logic Documentation

This document explains the transformation logic in the music_stems dbt project.

## Overview

The project transforms raw stem combination data through multiple layers:
1. **Seeds** - Raw data sources
2. **Staging** - Initial cleaning and categorization
3. **Intermediate** - Progressive enrichment and scoring
4. **Marts** - Final analytical models

## Transformation Layers

### Layer 1: Staging (stg_stem_combinations)

**Input:** Raw stem_combinations seed from get_combinations.py

**Transformations:**
- Categorize similarity scores into tiers:
  - `high`: >= 0.9
  - `medium`: >= 0.75
  - `low`: < 0.75
- Extract folder names from S3 paths
- Clean and validate data

**Output:** Clean, categorized combinations

### Layer 2a: Metadata Enrichment (int_combinations_with_metadata)

**Input:** stg_stem_combinations + track_metadata seed

**Transformations:**
- LEFT JOIN with track_metadata on track_path
- Add genre, mood, energy, key, tempo fields

**Purpose:** Enable analysis by musical characteristics

### Layer 2b: Family Classification (int_combinations_with_families)

**Input:** int_combinations_with_metadata + stem_family_mapping seed

**Transformations:**
- LEFT JOIN with stem_family_mapping (twice)
  - Once for replaced_stem_type → replaced_stem_family
  - Once for replacing_stem_type → replacing_stem_family
- Uses case-insensitive matching with LOWER(TRIM())

**Stem Families:**
- **Keys**: Piano, Rhodes, EP, Organ, Clav
- **Bass**: Electric, Upright, Synth Bass, 808
- **Drums**: Full Kit, 808 Drums, Perc Loops
- **Guitar**: Nylon, Steel, Electric, Jazz, Muted
- **Lead**: Pluck Lead, Saw Lead, Arp-Lead
- **Pad**: Pad, Strings, String Pad
- **Chords**: Chords, Progression

### Layer 3: Quality Scoring (int_quality_scored)

**Input:** int_combinations_with_families

**Transformations:**

1. **Quality Tier Assignment:**
   ```sql
   CASE
     WHEN similarity_score >= 0.95 THEN 'excellent'
     WHEN similarity_score >= 0.85 THEN 'good'
     WHEN similarity_score >= 0.75 THEN 'acceptable'
     ELSE 'poor'
   END as quality_tier
   ```

2. **Same Family Flag:**
   ```sql
   replaced_stem_family = replacing_stem_family
   ```

3. **Composite Quality Score (0-100):**
   ```sql
   similarity_score * 70 +  -- 70% weight on similarity
   CASE WHEN same_family THEN 30 ELSE 0 END  -- 30% bonus
   ```

**Scoring Logic:**
- Similarity is the primary factor (70%)
- Same-family replacements get a 30% bonus
- Same-family replacements are generally safer/more compatible
- Cross-family can work but requires higher similarity

**Examples:**
| Similarity | Same Family? | Composite Score |
|------------|-------------|-----------------|
| 0.95       | Yes         | 96.5           |
| 0.95       | No          | 66.5           |
| 0.85       | Yes         | 89.5           |
| 0.85       | No          | 59.5           |
| 0.75       | Yes         | 82.5           |
| 0.75       | No          | 52.5           |

### Layer 4: Ranking (int_best_combinations_per_track)

**Input:** int_quality_scored

**Transformations:**
- ROW_NUMBER() window function partitioned by (track_path, replaced_stem_type)
- Ordered by composite_quality_score DESC, similarity_score DESC
- Filter to keep only rank <= 3

**Purpose:** Reduce noise by showing only the top 3 options per stem

### Layer 5: Marts (Analytical Models)

#### mart_stem_family_compatibility

**Purpose:** Analyze which stem families work well together

**Key Metrics:**
- Total combinations per family pair
- Quality distribution (excellent/good/acceptable/poor counts)
- Average quality score
- Percentage high quality
- Replacement type (Same Family vs Cross Family)

**Use Case:** Understand general compatibility rules (e.g., "Bass → Synth Bass is 85% excellent")

#### mart_genre_mood_analysis

**Purpose:** Identify genre/mood patterns in replacements

**Key Metrics:**
- Total combinations per genre/mood/energy
- Number of unique tracks
- Average quality score
- Percentage high quality

**Use Case:** "Electronic/energetic tracks have more replacement options"

#### mart_key_tempo_compatibility

**Purpose:** Analyze by musical key and tempo ranges

**Tempo Ranges:**
- Slow: < 80 BPM
- Medium: 80-110 BPM
- Upbeat: 110-140 BPM
- Fast: >= 140 BPM

**Use Case:** "C Major upbeat tracks have better replacement quality"

#### mart_best_replacements_per_track

**Purpose:** Show top 3 options per stem per track

**Use Case:** "For track X, these are the 3 best replacements for the bass"

#### mart_replacement_recommendations ⭐

**Purpose:** Actionable recommendations for producers

**Filters:**
- Only `excellent` or `good` quality tiers
- Only rank 1 (best option) per stem
- Adds human-readable recommendation text
- Priority score (1-5) based on similarity

**Recommendation Text Logic:**
```sql
CASE
  WHEN quality_tier = 'excellent' AND same_family
    THEN 'Highly Recommended: Excellent match within same family'
  WHEN quality_tier = 'excellent' AND NOT same_family
    THEN 'Recommended: Excellent cross-family match'
  WHEN quality_tier = 'good' AND same_family
    THEN 'Recommended: Good match within same family'
  WHEN quality_tier = 'good' AND NOT same_family
    THEN 'Consider: Good cross-family match'
END
```

**Priority Score:**
- 5: similarity >= 0.95
- 4: similarity >= 0.90
- 3: similarity >= 0.85
- 2: similarity >= 0.80
- 1: similarity < 0.80

## Quality Philosophy

### Why Composite Scoring?

Pure similarity isn't enough because:
1. Cross-family replacements can be risky even at high similarity
2. Same-family replacements are more predictable
3. Producers need confidence in recommendations

### Example Scenarios

**Scenario 1: High Similarity, Same Family**
- Replacing "piano" with "rhodes"
- Similarity: 0.92
- Composite: 94.4
- Result: ⭐ Highly Recommended

**Scenario 2: High Similarity, Cross Family**
- Replacing "piano" (Keys) with "electric clean" (Guitar)
- Similarity: 0.92
- Composite: 64.4
- Result: ⚠️ Consider carefully

**Scenario 3: Medium Similarity, Same Family**
- Replacing "electric bass" with "synth bass"
- Similarity: 0.82
- Composite: 87.4
- Result: ✓ Recommended

**Scenario 4: Medium Similarity, Cross Family**
- Replacing "full kit" (Drums) with "808" (Bass)
- Similarity: 0.82
- Composite: 57.4
- Result: ❌ Not in recommendations

## Testing Strategy

The project includes data quality tests:

### Seeds
- NOT NULL tests on primary keys
- UNIQUE tests on track_metadata.track_path
- ACCEPTED_VALUES tests on stem_family_mapping.stem_family

### Models
- NOT NULL tests on critical fields
- ACCEPTED_VALUES tests on rank_within_stem (1, 2, 3)

## Updating Transformation Logic

To modify scoring weights:

1. Edit `int_quality_scored.sql`
2. Adjust the formula:
   ```sql
   similarity_score * NEW_WEIGHT +
   CASE WHEN same_family THEN (100 - NEW_WEIGHT) ELSE 0 END
   ```
3. Update quality tier thresholds if needed
4. Run `dbt run --select int_quality_scored+` to rebuild downstream models

To add new transformations:
1. Create new intermediate model
2. Reference upstream models with `{{ ref('model_name') }}`
3. Add documentation to schema.yml
4. Run `dbt run --select +new_model` to test
