import os
from dotenv import load_dotenv
import pandas as pd
from tqdm import tqdm
import numpy as np
from qdrant_client import models
import sys
load_dotenv()

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from clients import vdb_client

collection_name = "gramosynth_v3x_2"

def process_results(results):
    return [
        {
            "description": f"{i} - {hit.payload.get('genre', 'Unknown')} - {hit.payload.get('mood', 'Unknown')} - {hit.payload.get('energy', 'Unknown')}",
            "payload": hit.payload,
            "id": hit.id,
            "vector": hit.vector,
            "score": hit.score
        }
        for i, hit in enumerate(results)
    ]

def find_similar_tracks(audio_vector, key, tempo, similarity_threshold=0.7):
    search_result = vdb_client.search(
        collection_name=collection_name,
        query_vector=("audio", audio_vector),
        query_filter=models.Filter(
            must=[
                models.FieldCondition(
                    key="key",
                    match=models.MatchValue(value=key)
                ),
                models.FieldCondition(
                    key="tempo",
                    match=models.MatchValue(value=tempo)
                ),
                models.FieldCondition(
                    key="found_stems",
                    range=models.Range(
                        gte=2  # Greater than or equal to 3
                    )
                )
            ]
        ),
        score_threshold=similarity_threshold
    )

    # Filter out the exact match (100% similarity)
    filtered_results = [
        result for result in search_result
        if not np.isclose(result.score, 1.0, atol=1e-8)
    ]

    return process_results(filtered_results)

def normalize_stem_name(stem_name):
    """Normalize stem name to handle variations in naming"""
    import re
    
    if not stem_name:
        return ""
    
    # Convert to lowercase and strip
    normalized = stem_name.lower().strip()
    
    # Remove common prefixes/suffixes that don't affect instrument identity
    normalized = re.sub(r'\b(full|dry|wet|clean|distorted|heavy|light|soft|hard)\b', '', normalized)
    
    # Normalize common variations
    replacements = {
        # Piano variations
        r'\b(acoustic\s*piano|grand\s*piano|upright\s*piano)\b': 'piano',
        r'\bpno\b': 'piano',
        r'\bgrand\b': 'piano',
        
        # Electric piano variations
        r'\b(electric\s*piano|e\.?piano|e\.?p\.?)\b': 'ep',
        r'\b(fender\s*)?rhodes\b': 'rhodes',
        r'\b(wurlitzer|wurly)\b': 'wurli',
        
        # Bass variations
        r'\b(acoustic\s*bass|upright\s*bass|double\s*bass|standup\s*bass)\b': 'upright bass',
        r'\b(electric\s*bass|bass\s*guitar|e\.?bass)\b': 'electric bass',
        r'\b(synthesizer\s*bass|synth\s*bass|sub\s*bass)\b': 'synth bass',
        r'\b(808\s*bass|808\s*sub)\b': '808',
        
        # Guitar variations  
        r'\b(acoustic\s*guitar|nylon\s*guitar|classical\s*guitar)\b': 'nylon',
        r'\b(steel\s*string|steel\s*guitar|acoustic\s*steel)\b': 'steel',
        r'\b(electric\s*guitar|e\.?guitar)\b': 'electric clean',
        r'\b(jazz\s*guitar|clean\s*guitar)\b': 'jazz',
        r'\b(muted\s*guitar|palm\s*muted)\b': 'muted',
        
        # Drums variations
        r'\b(drum\s*kit|full\s*kit|acoustic\s*drums|live\s*drums)\b': 'full kit',
        r'\b(808\s*drums|tr\-?808|drum\s*machine)\b': '808 drums',
        r'\b(percussion\s*loops?|perc\s*loops?)\b': 'perc loops',
        r'\b(percussion|percussive)\b': 'perc',
        
        # Synth variations
        r'\b(pluck\s*lead|plucked\s*lead)\b': 'pluck lead',
        r'\b(saw\s*lead|sawtooth\s*lead)\b': 'saw lead',
        r'\b(arp\s*lead|arpeggio\s*lead|arpeggiated\s*lead)\b': 'arp-lead',
        r'\b(synthesizer|synth)\b': 'synth',
        
        # Organ variations
        r'\b(hammond\s*organ|b3\s*organ)\b': 'organ',
        r'\b(clavinet|clav)\b': 'clav',
    }
    
    # Apply replacements
    for pattern, replacement in replacements.items():
        normalized = re.sub(pattern, replacement, normalized)
    
    # Remove extra whitespace and punctuation
    normalized = re.sub(r'[^\w\s\-]', ' ', normalized)
    normalized = re.sub(r'\s+', ' ', normalized).strip()
    
    return normalized

