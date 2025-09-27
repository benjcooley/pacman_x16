#!/usr/bin/env python3
"""
MCP Test Runner

Simple test runner for MCP protocol compliance tests.
This script can be run independently or integrated into CI/CD pipelines.
"""

import os
import sys
import subprocess
import json
import time
import signal
from pathlib import Path

def find_mcp_binary():
    """Find the MCP server binary"""
    possible_paths = [
        "bin/mcp",
        "emulator/mcp",
        "./mcp"
    ]
    
    for path in possible_paths:
        if os.path.exists(path) and os.access(path, os.X_OK):
            return path
    
    return None

def test_mcp_basic_functionality():
    """Test basic MCP functionality without external dependencies"""
    mcp_binary = find_mcp_binary()
    if not mcp_binary:
        print("❌ MCP binary not found. Please build the project first.")
        return False
    
    print(f"✓ Found MCP binary at: {mcp_binary}")
    
    # Test 1: Binary execution
    try:
        # Start the MCP server process
        env = os.environ.copy()
        env.update({
            'X16_PORT': '9091',  # Use different port for testing
            'X16_LOG_LEVEL': 'INFO',
            'X16_DEBUG': '1'
        })
        
        print("🧪 Starting MCP server...")
        process = subprocess.Popen(
            [mcp_binary],
            env=env,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        
        # Give it time to start
        time.sleep(1)
        
        # Check if process is still running
        if process.poll() is not None:
            stdout, stderr = process.communicate()
            print(f"❌ MCP server failed to start")
            print(f"Stdout: {stdout}")
            print(f"Stderr: {stderr}")
            return False
        
        print("✓ MCP server started successfully")
        
        # Test 2: JSON-RPC communication
        print("🧪 Testing JSON-RPC communication...")
        
        # Send initialize request
        init_request = {
            "jsonrpc": "2.0",
            "id": 1,
            "method": "initialize",
            "params": {
                "protocolVersion": "2024-11-05",
                "capabilities": {},
                "clientInfo": {
                    "name": "test-client",
                    "version": "1.0.0"
                }
            }
        }
        
        request_json = json.dumps(init_request) + "\n"
        process.stdin.write(request_json)
        process.stdin.flush()
        
        # Read response with timeout
        response_line = process.stdout.readline()
        if not response_line:
            print("❌ No response received from MCP server")
            process.terminate()
            return False
        
        try:
            response = json.loads(response_line.strip())
            print("✓ Received valid JSON response")
            
            # Validate response structure
            if response.get("jsonrpc") != "2.0":
                print(f"❌ Invalid JSON-RPC version: {response.get('jsonrpc')}")
                process.terminate()
                return False
            
            if "result" not in response:
                print(f"❌ Missing result in response: {response}")
                process.terminate()
                return False
            
            result = response["result"]
            if "protocolVersion" not in result or "capabilities" not in result or "serverInfo" not in result:
                print(f"❌ Invalid initialize response structure: {result}")
                process.terminate()
                return False
            
            print("✓ Initialize response structure is valid")
            
        except json.JSONDecodeError as e:
            print(f"❌ Invalid JSON response: {e}")
            process.terminate()
            return False
        
        # Test 3: Tools list
        print("🧪 Testing tools/list...")
        
        tools_request = {
            "jsonrpc": "2.0",
            "id": 2,
            "method": "tools/list"
        }
        
        request_json = json.dumps(tools_request) + "\n"
        process.stdin.write(request_json)
        process.stdin.flush()
        
        response_line = process.stdout.readline()
        if response_line:
            try:
                response = json.loads(response_line.strip())
                if response.get("jsonrpc") == "2.0" and "result" in response:
                    tools = response["result"].get("tools", [])
                    print(f"✓ Tools list received with {len(tools)} tools")
                else:
                    print(f"❌ Invalid tools/list response: {response}")
                    process.terminate()
                    return False
            except json.JSONDecodeError:
                print("❌ Invalid JSON in tools/list response")
                process.terminate()
                return False
        else:
            print("❌ No response to tools/list request")
            process.terminate()
            return False
        
        # Clean up
        process.terminate()
        process.wait()
        
        print("✅ Basic MCP functionality test passed!")
        return True
        
    except Exception as e:
        print(f"❌ Error during MCP test: {e}")
        if 'process' in locals():
            try:
                process.terminate()
                process.wait()
            except:
                pass
        return False

def test_mcp_error_handling():
    """Test MCP error handling"""
    mcp_binary = find_mcp_binary()
    if not mcp_binary:
        return False
    
    print("🧪 Testing MCP error handling...")
    
    try:
        env = os.environ.copy()
        env.update({
            'X16_PORT': '9092',
            'X16_LOG_LEVEL': 'INFO',
            'X16_DEBUG': '1'
        })
        
        process = subprocess.Popen(
            [mcp_binary],
            env=env,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        
        time.sleep(1)
        
        if process.poll() is not None:
            return False
        
        # Test invalid JSON
        process.stdin.write('{"invalid": json}\n')
        process.stdin.flush()
        
        response_line = process.stdout.readline()
        if response_line:
            try:
                response = json.loads(response_line.strip())
                if (response.get("jsonrpc") == "2.0" and 
                    "error" in response and 
                    response["error"].get("code") == -32700):
                    print("✓ Parse error handling works correctly")
                else:
                    print(f"❌ Unexpected error response: {response}")
                    process.terminate()
                    return False
            except json.JSONDecodeError:
                print("❌ Invalid JSON in error response")
                process.terminate()
                return False
        
        # Test invalid method
        invalid_method_request = {
            "jsonrpc": "2.0",
            "id": 1,
            "method": "nonexistent_method"
        }
        
        request_json = json.dumps(invalid_method_request) + "\n"
        process.stdin.write(request_json)
        process.stdin.flush()
        
        response_line = process.stdout.readline()
        if response_line:
            try:
                response = json.loads(response_line.strip())
                if (response.get("jsonrpc") == "2.0" and 
                    "error" in response and 
                    response["error"].get("code") == -32601):
                    print("✓ Method not found error handling works correctly")
                else:
                    print(f"❌ Unexpected method error response: {response}")
                    process.terminate()
                    return False
            except json.JSONDecodeError:
                print("❌ Invalid JSON in method error response")
                process.terminate()
                return False
        
        process.terminate()
        process.wait()
        
        print("✅ Error handling test passed!")
        return True
        
    except Exception as e:
        print(f"❌ Error during error handling test: {e}")
        if 'process' in locals():
            try:
                process.terminate()
                process.wait()
            except:
                pass
        return False

def main():
    """Main test runner"""
    print("🚀 MCP Protocol Compliance Test Suite")
    print("=" * 40)
    
    # Check if we're in the right directory
    if not os.path.exists("Makefile"):
        print("❌ Please run this script from the project root directory")
        return 1
    
    # Run tests
    tests = [
        ("Basic Functionality", test_mcp_basic_functionality),
        ("Error Handling", test_mcp_error_handling)
    ]
    
    passed = 0
    total = len(tests)
    
    for test_name, test_func in tests:
        print(f"\n📋 Running: {test_name}")
        print("-" * 30)
        
        try:
            if test_func():
                passed += 1
            else:
                print(f"❌ {test_name} failed")
        except Exception as e:
            print(f"❌ {test_name} crashed: {e}")
    
    print(f"\n📊 Test Results")
    print("=" * 20)
    print(f"Passed: {passed}/{total}")
    print(f"Failed: {total - passed}/{total}")
    
    if passed == total:
        print("🎉 All tests passed!")
        return 0
    else:
        print("💥 Some tests failed")
        return 1

if __name__ == "__main__":
    sys.exit(main())











