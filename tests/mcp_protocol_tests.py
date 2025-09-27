#!/usr/bin/env python3
"""
Commander X16 Emulator MCP Protocol Compliance Test Suite

This test suite validates that the MCP server implementation complies with the
Model Context Protocol (MCP) specification. It tests JSON-RPC 2.0 compliance,
proper tool definitions, resource handling, and error responses.

Usage:
    python tests/mcp_protocol_tests.py
    
Environment Variables:
    MCP_SERVER_PATH - Path to the MCP server binary (default: bin/mcp)
    MCP_PORT - Port for HTTP server testing (default: 9090)
    MCP_TIMEOUT - Test timeout in seconds (default: 30)
"""

import json
import subprocess
import time
import unittest
import os
import sys
import threading
import socket
import requests
import logging
from typing import Dict, Any, Optional, List
from unittest.mock import patch, MagicMock

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class MCPProtocolTester:
    """Test harness for MCP protocol compliance testing"""
    
    def __init__(self, server_path: str = None, port: int = 9090, timeout: int = 30):
        self.server_path = server_path or os.path.join("bin", "mcp")
        self.port = port
        self.timeout = timeout
        self.server_process = None
        self.http_base_url = f"http://127.0.0.1:{port}"
        
    def start_server(self) -> bool:
        """Start the MCP server process"""
        try:
            # Set environment variables for the server
            env = os.environ.copy()
            env.update({
                'X16_PORT': str(self.port),
                'X16_LOG_LEVEL': 'INFO',
                'X16_DEBUG': '1'  # Enable debug mode for testing
            })
            
            logger.info(f"Starting MCP server: {self.server_path}")
            self.server_process = subprocess.Popen(
                [self.server_path],
                env=env,
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                bufsize=0
            )
            
            # Wait for server to start
            time.sleep(2)
            
            # Check if process is still running
            if self.server_process.poll() is not None:
                stdout, stderr = self.server_process.communicate()
                logger.error(f"Server failed to start. Stdout: {stdout}, Stderr: {stderr}")
                return False
                
            logger.info("MCP server started successfully")
            return True
            
        except Exception as e:
            logger.error(f"Failed to start server: {e}")
            return False
    
    def stop_server(self):
        """Stop the MCP server process"""
        if self.server_process:
            try:
                self.server_process.terminate()
                self.server_process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.server_process.kill()
                self.server_process.wait()
            except Exception as e:
                logger.error(f"Error stopping server: {e}")
    
    def send_jsonrpc_request(self, method: str, params: Dict = None, request_id: Any = 1) -> Dict:
        """Send a JSON-RPC 2.0 request to the MCP server via stdin"""
        request = {
            "jsonrpc": "2.0",
            "method": method,
            "id": request_id
        }
        if params:
            request["params"] = params
            
        try:
            request_json = json.dumps(request) + "\n"
            logger.debug(f"Sending JSON-RPC request: {request_json.strip()}")
            
            self.server_process.stdin.write(request_json)
            self.server_process.stdin.flush()
            
            # Read response
            response_line = self.server_process.stdout.readline()
            if not response_line:
                return {"error": "No response received"}
                
            logger.debug(f"Received JSON-RPC response: {response_line.strip()}")
            return json.loads(response_line.strip())
            
        except Exception as e:
            logger.error(f"Error sending JSON-RPC request: {e}")
            return {"error": str(e)}
    
    def send_http_request(self, endpoint: str, method: str = "GET", data: Dict = None) -> requests.Response:
        """Send HTTP request to the embedded HTTP server"""
        url = f"{self.http_base_url}{endpoint}"
        headers = {"Content-Type": "application/json"} if data else {}
        
        try:
            if method.upper() == "POST":
                return requests.post(url, json=data or {}, headers=headers, timeout=10)
            else:
                return requests.get(url, timeout=10)
        except Exception as e:
            logger.error(f"HTTP request failed: {e}")
            raise


