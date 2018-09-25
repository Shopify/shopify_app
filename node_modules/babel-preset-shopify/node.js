const nonStandardPlugins = require('./non-standard-plugins');

module.exports = function shopifyNodePreset(context, options = {}) {
  const {
    version = 'current',
    modules = 'commonjs',
  } = options;

  return {
    presets: [
      [require.resolve('babel-preset-env'), {
        modules,
        useBuiltIns: true,
        targets: {
          node: version,
        },
        debug: options.debug || false,
      }],
      require.resolve('babel-preset-stage-3'),
    ],
    plugins: nonStandardPlugins(options),
  };
};
