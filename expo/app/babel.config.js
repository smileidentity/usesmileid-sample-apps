/** Babel for the shell. babel-preset-expo is all the SDK needs; the worklets plugin is Reanimated's. */
module.exports = (api) => {
  api.cache(true);
  return {
    presets: ['babel-preset-expo'],
    // Must stay last: the worklets plugin rewrites what every earlier plugin has already produced.
    plugins: ['react-native-worklets/plugin'],
  };
};
