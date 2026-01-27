#!/usr/bin/env python3
"""
Helper script to extract track metadata from Qdrant to populate track_metadata.csv

This script reads from the same Qdrant collection used by get_combinations.py
and extracts genre, mood, energy, key, tempo metadata for each track.

Usage:
    python extract_metadata.py

Output:
    music_stems/seeds/track_metadata.csv
"""

import os
import sys
import pandas as pd
from tqdm import tqdm

# Add parent directory to path to import clients
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from clients import vdb_client

collection_name = "gramosynth_v3x_2"

def fetch_all_tracks(batch_size=100):
    """Fetch all tracks from Qdrant collection"""
    try:
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
        print(f"Fetching batch at offset: {offset}")
        try:
            results, next_offset = vdb_client.scroll(
                collection_name=collection_name,
                limit=batch_size,
                offset=offset,
                with_payload=True,
                with_vectors=False  # We don't need vectors for metadata extraction
            )
        except Exception as e:
            print(f"Error fetching tracks: {e}")
            break

        if not results:
            break

        for track in results:
            yield {
                "id": track.id,
                "payload": track.payload
            }

        offset = next_offset
        if offset is None:
            break

def extract_metadata():
    """Extract metadata from all tracks and save to CSV"""
    metadata_list = []

    print("Fetching tracks from Qdrant...")
    for track in tqdm(fetch_all_tracks()):
        payload = track['payload']

        # Extract metadata
        folder = payload.get('folder', '')
        audio_filename = payload.get('audio_filename', '')
        track_path = f"s3://rtsy-gramosynth/{folder}/{audio_filename}" if folder and audio_filename else ''

        if not track_path:
            continue

        metadata = {
            'track_path': track_path,
            'genre': payload.get('genre', ''),
            'mood': payload.get('mood', ''),
            'energy': payload.get('energy', ''),
            'key': payload.get('key', ''),
            'tempo': payload.get('tempo', ''),
            'audio_filename': audio_filename,
            'folder': folder,
            'source': payload.get('source', 'gramosynth')
        }

        metadata_list.append(metadata)

    # Create DataFrame
    df = pd.DataFrame(metadata_list)

    # Remove duplicates (keep first occurrence)
    df = df.drop_duplicates(subset=['track_path'], keep='first')

    # Sort by track_path for consistency
    df = df.sort_values('track_path')

    # Save to CSV
    output_path = 'music_stems/seeds/track_metadata.csv'
    df.to_csv(output_path, index=False)

    print(f"\n✓ Extracted metadata for {len(df)} tracks")
    print(f"✓ Saved to {output_path}")
    print(f"\nSample data:")
    print(df.head())

    # Print summary statistics
    print(f"\nSummary:")
    print(f"  Total tracks: {len(df)}")
    print(f"  Unique genres: {df['genre'].nunique()}")
    print(f"  Unique moods: {df['mood'].nunique()}")
    print(f"  Unique keys: {df['key'].nunique()}")
    print(f"  Tempo range: {df['tempo'].min()} - {df['tempo'].max()} BPM")

if __name__ == "__main__":
    extract_metadata()
