
 var path = require('path');
 var webpack = require('webpack');

 module.exports = {
  mode: 'development',
  entry: 'test/javascripts/test.js',
  output: {
      path: path.resolve(__dirname, 'build'),
      filename: 'test.bundle.js'
  },
  module: {
      loaders: [
          {
              test: /\.js$/,
              loader: 'babel-loader',
          }
      ]
  },
  stats: {
      colors: true
  },
  devtool: 'source-map'
 };
 