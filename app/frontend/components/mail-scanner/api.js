export async function markLetterMailed(publicId, csrfToken) {
  const response = await fetch(`/back_office/letters/${publicId}/mark_mailed`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-CSRF-Token': csrfToken,
    },
  });

  const data = await response.json();

  if (!response.ok) {
    if (data.error === 'already_mailed') {
      throw { type: 'already_mailed', letter: data.letter };
    }
    throw { type: 'error', message: data.error || 'Unknown error' };
  }

  return data;
}

export async function undoMarkMailed(publicId, csrfToken) {
  const response = await fetch(`/back_office/letters/${publicId}/undo_mark_mailed`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-CSRF-Token': csrfToken,
    },
  });

  if (!response.ok) {
    const data = await response.json();
    throw new Error(data.error || 'Failed to undo');
  }

  return await response.json();
}
