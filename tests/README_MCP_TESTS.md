# MCP Protocol Compliance Test Suite

This directory contains comprehensive tests for the Commander X16 Emulator's Model Context Protocol (MCP) server implementation. These tests ensure that the MCP server complies with the official MCP specification and provides reliable integration with MCP clients.

## Overview

The MCP server provides a standardized interface for controlling the Commander X16 emulator, including:

- **Emulator Control**: Start, stop, reset, and configure the emulator
- **Screen Capture**: Take screenshots and text screenshots
- **Input Simulation**: Send keyboard and joystick input
- **Debugging**: Set breakpoints, read/write memory, examine CPU state
- **Resource Management**: Access screenshots and other emulator resources

## Test Components

### 1. Basic Test Runner (`run_mcp_tests.py`)

A lightweight test runner that requires no external dependencies and tests core MCP functionality:

```bash
# Run basic tests
make test-mcp

# Or run directly
python3 tests/run_mcp_tests.py
```

**Tests included:**
- MCP server startup and shutdown
- JSON-RPC 2.0 protocol compliance
- Initialize handshake
- Tools list retrieval
- Error handling (malformed JSON, invalid methods)

### 2. Full Test Suite (`mcp_protocol_tests.py`)

Comprehensive test suite using Python unittest framework with external dependencies:

```bash
# Run full test suite (requires: pip install requests jsonschema)
make test-mcp-full

# Or run directly
python3 tests/mcp_protocol_tests.py
```

**Test Categories:**

#### Protocol Compliance Tests
- JSON-RPC 2.0 version validation
- Request/response structure validation
- Error code compliance
- Method parameter validation

#### Tool Functionality Tests
- Emulator lifecycle (start/stop/reset)
- Screenshot capture tools
- Keyboard input simulation
- Debugging tools (breakpoints, memory access)
- Resource management

#### HTTP Server Tests
- Embedded HTTP server endpoints
- POST request requirements
- Error handling and status codes

### 3. Schema Validator (`mcp_schema_validator.py`)

Utility for validating MCP responses against JSON schemas:

```python
from mcp_schema_validator import MCPSchemaValidator

validator = MCPSchemaValidator()
is_valid, error = validator.validate_response(response, "initialize_response")
```

## Configuration

### Environment Variables

- `MCP_SERVER_PATH`: Path to MCP server binary (default: `bin/mcp`)
- `MCP_PORT`: Port for HTTP server testing (default: 9090)
- `MCP_TIMEOUT`: Test timeout in seconds (default: 30)
- `X16_DEBUG`: Enable debug mode (set to 1 for verbose logging)

### Test Configuration

Tests automatically configure the MCP server with:
- Debug mode enabled for detailed logging
- Unique ports to avoid conflicts
- Appropriate timeouts for CI/CD environments

## Running Tests

### Prerequisites

1. **Build the MCP server:**
   ```bash
   make emulator  # This builds the MCP server as well
   ```

2. **For full test suite, install Python dependencies:**
   ```bash
   pip install requests jsonschema
   ```

### Test Execution

```bash
# Quick smoke test (no dependencies)
make test-mcp

# Full compliance test suite
make test-mcp-full

# Run specific test categories
python3 tests/mcp_protocol_tests.py TestMCPProtocolCompliance
python3 tests/mcp_protocol_tests.py TestHTTPServerCompliance
python3 tests/mcp_protocol_tests.py TestMCPToolFunctionality
```

### Continuous Integration

The tests are designed to run in CI/CD environments:

```yaml
# Example GitHub Actions step
- name: Run MCP Tests
  run: |
    make emulator
    make test-mcp
    make test-mcp-full
```

## Test Results

### Success Indicators

- ✅ All JSON-RPC responses include `"jsonrpc": "2.0"`
- ✅ Initialize handshake returns proper capabilities
- ✅ Tool definitions include required fields and valid schemas
- ✅ Error responses use standard JSON-RPC error codes
- ✅ HTTP endpoints return appropriate status codes

### Common Failure Modes

1. **Server Startup Failure**
   - Binary not found or not executable
   - Port already in use
   - Missing dependencies

2. **Protocol Violations**
   - Missing `jsonrpc` field in responses
   - Invalid error codes
   - Malformed tool definitions

3. **Timeout Issues**
   - Server takes too long to respond
   - Network connectivity problems
   - Resource contention

## MCP Protocol Reference

### Core Methods

| Method | Description | Required Parameters |
|--------|-------------|-------------------|
| `initialize` | Establish MCP session | `protocolVersion`, `capabilities`, `clientInfo` |
| `tools/list` | Get available tools | None |
| `tools/call` | Execute a tool | `name`, `arguments` |
| `resources/list` | Get available resources | None |
| `resources/read` | Read a resource | `uri` |

### Tool Categories

#### Emulator Control
- `start_emulator`: Launch emulator with optional program
- `stop_emulator`: Terminate emulator
- `reset_emulator`: Reset emulator state
- `get_status`: Get current emulator status

#### Screen Capture
- `take_screenshot`: Capture visual screenshot
- `take_text_screenshot`: Capture text content
- `take_snapshot`: Capture system state + screenshot

#### Input Simulation
- `send_keyboard`: Send keyboard input with macro support
- `send_joystick`: Send joystick commands

#### Debugging
- `debug_break`: Break into debugger
- `debug_set_breakpoint`: Set memory breakpoint
- `debug_read_memory`: Read memory with multiple formats
- `debug_write_memory`: Write memory

## Troubleshooting

### Common Issues

1. **"MCP binary not found"**
   ```bash
   make emulator  # Build the MCP server
   ```

2. **"Port already in use"**
   ```bash
   export MCP_PORT=9091  # Use different port
   make test-mcp
   ```

3. **"Missing Python dependencies"**
   ```bash
   pip install requests jsonschema
   ```

4. **"Server failed to start"**
   - Check if emulator dependencies are installed
   - Verify binary has execute permissions
   - Check system logs for detailed error messages

### Debug Mode

Enable debug mode for detailed logging:

```bash
export X16_DEBUG=1
make test-mcp
```

This will show:
- JSON-RPC request/response details
- HTTP transaction logs
- Server startup/shutdown events
- Error stack traces

## Contributing

When adding new MCP tools or modifying the protocol:

1. **Update test schemas** in `mcp_schema_validator.py`
2. **Add test cases** for new functionality
3. **Update tool definitions** to match implementation
4. **Run full test suite** to ensure no regressions
5. **Update documentation** with new capabilities

### Test Development Guidelines

- Use descriptive test names that explain what is being tested
- Include both positive and negative test cases
- Test edge cases and error conditions
- Validate both request and response formats
- Include performance/timeout considerations

## License

These tests are part of the Commander X16 Emulator project and follow the same licensing terms.











