# 🤖 AI DEVELOPMENT GUIDE - READ THIS FIRST! 🤖

**⚠️ MANDATORY READING FOR ALL AI ASSISTANTS WORKING ON THIS PROJECT ⚠️**

This is the **PRIMARY ENTRY POINT** for any AI working on the Commander X16 Pac-Man port project. Read this document completely before proceeding with any development work.

## 🎯 PROJECT MISSION

We are progressively porting Pac-Man to the Commander X16 in a **disciplined, methodical way**. This is not a quick hack - this is professional-grade retro game development with modern software engineering practices.

## 📋 MANDATORY DEVELOPMENT GROUND RULES

### 1. 🧹 KEEP THE PROJECT TIDY
- **Files in the right place**: Follow the established directory structure
- **Code is neat and efficient**: Clean, well-commented, optimized assembly
- **Clean up after ourselves**: Remove temporary files, organize properly
- **No clutter**: Every file has a purpose and proper location

### 2. 📊 FOLLOW THE PLAN & MARK PROGRESS
- **Stick to the documented plan**: See `docs/plan.md` for technical roadmap
- **Track progress**: Update `docs/progress.md` with completed milestones
- **When going in circles**: STOP and ask the human for guidance
- **Document decisions**: Record why choices were made

### 3. ✅ PROVE EVERYTHING WORKS
- **Screenshots are MANDATORY**: Use visual proof for all functionality
- **Extensive logging**: Implement and use logging throughout development
- **Test every component**: No assumptions - verify with evidence
- **Use available tools**: Leverage `tools/ai_dev_tool.py` and MCP emulator tools
- **Multi-frame verification**: Use motion screenshots when needed

### 4. 🔧 SMALL INCREMENTAL DEVELOPMENT
- **Bite-sized chunks**: Break work into small, testable pieces
- **Confirm before proceeding**: Each piece must work before moving to next
- **If small things don't work, large things are impossible**
- **Build incrementally**: Layer functionality step by step

### 5. 🚫 NO BACKWARDS MOVEMENT
- **Once something works, "check it in"**: Preserve working code
- **Git commits at milestones**: Submit to version control regularly
- **Don't break working functionality**: Protect what's already proven
- **Forward progress only**: Build on solid foundations

### 6. 🧪 REGRESSION TESTING
- **Maintain test suite**: All previous work must continue to function
- **Screenshot comparisons**: Compare current vs. expected screens
- **Automated verification**: Build tools to validate functionality
- **Continuous validation**: Every change must pass existing tests

### 7. 📝 WORK-IN-PROGRESS TRACKING
- **Maintain session context**: Document current work state
- **AI handoff information**: What was being done, how to continue
- **Clear next steps**: Specific actions for resuming work
- **Session logs**: Keep detailed records in `dev_logs/`

## 🗂️ PROJECT STRUCTURE & NAVIGATION

### 📚 Essential Documentation (READ THESE)
- **`README.md`**: Project overview and quick start guide
- **`docs/plan.md`**: Detailed technical plan and architecture
- **`docs/progress.md`**: Current progress tracking
- **`LLM_INSTRUCTIONS.md`**: Emulator output analysis instructions
- **`games/pacman/README.md`**: Game-specific documentation

### 🏗️ Core Development Areas
```
pacman_x16/
├── games/pacman/           # Main Pac-Man implementation
│   ├── pacman_x16.asm     # Primary game code
│   ├── pacman_minimal.asm # Minimal test version
│   ├── pacman_data.asm    # Game data and assets
│   └── test_*.asm         # Individual test files
├── framework/             # Reusable X16 framework
│   ├── core/              # Core system utilities
│   └── templates/         # Game templates
├── tools/                 # Development automation
│   ├── ai_dev_tool.py     # Primary AI development tool
│   └── *.py               # Analysis and automation scripts
├── emulator/              # X16 emulator with MCP integration
└── docs/                  # All project documentation
```

### 🛠️ Development Tools
- **`tools/ai_dev_tool.py`**: Primary tool for testing with visual output
- **MCP Emulator Tools**: Use `use_mcp_tool` for emulator control
- **`make` commands**: Build system for compilation and testing
- **Screenshot tools**: Automated visual verification

## 🚀 GETTING STARTED WORKFLOW

### Step 1: Understand Current State
1. Read `docs/progress.md` to see what's completed
2. Check `dev_logs/` for recent session information
3. Review `docs/plan.md` for technical context
4. Examine current code in `games/pacman/`

