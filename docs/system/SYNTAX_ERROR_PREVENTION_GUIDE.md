# HIVE Syntax Error Prevention Guide

## Executive Summary

This guide consolidates all rules and procedures to prevent the syntax errors and compilation failures that we encountered during HIVE development. Following these rules will prevent critical build failures and maintain development velocity.

## 🚨 Critical Error Patterns & Solutions

### 1. "Unknown word" Error at Line 1
**Error Message**: `SyntaxError: Unexpected token, expected ";" (1:1)`  
**Root Cause**: Byte Order Mark (BOM) characters in files  
**Emergency Fix**:
```powershell
taskkill /f /im node.exe
Remove-Item app/globals.css -Force
Set-Content -Path "app/globals.css" -Value "@tailwind base;@tailwind components;@tailwind utilities;body{background:#0D0D0D;color:white;}" -Encoding ASCII
npm run dev
```

### 2. Tailwind Config Parse Error
**Error Message**: `SyntaxError: Unexpected token, expected ";" (234:10)`  
**Root Cause**: Invalid JavaScript object structure  
**Emergency Fix**:
```powershell
Remove-Item tailwind.config.js -Force
Set-Content -Path "tailwind.config.js" -Value "module.exports = {content:['./app/**/*.{js,ts,jsx,tsx}'],theme:{extend:{}},plugins:[]}" -Encoding ASCII
```

### 3. Module Import Errors
**Error Message**: `Module not found: ./design-tokens/colors.json`  
**Root Cause**: Missing files or incorrect import paths  
**Solution**: Always verify file existence before importing in configs

## 📋 File Encoding Rules (CRITICAL)

### Rule 1: Encoding Standards
- **React/TypeScript files**: UTF-8 without BOM
- **Configuration files** (Tailwind, Next.js): ASCII encoding
- **CSS files**: ASCII encoding when issues occur
- **Never use BOM**: Causes "Unknown word" errors

### Rule 2: File Creation Commands
```powershell
# Safe React component creation
Set-Content -Path "component.tsx" -Value "content" -Encoding UTF8NoBOM

# Safe config file creation  
Set-Content -Path "tailwind.config.js" -Value "content" -Encoding ASCII

# Safe CSS file creation
Set-Content -Path "styles.css" -Value "content" -Encoding ASCII
```

### Rule 3: Encoding Verification
```powershell
# Check for BOM
Get-Content -Path "filename" -Encoding Byte | Format-Hex | Select-Object -First 5

# Look for EF BB BF at start = BOM detected
```

## ⚙️ Configuration File Rules

### Rule 4: Tailwind Config Safety
- **Start minimal**: Use basic config template
- **Expand gradually**: Test each addition separately
- **Avoid complex imports**: Only import verified files
- **Use consistent structure**: Follow established patterns

**Safe Tailwind Template**:
```javascript
module.exports = {
  content: ['./app/**/*.{js,ts,jsx,tsx}'],
  theme: { extend: {} },
  plugins: []
}
```

### Rule 5: Import Path Validation
- **Verify file existence** before requiring
- **Use relative paths** consistently
- **Handle missing files** with try-catch
- **Test imports** in isolation

**Safe Import Pattern**:
```javascript
const colors = (() => {
  try {
    return require('./design-tokens/colors.json');
  } catch (error) {
    return { surface: { 0: { value: '#000000' } } };
  }
})();
```

## 🔧 Development Workflow Rules

### Rule 6: Incremental Development
- **One change at a time**: Never make multiple config changes
- **Test after each change**: Verify build passes
- **Commit frequently**: Save working states
- **Kill processes**: Before major config changes

### Rule 7: Pre-Change Checklist
1. ✅ Kill all Node processes (`taskkill /f /im node.exe`)
2. ✅ Backup working configs
3. ✅ Make single focused change
4. ✅ Test build immediately
5. ✅ Commit if successful

### Rule 8: Error Detection Protocol
1. **Read full error message** - don't skip details
2. **Check recently changed files** first
3. **Verify file encodings** if "Unknown word" errors
4. **Test with minimal configs** to isolate issues

