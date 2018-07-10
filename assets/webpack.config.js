const path = require('path');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const UglifyJsPlugin = require('uglifyjs-webpack-plugin');
const OptimizeCSSAssetsPlugin = require('optimize-css-assets-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');

module.exports = (env, options) => {
  const isDev = options.mode == 'development';

  return {
    optimization: {
      minimizer: [
        new UglifyJsPlugin({ cache: true, parallel: true, sourceMap: isDev }),
        new OptimizeCSSAssetsPlugin({})
      ]
    },
    entry: {
        'app': ['./js/app.js', './css/app.css']
    },

    resolve: {
      extensions: ['.js', '.elm'],
      modules: ['node_modules']
    },
    output: {
      filename: '[name].js',
      path: path.resolve(__dirname, '../priv/static/js')
    },
    module: {
      rules: [
        {
          test: /\.js$/,
          exclude: /node_modules/,
          use: {
            loader: 'babel-loader'
          }
        },
        {
          test: /\.elm$/,
          exclude: [/elm-stuff/, /node_modules/],
          use: [{
            loader: 'elm-webpack-loader',
            options: {
              verbose: isDev,
              warn: isDev,
              debug: isDev
            }
          }]
        },
        {
          test: /\.css$/,
          use: [MiniCssExtractPlugin.loader, 'css-loader']
        },
        {
          test: /\.scss$/,
          use: [
            MiniCssExtractPlugin.loader,
            'css-loader',
            'sass-loader'
          ]
        }
      ]
    },
    plugins: [
      new MiniCssExtractPlugin({
        filename: "../css/[name].css"
      }),
      new CopyWebpackPlugin([{ from: 'static/', to: '../' }])
    ]
  }
};