### Step 2: Identify Next Task
1. Look for "TODO" items in documentation
2. Check for incomplete features in current code
3. Review test files to understand what's working
4. Consult the human if unclear about priorities

### Step 3: Plan Your Approach
1. Break the task into small, testable pieces
2. Identify what needs to be proven with screenshots
3. Plan your testing strategy
4. Document your approach before coding

### Step 4: Implement & Verify
1. Write small code sections
2. Test each section immediately
3. Capture screenshots of results
4. Use logging to trace execution
5. Verify against expected behavior

### Step 5: Document & Commit
1. Update progress documentation
2. Add session logs
3. Commit working code to git
4. Prepare handoff information for next session

## 🔧 TESTING & VERIFICATION PROCEDURES

### Visual Verification Requirements
```bash
# Always use this for testing with visual proof
python3 tools/ai_dev_tool.py 10

# Look for this output pattern:
🎬 GIF RECORDING EXPORTED:
   📁 File: [filename].gif
   🤖 LLM VIEWING INSTRUCTIONS:
      Use: browser_action -> launch -> file://[full_path]
```

### MCP Emulator Integration
```bash
# Use MCP tools for emulator control
use_mcp_tool -> x16-emulator -> test_program
use_mcp_tool -> x16-emulator -> take_screenshot
use_mcp_tool -> x16-emulator -> take_text_screenshot
```

### Success Criteria Checklist
- [ ] Code compiles without errors
- [ ] Program loads in emulator
- [ ] Visual output matches expectations
- [ ] No crashes or hangs
- [ ] Logging shows expected execution flow
- [ ] Screenshots document functionality

## ⚠️ CRITICAL WARNINGS

### 🛑 STOP CONDITIONS
- If you're repeating the same failed approach 3+ times
- If tests are failing and you can't determine why
- If you're unsure about the technical approach
- If you're about to modify working code without a clear plan

### 🆘 WHEN TO ASK FOR HELP
- Technical decisions about X16 hardware specifics
- Debugging complex assembly issues
- Prioritizing between multiple possible approaches
- Understanding original Pac-Man behavior requirements

### 🚨 NEVER DO THESE
- Skip testing "because it should work"
- Modify multiple components simultaneously
- Assume previous code works without verification
- Proceed without visual confirmation
- Break existing functionality

## 📊 PROGRESS TRACKING

### Current Status Indicators
- **🟢 WORKING**: Proven with screenshots and tests
- **🟡 IN PROGRESS**: Currently being developed
- **🔴 BROKEN**: Known issues that need fixing
- **⚪ PLANNED**: Future work items

### Session Documentation
Each development session must update:
1. `docs/progress.md` - Overall project status
2. `dev_logs/session_[timestamp].json` - Detailed session log
3. Git commits for working code
4. Screenshot evidence in `dev_screenshots/`

## 🎮 COMMANDER X16 SPECIFIC NOTES

### Hardware Constraints
- 65C02 CPU @ 8MHz
- 512KB RAM + 512KB ROM
- VERA graphics chip
- Limited memory banking

### Development Environment
- CC65 toolchain for assembly
- X16 emulator for testing
- Custom MCP integration for automation
- Python tools for analysis

### Key Technical Files
- `framework/core/x16_constants.inc` - Hardware definitions
- `framework/core/x16_system.asm` - System utilities
- `framework/core/vera_graphics.asm` - Graphics routines

## 🎯 SUCCESS METRICS

### Code Quality
- Clean, commented assembly code
- Efficient memory usage
- Proper error handling
- Modular design

### Functionality
- Accurate Pac-Man behavior
- Smooth 60 FPS performance
- Authentic graphics and sound
- Robust input handling

### Process Quality
- Complete documentation
- Comprehensive testing
- Visual verification
- Regression protection

---

## 🚀 READY TO START?

1. **Read the current progress**: Check `docs/progress.md`
2. **Understand the plan**: Review `docs/plan.md`
3. **Set up your environment**: Ensure tools are working
4. **Start small**: Pick the next incremental task
5. **Test everything**: Prove it works with screenshots
6. **Document progress**: Update tracking files

**Remember: This is a marathon, not a sprint. Quality and discipline over speed.**

---

**Last Updated**: 2025-08-02  
**Project Phase**: Progressive Development  
**Current Focus**: Incremental Pac-Man Port to Commander X16
