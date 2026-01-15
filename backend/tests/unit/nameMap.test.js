const { resolveDisplayName } = require('../../src/nameMap');

describe('nameMap', () => {
  test('returns mapped name if exists', () => {
    expect(resolveDisplayName('v_patient_public')).toBe('患者公开信息');
  });

  test('returns comment if no map exists', () => {
    expect(resolveDisplayName('unknown_table', 'Some Comment')).toBe('Some Comment');
  });

  test('returns object name if no map and no comment', () => {
    expect(resolveDisplayName('unknown_table')).toBe('unknown_table');
  });
});
