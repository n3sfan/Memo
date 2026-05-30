export type ResourceAccessRole = 'owner' | 'duo_member' | 'share_link';

export class ResourceAccessDto {
  allowed!: boolean;
  role?: ResourceAccessRole;
}
