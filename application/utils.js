'use strict';

function printJSON(buffer) {
  const str = Buffer.from(buffer).toString('utf8');
  try {
    const obj = JSON.parse(str);
    console.log('\nRezultat:');
    console.log(JSON.stringify(obj, null, 2));
  } catch {
    console.log('\nRezultat:', str);
  }
}

function extractErrorMessage(error) {
  const details = error.details || [];
  if (details.length > 0) {
    return details.map(d => d.message).join('; ');
  }
  return error.message || String(error);
}

module.exports = { printJSON, extractErrorMessage };