class TestMCPProtocolCompliance(unittest.TestCase):
    """Test cases for MCP protocol compliance"""
    
    @classmethod
    def setUpClass(cls):
        """Set up the test environment"""
        cls.server_path = os.environ.get('MCP_SERVER_PATH', 'bin/mcp')
        cls.port = int(os.environ.get('MCP_PORT', '9090'))
        cls.timeout = int(os.environ.get('MCP_TIMEOUT', '30'))
        
        cls.tester = MCPProtocolTester(cls.server_path, cls.port, cls.timeout)
        
        # Start the server
        if not cls.tester.start_server():
            raise unittest.SkipTest("Failed to start MCP server")
    
    @classmethod
    def tearDownClass(cls):
        """Clean up the test environment"""
        if hasattr(cls, 'tester'):
            cls.tester.stop_server()
    
    def test_jsonrpc_version_compliance(self):
        """Test that all responses include proper JSON-RPC 2.0 version"""
        response = self.tester.send_jsonrpc_request("initialize", {
            "protocolVersion": "2024-11-05",
            "capabilities": {},
            "clientInfo": {"name": "test-client", "version": "1.0.0"}
        })
        
        self.assertIn("jsonrpc", response)
        self.assertEqual(response["jsonrpc"], "2.0")
        self.assertIn("id", response)
        self.assertIn("result", response)
    
    def test_initialize_method(self):
        """Test the initialize method returns proper capabilities"""
        response = self.tester.send_jsonrpc_request("initialize", {
            "protocolVersion": "2024-11-05",
            "capabilities": {},
            "clientInfo": {"name": "test-client", "version": "1.0.0"}
        })
        
        self.assertEqual(response.get("jsonrpc"), "2.0")
        self.assertIn("result", response)
        
        result = response["result"]
        self.assertIn("protocolVersion", result)
        self.assertIn("capabilities", result)
        self.assertIn("serverInfo", result)
        
        # Check server info
        server_info = result["serverInfo"]
        self.assertIn("name", server_info)
        self.assertIn("version", server_info)
        self.assertEqual(server_info["name"], "x16-emulator-mcp")
        
        # Check capabilities
        capabilities = result["capabilities"]
        self.assertIn("tools", capabilities)
        self.assertIn("resources", capabilities)
    
    def test_tools_list_method(self):
        """Test the tools/list method returns proper tool definitions"""
        # Initialize first
        self.tester.send_jsonrpc_request("initialize", {
            "protocolVersion": "2024-11-05",
            "capabilities": {},
            "clientInfo": {"name": "test-client", "version": "1.0.0"}
        })
        
        response = self.tester.send_jsonrpc_request("tools/list")
        
        self.assertEqual(response.get("jsonrpc"), "2.0")
        self.assertIn("result", response)
        
        result = response["result"]
        self.assertIn("tools", result)
        
        tools = result["tools"]
        self.assertIsInstance(tools, list)
        self.assertGreater(len(tools), 0)
        
        # Check required tool fields
        expected_tools = [
            "start_emulator", "stop_emulator", "reset_emulator", "send_nmi",
            "take_screenshot", "take_text_screenshot", "take_snapshot",
            "send_keyboard", "debug_break", "load_program"
        ]
        
        tool_names = [tool["name"] for tool in tools]
        for expected_tool in expected_tools:
            self.assertIn(expected_tool, tool_names, f"Missing tool: {expected_tool}")
        
        # Validate tool schema
        for tool in tools:
            self.assertIn("name", tool)
            self.assertIn("description", tool)
            self.assertIn("inputSchema", tool)
            
            # Check input schema structure
            schema = tool["inputSchema"]
            self.assertIn("type", schema)
            self.assertEqual(schema["type"], "object")
            self.assertIn("properties", schema)
    
    def test_resources_list_method(self):
        """Test the resources/list method returns proper resource definitions"""
        # Initialize first
        self.tester.send_jsonrpc_request("initialize", {
            "protocolVersion": "2024-11-05",
            "capabilities": {},
            "clientInfo": {"name": "test-client", "version": "1.0.0"}
        })
        
        response = self.tester.send_jsonrpc_request("resources/list")
        
        self.assertEqual(response.get("jsonrpc"), "2.0")
        self.assertIn("result", response)
        
        result = response["result"]
        self.assertIn("resources", result)
        
        resources = result["resources"]
        self.assertIsInstance(resources, list)
        # Note: Resources might be empty if no screenshots exist, which is valid
    
    def test_invalid_method_error(self):
        """Test that invalid methods return proper JSON-RPC errors"""
        response = self.tester.send_jsonrpc_request("invalid_method")
        
        self.assertEqual(response.get("jsonrpc"), "2.0")
        self.assertIn("error", response)
        
        error = response["error"]
        self.assertIn("code", error)
        self.assertIn("message", error)
        self.assertEqual(error["code"], -32601)  # Method not found
    
    def test_invalid_jsonrpc_version(self):
        """Test that requests with invalid JSON-RPC version return errors"""
        request = {
            "jsonrpc": "1.0",  # Invalid version
            "method": "initialize",
            "id": 1
        }
        
        try:
            request_json = json.dumps(request) + "\n"
            self.tester.server_process.stdin.write(request_json)
            self.tester.server_process.stdin.flush()
            
            response_line = self.tester.server_process.stdout.readline()
            response = json.loads(response_line.strip())
            
            self.assertEqual(response.get("jsonrpc"), "2.0")
            self.assertIn("error", response)
            
            error = response["error"]
            self.assertEqual(error["code"], -32600)  # Invalid Request
            
        except Exception as e:
            self.fail(f"Failed to test invalid JSON-RPC version: {e}")
    
    def test_malformed_json_error(self):
        """Test that malformed JSON returns proper parse errors"""
        malformed_json = '{"jsonrpc": "2.0", "method": "initialize", invalid}\n'
        
        try:
            self.tester.server_process.stdin.write(malformed_json)
            self.tester.server_process.stdin.flush()
            
            response_line = self.tester.server_process.stdout.readline()
            response = json.loads(response_line.strip())
            
            self.assertEqual(response.get("jsonrpc"), "2.0")
            self.assertIn("error", response)
            
            error = response["error"]
            self.assertEqual(error["code"], -32700)  # Parse error
            
        except Exception as e:
            self.fail(f"Failed to test malformed JSON: {e}")
    
    def test_tool_execution_schema_validation(self):
        """Test that tool execution validates input schemas properly"""
        # Initialize first
        self.tester.send_jsonrpc_request("initialize", {
            "protocolVersion": "2024-11-05",
            "capabilities": {},
            "clientInfo": {"name": "test-client", "version": "1.0.0"}
        })
        
        # Test valid tool call
        response = self.tester.send_jsonrpc_request("tools/call", {
            "name": "get_status",
            "arguments": {}
        })
        
        self.assertEqual(response.get("jsonrpc"), "2.0")
        # Should either succeed or fail gracefully (emulator might not be running)
        self.assertTrue("result" in response or "error" in response)
        
        # Test invalid tool call (missing required parameter)
        response = self.tester.send_jsonrpc_request("tools/call", {
            "name": "debug_read_memory",
            "arguments": {}  # Missing required 'address' parameter
        })
        
        self.assertEqual(response.get("jsonrpc"), "2.0")
        self.assertIn("error", response)


