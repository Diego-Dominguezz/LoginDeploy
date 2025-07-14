module.exports = {
    testEnvironment: 'node',
    testMatch: ['**/tests/unit.test.js'],
    collectCoverageFrom: [
        '!**/node_modules/**',
        '!**/test/**',
        '!**/coverage/**'
    ],
    coverageDirectory: 'coverage',
    coverageReporters: ['text', 'lcov', 'html'],
    // NO usar jest.setup.js para pruebas unitarias
    testTimeout: 10000,
    detectOpenHandles: false,
    forceExit: true,
    verbose: true,
    maxWorkers: 1
};