def load_compatibility_matrix():
    """Load compatibility matrix from sheets/matrix.csv"""
    matrix_path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "sheets", "matrix.csv")
    df = pd.read_csv(matrix_path, index_col=0)
    return df

def get_stem_family_mapping():
    """Create mapping of stem types to their families based on matrix categories"""
    family_mapping = {}
    
    # Keys family - expanded with common variations
    keys_stems = [
        "piano", "pno", "grand", "upright", "acoustic piano", "grand piano", "upright piano",
        "ep", "electric piano", "e.piano", "e.p", "epiano", 
        "rhodes", "fender rhodes", "wurli", "wurlitzer", "wurly",
        "organ", "hammond", "hammond organ", "b3", "b3 organ",
        "clav", "clavinet", "clavichord",
        "keyboard", "keyboards", "keys"
    ]
    for stem in keys_stems:
        family_mapping[stem] = "Keys"
    
    # Chords family (similar to Keys but for chord progressions)
    chords_stems = [
        "chords", "chord", "progression", "harmony", "harmonic"
    ]
    for stem in chords_stems:
        family_mapping[stem] = "Chords"
    
    # Pad family
    pad_stems = [
        "pad", "pads", "string pad", "synth pad", "atmospheric", "ambient",
        "strings", "string section", "orchestra", "orchestral", "padss"
    ]
    for stem in pad_stems:
        family_mapping[stem] = "Pad"
    
    # Lead family
    lead_stems = [
        "pluck lead", "pluck", "plucked lead", "plucked",
        "saw lead", "saw", "sawtooth", "sawtooth lead",  
        "arp-lead", "arp lead", "arp", "arpeggio", "arpeggiated",
        "lead", "synth lead", "synthesizer lead", "melody"
    ]
    for stem in lead_stems:
        family_mapping[stem] = "Lead"
    
    # # Misc family
    # misc_stems = [
    #     "synth", "synthesizer", "analog", "digital", "fx", "effects",
    #     "texture", "ambient", "noise", "sweep", "riser", "drop",
    #     "sfx", "sound effects", "sound fx"
    # ]
    # for stem in misc_stems:
    #     family_mapping[stem] = "Misc"
    
    # Guitar family - expanded
    guitar_stems = [
        "nylon", "classical", "nylon guitar", "classical guitar", "acoustic guitar",
        "steel", "steel string", "steel guitar", "acoustic steel",
        "electric clean", "electric guitar", "e.guitar", "clean guitar", "clean",
        "jazz", "jazz guitar", "hollow body",
        "muted", "muted guitar", "palm muted", "palm muting",
        "guitar", "gtr"
    ]
    for stem in guitar_stems:
        family_mapping[stem] = "Guitar"
    
    # Bass family - expanded
    bass_stems = [
        "electric bass", "bass guitar", "e.bass", "ebass", "electric",
        "upright bass", "acoustic bass", "double bass", "standup bass", "upright",
        "synth bass", "synthesizer bass", "sub bass", "analog bass",
        "808", "808 bass", "808 sub", "tr-808", "drum machine bass",
        "bass"
    ]
    for stem in bass_stems:
        family_mapping[stem] = "Bass"
    
    # Drums family - expanded
    drums_stems = [
        "full kit", "drum kit", "acoustic drums", "live drums", "kit",
        "808 drums", "tr-808", "drum machine", "electronic drums",
        "perc loops", "percussion loops", "perc", "percussion", "percussive",
        "drums", "drum", "kick", "snare", "hihat", "hi-hat", "cymbal"
    ]
    for stem in drums_stems:
        family_mapping[stem] = "Drums"
    
    return family_mapping

