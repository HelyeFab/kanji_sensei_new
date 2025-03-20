#!/usr/bin/env python3
import json
import os
import re
import sys
import time

def parse_kanji_line(line):
    """Parse a single line of kanji data."""
    # Skip empty lines
    if not line.strip():
        return None
    
    # Split by tabs
    parts = line.strip().split('\t')
    if len(parts) < 2:
        print(f"Warning: Skipping malformed line: {line}")
        return None
    
    kanji = parts[0]
    
    # Extract meaning
    meaning_match = re.search(r'^\S+\s+(.+?)(?=\s+[ア-ン]|\s*$)', parts[1])
    if not meaning_match:
        print(f"Warning: Could not extract meaning from line: {line}")
        return None
    
    meaning = meaning_match.group(1).strip()
    
    # Extract onyomi (katakana) and kunyomi (hiragana)
    onyomi = []
    kunyomi = []
    
    # Process all parts after the first tab
    remaining_text = parts[1]
    
    # Find all katakana words (onyomi)
    onyomi = re.findall(r'[ア-ン]+', remaining_text)
    
    # Find all hiragana words (kunyomi)
    # This pattern looks for hiragana possibly followed by periods, dashes, or specific endings
    kunyomi_pattern = r'[ぁ-ん]+(?:\.[ぁ-ん]+|-[ぁ-ん]*|\s+[a-zA-Z\s]+)?'
    kunyomi = re.findall(kunyomi_pattern, remaining_text)
    
    # Clean up kunyomi entries
    cleaned_kunyomi = []
    for k in kunyomi:
        # Remove any English descriptions that might have been captured
        k = re.sub(r'\s+[a-zA-Z\s]+$', '', k)
        # Trim whitespace
        k = k.strip()
        if k:  # Only add non-empty entries
            cleaned_kunyomi.append(k)
    
    return {
        "kanji": kanji,
        "meaning": meaning,
        "onyomi": onyomi,
        "kunyomi": cleaned_kunyomi
    }

def main():
    print("Kanji to JSON Converter")
    print("=======================")
    
    # Get folder name
    folder_name = input("Enter the folder name in kanji_data where the file should be saved: ")
    
    # Get file name
    file_name = input("Enter the file name (without .json extension): ")
    if not file_name.endswith('.json'):
        file_name += '.json'
    
    # Create the directory if it doesn't exist
    # Use absolute path from project root
    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '../..'))
    output_dir = os.path.join(project_root, 'lib', 'assets', 'kanji_data', folder_name)
    os.makedirs(output_dir, exist_ok=True)
    
    output_path = os.path.join(output_dir, file_name)
    
    print("\nPaste your raw kanji data below.")
    print("When finished, press Ctrl+D (Unix/Mac) or Ctrl+Z followed by Enter (Windows).")
    print("---------------------------------------------------------------------")
    
    # Read raw data from stdin
    raw_data = sys.stdin.read()
    
    # Parse each line with progress indicator and time estimation
    lines = raw_data.strip().split('\n')
    total_lines = len(lines)
    kanji_list = []
    
    print("\nProcessing kanji data:")
    print("[" + " " * 50 + "] 0% - Estimating time...", end="\r")
    
    start_time = time.time()
    processed_lines = 0
    
    for i, line in enumerate(lines):
        line_start_time = time.time()
        
        kanji_entry = parse_kanji_line(line)
        if kanji_entry:
            kanji_list.append(kanji_entry)
            processed_lines += 1
        
        # Calculate progress
        progress = int((i + 1) / total_lines * 100)
        filled_length = int(50 * (i + 1) / total_lines)
        bar = "█" * filled_length + " " * (50 - filled_length)
        
        # Calculate time estimation after processing a few lines
        if i >= 5:  # Wait for a few lines to get a better average
            elapsed_time = time.time() - start_time
            lines_per_second = (i + 1) / elapsed_time if elapsed_time > 0 else 0
            remaining_lines = total_lines - (i + 1)
            estimated_remaining_seconds = remaining_lines / lines_per_second if lines_per_second > 0 else 0
            
            # Format time remaining
            if estimated_remaining_seconds < 60:
                time_str = f"{estimated_remaining_seconds:.1f}s remaining"
            elif estimated_remaining_seconds < 3600:
                time_str = f"{estimated_remaining_seconds/60:.1f}m remaining"
            else:
                time_str = f"{estimated_remaining_seconds/3600:.1f}h remaining"
                
            print(f"[{bar}] {progress}% - {time_str}", end="\r")
        else:
            print(f"[{bar}] {progress}% - Estimating time...", end="\r")
    
    print("\n")  # Move to next line after progress bar completes
    
    # Write to JSON file with progress indicator
    print(f"Writing JSON data to file... ", end="")
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(kanji_list, f, ensure_ascii=False, indent=2)
    print("Done!")
    
    # Calculate total processing time
    total_time = time.time() - start_time
    if total_time < 60:
        time_str = f"{total_time:.1f} seconds"
    elif total_time < 3600:
        time_str = f"{total_time/60:.1f} minutes"
    else:
        time_str = f"{total_time/3600:.1f} hours"
    
    print(f"\nSuccessfully converted {len(kanji_list)} kanji entries in {time_str}.")
    print(f"JSON file saved to: {output_path}")

if __name__ == "__main__":
    main()
