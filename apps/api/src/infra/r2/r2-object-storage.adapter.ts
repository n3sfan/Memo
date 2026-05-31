import {
  DeleteObjectCommand,
  GetObjectCommand,
  PutObjectCommand,
  S3Client,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { Injectable } from '@nestjs/common';

import { throwInternalError } from '../../common/api-error';
import {
  CreatePresignedUploadInput,
  ObjectStoragePort,
  PresignedRead,
  PresignedUpload,
} from './object-storage.port';

const DEFAULT_R2_REGION = 'auto';
const DEFAULT_UPLOAD_TTL_SECONDS = 15 * 60;
const DEFAULT_READ_TTL_SECONDS = 15 * 60;

@Injectable()
export class R2ObjectStorageAdapter implements ObjectStoragePort {
  private s3Client?: S3Client;

  async createPresignedUpload(
    input: CreatePresignedUploadInput,
  ): Promise<PresignedUpload> {
    const config = this.r2Config();
    const expiresIn = this.ttlSeconds(
      process.env.R2_UPLOAD_TTL_SECONDS,
      DEFAULT_UPLOAD_TTL_SECONDS,
    );
    const command = new PutObjectCommand({
      Bucket: config.bucket,
      Key: input.objectKey,
      ContentType: input.mimeType,
    });

    return {
      uploadUrl: await getSignedUrl(this.client(config), command, {
        expiresIn,
      }),
      objectKey: input.objectKey,
      expiresAt: this.expiresAt(expiresIn),
    };
  }

  async createPresignedRead(objectKey: string): Promise<PresignedRead> {
    const config = this.r2Config();
    const expiresIn = this.ttlSeconds(
      process.env.R2_READ_TTL_SECONDS,
      DEFAULT_READ_TTL_SECONDS,
    );
    const command = new GetObjectCommand({
      Bucket: config.bucket,
      Key: objectKey,
    });

    return {
      readUrl: await getSignedUrl(this.client(config), command, {
        expiresIn,
      }),
      expiresAt: this.expiresAt(expiresIn),
    };
  }

  async deleteObject(objectKey: string): Promise<void> {
    const config = this.r2Config();
    await this.client(config).send(
      new DeleteObjectCommand({
        Bucket: config.bucket,
        Key: objectKey,
      }),
    );
  }

  private client(config: R2Config): S3Client {
    this.s3Client ??= new S3Client({
      region: config.region,
      endpoint: config.endpoint,
      credentials: {
        accessKeyId: config.accessKeyId,
        secretAccessKey: config.secretAccessKey,
      },
    });

    return this.s3Client;
  }

  private r2Config(): R2Config {
    const accountId = process.env.R2_ACCOUNT_ID;
    const endpoint =
      process.env.R2_ENDPOINT ??
      (accountId
        ? `https://${accountId}.r2.cloudflarestorage.com`
        : undefined);
    const bucket = process.env.R2_BUCKET;
    const accessKeyId = process.env.R2_ACCESS_KEY_ID;
    const secretAccessKey = process.env.R2_SECRET_ACCESS_KEY;

    if (!endpoint || !bucket || !accessKeyId || !secretAccessKey) {
      throwInternalError('R2 storage is not configured.');
    }

    return {
      endpoint,
      bucket,
      accessKeyId,
      secretAccessKey,
      region: process.env.R2_REGION || DEFAULT_R2_REGION,
    };
  }

  private ttlSeconds(value: string | undefined, fallback: number): number {
    const parsed = value ? Number(value) : fallback;

    if (!Number.isInteger(parsed) || parsed <= 0) {
      return fallback;
    }

    return parsed;
  }

  private expiresAt(ttlSeconds: number): Date {
    return new Date(Date.now() + ttlSeconds * 1000);
  }
}

interface R2Config {
  endpoint: string;
  bucket: string;
  accessKeyId: string;
  secretAccessKey: string;
  region: string;
}
