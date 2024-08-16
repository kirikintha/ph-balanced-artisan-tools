import { nodeResolve } from '@rollup/plugin-node-resolve';
import commonjs from '@rollup/plugin-commonjs';
import typescript from 'rollup-plugin-typescript2';

export default {
  input: 'src/extension.ts',
  output: {
    file: 'dist/extension.js',
    format: 'esm',
    sourcemap: true,
  },
  external: ['vscode'],
  plugins: [
    nodeResolve(),
    commonjs(),
    typescript({ tsconfig: './tsconfig.rollup.json' }),
  ],
};