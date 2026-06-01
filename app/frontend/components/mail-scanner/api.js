export async function markLetterMailed(publicId, csrfToken) {
  try {
    const response = await fetch(`/back_office/letters/${publicId}/mark_mailed`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-CSRF-Token': csrfToken,
      },
    });

    // Check if response is actually JSON
    const contentType = response.headers.get('content-type');
    if (!contentType || !contentType.includes('application/json')) {
      throw { type: 'error', message: `Letter not found: ${publicId}` };
    }

    const data = await response.json();

    if (!response.ok) {
      if (data.error === 'already_mailed') {
        throw { type: 'already_mailed', letter: data.letter };
      }
      throw { type: 'error', message: data.error || 'Unknown error' };
    }

    return data;
  } catch (error) {
    // If it's already our error format, re-throw
    if (error.type) {
      throw error;
    }
    // Otherwise wrap it
    throw { type: 'error', message: error.message || 'Network error' };
  }
}

export async function undoMarkMailed(publicId, csrfToken) {
  try {
    const response = await fetch(`/back_office/letters/${publicId}/undo_mark_mailed`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-CSRF-Token': csrfToken,
      },
    });

    const contentType = response.headers.get('content-type');
    if (!contentType || !contentType.includes('application/json')) {
      throw new Error(`Letter not found: ${publicId}`);
    }

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.error || 'Failed to undo');
    }

    return data;
  } catch (error) {
    throw new Error(error.message || 'Network error');
  }
}
