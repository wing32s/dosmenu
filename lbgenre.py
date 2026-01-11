#!/usr/bin/env python3
"""
Genre name to code mapping for LaunchBox import
Matches LaunchBox genre names to DOS launcher genre codes
"""

GENRE_MAP = {
    '(None)': 0,
    'Action': 1,
    'Adventure': 2,
    "Beat 'em Up": 3,
    'Board Game': 4,
    'Casino': 5,
    'Compilation': 6,
    'Construction and Management Simulation': 7,
    'Education': 8,
    'Fighting': 9,
    'Flight Simulator': 10,
    'Horror': 11,
    'Life Simulation': 12,
    'MMO': 13,
    'Music': 14,
    'Party': 15,
    'Pinball': 16,
    'Platform': 17,
    'Puzzle': 18,
    'Quiz': 19,
    'Racing': 20,
    'Role-Playing': 21,
    'Sandbox': 22,
    'Shooter': 23,
    'Sports': 24,
    'Stealth': 25,
    'Strategy': 26,
    'Vehicle Simulation': 27,
    'Visual Novel': 28
}

def genre_name_to_code(name):
    """Convert genre name to code with fuzzy matching"""
    if not name:
        return 0
    
    # Try exact match first
    if name in GENRE_MAP:
        return GENRE_MAP[name]
    
    # Try case-insensitive match
    name_upper = name.upper()
    for genre_name, code in GENRE_MAP.items():
        if genre_name.upper() == name_upper:
            return code
    
    # Fuzzy matching for common variations
    if 'ACTION' in name_upper:
        return 1
    elif 'ADVENTURE' in name_upper:
        return 2
    elif 'BEAT' in name_upper or 'BRAWL' in name_upper:
        return 3
    elif 'BOARD' in name_upper:
        return 4
    elif 'CASINO' in name_upper:
        return 5
    elif 'COMPILATION' in name_upper:
        return 6
    elif 'CONSTRUCTION' in name_upper or 'MANAGEMENT' in name_upper or 'BUILDING' in name_upper:
        return 7
    elif 'EDUCATION' in name_upper or 'LEARNING' in name_upper:
        return 8
    elif 'FIGHTING' in name_upper:
        return 9
    elif 'FLIGHT' in name_upper:
        return 10
    elif 'HORROR' in name_upper:
        return 11
    elif 'LIFE' in name_upper and 'SIM' in name_upper:
        return 12
    elif 'MMO' in name_upper or 'ONLINE' in name_upper:
        return 13
    elif 'MUSIC' in name_upper or 'RHYTHM' in name_upper:
        return 14
    elif 'PARTY' in name_upper:
        return 15
    elif 'PINBALL' in name_upper:
        return 16
    elif 'PLATFORM' in name_upper or 'PLATFORMER' in name_upper:
        return 17
    elif 'PUZZLE' in name_upper:
        return 18
    elif 'QUIZ' in name_upper or 'TRIVIA' in name_upper:
        return 19
    elif 'RACING' in name_upper or 'DRIVING' in name_upper:
        return 20
    elif 'ROLE' in name_upper or 'RPG' in name_upper:
        return 21
    elif 'SANDBOX' in name_upper:
        return 22
    elif 'SHOOT' in name_upper or 'FPS' in name_upper or 'SHMUP' in name_upper:
        return 23
    elif 'SPORT' in name_upper:
        return 24
    elif 'STEALTH' in name_upper:
        return 25
    elif 'STRATEG' in name_upper:
        return 26
    elif 'VEHICLE' in name_upper and 'SIM' in name_upper:
        return 27
    elif 'VISUAL' in name_upper and 'NOVEL' in name_upper:
        return 28
    
    return 0  # Unknown

def genre_code_to_name(code):
    """Convert genre code to name"""
    for name, c in GENRE_MAP.items():
        if c == code:
            return name
    return '(None)'
