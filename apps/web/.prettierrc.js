module.exports = {
  // Basic formatting
  semi: true,
  trailingComma: 'never',
  singleQuote: true,
  printWidth: 80,
  tabWidth: 2,
  useTabs: false,
  
  // Line endings (important for cross-platform)
  endOfLine: 'lf',
  
  // JSX specific
  jsxSingleQuote: true,
  jsxBracketSameLine: false,
  
  // Other formatting
  arrowParens: 'avoid',
  bracketSpacing: true,
  insertPragma: false,
  requirePragma: false,
  proseWrap: 'preserve',
  
  // File-specific overrides
  overrides: [
    {
      files: '*.json',
      options: {
        parser: 'json',
        trailingComma: 'none'
      }
    },
    {
      files: '*.md',
      options: {
        parser: 'markdown',
        proseWrap: 'always'
      }
    },
    {
      files: ['*.css', '*.scss'],
      options: {
        parser: 'css'
      }
    }
  ]
}; 