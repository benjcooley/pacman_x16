#!/usr/bin/env python3
"""
AI Development Tool for Commander X16 Pac-Man
==============================================

This tool is designed specifically for AI-driven development, providing:
1. Reliable screenshot capture with timestamped preservation
2. Emulator log capture and analysis
3. Structured output for AI analysis
4. Persistent diagnostic data
"""

import subprocess
import time
import json
import os
import sys
from datetime import datetime
from pathlib import Path

class X16DevTool:
    def __init__(self, project_dir="."):
        self.project_dir = Path(project_dir)
        self.screenshots_dir = self.project_dir / "dev_screenshots"
        self.logs_dir = self.project_dir / "dev_logs"
        self.session_id = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        # Create directories
        self.screenshots_dir.mkdir(exist_ok=True)
        self.logs_dir.mkdir(exist_ok=True)
        
        print(f"🔧 AI Development Tool - Session {self.session_id}")
        print(f"📁 Screenshots: {self.screenshots_dir}")
        print(f"📁 Logs: {self.logs_dir}")

    def build_project(self, game="pacman"):
        """Build the project and capture build output"""
        print(f"\n🔨 Building {game}...")
        
        build_log = {
            "timestamp": datetime.now().isoformat(),
            "command": f"make GAME={game}",
            "success": False,
            "output": "",
            "errors": ""
        }
        
        try:
            result = subprocess.run(
                ["make", f"GAME={game}"], 
                cwd=self.project_dir,
                capture_output=True, 
                text=True, 
                timeout=30
            )
            
            build_log["output"] = result.stdout
            build_log["errors"] = result.stderr
            build_log["return_code"] = result.returncode
            build_log["success"] = result.returncode == 0
            
            if build_log["success"]:
                print("✅ Build successful")
            else:
                print("❌ Build failed")
                print(f"Error: {result.stderr}")
                
        except subprocess.TimeoutExpired:
            build_log["errors"] = "Build timeout after 30 seconds"
            print("⏰ Build timeout")
        except Exception as e:
            build_log["errors"] = str(e)
            print(f"💥 Build error: {e}")
        
        # Save build log
        log_file = self.logs_dir / f"build_{self.session_id}.json"
        with open(log_file, 'w') as f:
            json.dump(build_log, f, indent=2)
            
        return build_log["success"]

    def run_emulator_with_capture(self, program="pacman.prg", duration=10):
        """Run emulator and capture screenshots + logs using built-in GIF recording"""
        print(f"\n🎮 Running emulator with {program} for {duration} seconds...")
        
        session_data = {
            "session_id": self.session_id,
            "timestamp": datetime.now().isoformat(),
            "program": program,
            "duration": duration,
            "screenshots": [],
            "gif_recording": None,
            "emulator_output": "",
            "emulator_stderr": "",
            "status": "unknown",
            "program_exists": False,
            "emulator_pid": None
        }
        
        # Check if program file exists
        program_path = self.project_dir / program
        session_data["program_exists"] = program_path.exists()
        if not session_data["program_exists"]:
            session_data["status"] = "program_not_found"
            print(f"❌ Program file not found: {program_path}")
            return session_data
        
        print(f"✅ Program file found: {program_path} ({program_path.stat().st_size} bytes)")
        
        # Create GIF recording filename
        gif_filename = f"recording_{self.session_id}.gif"
        gif_path = self.screenshots_dir / gif_filename
        
        # Start emulator with GIF recording
        emulator_cmd = ["x16emu", "-prg", program, "-run", "-gif", str(gif_path)]
        session_data["gif_recording"] = str(gif_path)
        
        try:
            print("🚀 Starting emulator...")
            print(f"Command: {' '.join(emulator_cmd)}")
            
            emulator_process = subprocess.Popen(
                emulator_cmd,
                cwd=self.project_dir,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            
            session_data["emulator_pid"] = emulator_process.pid
            print(f"📍 Emulator PID: {emulator_process.pid}")
            
            # Wait for emulator to start and window to appear
            time.sleep(5)
            
            # Check if emulator is still running
            if emulator_process.poll() is not None:
                # Emulator has already exited
                stdout, stderr = emulator_process.communicate()
                session_data["emulator_output"] = stdout
                session_data["emulator_stderr"] = stderr
                session_data["status"] = "emulator_exited_early"
                print(f"❌ Emulator exited early with code {emulator_process.returncode}")
                print(f"STDOUT: {stdout}")
                print(f"STDERR: {stderr}")
                return session_data
            
            print("✅ Emulator appears to be running")
            
            # Try to bring emulator window to front (macOS specific)
            try:
                subprocess.run(["osascript", "-e", 'tell application "x16emu" to activate'], 
                             timeout=2, capture_output=True)
            except:
                pass  # Ignore if this fails
            
            # Capture screenshots at intervals
            screenshot_times = [1, 3, 5, 8, 10]  # Seconds after start
            
            for i, capture_time in enumerate(screenshot_times):
                if capture_time <= duration:
                    time.sleep(capture_time - (screenshot_times[i-1] if i > 0 else 0))
                    screenshot_file = self.capture_screenshot(f"step_{i+1}")
                    if screenshot_file:
                        session_data["screenshots"].append({
                            "time": capture_time,
                            "file": str(screenshot_file),
                            "step": i+1
                        })
            
            # Wait for remaining time
            remaining_time = duration - max(screenshot_times)
            if remaining_time > 0:
                time.sleep(remaining_time)
            
            # Try to get emulator output
            try:
                emulator_output, _ = emulator_process.communicate(timeout=2)
                session_data["emulator_output"] = emulator_output
            except subprocess.TimeoutExpired:
                session_data["emulator_output"] = "Emulator still running (timeout)"
            
            # Kill emulator
            try:
                subprocess.run(["pkill", "x16emu"], timeout=5)
                session_data["status"] = "completed"
                print("✅ Emulator session completed")
                
                # Announce GIF recording completion
                if session_data.get("gif_recording") and Path(session_data["gif_recording"]).exists():
                    gif_size = Path(session_data["gif_recording"]).stat().st_size
                    print(f"\n🎬 GIF RECORDING EXPORTED:")
                    print(f"   📁 File: {session_data['gif_recording']}")
                    print(f"   📏 Size: {gif_size:,} bytes ({gif_size/1024/1024:.1f} MB)")
                    print(f"   🤖 LLM VIEWING INSTRUCTIONS:")
                    print(f"      Use: browser_action -> launch -> file://{os.path.abspath(session_data['gif_recording'])}")
                    print(f"      This shows exactly what the emulator displayed during execution")
                
            except:
                session_data["status"] = "force_killed"
                print("⚠️ Emulator force killed")
                
        except Exception as e:
            session_data["status"] = "error"
            session_data["error"] = str(e)
            print(f"💥 Emulator error: {e}")
            
            # Try to kill emulator anyway
            try:
                subprocess.run(["pkill", "x16emu"], timeout=5)
            except:
                pass
        
        # Save session data
        session_file = self.logs_dir / f"session_{self.session_id}.json"
        with open(session_file, 'w') as f:
            json.dump(session_data, f, indent=2)
        
        return session_data

    def capture_screenshot(self, label=""):
        """Capture a screenshot with timestamp"""
        timestamp = datetime.now().strftime("%H%M%S")
        filename = f"screenshot_{self.session_id}_{timestamp}"
        if label:
            filename += f"_{label}"
        filename += ".png"
        
        screenshot_path = self.screenshots_dir / filename
        
        try:
            # Use system screencapture to capture the entire screen
            # This is more reliable than trying to send keystrokes to specific processes
            subprocess.run([
                "screencapture", "-x", str(screenshot_path)
            ], timeout=10, check=True)
            
            print(f"📸 Screenshot saved: {filename}")
            return screenshot_path
            
        except Exception as e:
            print(f"📸 Screenshot failed: {e}")
            return None

    def analyze_session(self, session_data):
        """Analyze the captured session data"""
        print(f"\n🔍 Analyzing session {session_data['session_id']}...")
        
        analysis = {
            "session_id": session_data["session_id"],
            "timestamp": datetime.now().isoformat(),
            "program_status": "unknown",
            "screenshots_captured": len(session_data["screenshots"]),
            "issues_detected": [],
            "recommendations": []
        }
        
        # Check if screenshots were captured
        if len(session_data["screenshots"]) == 0:
            analysis["issues_detected"].append("No screenshots captured")
            analysis["recommendations"].append("Check screencapture permissions")
        
        # Check emulator status
        if session_data["status"] == "error":
            analysis["issues_detected"].append(f"Emulator error: {session_data.get('error', 'Unknown')}")
            analysis["recommendations"].append("Check emulator installation and program file")
        
        # Analyze emulator output
        emulator_output = session_data.get("emulator_output", "")
        if "error" in emulator_output.lower():
            analysis["issues_detected"].append("Emulator reported errors")
        
        # Basic screenshot analysis
        for screenshot in session_data["screenshots"]:
            screenshot_path = Path(screenshot["file"])
            if screenshot_path.exists():
                file_size = screenshot_path.stat().st_size
                if file_size < 1000:  # Very small file, likely empty
                    analysis["issues_detected"].append(f"Screenshot {screenshot['step']} is unusually small")
                elif file_size > 20_000_000:  # Very large file
                    analysis["issues_detected"].append(f"Screenshot {screenshot['step']} is unusually large")
        
        # Save analysis
        analysis_file = self.logs_dir / f"analysis_{self.session_id}.json"
        with open(analysis_file, 'w') as f:
            json.dump(analysis, f, indent=2)
        
        # Print summary
        print(f"📊 Analysis Summary:")
        print(f"   Screenshots: {analysis['screenshots_captured']}")
        print(f"   Issues: {len(analysis['issues_detected'])}")
        
        for issue in analysis["issues_detected"]:
            print(f"   ⚠️ {issue}")
        
        for rec in analysis["recommendations"]:
            print(f"   💡 {rec}")
        
        return analysis

    def run_full_diagnostic(self, game="pacman", duration=10):
        """Run complete build + test + analysis cycle"""
        print(f"\n🚀 Starting full diagnostic for {game}")
        print("=" * 60)
        
        # Step 1: Build
        build_success = self.build_project(game)
        if not build_success:
            print("❌ Build failed - stopping diagnostic")
            return False
        
        # Step 2: Run and capture
        session_data = self.run_emulator_with_capture(f"{game}.prg", duration)
        
        # Step 3: Analyze
        analysis = self.analyze_session(session_data)
        
        # Step 4: Summary
        print(f"\n📋 Diagnostic Summary for Session {self.session_id}")
        print("=" * 60)
        print(f"Build: {'✅ Success' if build_success else '❌ Failed'}")
        print(f"Emulator: {session_data['status']}")
        print(f"Screenshots: {len(session_data['screenshots'])}")
        print(f"Issues: {len(analysis['issues_detected'])}")
        
        # List screenshot files for AI analysis
        print(f"\n📁 Files for AI Analysis:")
        for screenshot in session_data["screenshots"]:
            print(f"   📸 {screenshot['file']} (step {screenshot['step']}, t={screenshot['time']}s)")
        
        # Show GIF recording if available
        if session_data.get("gif_recording"):
            print(f"   🎬 {session_data['gif_recording']} (emulator recording)")
            print(f"   💡 To view GIF: open {session_data['gif_recording']}")
            print(f"   💡 For LLM analysis: Use browser_action to launch file://{os.path.abspath(session_data['gif_recording'])}")
        
        print(f"   📄 {self.logs_dir}/session_{self.session_id}.json")
        print(f"   📄 {self.logs_dir}/analysis_{self.session_id}.json")
        print(f"   📄 {self.logs_dir}/build_{self.session_id}.json")
        
        print(f"\n🤖 LLM Instructions:")
        print(f"   To analyze emulator output, use:")
        print(f"   browser_action -> launch -> file://{os.path.abspath(self.project_dir)}/[filename]")
        print(f"   This will show you exactly what the emulator displayed")
        
        return True

def main():
    if len(sys.argv) > 1:
        duration = int(sys.argv[1])
    else:
        duration = 10
    
    tool = X16DevTool()
    tool.run_full_diagnostic(duration=duration)

if __name__ == "__main__":
    main()
