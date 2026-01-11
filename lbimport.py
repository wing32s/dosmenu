#!/usr/bin/env python3
"""
LaunchBox XML Metadata Importer for DOS Game Launcher
Merges Publisher, Year, and Genre from LaunchBox XML into GAMES.DAT
Maintains LaunchBox ID mappings in LBMAP.DAT for reliable re-imports

Usage: python lbimport.py <launchbox.xml> [games.dat]
"""

import sys
import struct
import xml.etree.ElementTree as ET
from pathlib import Path
from difflib import SequenceMatcher
from lbgenre import genre_name_to_code, genre_code_to_name

# Record structure matches GAMETYPES.PAS
RECORD_SIZE = 256
MAP_RECORD_SIZE = 48

def pascal_string_encode(s, max_len):
    """Encode a Python string as a Pascal string with length prefix"""
    s = s[:max_len]  # Truncate if needed
    encoded = s.encode('cp437', errors='replace')
    return bytes([len(encoded)]) + encoded + b'\x00' * (max_len - len(encoded))

def pascal_string_decode(data, max_len):
    """Decode a Pascal string (length prefix + chars)"""
    if len(data) < 1:
        return ""
    length = data[0]
    if length > max_len:
        length = max_len
    try:
        return data[1:1+length].decode('cp437', errors='replace')
    except:
        return ""

def pack_game_record(game):
    """Pack a game record into 256 bytes"""
    record = bytearray(RECORD_SIZE)
    
    # Encode each field
    title = pascal_string_encode(game['title'], 50)
    path = pascal_string_encode(game['path'], 80)
    command = pascal_string_encode(game['command'], 13)
    args = pascal_string_encode(game['args'], 60)
    publisher = pascal_string_encode(game['publisher'], 30)
    year = pascal_string_encode(game['year'], 4)
    
    # Pack into record (must match Pascal record layout)
    pos = 0
    record[pos:pos+51] = title; pos += 51
    record[pos:pos+81] = path; pos += 81
    record[pos:pos+14] = command; pos += 14
    record[pos:pos+61] = args; pos += 61
    record[pos] = game.get('sound_flags', 0); pos += 1
    record[pos] = game.get('sound_fm', 0); pos += 1
    record[pos] = game.get('sound_midi', 0); pos += 1
    record[pos] = game.get('graphics_flags', 0); pos += 1
    record[pos:pos+31] = publisher; pos += 31
    record[pos:pos+5] = year; pos += 5
    record[pos] = game['genre_code']; pos += 1  # Genre code (1 byte)
    struct.pack_into('<H', record, pos, game.get('slowdown_su', 0)); pos += 2  # Word (2 bytes)
    record[pos] = 1 if game.get('requires_cd', False) else 0; pos += 1
    record[pos] = 1 if game['deleted'] else 0; pos += 1
    
    return bytes(record)

def unpack_game_record(data):
    """Unpack 256 bytes into a game record"""
    if len(data) != RECORD_SIZE:
        raise ValueError(f"Record must be exactly {RECORD_SIZE} bytes")
    
    pos = 0
    game = {}
    
    game['title'] = pascal_string_decode(data[pos:pos+51], 50); pos += 51
    game['path'] = pascal_string_decode(data[pos:pos+81], 80); pos += 81
    game['command'] = pascal_string_decode(data[pos:pos+14], 13); pos += 14
    game['args'] = pascal_string_decode(data[pos:pos+61], 60); pos += 61
    game['sound_flags'] = data[pos]; pos += 1
    game['sound_fm'] = data[pos]; pos += 1
    game['sound_midi'] = data[pos]; pos += 1
    game['graphics_flags'] = data[pos]; pos += 1
    game['publisher'] = pascal_string_decode(data[pos:pos+31], 30); pos += 31
    game['year'] = pascal_string_decode(data[pos:pos+5], 4); pos += 5
    game['genre_code'] = data[pos]; pos += 1  # Genre code (1 byte)
    game['slowdown_su'] = struct.unpack_from('<H', data, pos)[0]; pos += 2  # Word (2 bytes)
    game['requires_cd'] = bool(data[pos]); pos += 1
    game['deleted'] = bool(data[pos]); pos += 1
    
    return game

def normalize_title(title):
    """Normalize title for matching"""
    # Remove common suffixes, colons, etc.
    title = title.upper()
    title = title.replace(':', '').replace('-', ' ')
    title = title.replace('  ', ' ').strip()
    return title

def similarity_ratio(a, b):
    """Calculate similarity between two titles"""
    return SequenceMatcher(None, normalize_title(a), normalize_title(b)).ratio()