def get_stem_family(stem_type, family_mapping):
    """Get the family of a stem type using normalized matching"""
    if not stem_type:
        return None
        
    normalized_stem = normalize_stem_name(stem_type)
    
    # Direct match on normalized name
    if normalized_stem in family_mapping:
        return family_mapping[normalized_stem]
    
    # Partial match - check if any family key is contained in the normalized stem type
    for key, family in family_mapping.items():
        normalized_key = normalize_stem_name(key)
        if normalized_key and (normalized_key in normalized_stem or normalized_stem in normalized_key):
            return family
    
    # Word-based matching for compound terms
    stem_words = normalized_stem.split()
    for word in stem_words:
        if word in family_mapping:
            return family_mapping[word]
    
    return None

def are_stems_compatible(stem1, stem2, family_mapping, compatibility_matrix):
    """Check if two stems are compatible based on the matrix rules"""
    if not stem1 or not stem2:
        return False, "none"
    
    norm1 = normalize_stem_name(stem1)
    norm2 = normalize_stem_name(stem2)
    
    # Exact normalized match
    if norm1 == norm2:
        return True, "exact"
    
    # Check if either contains the other (for variations)
    if norm1 in norm2 or norm2 in norm1:
        return True, "variation"
    
    # Matrix-based compatibility check
    family1 = get_stem_family(stem1, family_mapping)
    family2 = get_stem_family(stem2, family_mapping)
    
    if family1 and family2:
        # Check matrix compatibility
        try:
            if family1 in compatibility_matrix.index and family2 in compatibility_matrix.columns:
                is_compatible = compatibility_matrix.loc[family1, family2] == "YES"
                if is_compatible:
                    return True, "matrix_compatible"
        except (KeyError, AttributeError):
            pass
        
        # Fallback to exact family match for same families
        if family1 == family2:
            return True, "same_family"
    
    return False, "none"

def match_stems(original_stems, similar_tracks):
    family_mapping = get_stem_family_mapping()
    compatibility_matrix = load_compatibility_matrix()
    stem_pairs = []
    
    for original_stem in original_stems:
        # Extract just the stem type (remove filename part in parentheses)
        original_stem_type = original_stem.split(" (")[0] if "(" in original_stem else original_stem
        matched_stems = []
        
        for track in similar_tracks:
            for i in range(1, 8):
                stem_type = track['payload'].get(f'stem_{i}_type', '')
                stem_filename = track['payload'].get(f'stem_{i}_filename')
                
                if stem_type and stem_filename:
                    # Use matrix-based compatibility checking
                    is_compatible, match_type = are_stems_compatible(original_stem_type, stem_type, family_mapping, compatibility_matrix)
                    
                    if is_compatible:
                        matched_stems.append({
                            "track_description": track['description'],
                            "stem_type": stem_type,
                            "stem_filename": stem_filename,
                            "folder": track['payload'].get('folder'),
                            "source": track['payload'].get('source'),
                            "similarity_score": track['score'],
                            "match_type": match_type,
                            "original_normalized": normalize_stem_name(original_stem_type),
                            "matched_normalized": normalize_stem_name(stem_type)
                        })

        if matched_stems:
            # Sort by match type priority and then by similarity score
            match_type_priority = {"exact": 0, "variation": 1, "same_family": 2, "matrix_compatible": 3}
            matched_stems.sort(key=lambda x: (match_type_priority.get(x['match_type'], 4), -x['similarity_score']))
            
            stem_pairs.append({
                "original_stem": original_stem,
                "matched_stems": matched_stems
            })
    return stem_pairs

