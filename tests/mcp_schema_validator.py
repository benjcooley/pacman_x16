#!/usr/bin/env python3
"""
MCP Schema Validator

Validates that the MCP server's tool definitions and responses conform to
the Model Context Protocol JSON schema specifications.
"""

import json
import jsonschema
from typing import Dict, Any, List, Optional
import logging

logger = logging.getLogger(__name__)

# MCP Protocol JSON Schemas
MCP_INITIALIZE_REQUEST_SCHEMA = {
    "type": "object",
    "properties": {
        "jsonrpc": {"const": "2.0"},
        "id": {},
        "method": {"const": "initialize"},
        "params": {
            "type": "object",
            "properties": {
                "protocolVersion": {"type": "string"},
                "capabilities": {"type": "object"},
                "clientInfo": {
                    "type": "object",
                    "properties": {
                        "name": {"type": "string"},
                        "version": {"type": "string"}
                    },
                    "required": ["name", "version"]
                }
            },
            "required": ["protocolVersion", "capabilities", "clientInfo"]
        }
    },
    "required": ["jsonrpc", "id", "method", "params"]
}

MCP_INITIALIZE_RESPONSE_SCHEMA = {
    "type": "object",
    "properties": {
        "jsonrpc": {"const": "2.0"},
        "id": {},
        "result": {
            "type": "object",
            "properties": {
                "protocolVersion": {"type": "string"},
                "capabilities": {
                    "type": "object",
                    "properties": {
                        "tools": {"type": "object"},
                        "resources": {"type": "object"}
                    }
                },
                "serverInfo": {
                    "type": "object",
                    "properties": {
                        "name": {"type": "string"},
                        "version": {"type": "string"}
                    },
                    "required": ["name", "version"]
                }
            },
            "required": ["protocolVersion", "capabilities", "serverInfo"]
        }
    },
    "required": ["jsonrpc", "id", "result"]
}

MCP_TOOLS_LIST_RESPONSE_SCHEMA = {
    "type": "object",
    "properties": {
        "jsonrpc": {"const": "2.0"},
        "id": {},
        "result": {
            "type": "object",
            "properties": {
                "tools": {
                    "type": "array",
                    "items": {
                        "type": "object",
                        "properties": {
                            "name": {"type": "string"},
                            "description": {"type": "string"},
                            "inputSchema": {
                                "type": "object",
                                "properties": {
                                    "type": {"const": "object"},
                                    "properties": {"type": "object"}
                                },
                                "required": ["type", "properties"]
                            }
                        },
                        "required": ["name", "description", "inputSchema"]
                    }
                }
            },
            "required": ["tools"]
        }
    },
    "required": ["jsonrpc", "id", "result"]
}

MCP_RESOURCES_LIST_RESPONSE_SCHEMA = {
    "type": "object",
    "properties": {
        "jsonrpc": {"const": "2.0"},
        "id": {},
        "result": {
            "type": "object",
            "properties": {
                "resources": {
                    "type": "array",
                    "items": {
                        "type": "object",
                        "properties": {
                            "uri": {"type": "string"},
                            "name": {"type": "string"},
                            "description": {"type": "string"},
                            "mimeType": {"type": "string"}
                        },
                        "required": ["uri", "name"]
                    }
                }
            },
            "required": ["resources"]
        }
    },
    "required": ["jsonrpc", "id", "result"]
}

MCP_ERROR_RESPONSE_SCHEMA = {
    "type": "object",
    "properties": {
        "jsonrpc": {"const": "2.0"},
        "id": {},
        "error": {
            "type": "object",
            "properties": {
                "code": {"type": "integer"},
                "message": {"type": "string"},
                "data": {}
            },
            "required": ["code", "message"]
        }
    },
    "required": ["jsonrpc", "error"]
}

