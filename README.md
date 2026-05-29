# Bản Đồ Kỷ Niệm

Ứng dụng mobile-first để lưu kỷ niệm theo tọa độ, gồm backend NestJS và mobile Flutter trong một monorepo.

## Trạng Thái Hiện Tại

Đã có:

- Monorepo skeleton.
- Backend NestJS skeleton tại `apps/api`.
- Mobile Flutter skeleton tại `apps/mobile`.
- Docker Compose local gồm API, PostgreSQL/PostGIS và Redis.
- PM2 cluster config cho triển khai VPS.
- Nginx TLS reverse proxy template.

Chưa có:

- Prisma schema/migration thật.
- Các module nghiệp vụ Auth, Pins, Maps, Media, Sharing, Account.
- UI mobile hoàn chỉnh.

Vì vậy hiện tại dự án chạy được ở mức **backend skeleton + health check**. Chưa phải app đầy đủ.

## Yêu Cầu Máy Local

- Node.js 20+.
- pnpm 10+.
- Docker Desktop hoặc Docker Engine có Docker Compose.
- Flutter SDK nếu muốn chạy mobile. Hiện backend không cần Flutter.

Kiểm tra nhanh:

```powershell
node --version
pnpm --version
docker --version
docker compose version
```

## Cấu Hình Env

Tạo file `.env` từ mẫu:

```powershell
Copy-Item .env.example .env
```

Với chạy local Docker, tối thiểu cần điền:

```env
POSTGRES_DB=memory_map
POSTGRES_USER=memory_map
POSTGRES_PASSWORD=<mat-khau-random>
DATABASE_URL=postgresql://memory_map:<mat-khau-random>@127.0.0.1:5432/memory_map?schema=public
JWT_ACCESS_SECRET=<secret-random>
JWT_REFRESH_SECRET=<secret-random-khac>
```

Tạo secret random bằng Node:

```powershell
node -e "console.log(require('crypto').randomBytes(32).toString('base64url'))"
```

Các biến R2, Google OAuth, Apple OAuth có thể để trống trong giai đoạn skeleton vì backend hiện chưa gọi tới chúng.

## Chạy Backend Bằng Docker

Từ root repo:

```powershell
docker compose up -d --build
```

Kiểm tra trạng thái:

```powershell
docker compose ps
```

Health check API:

```powershell
Invoke-RestMethod http://127.0.0.1:3000/api/v1/health
```

Kết quả mong đợi:

```json
{
  "status": "ok"
}
```

Nếu cổng `3000` đang bị chiếm, đổi cổng host trong `.env`:

```env
API_BIND_HOST=127.0.0.1
API_HOST_PORT=3020
```

Sau đó chạy lại:

```powershell
docker compose up -d api
Invoke-RestMethod http://127.0.0.1:3020/api/v1/health
```

Xem log API:

```powershell
docker compose logs -f api
```

Dừng stack:

```powershell
docker compose down
```

Xóa cả volume database local nếu muốn reset sạch dữ liệu:

```powershell
docker compose down -v
```

## Chạy Backend Không Qua Docker

Hiện cách khuyến nghị là chạy API bằng Docker Compose vì `docker-compose.yml` đang để API nói chuyện với Postgres/Redis qua network nội bộ Docker.

Nếu muốn chạy `pnpm api:start:dev` trên host, cần publish cổng Postgres/Redis ra localhost trong `docker-compose.yml` hoặc tự cài Postgres/Redis local. Phần này chưa được chuẩn hóa vì task hiện tại mới dừng ở hạ tầng Docker.

Các lệnh backend hiện có:

```powershell
pnpm install
pnpm api:prisma:validate
pnpm api:prisma:generate
pnpm api:db:deploy
pnpm api:build
pnpm api:test
pnpm api:test:property
```

Nếu bạn đã từng chạy Postgres Docker rồi sau đó đổi `POSTGRES_PASSWORD`, volume cũ vẫn giữ password lúc khởi tạo lần đầu. Với DB dev local có thể reset sạch bằng:

```powershell
docker compose down -v
docker compose up -d postgres redis
pnpm api:db:deploy
```

## Mobile Flutter

Mobile hiện là skeleton cấu trúc thư mục và dependency.

Sau khi cài Flutter SDK:

```powershell
cd apps/mobile
flutter pub get
flutter analyze
flutter test
```

Trong máy hiện tại, Flutter/Dart chưa có trong PATH nên phần mobile chưa được verify bằng command.

## Deploy VPS Tóm Tắt

Tài liệu deploy nằm ở `deploy/README.md`.

Luồng cơ bản:

```bash
pnpm install --frozen-lockfile
pnpm api:build
pm2 start apps/api/ecosystem.config.js --env production
pm2 save
```

Render Nginx config:

```bash
DOMAIN=api.example.com \
API_UPSTREAM=127.0.0.1:3000 \
deploy/scripts/render-nginx-config.sh
```

Install Nginx site:

```bash
DOMAIN=api.example.com deploy/scripts/install-nginx-site.sh
```

TLS mặc định dùng Let's Encrypt/Certbot path:

```text
/etc/letsencrypt/live/<domain>/fullchain.pem
/etc/letsencrypt/live/<domain>/privkey.pem
```

## Task Tiếp Theo

Task tiếp theo theo spec là task 4:

- Auth OAuth, JWT, refresh/logout và AuthGuard.

Sau task 3, API đã có database contract nền để các module Auth, Pins, Maps, Media, Sharing và Account dùng.