def pack_mapping_record(game_index, database_id, guid):
    """Pack a LaunchBox mapping record into 48 bytes"""
    record = bytearray(MAP_RECORD_SIZE)
    
    # Word (2 bytes) + LongInt (4 bytes) + String[36] (37 bytes) = 43 bytes + padding
    struct.pack_into('<H', record, 0, game_index)  # Word at offset 0
    struct.pack_into('<i', record, 2, database_id)  # LongInt at offset 2
    
    # Pascal string: length byte + chars
    guid_encoded = guid[:36].encode('cp437', errors='replace')
    record[6] = len(guid_encoded)  # Length byte at offset 6
    record[7:7+len(guid_encoded)] = guid_encoded  # String data at offset 7
    
    return bytes(record)

def unpack_mapping_record(data):
    """Unpack 48 bytes into mapping record"""
    if len(data) != MAP_RECORD_SIZE:
        raise ValueError(f"Mapping record must be exactly {MAP_RECORD_SIZE} bytes")
    
    game_index = struct.unpack_from('<H', data, 0)[0]
    database_id = struct.unpack_from('<i', data, 2)[0]
    
    guid_len = data[6]
    if guid_len > 36:
        guid_len = 36
    guid = data[7:7+guid_len].decode('cp437', errors='replace')
    
    return game_index, database_id, guid

def load_mapping_file(map_path):
    """Load existing LaunchBox mappings"""
    mappings = {}  # database_id -> game_index
    guid_mappings = {}  # guid -> game_index
    
    if not map_path.exists():
        return mappings, guid_mappings
    
    with open(map_path, 'rb') as f:
        data = f.read()
    
    record_count = len(data) // MAP_RECORD_SIZE
    for i in range(record_count):
        offset = i * MAP_RECORD_SIZE
        record_data = data[offset:offset+MAP_RECORD_SIZE]
        
        game_index, database_id, guid = unpack_mapping_record(record_data)
        
        if game_index > 0:  # 0 = unused slot
            if database_id > 0:
                mappings[database_id] = game_index
            if guid:
                guid_mappings[guid] = game_index
    
    return mappings, guid_mappings

def save_mapping_file(map_path, mappings_list):
    """Save LaunchBox mappings to LBMAP.DAT"""
    with open(map_path, 'wb') as f:
        for game_index, database_id, guid in mappings_list:
            record = pack_mapping_record(game_index, database_id, guid)
            f.write(record)

def parse_launchbox_xml(xml_path):
    """Parse LaunchBox XML and return metadata dictionary with IDs"""
    tree = ET.parse(xml_path)
    root = tree.getroot()
    
    metadata = {}
    
    for game in root.findall('.//Game'):
        title_elem = game.find('Title')
        if title_elem is None or not title_elem.text:
            continue
        
        title = title_elem.text.strip()
        
        # Extract IDs
        database_id_elem = game.find('DatabaseID')
        database_id = int(database_id_elem.text) if database_id_elem is not None and database_id_elem.text else 0
        
        id_elem = game.find('Id')
        guid = id_elem.text.strip() if id_elem is not None and id_elem.text else ""
        
        # Extract metadata
        publisher_elem = game.find('Publisher')
        publisher = publisher_elem.text.strip() if publisher_elem is not None and publisher_elem.text else ""
        
        release_elem = game.find('ReleaseDate')
        release_year = ""
        if release_elem is not None and release_elem.text:
            # Extract year from date (format varies: YYYY, YYYY-MM-DD, etc.)
            release_year = release_elem.text.strip()[:4]
        
        genre_elem = game.find('Genre')
        genre = genre_elem.text.strip() if genre_elem is not None and genre_elem.text else ""
        # Some LaunchBox XMLs have multiple genres separated by semicolons
        if ';' in genre:
            genre = genre.split(';')[0].strip()
        
        # Convert genre name to code
        genre_code = genre_name_to_code(genre)
        
        metadata[title] = {
            'publisher': publisher[:30],  # Truncate to fit
            'year': release_year[:4],
            'genre_code': genre_code,
            'database_id': database_id,
            'guid': guid[:36]
        }
    
    return metadata