def generate_combinations(track_path, stem_pairs, all_original_stems):
    family_mapping = get_stem_family_mapping()
    all_combinations = []
    
    # Get families of all original stems (excluding the one being replaced)
    original_families = []
    for stem in all_original_stems:
        stem_type = stem.split(" (")[0] if "(" in stem else stem
        family = get_stem_family(stem_type, family_mapping)
        if family:
            original_families.append(family)
    
    for pair in stem_pairs:
        original_stem = pair['original_stem']
        original_stem_type = original_stem.split(" (")[0]
        original_family = get_stem_family(original_stem_type, family_mapping)
        
        for matched_stem in pair['matched_stems']:
            replacing_family = get_stem_family(matched_stem['stem_type'], family_mapping)
            
            # Check if replacing with this stem would create a duplicate family
            remaining_families = [f for f in original_families if f != original_family]
            
            if replacing_family and replacing_family in remaining_families:
                # Skip this combination to avoid duplicate families
                continue
                
            folder = matched_stem['folder']
            all_combinations.append({
                'track_path': track_path,
                'replaced_stem_type': original_stem_type,
                'replacing_stem_type': matched_stem['stem_type'],
                'replacing_stem_path': f"s3://rtsy-gramosynth/{folder}/{matched_stem['stem_filename']}",
                'similarity_score': matched_stem['similarity_score']
            })
    return all_combinations

def process_track(track, similarity_threshold):
    audio_vector = track["vector"]["audio"]
    key = track['payload'].get('key')
    tempo = track['payload'].get('tempo')

    if not all([audio_vector, key, tempo]):
        return []

    similar_tracks = find_similar_tracks(audio_vector, key, tempo, similarity_threshold)

    original_stems = []
    for i in range(1, 6):
        stem_type = track['payload'].get(f'stem_{i}_type')
        stem_filename = track['payload'].get(f'stem_{i}_filename')
        if stem_type and stem_filename:
            original_stems.append(f"{stem_type} ({stem_filename})")

    if not original_stems:
        return []

    stem_pairs = match_stems(original_stems, similar_tracks)
    folder =  track['payload'].get('folder', '')
    track_path = f"s3://rtsy-gramosynth/{folder}/{track['payload'].get('audio_filename', '')}"
    return generate_combinations(track_path, stem_pairs, original_stems)

def fetch_all_tracks(batch_size=100):
    try:
        # Check if collection exists
        collections = vdb_client.get_collections()
        collection_names = [c.name for c in collections.collections]
        if collection_name not in collection_names:
            print(f"Error: Collection '{collection_name}' not found. Available collections: {collection_names}")
            return
    except Exception as e:
        print(f"Error connecting to Qdrant server: {e}")
        return
    
    offset = None
    while True:
        print("Offset", offset)
        try:
            results, next_offset = vdb_client.scroll(
                collection_name=collection_name,
                limit=batch_size,
                offset=offset,
                with_payload=True,
                with_vectors=True
            )
        except Exception as e:
            print(f"Error fetching tracks: {e}")
            break
            
        if not results:
            break
        for track in results:
            yield {
                "id": track.id,
                "payload": track.payload,
                "vector": track.vector
            }
        offset = next_offset
        # break
        if offset is None:
            break

def main(similarity_threshold=0.7):
    all_combinations = []

    for track in tqdm(fetch_all_tracks()):
        track_combinations = process_track(track, similarity_threshold)
        all_combinations.extend(track_combinations)
        interim_df = pd.DataFrame(all_combinations)
        interim_df.to_csv(f'sheets/results_.csv', index=False)

    # Create a new DataFrame with the results
    results_df = pd.DataFrame(all_combinations)

    # Save the results to an Excel file
    results_df.to_csv('sheets/stem_combinations3.csv', index=False)
    print("Results saved to stem_combinations3.csv")

if __name__ == "__main__":
    main(similarity_threshold=0.7)
