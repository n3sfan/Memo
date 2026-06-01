import { isAllowedOrigin } from '../../src/common/cors-options';

describe('CORS options', () => {
  it('allows Flutter web localhost origins with any dev port', () => {
    expect(isAllowedOrigin('http://localhost:53421')).toBe(true);
    expect(isAllowedOrigin('http://127.0.0.1:53421')).toBe(true);
  });

  it('allows configured origins', () => {
    expect(
      isAllowedOrigin(
        'https://memo.example.com',
        new Set(['https://memo.example.com']),
      ),
    ).toBe(true);
  });

  it('rejects untrusted non-local origins', () => {
    expect(isAllowedOrigin('https://evil.example.com')).toBe(false);
  });
});
