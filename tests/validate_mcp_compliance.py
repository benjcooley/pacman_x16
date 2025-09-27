#!/usr/bin/env python3
"""
MCP Compliance Validation Script

This script performs a comprehensive validation of the MCP server's compliance
with the Model Context Protocol specification. It can be used for:

1. Development validation
2. CI/CD pipeline integration  
3. Release verification
4. Debugging protocol issues

Usage:
    python3 tests/validate_mcp_compliance.py [--verbose] [--json-output]
"""

import sys
import json
import subprocess
import time
import argparse
from pathlib import Path
from typing import Dict, List, Any, Optional

def run_validation_tests() -> Dict[str, Any]:
    """Run all MCP compliance validation tests"""
    results = {
        "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
        "tests": {},
        "summary": {
            "total": 0,
            "passed": 0,
            "failed": 0,
            "skipped": 0
        }
    }
    
    # Test 1: Basic functionality
    print("🔍 Validating basic MCP functionality...")
    try:
        result = subprocess.run([
            "python3", "tests/run_mcp_tests.py"
        ], capture_output=True, text=True, timeout=60)
        
        test_result = {
            "name": "Basic MCP Functionality",
            "status": "passed" if result.returncode == 0 else "failed",
            "output": result.stdout,
            "error": result.stderr if result.returncode != 0 else None,
            "duration": "< 60s"
        }
        
        results["tests"]["basic_functionality"] = test_result
        results["summary"]["total"] += 1
        
        if result.returncode == 0:
            results["summary"]["passed"] += 1
            print("  ✅ Basic functionality tests passed")
        else:
            results["summary"]["failed"] += 1
            print("  ❌ Basic functionality tests failed")
            
    except subprocess.TimeoutExpired:
        results["tests"]["basic_functionality"] = {
            "name": "Basic MCP Functionality",
            "status": "failed",
            "error": "Test timeout after 60 seconds",
            "duration": "> 60s"
        }
        results["summary"]["total"] += 1
        results["summary"]["failed"] += 1
        print("  ❌ Basic functionality tests timed out")
    except Exception as e:
        results["tests"]["basic_functionality"] = {
            "name": "Basic MCP Functionality", 
            "status": "failed",
            "error": str(e),
            "duration": "unknown"
        }
        results["summary"]["total"] += 1
        results["summary"]["failed"] += 1
        print(f"  ❌ Basic functionality tests crashed: {e}")
    
    # Test 2: Protocol compliance (if dependencies available)
    print("🔍 Validating protocol compliance...")
    try:
        # Check if dependencies are available
        dep_check = subprocess.run([
            "python3", "-c", "import requests, jsonschema"
        ], capture_output=True)
        
        if dep_check.returncode == 0:
            result = subprocess.run([
                "python3", "tests/mcp_protocol_tests.py"
            ], capture_output=True, text=True, timeout=120)
            
            test_result = {
                "name": "Protocol Compliance",
                "status": "passed" if result.returncode == 0 else "failed",
                "output": result.stdout,
                "error": result.stderr if result.returncode != 0 else None,
                "duration": "< 120s"
            }
            
            results["tests"]["protocol_compliance"] = test_result
            results["summary"]["total"] += 1
            
            if result.returncode == 0:
                results["summary"]["passed"] += 1
                print("  ✅ Protocol compliance tests passed")
            else:
                results["summary"]["failed"] += 1
                print("  ❌ Protocol compliance tests failed")
        else:
            results["tests"]["protocol_compliance"] = {
                "name": "Protocol Compliance",
                "status": "skipped",
                "error": "Missing dependencies: requests, jsonschema",
                "duration": "0s"
            }
            results["summary"]["total"] += 1
            results["summary"]["skipped"] += 1
            print("  ⏭️  Protocol compliance tests skipped (missing dependencies)")
            
    except subprocess.TimeoutExpired:
        results["tests"]["protocol_compliance"] = {
            "name": "Protocol Compliance",
            "status": "failed",
            "error": "Test timeout after 120 seconds",
            "duration": "> 120s"
        }
        results["summary"]["total"] += 1
        results["summary"]["failed"] += 1
        print("  ❌ Protocol compliance tests timed out")
    except Exception as e:
        results["tests"]["protocol_compliance"] = {
            "name": "Protocol Compliance",
            "status": "failed", 
            "error": str(e),
            "duration": "unknown"
        }
        results["summary"]["total"] += 1
        results["summary"]["failed"] += 1
        print(f"  ❌ Protocol compliance tests crashed: {e}")
    
    # Test 3: Schema validation
    print("🔍 Validating schema definitions...")
    try:
        result = subprocess.run([
            "python3", "-c", 
            """
import sys
sys.path.append('tests')
from mcp_schema_validator import MCPSchemaValidator

validator = MCPSchemaValidator()

# Test sample responses
sample_init = {
    "jsonrpc": "2.0",
    "id": 1,
    "result": {
        "protocolVersion": "2024-11-05",
        "capabilities": {"tools": {}, "resources": {}},
        "serverInfo": {"name": "x16-emulator-mcp", "version": "1.0.0"}
    }
}

is_valid, error = validator.validate_response(sample_init, "initialize_response")
if not is_valid:
    print(f"Schema validation failed: {error}")
    sys.exit(1)
    
print("Schema validation passed")
"""
        ], capture_output=True, text=True, timeout=30)
        
        test_result = {
            "name": "Schema Validation",
            "status": "passed" if result.returncode == 0 else "failed",
            "output": result.stdout,
            "error": result.stderr if result.returncode != 0 else None,
            "duration": "< 30s"
        }
        
        results["tests"]["schema_validation"] = test_result
        results["summary"]["total"] += 1
        
        if result.returncode == 0:
            results["summary"]["passed"] += 1
            print("  ✅ Schema validation passed")
        else:
            results["summary"]["failed"] += 1
            print("  ❌ Schema validation failed")
            
    except Exception as e:
        results["tests"]["schema_validation"] = {
            "name": "Schema Validation",
            "status": "failed",
            "error": str(e),
            "duration": "unknown"
        }
        results["summary"]["total"] += 1
        results["summary"]["failed"] += 1
        print(f"  ❌ Schema validation crashed: {e}")
    
    return results

