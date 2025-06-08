#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

console.log('🔍 HIVE Syntax Validation');
console.log('========================');

let hasErrors = false;

// Check for BOM in critical files
function checkForBOM(filePath) {
  try {
    const buffer = fs.readFileSync(filePath);
    const hasBOM = buffer.length >= 3 && 
                   buffer[0] === 0xEF && 
                   buffer[1] === 0xBB && 
                   buffer[2] === 0xBF;
    
    if (hasBOM) {
      console.error(`❌ BOM detected in: ${filePath}`);
      console.error('   Fix: Recreate file with UTF-8 without BOM');
      hasErrors = true;
    } else {
      console.log(`✅ ${filePath} - No BOM`);
    }
  } catch (error) {
    console.log(`⚠️  Could not read: ${filePath}`);
  }
}

// Check JavaScript/TypeScript syntax
function checkJSSyntax(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf-8');
    
    // Check for common issues
    const issues = [];
    
    // Check for orphaned content after closing braces
    const lines = content.split('\n');
    let braceCount = 0;
    let foundClosingBrace = false;
    
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();
      
      if (line.includes('{')) braceCount += (line.match(/\{/g) || []).length;
      if (line.includes('}')) {
        braceCount -= (line.match(/\}/g) || []).length;
        if (line === '}' && braceCount === 0) {
          foundClosingBrace = true;
          // Check if there's content after this closing brace
          for (let j = i + 1; j < lines.length; j++) {
            const nextLine = lines[j].trim();
            if (nextLine && !nextLine.startsWith('//') && !nextLine.startsWith('/*')) {
              issues.push(`Potential orphaned content after line ${i + 1}: "${nextLine}"`);
              break;
            }
          }
        }
      }
    }
    
    // Check for missing module.exports ending
    if (filePath.endsWith('.js') && content.includes('module.exports') && !content.trim().endsWith('}')) {
      issues.push('Missing proper module.exports closing');
    }
    
    if (issues.length > 0) {
      console.error(`❌ Issues in: ${filePath}`);
      issues.forEach(issue => console.error(`   - ${issue}`));
      hasErrors = true;
    } else {
      console.log(`✅ ${filePath} - Structure OK`);
    }
    
  } catch (error) {
    console.error(`❌ Error reading ${filePath}: ${error.message}`);
    hasErrors = true;
  }
}

// Check CSS syntax
function checkCSSSyntax(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf-8');
    
    // Check for balanced braces
    const openBraces = (content.match(/\{/g) || []).length;
    const closeBraces = (content.match(/\}/g) || []).length;
    
    if (openBraces !== closeBraces) {
      console.error(`❌ Unbalanced braces in: ${filePath}`);
      console.error(`   Open: ${openBraces}, Close: ${closeBraces}`);
      hasErrors = true;
    } else {
      console.log(`✅ ${filePath} - Braces balanced`);
    }
    
    // Check for problematic properties
    const problematicProps = ['inset:', 'mask:', '-webkit-mask:'];
    problematicProps.forEach(prop => {
      if (content.includes(prop)) {
        console.warn(`⚠️  Potentially problematic CSS property "${prop}" in: ${filePath}`);
      }
    });
    
  } catch (error) {
    console.error(`❌ Error reading ${filePath}: ${error.message}`);
    hasErrors = true;
  }
}

// Files to check
const filesToCheck = [
  'app/globals.css',
  'tailwind.config.js',
  'next.config.js',
  'app/layout.tsx'
];

console.log('\n📁 Checking critical files...');
filesToCheck.forEach(file => {
  const fullPath = path.join(process.cwd(), file);
  
  if (fs.existsSync(fullPath)) {
    console.log(`\n🔍 Checking: ${file}`);
    
    // Check for BOM
    checkForBOM(fullPath);
    
    // Check syntax based on file type
    if (file.endsWith('.js')) {
      checkJSSyntax(fullPath);
    } else if (file.endsWith('.css')) {
      checkCSSSyntax(fullPath);
    } else if (file.endsWith('.tsx') || file.endsWith('.ts')) {
      // For TS files, just check BOM for now
      console.log(`✅ ${file} - TypeScript file checked`);
    }
  } else {
    console.log(`⚠️  File not found: ${file}`);
  }
});

console.log('\n🔧 Running build test...');
try {
  execSync('npm run build:check', { stdio: 'pipe' });
  console.log('✅ Build test passed');
} catch (error) {
  console.error('❌ Build test failed');
  console.error(error.stdout?.toString() || error.message);
  hasErrors = true;
}

console.log('\n' + '='.repeat(50));
if (hasErrors) {
  console.error('❌ VALIDATION FAILED - Fix errors before proceeding');
  process.exit(1);
} else {
  console.log('✅ ALL CHECKS PASSED - Ready to proceed');
  process.exit(0);
} 