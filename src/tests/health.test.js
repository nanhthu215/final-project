const fs = require('fs');
const path = require('path');

console.log('Running basic application structure tests...');

const filesToCheck = [
    'src/main.js',
    'src/package.json',
    'src/controllers',
    'src/routes',
    'src/services'
];

let failed = false;

filesToCheck.forEach(file => {
    const fullPath = path.join(__dirname, '../../', file);
    if (fs.existsSync(fullPath)) {
        console.log(`[PASS] ${file} exists.`);
    } else {
        console.error(`[FAIL] ${file} is missing!`);
        failed = true;
    }
});

if (failed) {
    console.error('Tests failed!');
    process.exit(1);
} else {
    console.log('All structure tests passed!');
    process.exit(0);
}