## 🛠️ Emergency Recovery Procedures

### Critical Error Response (< 5 minutes)
```powershell
# 1. Kill all Node processes
taskkill /f /im node.exe

# 2. Reset to minimal working config
Remove-Item tailwind.config.js -Force
Set-Content -Path "tailwind.config.js" -Value "module.exports={content:['./app/**/*.{js,ts,jsx,tsx}'],theme:{extend:{}},plugins:[]}" -Encoding ASCII

# 3. Fix CSS if needed
Remove-Item app/globals.css -Force  
Set-Content -Path "app/globals.css" -Value "@tailwind base;@tailwind components;@tailwind utilities;body{background:#0D0D0D;color:white;}" -Encoding ASCII

# 4. Clear build cache
Remove-Item .next -Recurse -Force -ErrorAction SilentlyContinue

# 5. Restart server
npm run dev
```

### File Corruption Recovery
```powershell
# Complete file recreation
Remove-Item problematic-file.js -Force
Set-Content -Path "problematic-file.js" -Value "minimal-content" -Encoding ASCII
# Add content incrementally and test
```

## 🔍 Validation Tools

### Rule 9: Pre-Commit Validation Script
Created validation script at `apps/web/scripts/validate.js`:
- Checks for BOM in critical files
- Validates file existence before builds
- Reports encoding issues immediately

### Rule 10: Automated Linting
ESLint configuration (`.eslintrc.js`):
- Enforces consistent formatting
- Catches syntax errors early
- Validates object structure

Prettier configuration (`.prettierrc.js`):
- Consistent code formatting
- Prevents syntax issues from formatting

## 📊 Success Metrics

### Indicators of Success
- ✅ Home page returns 200 status
- ✅ School selection page returns 200 status  
- ✅ No "Unknown word" errors in build logs
- ✅ Tailwind config loads without errors
- ✅ CSS compiles successfully

### Warning Signs
- ⚠️ Build warnings about encoding
- ⚠️ Slow build times (cache issues)
- ⚠️ Inconsistent behavior across environments

## 🎯 HIVE-Specific Rules

### Rule 11: Design Token Safety
- **Validate JSON structure** before importing
- **Provide fallback values** for missing tokens  
- **Test token files** in isolation
- **Use consistent naming** across all tokens

### Rule 12: Animation Implementation
- **Test emerge animations** on multiple browsers
- **Use CSS keyframes** over complex JavaScript
- **Implement proper timing** for particle effects
- **Ensure performance** on low-end devices

## 📝 Quick Reference Commands

**Check if server is running**:
```powershell
Invoke-WebRequest -Uri http://localhost:3000/ -Method GET -UseBasicParsing
```

**Verify file encoding**:
```powershell
Get-Content -Path "filename" -Encoding Byte | Format-Hex | Select-Object -First 3
```

**Create safe CSS file**:
```powershell
Set-Content -Path "app/globals.css" -Value "@tailwind base;@tailwind components;@tailwind utilities;body{background:#0D0D0D;color:white;}" -Encoding ASCII
```

**Reset to working state**:
```powershell
git checkout HEAD -- tailwind.config.js app/globals.css
```

## 🔐 Never Do List

- ❌ Save files with BOM encoding
- ❌ Make multiple config changes simultaneously
- ❌ Import files without existence verification
- ❌ Use complex CSS properties without testing
- ❌ Skip build testing after changes
- ❌ Copy configs from external sources without validation

## 📚 Lessons Learned

1. **File encoding is critical** - BOM characters cause immediate build failures
2. **Minimal configs work better** - Complex configurations increase error probability
3. **Incremental development prevents issues** - One change at a time is safer
4. **ASCII encoding for configs** - Prevents parsing issues in build tools
5. **Process management matters** - Kill Node processes before major changes

Following these rules religiously will prevent the critical syntax errors that can halt development and maintain the high-quality HIVE development experience. 