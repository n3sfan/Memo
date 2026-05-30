export interface ApiEnvelope<TData> {
  data: TData;
  requestId: string;
}

export function createEnvelope<TData>(
  data: TData,
  requestId?: string,
): ApiEnvelope<TData> {
  return {
    data,
    requestId: requestId ?? '',
  };
}

export interface ApiErrorBody {
  error: string;
  message: string;
  details: Record<string, unknown>;
  requestId: string;
}