def print_summary_report(results: Dict[str, Any], verbose: bool = False):
    """Print a human-readable summary report"""
    print("\n" + "="*60)
    print("🧪 MCP COMPLIANCE VALIDATION REPORT")
    print("="*60)
    
    summary = results["summary"]
    print(f"📊 Test Summary:")
    print(f"   Total Tests: {summary['total']}")
    print(f"   ✅ Passed:   {summary['passed']}")
    print(f"   ❌ Failed:   {summary['failed']}")
    print(f"   ⏭️  Skipped:  {summary['skipped']}")
    
    success_rate = (summary['passed'] / summary['total'] * 100) if summary['total'] > 0 else 0
    print(f"   📈 Success Rate: {success_rate:.1f}%")
    
    print(f"\n🕐 Timestamp: {results['timestamp']}")
    
    if verbose:
        print(f"\n📋 Detailed Results:")
        for test_id, test_data in results["tests"].items():
            status_emoji = {
                "passed": "✅",
                "failed": "❌", 
                "skipped": "⏭️"
            }.get(test_data["status"], "❓")
            
            print(f"\n{status_emoji} {test_data['name']}")
            print(f"   Status: {test_data['status']}")
            print(f"   Duration: {test_data.get('duration', 'unknown')}")
            
            if test_data.get('error'):
                print(f"   Error: {test_data['error']}")
            
            if verbose and test_data.get('output'):
                print(f"   Output: {test_data['output'][:200]}...")
    
    # Overall result
    if summary['failed'] == 0:
        print(f"\n🎉 OVERALL RESULT: PASS")
        print("   All MCP compliance tests passed successfully!")
    else:
        print(f"\n💥 OVERALL RESULT: FAIL") 
        print(f"   {summary['failed']} test(s) failed. Please review the errors above.")
    
    print("="*60)

def main():
    """Main validation script"""
    parser = argparse.ArgumentParser(description="MCP Protocol Compliance Validator")
    parser.add_argument("--verbose", "-v", action="store_true", 
                       help="Show detailed test output")
    parser.add_argument("--json-output", "-j", action="store_true",
                       help="Output results as JSON")
    
    args = parser.parse_args()
    
    # Check if we're in the right directory
    if not Path("Makefile").exists():
        print("❌ Error: Please run this script from the project root directory")
        return 1
    
    # Check if MCP binary exists
    if not Path("bin/mcp").exists():
        print("❌ Error: MCP server binary not found at bin/mcp")
        print("   Please build the project first with: make emulator")
        return 1
    
    print("🚀 Starting MCP Protocol Compliance Validation")
    print("="*50)
    
    # Run validation tests
    results = run_validation_tests()
    
    # Output results
    if args.json_output:
        print(json.dumps(results, indent=2))
    else:
        print_summary_report(results, verbose=args.verbose)
    
    # Return exit code based on results
    return 0 if results["summary"]["failed"] == 0 else 1

if __name__ == "__main__":
    sys.exit(main())











