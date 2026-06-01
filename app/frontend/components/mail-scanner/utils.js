/**
 * Extracts a letter public ID from various input formats:
 * - URLs: https://mail.hack.club/ltr!abc123?qr=1
 * - Bare IDs: ltr!abc123
 * - Different domains: http://example.com/ltr!abc123
 */
export function extractPublicId(text) {
  if (!text || typeof text !== 'string') {
    return null;
  }

  // Remove any whitespace
  text = text.trim();

  // Strategy 1: Try to extract from URL
  // Match: https://mail.hack.club/ltr!abc123?qr=1
  // Or any URL with a path segment containing ltr!...
  const urlMatch = text.match(/(?:https?:\/\/[^\/]+\/)?([a-z]{3}![a-zA-Z0-9]+)/);
  if (urlMatch) {
    return urlMatch[1];
  }

  // Strategy 2: Check if the text itself looks like a public ID
  // Format: ltr!{hashid} (3 letter prefix, !, then alphanumeric)
  const bareIdMatch = text.match(/^([a-z]{3}![a-zA-Z0-9]+)$/);
  if (bareIdMatch) {
    return bareIdMatch[1];
  }

  return null;
}
