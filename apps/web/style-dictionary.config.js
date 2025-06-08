const StyleDictionary = require('style-dictionary');

// Custom transform to create proper HIVE variable names
StyleDictionary.registerTransform({
  name: 'name/hive-kebab',
  type: 'name',
  transformer: function(token) {
    const path = token.path.join('-');
    return `hive-${path.replace(/_/g, '-')}`;
  }
});

// Custom transform group for HIVE CSS variables
StyleDictionary.registerTransformGroup({
  name: 'hive/css',
  transforms: ['attribute/cti', 'name/hive-kebab', 'color/css']
});

module.exports = {
  source: ['../../packages/tokens/src/**/*.json'],
  platforms: {
    css: {
      transformGroup: 'hive/css',
      buildPath: 'styles/',
      files: [
        {
          destination: 'tokens.css',
          format: 'css/variables',
          selector: ':root',
          options: {
            outputReferences: true
          }
        }
      ]
    }
  }
}; 