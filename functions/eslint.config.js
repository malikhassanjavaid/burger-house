"use strict";

module.exports = [
  {
    ignores: ["node_modules/**"],
  },
  {
    files: ["**/*.js"],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "commonjs",
      globals: {
        console: "readonly",
        exports: "writable",
        module: "readonly",
        require: "readonly",
      },
    },
    rules: {
      "comma-dangle": ["error", "always-multiline"],
      "eol-last": ["error", "always"],
      "indent": ["error", 2],
      "max-len": ["error", {code: 100, ignoreUrls: true}],
      "no-trailing-spaces": "error",
      "quotes": ["error", "double", {allowTemplateLiterals: true}],
      "semi": ["error", "always"],
    },
  },
];