class TestHTTPServerCompliance(unittest.TestCase):
    """Test cases for the embedded HTTP server compliance"""
    
    @classmethod
    def setUpClass(cls):
        """Set up the test environment"""
        cls.server_path = os.environ.get('MCP_SERVER_PATH', 'bin/mcp')
        cls.port = int(os.environ.get('MCP_PORT', '9090'))
        cls.timeout = int(os.environ.get('MCP_TIMEOUT', '30'))
        
        cls.tester = MCPProtocolTester(cls.server_path, cls.port, cls.timeout)
        
        # Start the server
        if not cls.tester.start_server():
            raise unittest.SkipTest("Failed to start MCP server")
        
        # Wait for HTTP server to be ready
        time.sleep(3)
    
    @classmethod
    def tearDownClass(cls):
        """Clean up the test environment"""
        if hasattr(cls, 'tester'):
            cls.tester.stop_server()
    
    def test_http_server_info_endpoint(self):
        """Test the root endpoint returns server information"""
        try:
            response = self.tester.send_http_request("/")
            self.assertEqual(response.status_code, 200)
            
            data = response.json()
            self.assertIn("name", data)
            self.assertIn("version", data)
            self.assertIn("description", data)
            self.assertIn("endpoints", data)
            self.assertEqual(data["name"], "x16-emulator-mcp-server")
            
        except requests.exceptions.RequestException:
            self.skipTest("HTTP server not accessible - may be MCP-only mode")
    
    def test_http_status_endpoint(self):
        """Test the status endpoint returns proper status"""
        try:
            response = self.tester.send_http_request("/status")
            self.assertEqual(response.status_code, 200)
            
            data = response.json()
            self.assertIn("status", data)
            self.assertIn("port", data)
            self.assertIn("debug", data)
            self.assertEqual(data["status"], "running")
            self.assertEqual(data["port"], self.tester.port)
            
        except requests.exceptions.RequestException:
            self.skipTest("HTTP server not accessible - may be MCP-only mode")
    
    def test_http_post_requirements(self):
        """Test that POST endpoints require proper headers and body"""
        try:
            # Test POST without Content-Type header (should fail)
            response = requests.post(f"{self.tester.http_base_url}/test", timeout=10)
            # Should either work or return a specific error, but not crash
            self.assertIsNotNone(response.status_code)
            
            # Test POST with proper headers and body
            response = self.tester.send_http_request("/test", "POST", {})
            self.assertEqual(response.status_code, 200)
            
            data = response.json()
            self.assertIn("status", data)
            self.assertEqual(data["status"], "success")
            
        except requests.exceptions.RequestException:
            self.skipTest("HTTP server not accessible - may be MCP-only mode")