def import_metadata(games_dat_path, launchbox_xml_path, dry_run=False):
    """Import metadata from LaunchBox XML into GAMES.DAT"""
    
    map_path = games_dat_path.parent / 'LBMAP.DAT'
    
    print(f"Loading LaunchBox XML: {launchbox_xml_path}")
    lb_metadata = parse_launchbox_xml(launchbox_xml_path)
    print(f"Found {len(lb_metadata)} games in LaunchBox XML\n")
    
    print(f"Loading existing mappings: {map_path}")
    existing_mappings, existing_guid_mappings = load_mapping_file(map_path)
    print(f"Found {len(existing_mappings)} existing LaunchBox mappings\n")
    
    print(f"Loading GAMES.DAT: {games_dat_path}")
    
    # Read all records
    with open(games_dat_path, 'rb') as f:
        data = f.read()
    
    if len(data) % RECORD_SIZE != 0:
        print(f"Warning: File size {len(data)} is not a multiple of {RECORD_SIZE}")
    
    record_count = len(data) // RECORD_SIZE
    print(f"Found {record_count} records in GAMES.DAT\n")
    
    # Process each record
    updated_data = bytearray()
    updates = 0
    matches = []
    new_mappings = []
    
    for i in range(record_count):
        offset = i * RECORD_SIZE
        record_data = data[offset:offset+RECORD_SIZE]
        
        game = unpack_game_record(record_data)
        game_index = i + 1  # 1-based index
        
        if game['deleted']:
            updated_data.extend(record_data)
            continue
        
        # Try exact match first using existing mappings
        lb_match = None
        match_type = "fuzzy"
        
        # Check if this game already has a mapping
        for lb_title, lb_data in lb_metadata.items():
            database_id = lb_data.get('database_id', 0)
            guid = lb_data.get('guid', '')
            
            # Try exact match via database ID
            if database_id > 0 and game_index == existing_mappings.get(database_id):
                lb_match = (lb_title, lb_data)
                match_type = "exact (DB ID)"
                break
            
            # Try exact match via GUID
            if guid and game_index == existing_guid_mappings.get(guid):
                lb_match = (lb_title, lb_data)
                match_type = "exact (GUID)"
                break
        
        # Fall back to fuzzy matching if no exact match
        if lb_match is None:
            best_ratio = 0.0
            for lb_title, lb_data in lb_metadata.items():
                ratio = similarity_ratio(game['title'], lb_title)
                if ratio > best_ratio:
                    best_ratio = ratio
                    lb_match = (lb_title, lb_data)
            
            # Only accept fuzzy matches above threshold
            if best_ratio < 0.8:
                lb_match = None
            else:
                match_type = f"fuzzy ({best_ratio:.0%})"
        
        # Update if match found
        if lb_match:
            lb_title, lb_data = lb_match
            
            old_pub = game['publisher']
            old_year = game['year']
            old_genre = game['genre_code']
            
            # Update fields (only if empty)
            if not game['publisher'] or len(game['publisher'].strip()) == 0:
                game['publisher'] = lb_data['publisher']
            if not game['year'] or len(game['year'].strip()) == 0:
                game['year'] = lb_data['year']
            if game['genre_code'] == 0:  # 0 = None/Unknown
                game['genre_code'] = lb_data['genre_code']
            
            # Store mapping for this game
            database_id = lb_data.get('database_id', 0)
            guid = lb_data.get('guid', '')
            if database_id > 0 or guid:
                new_mappings.append((game_index, database_id, guid))
            
            if (game['publisher'] != old_pub or game['year'] != old_year or game['genre_code'] != old_genre):
                updates += 1
                match_info = {
                    'title': game['title'],
                    'lb_title': lb_title,
                    'match_type': match_type,
                    'publisher': f"{old_pub or '(none)'} -> {game['publisher']}",
                    'year': f"{old_year or '(none)'} -> {game['year']}",
                    'genre': f"{genre_code_to_name(old_genre)} -> {genre_code_to_name(game['genre_code'])}"
                }
                matches.append(match_info)
        
        # Pack updated record
        updated_data.extend(pack_game_record(game))
    
    # Display matches
    print("=" * 80)
    print("MATCHED GAMES:")
    print("=" * 80)
    for match in matches:
        print(f"\n{match['title']}")
        if match['title'] != match['lb_title']:
            print(f"  LaunchBox: {match['lb_title']}")
        print(f"  Match:     {match['match_type']}")
        print(f"  Publisher: {match['publisher']}")
        print(f"  Year:      {match['year']}")
        print(f"  Genre:     {match['genre']}")
    
    print(f"\n" + "=" * 80)
    print(f"Summary: {updates} records updated, {len(new_mappings)} mappings created")
    print("=" * 80)
    
    if not dry_run:
        # Backup original
        backup_path = str(games_dat_path) + '.bak'
        print(f"\nCreating backup: {backup_path}")
        with open(backup_path, 'wb') as f:
            f.write(data)
        
        # Write updated file
        print(f"Writing updated GAMES.DAT...")
        with open(games_dat_path, 'wb') as f:
            f.write(updated_data)
        
        # Write mapping file
        if new_mappings:
            print(f"Writing LaunchBox mappings: {map_path}")
            save_mapping_file(map_path, new_mappings)
        
        print("Done!")
    else:
        print("\nDRY RUN - No changes made")

def main():
    if len(sys.argv) < 2:
        print("Usage: python lbimport.py <launchbox.xml> [games.dat]")
        print("\nImports Publisher, Year, and Genre from LaunchBox XML into GAMES.DAT")
        print("Creates GAMES.DAT.BAK backup before modifying")
        sys.exit(1)
    
    xml_path = Path(sys.argv[1])
    if not xml_path.exists():
        print(f"Error: {xml_path} not found")
        sys.exit(1)
    
    dat_path = Path(sys.argv[2] if len(sys.argv) > 2 else 'GAMES.DAT')
    if not dat_path.exists():
        print(f"Error: {dat_path} not found")
        sys.exit(1)
    
    import_metadata(dat_path, xml_path, dry_run=False)

if __name__ == '__main__':
    main()