class MCPSchemaValidator:
    """Validator for MCP protocol compliance"""
    
    def __init__(self):
        self.schemas = {
            "initialize_request": MCP_INITIALIZE_REQUEST_SCHEMA,
            "initialize_response": MCP_INITIALIZE_RESPONSE_SCHEMA,
            "tools_list_response": MCP_TOOLS_LIST_RESPONSE_SCHEMA,
            "resources_list_response": MCP_RESOURCES_LIST_RESPONSE_SCHEMA,
            "error_response": MCP_ERROR_RESPONSE_SCHEMA
        }
    
    def validate_response(self, response: Dict[str, Any], schema_name: str) -> tuple[bool, Optional[str]]:
        """Validate a response against the specified schema"""
        try:
            schema = self.schemas.get(schema_name)
            if not schema:
                return False, f"Unknown schema: {schema_name}"
            
            jsonschema.validate(response, schema)
            return True, None
            
        except jsonschema.ValidationError as e:
            return False, f"Schema validation error: {e.message}"
        except Exception as e:
            return False, f"Validation error: {str(e)}"
    
    def validate_tool_definition(self, tool: Dict[str, Any]) -> tuple[bool, Optional[str]]:
        """Validate a single tool definition"""
        required_fields = ["name", "description", "inputSchema"]
        
        for field in required_fields:
            if field not in tool:
                return False, f"Missing required field: {field}"
        
        # Validate input schema structure
        input_schema = tool["inputSchema"]
        if not isinstance(input_schema, dict):
            return False, "inputSchema must be an object"
        
        if input_schema.get("type") != "object":
            return False, "inputSchema type must be 'object'"
        
        if "properties" not in input_schema:
            return False, "inputSchema must have 'properties' field"
        
        return True, None
    
    def validate_all_tools(self, tools: List[Dict[str, Any]]) -> tuple[bool, List[str]]:
        """Validate all tool definitions"""
        errors = []
        
        for i, tool in enumerate(tools):
            is_valid, error = self.validate_tool_definition(tool)
            if not is_valid:
                errors.append(f"Tool {i} ({tool.get('name', 'unnamed')}): {error}")
        
        return len(errors) == 0, errors
    
    def validate_jsonrpc_base(self, response: Dict[str, Any]) -> tuple[bool, Optional[str]]:
        """Validate basic JSON-RPC 2.0 structure"""
        if not isinstance(response, dict):
            return False, "Response must be a JSON object"
        
        if response.get("jsonrpc") != "2.0":
            return False, "Missing or invalid 'jsonrpc' field (must be '2.0')"
        
        # Must have either 'result' or 'error', but not both
        has_result = "result" in response
        has_error = "error" in response
        
        if not has_result and not has_error:
            return False, "Response must have either 'result' or 'error'"
        
        if has_result and has_error:
            return False, "Response cannot have both 'result' and 'error'"
        
        # If it has an id field, it should not be null (unless it's an error response to a malformed request)
        if "id" in response and response["id"] is None and has_result:
            return False, "Response 'id' should not be null for successful responses"
        
        return True, None
    
    def generate_test_report(self, test_results: Dict[str, Any]) -> str:
        """Generate a human-readable test report"""
        report = ["MCP Protocol Compliance Test Report", "=" * 40, ""]
        
        total_tests = len(test_results)
        passed_tests = sum(1 for result in test_results.values() if result.get("passed", False))
        
        report.append(f"Total Tests: {total_tests}")
        report.append(f"Passed: {passed_tests}")
        report.append(f"Failed: {total_tests - passed_tests}")
        report.append("")
        
        for test_name, result in test_results.items():
            status = "PASS" if result.get("passed", False) else "FAIL"
            report.append(f"{status}: {test_name}")
            
            if not result.get("passed", False) and "error" in result:
                report.append(f"    Error: {result['error']}")
            
            if "details" in result:
                for detail in result["details"]:
                    report.append(f"    - {detail}")
            
            report.append("")
        
        return "\n".join(report)


def validate_mcp_server_response(response_json: str, expected_schema: str) -> tuple[bool, Optional[str]]:
    """Convenience function to validate a JSON response string"""
    try:
        response = json.loads(response_json)
        validator = MCPSchemaValidator()
        return validator.validate_response(response, expected_schema)
    except json.JSONDecodeError as e:
        return False, f"Invalid JSON: {e}"


if __name__ == "__main__":
    # Example usage
    validator = MCPSchemaValidator()
    
    # Test a sample initialize response
    sample_response = {
        "jsonrpc": "2.0",
        "id": 1,
        "result": {
            "protocolVersion": "2024-11-05",
            "capabilities": {
                "tools": {},
                "resources": {}
            },
            "serverInfo": {
                "name": "x16-emulator-mcp",
                "version": "1.0.0"
            }
        }
    }
    
    is_valid, error = validator.validate_response(sample_response, "initialize_response")
    print(f"Sample response validation: {'PASS' if is_valid else 'FAIL'}")
    if error:
        print(f"Error: {error}")











