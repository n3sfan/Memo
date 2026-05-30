export interface CurrentUser {
  id: string;
  email?: string | null;
  displayName?: string | null;
  provider?: string | null;
}

export interface RequestWithCurrentUser {
  headers?: Record<string, string | string[] | undefined>;
  user?: CurrentUser;
}
