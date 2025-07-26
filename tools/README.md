# PAC-MAN X16 Development Tools

This directory contains automated development tools for the PAC-MAN X16 project.

## Tools Overview

### Core Development Tools

#### `development_loop.py`
**Purpose**: Basic automated development loop
- Builds project using make
- Runs X16 emulator with screenshot capture
- Logs build results and progress
- Simple iteration tracking

**Usage**: `python3 tools/development_loop.py [iterations]`

#### `enhanced_dev_loop.py`
**Purpose**: AI-assisted intelligent development loop
- Automated build and test cycles
- Visual analysis of emulator output
- Intelligent code improvements based on screenshots
- Advanced progress tracking with JSON logs

**Usage**: `python3 tools/enhanced_dev_loop.py [iterations]`

#### `comparison_analyzer.py`
**Purpose**: Reference implementation analysis
- Analyzes C reference implementation (pacman.c)
- Compares with current X16 assembly implementation
- Identifies missing features and development priorities
- Generates completion percentage and roadmaps

**Usage**: `python3 tools/comparison_analyzer.py`

#### `project_execution_plan.py`
**Purpose**: Phase-by-phase project execution
- Implements 12-phase development plan
- Automated phase execution with testing
- Progress tracking and validation
- Structured approach to complex project

**Usage**: `python3 tools/project_execution_plan.py`

## Development Workflow

### Recommended Development Process

1. **Phase Planning**: Use `project_execution_plan.py` to execute structured phases
2. **Development**: Use `enhanced_dev_loop.py` for AI-assisted development
3. **Analysis**: Use `comparison_analyzer.py` to track progress against reference
4. **Testing**: Use automated testing tools for validation

### Quick Start Commands

```bash
# Run phase-by-phase development
python3 tools/project_execution_plan.py

# Analyze current progress
python3 tools/comparison_analyzer.py

# Run enhanced development loop
python3 tools/enhanced_dev_loop.py 5

# Basic development iteration
python3 tools/development_loop.py 3
```

## Tool Integration

### Data Pipeline
1. **Extraction**: Tools extract data from reference implementation
2. **Conversion**: Transform data to X16-compatible formats
3. **Integration**: Incorporate converted data into assembly source
4. **Validation**: Verify accuracy against original reference

### Quality Assurance
1. **Build Validation**: Ensure clean builds and proper memory usage
2. **Performance Testing**: Validate 60fps target and timing accuracy
3. **Accuracy Testing**: Compare against reference frame-by-frame
4. **Regression Testing**: Prevent quality degradation during development

## Configuration

### Environment Setup
- Python 3.7+ required
- X16 emulator (x16emu) in PATH
- CC65 toolchain for building
- Make utility for build automation

### Tool Configuration
Most tools use configuration files or command-line parameters:
- Screenshot directories and naming conventions
- Build paths and output locations
- Emulator launch parameters
- Analysis thresholds and criteria

## Logging and Reporting

### Log Files
- `development_log.txt` - Basic development loop logs
- `enhanced_development_log.json` - Detailed AI-assisted development logs
- `comparison_report.json` - Reference comparison analysis
- `execution_log.json` - Phase execution tracking

### Reports
- `comparison_report.txt` - Human-readable comparison analysis
- `execution_summary.txt` - Phase completion summary

## Best Practices

### Tool Usage
1. **Start with Planning**: Use execution plan for structured approach
2. **Iterate Intelligently**: Use enhanced development loop for complex problems
3. **Validate Frequently**: Use comparison analyzer to track progress
4. **Document Everything**: Maintain comprehensive logs and reports

### Development Workflow
1. **Phase-Based Development**: Complete one phase before moving to next
2. **Automated Testing**: Use tools to validate each change
3. **Reference Compliance**: Regularly compare against original implementation
4. **Performance Monitoring**: Track performance throughout development

### Quality Control
1. **Build Validation**: Ensure every change builds successfully
2. **Visual Testing**: Use screenshots to verify graphical changes
3. **Regression Prevention**: Test existing functionality after changes
4. **Documentation Updates**: Keep documentation current with code changes

## Future Tool Development

### Planned Tools

#### `tile_extractor.py`
**Purpose**: Extract and convert tile data from reference
- Extract ROM tile data from pacman.c
- Convert to VERA-compatible 4bpp format
- Generate assembly data files
- Validate tile accuracy

#### `sprite_converter.py`
**Purpose**: Convert sprite data for X16
- Extract sprite data from reference
- Convert to VERA sprite format
- Generate sprite positioning data
- Create animation sequences

#### `maze_generator.py`
**Purpose**: Generate maze layout data
- Extract maze layout from reference
- Convert to tilemap format
- Generate collision data
- Validate maze accuracy

#### `performance_analyzer.py`
**Purpose**: Performance analysis and optimization
- Measure frame rates and timing
- Identify performance bottlenecks
- Generate optimization recommendations
- Track performance regressions

## Troubleshooting

### Common Issues

#### Build Failures
- Check CC65 toolchain installation
- Verify Makefile configuration
- Ensure proper file permissions
- Check for syntax errors in assembly

#### Emulator Issues
- Verify x16emu is in PATH
- Check emulator version compatibility
- Ensure proper ROM files are available
- Verify display configuration

#### Tool Errors
- Check Python version (3.7+ required)
- Verify all dependencies are installed
- Check file paths and permissions
- Review tool-specific documentation

### Getting Help

1. Check tool-specific error messages
2. Review log files for detailed information
3. Verify environment setup
4. Consult project documentation
5. Check GitHub issues for known problems

---

*Last Updated: 2025-07-24*  
*Tool Version: 1.0*