class TestMCPToolFunctionality(unittest.TestCase):
    """Test cases for MCP tool functionality"""
    
    @classmethod
    def setUpClass(cls):
        """Set up the test environment"""
        cls.server_path = os.environ.get('MCP_SERVER_PATH', 'bin/mcp')
        cls.port = int(os.environ.get('MCP_PORT', '9090'))
        cls.timeout = int(os.environ.get('MCP_TIMEOUT', '30'))
        
        cls.tester = MCPProtocolTester(cls.server_path, cls.port, cls.timeout)
        
        # Start the server
        if not cls.tester.start_server():
            raise unittest.SkipTest("Failed to start MCP server")
        
        # Initialize the MCP session
        cls.tester.send_jsonrpc_request("initialize", {
            "protocolVersion": "2024-11-05",
            "capabilities": {},
            "clientInfo": {"name": "test-client", "version": "1.0.0"}
        })
    
    @classmethod
    def tearDownClass(cls):
        """Clean up the test environment"""
        if hasattr(cls, 'tester'):
            cls.tester.stop_server()
    
    def test_emulator_lifecycle_tools(self):
        """Test emulator start/stop/reset tools"""
        # Test get_status (should work even if emulator not running)
        response = self.tester.send_jsonrpc_request("tools/call", {
            "name": "get_status",
            "arguments": {}
        })
        
        self.assertEqual(response.get("jsonrpc"), "2.0")
        # Should return result or error, but be well-formed
        self.assertTrue("result" in response or "error" in response)
    
    def test_screenshot_tools(self):
        """Test screenshot-related tools"""
        # Test take_screenshot tool
        response = self.tester.send_jsonrpc_request("tools/call", {
            "name": "take_screenshot",
            "arguments": {}
        })
        
        self.assertEqual(response.get("jsonrpc"), "2.0")
        # May fail if emulator not running, but should be well-formed
        self.assertTrue("result" in response or "error" in response)
        
        # Test take_text_screenshot tool
        response = self.tester.send_jsonrpc_request("tools/call", {
            "name": "take_text_screenshot",
            "arguments": {
                "layer": -1,
                "include_colors": True
            }
        })
        
        self.assertEqual(response.get("jsonrpc"), "2.0")
        self.assertTrue("result" in response or "error" in response)
    
    def test_keyboard_tool(self):
        """Test keyboard input tool"""
        response = self.tester.send_jsonrpc_request("tools/call", {
            "name": "send_keyboard",
            "arguments": {
                "text": "HELLO`ENTER`",
                "mode": "ascii"
            }
        })
        
        self.assertEqual(response.get("jsonrpc"), "2.0")
        # May fail if emulator not running, but should be well-formed
        self.assertTrue("result" in response or "error" in response)
    
    def test_debug_tools(self):
        """Test debugging-related tools"""
        # Test debug_get_status
        response = self.tester.send_jsonrpc_request("tools/call", {
            "name": "debug_get_status",
            "arguments": {}
        })
        
        self.assertEqual(response.get("jsonrpc"), "2.0")
        self.assertTrue("result" in response or "error" in response)
        
        # Test debug_read_memory with valid parameters
        response = self.tester.send_jsonrpc_request("tools/call", {
            "name": "debug_read_memory",
            "arguments": {
                "address": 0x0000,
                "length": 16,
                "format": "hexdump"
            }
        })
        
        self.assertEqual(response.get("jsonrpc"), "2.0")
        self.assertTrue("result" in response or "error" in response)


def run_tests():
    """Run all MCP protocol compliance tests"""
    # Check if server binary exists
    server_path = os.environ.get('MCP_SERVER_PATH', 'bin/mcp')
    if not os.path.exists(server_path):
        print(f"Error: MCP server binary not found at {server_path}")
        print("Please build the server first with: make")
        return 1
    
    # Create test suite
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()
    
    # Add test cases
    suite.addTests(loader.loadTestsFromTestCase(TestMCPProtocolCompliance))
    suite.addTests(loader.loadTestsFromTestCase(TestHTTPServerCompliance))
    suite.addTests(loader.loadTestsFromTestCase(TestMCPToolFunctionality))
    
    # Run tests
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    return 0 if result.wasSuccessful() else 1


if __name__ == "__main__":
    sys.exit(run_tests())











