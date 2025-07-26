#!/usr/bin/env python3
"""
Comparison Analyzer for Commander X16 Pac-Man Project

This script analyzes the C reference implementation (pacman.c) and compares it
with the current X16 assembly implementation to identify differences and guide
development priorities.

Usage: python3 comparison_analyzer.py
"""

import re
import os
from datetime import datetime

class PacmanComparisonAnalyzer:
    def __init__(self):
        self.project_dir = "/Users/benjamincooley/projects/pacman_x16"
        self.c_reference_path = os.path.join(self.project_dir, "reference/pacman.c")
        self.x16_asm_path = os.path.join(self.project_dir, "pacman_x16.asm")
        
    def analyze_c_reference(self):
        """Analyze the C reference implementation to extract key components"""
        print("Analyzing C reference implementation...")
        
        with open(self.c_reference_path, 'r') as f:
            c_code = f.read()
        
        analysis = {
            'data_structures': [],
            'game_states': [],
            'key_functions': [],
            'constants': [],
            'graphics_system': [],
            'audio_system': [],
            'game_logic': []
        }
        
        # Extract data structures
        struct_matches = re.findall(r'typedef struct\s*{[^}]+}\s*(\w+);', c_code, re.DOTALL)
        analysis['data_structures'] = struct_matches
        
        # Extract enums (game states, directions, etc.)
        enum_matches = re.findall(r'typedef enum\s*{[^}]+}\s*(\w+);', c_code, re.DOTALL)
        analysis['game_states'] = enum_matches
        
        # Extract key function definitions
        func_matches = re.findall(r'static\s+\w+\s+(\w+)\([^)]*\)\s*{', c_code)
        analysis['key_functions'] = func_matches[:20]  # First 20 functions
        
        # Extract important constants
        const_matches = re.findall(r'#define\s+(\w+)\s+\([^)]+\)', c_code)
        analysis['constants'] = const_matches[:15]  # First 15 constants
        
        # Look for graphics-related code
        gfx_functions = [f for f in func_matches if 'gfx' in f.lower() or 'draw' in f.lower() or 'render' in f.lower()]
        analysis['graphics_system'] = gfx_functions
        
        # Look for audio-related code
        audio_functions = [f for f in func_matches if 'snd' in f.lower() or 'audio' in f.lower() or 'sound' in f.lower()]
        analysis['audio_system'] = audio_functions
        
        # Look for game logic functions
        game_functions = [f for f in func_matches if 'game' in f.lower() or 'pacman' in f.lower() or 'ghost' in f.lower()]
        analysis['game_logic'] = game_functions
        
        return analysis
    
    def analyze_x16_implementation(self):
        """Analyze the current X16 assembly implementation"""
        print("Analyzing X16 assembly implementation...")
        
        with open(self.x16_asm_path, 'r') as f:
            asm_code = f.read()
        
        analysis = {
            'implemented_features': [],
            'missing_features': [],
            'current_state': 'basic_demo',
            'has_graphics': False,
            'has_audio': False,
            'has_game_logic': False,
            'labels': [],
            'constants': []
        }
        
        # Extract labels (function equivalents)
        label_matches = re.findall(r'^(\w+):(?:\s*;.*)?$', asm_code, re.MULTILINE)
        analysis['labels'] = label_matches
        
        # Extract constants
        const_matches = re.findall(r'^(\w+)\s*=\s*\$[0-9A-Fa-f]+', asm_code, re.MULTILINE)
        analysis['constants'] = const_matches
        
        # Check for implemented features
        if 'VERA' in asm_code:
            analysis['implemented_features'].append('VERA register access')
        if 'chrout' in asm_code:
            analysis['implemented_features'].append('Text output')
        if 'border' in asm_code.lower():
            analysis['implemented_features'].append('Border color changes')
        if 'sprite' in asm_code.lower():
            analysis['has_graphics'] = True
            analysis['implemented_features'].append('Sprite support')
        if 'tilemap' in asm_code.lower():
            analysis['has_graphics'] = True
            analysis['implemented_features'].append('Tilemap support')
        
        # Determine current state
        if 'infinite_loop' in asm_code:
            analysis['current_state'] = 'basic_demo'
        elif len(analysis['implemented_features']) > 3:
            analysis['current_state'] = 'advanced_demo'
        
        return analysis
    
    def compare_implementations(self, c_analysis, x16_analysis):
        """Compare the C reference with X16 implementation"""
        print("Comparing implementations...")
        
        comparison = {
            'completion_percentage': 0,
            'priority_tasks': [],
            'missing_critical_features': [],
            'implementation_gaps': [],
            'next_development_steps': []
        }
        
        # Calculate rough completion percentage
        total_c_features = (len(c_analysis['key_functions']) + 
                           len(c_analysis['graphics_system']) + 
                           len(c_analysis['audio_system']) + 
                           len(c_analysis['game_logic']))
        
        implemented_features = len(x16_analysis['implemented_features'])
        completion_percentage = min(100, (implemented_features / max(total_c_features, 1)) * 100)
        comparison['completion_percentage'] = completion_percentage
        
        # Identify missing critical features
        if not x16_analysis['has_graphics']:
            comparison['missing_critical_features'].append('Graphics system (VERA tilemap/sprites)')
        if not x16_analysis['has_audio']:
            comparison['missing_critical_features'].append('Audio system')
        if not x16_analysis['has_game_logic']:
            comparison['missing_critical_features'].append('Game logic (Pacman movement, ghosts)')
        
        # Priority tasks based on C reference
        if 'gfx_init' in c_analysis['key_functions']:
            comparison['priority_tasks'].append('Implement VERA graphics initialization')
        if 'game_init' in c_analysis['key_functions']:
            comparison['priority_tasks'].append('Implement game state initialization')
        if 'game_tick' in c_analysis['key_functions']:
            comparison['priority_tasks'].append('Implement main game loop')
        
        # Next development steps
        if x16_analysis['current_state'] == 'basic_demo':
            comparison['next_development_steps'] = [
                'Replace infinite loop with proper game initialization',
                'Implement VERA graphics setup',
                'Add tilemap rendering',
                'Implement sprite system',
                'Add basic Pacman movement'
            ]
        
        return comparison
    
    def generate_development_roadmap(self, c_analysis, x16_analysis, comparison):
        """Generate a detailed development roadmap"""
        roadmap = {
            'immediate_tasks': [],
            'short_term_goals': [],
            'medium_term_goals': [],
            'long_term_goals': [],
            'code_snippets_needed': []
        }
        
        # Immediate tasks (next 1-2 development cycles)
        if comparison['completion_percentage'] < 10:
            roadmap['immediate_tasks'] = [
                'Remove infinite loop and implement proper initialization',
                'Set up VERA for tilemap mode',
                'Create basic tile data structure',
                'Implement simple maze rendering'
            ]
        
        # Short-term goals (next week)
        roadmap['short_term_goals'] = [
            'Complete graphics system implementation',
            'Add sprite rendering capability',
            'Implement basic Pacman character',
            'Add keyboard input handling'
        ]
        
        # Medium-term goals (next month)
        roadmap['medium_term_goals'] = [
            'Implement ghost AI system',
            'Add collision detection',
            'Implement dot eating mechanics',
            'Add score system'
        ]
        
        # Long-term goals (full game)
        roadmap['long_term_goals'] = [
            'Complete audio system',
            'Add all game levels',
            'Implement attract mode',
            'Add high score system',
            'Optimize performance'
        ]
        
        # Code snippets that need to be created
        roadmap['code_snippets_needed'] = [
            'VERA initialization routine',
            'Tilemap upload routine',
            'Sprite positioning code',
            'Input handling routine',
            'Game state management'
        ]
        
        return roadmap
    
    def create_comparison_report(self):
        """Create a comprehensive comparison report"""
        print("Creating comparison report...")
        
        c_analysis = self.analyze_c_reference()
        x16_analysis = self.analyze_x16_implementation()
        comparison = self.compare_implementations(c_analysis, x16_analysis)
        roadmap = self.generate_development_roadmap(c_analysis, x16_analysis, comparison)
        
        report = {
            'timestamp': datetime.now().isoformat(),
            'c_reference_analysis': c_analysis,
            'x16_implementation_analysis': x16_analysis,
            'comparison': comparison,
            'development_roadmap': roadmap
        }
        
        return report
    
    def save_report(self, report):
        """Save the comparison report to files"""
        # Save JSON report
        import json
        json_path = os.path.join(self.project_dir, "comparison_report.json")
        with open(json_path, 'w') as f:
            json.dump(report, f, indent=2)
        
        # Save human-readable report
        text_path = os.path.join(self.project_dir, "comparison_report.txt")
        with open(text_path, 'w') as f:
            f.write("PAC-MAN X16 DEVELOPMENT COMPARISON REPORT\n")
            f.write("=" * 50 + "\n\n")
            f.write(f"Generated: {report['timestamp']}\n\n")
            
            f.write("COMPLETION STATUS:\n")
            f.write(f"Overall Progress: {report['comparison']['completion_percentage']:.1f}%\n\n")
            
            f.write("C REFERENCE ANALYSIS:\n")
            f.write(f"Data Structures: {len(report['c_reference_analysis']['data_structures'])}\n")
            f.write(f"Key Functions: {len(report['c_reference_analysis']['key_functions'])}\n")
            f.write(f"Graphics Functions: {len(report['c_reference_analysis']['graphics_system'])}\n")
            f.write(f"Audio Functions: {len(report['c_reference_analysis']['audio_system'])}\n\n")
            
            f.write("X16 IMPLEMENTATION STATUS:\n")
            f.write(f"Current State: {report['x16_implementation_analysis']['current_state']}\n")
            f.write(f"Implemented Features: {len(report['x16_implementation_analysis']['implemented_features'])}\n")
            for feature in report['x16_implementation_analysis']['implemented_features']:
                f.write(f"  - {feature}\n")
            f.write("\n")
            
            f.write("MISSING CRITICAL FEATURES:\n")
            for feature in report['comparison']['missing_critical_features']:
                f.write(f"  - {feature}\n")
            f.write("\n")
            
            f.write("IMMEDIATE TASKS:\n")
            for task in report['development_roadmap']['immediate_tasks']:
                f.write(f"  1. {task}\n")
            f.write("\n")
            
            f.write("NEXT DEVELOPMENT STEPS:\n")
            for i, step in enumerate(report['comparison']['next_development_steps'], 1):
                f.write(f"  {i}. {step}\n")
        
        print(f"Reports saved to:")
        print(f"  - {json_path}")
        print(f"  - {text_path}")
    
    def run_analysis(self):
        """Run the complete comparison analysis"""
        print("Starting Pac-Man C vs X16 Comparison Analysis")
        print("=" * 50)
        
        try:
            report = self.create_comparison_report()
            self.save_report(report)
            
            print(f"\nANALYSIS COMPLETE!")
            print(f"Completion: {report['comparison']['completion_percentage']:.1f}%")
            print(f"Missing Critical Features: {len(report['comparison']['missing_critical_features'])}")
            print(f"Immediate Tasks: {len(report['development_roadmap']['immediate_tasks'])}")
            
            return report
            
        except Exception as e:
            print(f"Error during analysis: {e}")
            return None

if __name__ == "__main__":
    analyzer = PacmanComparisonAnalyzer()
    report = analyzer.run_analysis()
    
    if report:
        print("\n" + "=" * 50)
        print("KEY FINDINGS:")
        print("=" * 50)
        
        print("\nIMMEDIATE PRIORITIES:")
        for task in report['development_roadmap']['immediate_tasks'][:3]:
            print(f"  • {task}")
        
        print(f"\nCOMPLETION STATUS: {report['comparison']['completion_percentage']:.1f}%")
        
        if report['comparison']['missing_critical_features']:
            print("\nCRITICAL GAPS:")
            for gap in report['comparison']['missing_critical_features']:
                print(f"  ⚠ {gap}")
