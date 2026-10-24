/** Babel for the shell: babel-preset-expo is all the SDK needs. */
module.exports = (api) => {
  api.cache(true);
  return {
    presets: ['babel-preset-expo'],
  };
};
