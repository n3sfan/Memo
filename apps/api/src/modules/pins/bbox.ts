import { throwValidationError } from '../../common/api-error';

export interface Bbox {
  minLng: number;
  minLat: number;
  maxLng: number;
  maxLat: number;
}

export function parseBbox(raw?: string): Bbox {
  if (!raw) {
    return invalidBbox(raw, 'bbox is required.');
  }

  const values = raw.split(',').map((value) => Number(value.trim()));

  if (values.length !== 4 || values.some((value) => !Number.isFinite(value))) {
    return invalidBbox(raw, 'bbox must contain four finite numbers.');
  }

  const [minLng, minLat, maxLng, maxLat] = values as [
    number,
    number,
    number,
    number,
  ];

  if (minLng < -180 || maxLng > 180 || minLng >= maxLng) {
    return invalidBbox(raw, 'bbox longitude bounds are invalid.');
  }

  if (minLat < -90 || maxLat > 90 || minLat >= maxLat) {
    return invalidBbox(raw, 'bbox latitude bounds are invalid.');
  }

  return {
    minLng,
    minLat,
    maxLng,
    maxLat,
  };
}

function invalidBbox(raw: string | undefined, reason: string): never {
  throwValidationError('Invalid bbox query.', {
    bbox: raw,
    reason,
  });
}
