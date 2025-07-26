#!/usr/bin/env python3
"""
Development Loop Script for Commander X16 Pac-Man Project

This script establishes an automated development loop that can:
1. Build the project
2. Run the emulator
3. Take screenshots
4. Analyze progress
5. Make code changes based on feedback
6. Repeat the cycle

Usage: python3 development_loop.py
"""

import subprocess
import time
import os
import sys
from datetime import datetime
import signal

class X16DevLoop:
    def __init__(self):
        self.project_dir = "/Users/benjamincooley/projects/pacman_x16"
        self.emulator_process = None
        self.iteration = 0
        
    def build_project(self):
        """Build the project using make"""
        print(f"[{datetime.now().strftime('%H:%M:%S')}] Building project...")
        try:
            result = subprocess.run(['make', 'clean'], 
                                  cwd=self.project_dir, 
                                  capture_output=True, 
                                  text=True)
            result = subprocess.run(['make'], 
                                  cwd=self.project_dir, 
                                  capture_output=True, 
                                  text=True)
            if result.returncode == 0:
                print("✓ Build successful")
                return True
            else:
                print(f"✗ Build failed: {result.stderr}")
                return False
        except Exception as e:
            print(f"✗ Build error: {e}")
            return False
    
    def start_emulator(self):
        """Start the X16 emulator"""
        print(f"[{datetime.now().strftime('%H:%M:%S')}] Starting emulator...")
        try:
            # Kill any existing emulator processes
            subprocess.run(['killall', 'x16emu'], capture_output=True)
            time.sleep(1)
            
            # Start new emulator process
            self.emulator_process = subprocess.Popen([
                'x16emu', '-prg', 'pacman.prg', '-run'
            ], cwd=self.project_dir)
            
            # Give emulator time to start
            time.sleep(3)
            print("✓ Emulator started")
            return True
        except Exception as e:
            print(f"✗ Emulator start error: {e}")
            return False
    
    def take_screenshot(self):
        """Take a screenshot of the current emulator state"""
        timestamp = datetime.now().strftime('%Y-%m-%d-%H-%M-%S')
        screenshot_name = f"iteration_{self.iteration:03d}_{timestamp}.png"
        
        print(f"[{datetime.now().strftime('%H:%M:%S')}] Taking screenshot: {screenshot_name}")
        
        # The emulator automatically saves screenshots, so we just need to wait
        time.sleep(1)
        
        # Find the most recent screenshot
        png_files = [f for f in os.listdir(self.project_dir) if f.endswith('.png')]
        if png_files:
            latest_png = max(png_files, key=lambda x: os.path.getctime(os.path.join(self.project_dir, x)))
            new_name = f"iteration_{self.iteration:03d}_{latest_png}"
            os.rename(os.path.join(self.project_dir, latest_png), 
                     os.path.join(self.project_dir, new_name))
            print(f"✓ Screenshot saved as: {new_name}")
            return new_name
        else:
            print("✗ No screenshot found")
            return None
    
    def stop_emulator(self):
        """Stop the emulator"""
        print(f"[{datetime.now().strftime('%H:%M:%S')}] Stopping emulator...")
        try:
            if self.emulator_process:
                self.emulator_process.terminate()
                self.emulator_process.wait(timeout=5)
            subprocess.run(['killall', 'x16emu'], capture_output=True)
            print("✓ Emulator stopped")
        except Exception as e:
            print(f"✗ Error stopping emulator: {e}")
    
    def analyze_progress(self, screenshot_name):
        """Analyze the current state and determine next steps"""
        print(f"[{datetime.now().strftime('%H:%M:%S')}] Analyzing progress...")
        
        # For now, just log the current state
        # In a full implementation, this would analyze the screenshot
        # and determine what changes need to be made
        
        analysis = {
            'iteration': self.iteration,
            'screenshot': screenshot_name,
            'timestamp': datetime.now().isoformat(),
            'status': 'running',
            'next_action': 'continue_development'
        }
        
        print(f"✓ Analysis complete - Iteration {self.iteration}")
        return analysis
    
    def run_development_cycle(self):
        """Run one complete development cycle"""
        print(f"\n{'='*60}")
        print(f"DEVELOPMENT CYCLE - ITERATION {self.iteration}")
        print(f"{'='*60}")
        
        # Step 1: Build
        if not self.build_project():
            return False
        
        # Step 2: Start emulator
        if not self.start_emulator():
            return False
        
        # Step 3: Let it run for a bit
        print(f"[{datetime.now().strftime('%H:%M:%S')}] Running for 10 seconds...")
        time.sleep(10)
        
        # Step 4: Take screenshot
        screenshot = self.take_screenshot()
        
        # Step 5: Stop emulator
        self.stop_emulator()
        
        # Step 6: Analyze
        analysis = self.analyze_progress(screenshot)
        
        # Step 7: Log results
        self.log_iteration(analysis)
        
        self.iteration += 1
        return True
    
    def log_iteration(self, analysis):
        """Log the results of this iteration"""
        log_file = os.path.join(self.project_dir, "development_log.txt")
        with open(log_file, "a") as f:
            f.write(f"\n--- Iteration {analysis['iteration']} ---\n")
            f.write(f"Timestamp: {analysis['timestamp']}\n")
            f.write(f"Screenshot: {analysis['screenshot']}\n")
            f.write(f"Status: {analysis['status']}\n")
            f.write(f"Next Action: {analysis['next_action']}\n")
    
    def cleanup(self):
        """Clean up resources"""
        self.stop_emulator()
        print("\n✓ Development loop stopped")
    
    def run_loop(self, max_iterations=5):
        """Run the development loop for a specified number of iterations"""
        print("Starting X16 Pac-Man Development Loop")
        print(f"Max iterations: {max_iterations}")
        
        try:
            while self.iteration < max_iterations:
                if not self.run_development_cycle():
                    print("✗ Development cycle failed, stopping")
                    break
                
                if self.iteration < max_iterations:
                    print(f"\nWaiting 5 seconds before next iteration...")
                    time.sleep(5)
            
            print(f"\n✓ Completed {self.iteration} development iterations")
            
        except KeyboardInterrupt:
            print("\n⚠ Interrupted by user")
        finally:
            self.cleanup()

def signal_handler(sig, frame):
    print('\n⚠ Received interrupt signal')
    sys.exit(0)

if __name__ == "__main__":
    signal.signal(signal.SIGINT, signal_handler)
    
    dev_loop = X16DevLoop()
    
    # Run 3 iterations by default
    iterations = 3
    if len(sys.argv) > 1:
        try:
            iterations = int(sys.argv[1])
        except ValueError:
            print("Usage: python3 development_loop.py [iterations]")
            sys.exit(1)
    
    dev_loop.run_loop(iterations)
