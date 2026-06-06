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

Trên macOS/Linux:

```bash
cp .env.example .env
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

Trên macOS/Linux:

```bash
curl http://127.0.0.1:3000/api/v1/health
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

Trên macOS/Linux:

```bash
docker compose up -d api
curl http://127.0.0.1:3020/api/v1/health
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

Cách dev local khuyến nghị là chạy Postgres/Redis bằng Docker Compose và chạy API trên host:

```powershell
pnpm install
docker compose up -d --wait postgres redis
pnpm api:start:dev
```

`pnpm api:start:dev` tự chạy `prisma generate` và `prisma migrate deploy` trước khi NestJS start. Vì vậy sau khi pull code mới, reset database hoặc đổi Prisma schema, bạn không cần chạy riêng hai lệnh Prisma này cho flow dev thông thường.

Nếu cần chạy thủ công:

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
docker compose up -d --wait postgres redis
pnpm api:db:deploy
```

## Chạy Frontend Mobile Flutter

Mobile hiện dùng Flutter tại `apps/mobile`. App gọi API thật mặc định
(`USE_MOCK_DATA=false`) với `API_BASE_URL=http://localhost:3000/api/v1`.
Khi muốn chạy frontend mock không cần backend, truyền
`--dart-define=USE_MOCK_DATA=true`.

### Chuẩn Bị Chung

```powershell
cd apps/mobile
flutter pub get
flutter devices
```

Nếu Flutter không nằm trên `PATH` trên Windows, dùng trực tiếp SDK local:

```powershell
cd apps/mobile
& 'C:\Users\Admin\dev\flutter\bin\flutter.bat' pub get
& 'C:\Users\Admin\dev\flutter\bin\flutter.bat' devices
```

Trên macOS/Linux:

```bash
cd apps/mobile
flutter pub get
flutter devices
```

### Chạy Bằng Mock Data

Mock data là cách nhanh nhất để xem UI/frontend.

Windows PowerShell:

```powershell
cd apps/mobile
flutter run --dart-define=USE_MOCK_DATA=true --dart-define=USE_REAL_AUTH=false
```

macOS/Linux:

```bash
cd apps/mobile
flutter run --dart-define=USE_MOCK_DATA=true --dart-define=USE_REAL_AUTH=false
```

Nếu có nhiều device, chỉ định device id từ `flutter devices`:

```powershell
flutter run -d <device-id> --dart-define=USE_MOCK_DATA=true --dart-define=USE_REAL_AUTH=false
```

### Chạy Với API Thật

Bật database và backend trước:

```powershell
docker compose up -d --wait postgres redis
pnpm api:start:dev
```

Với OAuth trên Chrome, giữ web app ở `http://localhost:5000`. Không dùng `127.0.0.1:5000` cho Flutter web vì OAuth callback của API mặc định chuyển về `localhost:5000`; hai host này là hai browser origin khác nhau và có thể làm callback đăng nhập bị đứng ở màn hình trắng.

Với Chrome, Windows desktop, macOS desktop, Linux desktop hoặc iOS simulator
chạy cùng máy host:

```powershell
cd apps/mobile
flutter run -d chrome --web-hostname localhost --web-port 5000
```

Với Android emulator, dùng `10.0.2.2` để trỏ về host machine:

```powershell
cd apps/mobile
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
```

Với thiết bị Android/iOS thật, dùng IP LAN của máy chạy backend:

```powershell
flutter run -d <device-id> --dart-define=API_BASE_URL=http://<LAN_IP>:3000/api/v1
```

Ví dụ:

```powershell
flutter run -d R58N0000000 --dart-define=API_BASE_URL=http://192.168.1.20:3000/api/v1
```

Nếu `.env` đổi `API_HOST_PORT=3020`, thay `3000` bằng `3020`.

### Chạy Trên Windows

Yêu cầu: Flutter SDK, Android Studio/Android emulator hoặc Chrome.

```powershell
cd apps/mobile
flutter pub get
flutter devices
flutter run -d chrome
```

Chạy Android emulator:

```powershell
flutter emulators
flutter emulators --launch <emulator-id>
flutter run -d emulator-5554
```

### Chạy Trên macOS

Yêu cầu: Flutter SDK. Để chạy iOS cần Xcode và CocoaPods.

```bash
cd apps/mobile
flutter pub get
flutter devices
flutter run -d chrome
```

Chạy iOS simulator:

```bash
open -a Simulator
flutter run -d ios
```

Chạy Android emulator trên macOS:

```bash
flutter emulators
flutter emulators --launch <emulator-id>
flutter run -d <android-device-id>
```

### Chạy Trên Linux

Yêu cầu: Flutter SDK, Chrome hoặc Android Studio/Android emulator.

```bash
cd apps/mobile
flutter pub get
flutter devices
flutter run -d chrome
```

Chạy Android emulator:

```bash
flutter emulators
flutter emulators --launch <emulator-id>
flutter run -d <android-device-id>
```

### Chạy Qua Chrome

Project đã có thư mục `apps/mobile/web`, nên có thể chạy Flutter Web bằng
Chrome:

```powershell
cd apps/mobile
flutter config --enable-web
flutter run -d chrome
```

Chạy Chrome với API thật:

```powershell
flutter run -d chrome --web-hostname localhost --web-port 5000
```

Muốn cố định port web để debug:

```powershell
flutter run -d chrome --web-hostname localhost --web-port 5000
```

### Chạy Desktop Preview

Desktop preview không phải target MVP chính, nhưng có thể hữu ích khi kiểm tra
layout. Hiện repo đã có Android và Web platform folders; nếu muốn chạy desktop,
tạo platform folder tương ứng trước.

Windows:

```powershell
cd apps/mobile
flutter config --enable-windows-desktop
flutter create --platforms=windows .
flutter run -d windows
```

macOS:

```bash
cd apps/mobile
flutter config --enable-macos-desktop
flutter create --platforms=macos .
flutter run -d macos
```

Linux:

```bash
cd apps/mobile
flutter config --enable-linux-desktop
flutter create --platforms=linux .
flutter run -d linux
```

### Kiểm Tra Frontend

```powershell
cd apps/mobile
flutter analyze
flutter test
```

Nếu Flutter không nằm trên `PATH`:

```powershell
cd apps/mobile
& 'C:\Users\Admin\dev\flutter\bin\flutter.bat' analyze
& 'C:\Users\Admin\dev\flutter\bin\flutter.bat' test
```

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
