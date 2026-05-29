# Kế hoạch Triển khai (Implementation Plan): Bản Đồ Kỷ Niệm (Memory Map) — MVP (Phase 1)

## Tổng quan (Overview)

Kế hoạch này chuyển thiết kế MVP thành chuỗi coding task tăng dần (incremental), test-driven, không có code mồ côi. Mỗi task xây dựng trên các task trước và kết thúc bằng việc tích hợp (wiring) các thành phần lại với nhau.

**Stack đã chốt (theo design):**
- **Backend:** NestJS (Node.js/TypeScript), PostgreSQL + PostGIS (`geometry(Point,4326)` + GiST), Prisma ORM + `$queryRaw` cho spatial, Redis (cache tiling + token denylist), Cloudflare R2 (presigned URL — không lưu nhị phân ở server/DB), Docker + PM2 cluster + Nginx TLS.
- **Mobile:** Flutter (Dart), `flutter_map`/`mapbox_maps_flutter`, `drift`/`sqflite` + `shared_preferences`, `connectivity_plus`, `workmanager`, `flutter_image_compress`, `record`, `image_picker`, `dio`, `go_router`, Riverpod/Bloc, `intl` + `flutter_localizations` (ARB, tiếng Việt mặc định).

**Quy ước Property-Based Testing (PBT):**
- Backend: **fast-check** (chạy với Jest). Mobile: **glados** (chạy với `flutter test`). Không tự cài đặt PBT từ đầu.
- Mỗi property test chạy **tối thiểu 100 vòng** (fast-check `{ numRuns: 100 }`; glados `ExploreConfig(numRuns: 100)`).
- Nhãn mỗi test PBT theo định dạng: `// Feature: ban-do-ky-niem, Property {n}: {property_text}`.

**Quy ước task:** Task có hậu tố `*` là test (unit/property/integration) — **tùy chọn**, có thể bỏ qua cho MVP nhanh. Task không có `*` là cốt lõi, bắt buộc thực hiện.

## Tasks

- [x] 1. Khởi tạo monorepo và skeleton hai ứng dụng (apps/api + apps/mobile)
  - [x] 1.1 Tạo cấu trúc monorepo và backend skeleton (NestJS)
    - Tạo `apps/api` với cấu trúc `src/{common,modules,infra,domain}`, `test/{unit,property,integration}` theo design "Cấu trúc Project"
    - Khởi tạo NestJS (`main.ts`, `app.module.ts`) ở mức skeleton, prefix `/api/v1`
    - Cấu hình test framework backend: Jest + **fast-check** (devDependency), script `test`/`test:property`
    - _Requirements: 1.1, 2.1_

  - [x] 1.2 Tạo mobile skeleton (Flutter)
    - Tạo `apps/mobile` với cấu trúc `lib/{app,data,sync,media,auth,l10n}`, `test/{unit,property}`
    - Khai báo dependencies trong `pubspec.yaml`: `flutter_map`/`mapbox_maps_flutter`, `drift`, `sqflite`, `shared_preferences`, `connectivity_plus`, `workmanager`, `flutter_image_compress`, `record`, `image_picker`, `dio`, `go_router`, `flutter_riverpod` (hoặc `flutter_bloc`), `intl`, `flutter_localizations`, `glados` (dev)
    - Cấu hình `analysis_options.yaml` (flutter_lints) và test framework `flutter test` + **glados**
    - _Requirements: 1.1, 7.2, 9.1_

- [x] 2. Hạ tầng triển khai (Docker, PM2, Nginx TLS)
  - [x] 2.1 Viết `docker-compose.yml` + `Dockerfile` backend
    - Service `postgres` dùng image PostGIS, service `redis`, service `api`
    - Biến môi trường kết nối PG/Redis/R2, volume bền vững cho Postgres
    - _Requirements: 7.3, 7.4_

  - [x] 2.2 Cấu hình PM2 cluster (`ecosystem.config.js`)
    - Chạy nhiều instance NestJS (cluster mode), app tier stateless (phiên/denylist ở Redis)
    - _Requirements: 1.6_

  - [x] 2.3 Cấu hình Nginx TLS + script reverse proxy
    - TLS termination, redirect HTTP→HTTPS, bật HSTS, proxy tới cluster PM2
    - _Requirements: 10.5_

- [ ] 3. Schema cơ sở dữ liệu và migration (Prisma + PostGIS)
  - [ ] 3.1 Định nghĩa Prisma schema + client (`infra/prisma`)
    - Models: `users`, `maps`, `map_members`, `pins` (lat/lng + `geom Unsupported("geometry(Point,4326)")`), `media_files`, `invitations`, `share_links`
    - Sinh migration baseline
    - _Requirements: 2.1, 3.3, 4.1, 6.1, 10.2_

  - [ ] 3.2 Bổ sung migration SQL cho PostGIS và ràng buộc tọa độ
    - `CREATE EXTENSION postgis`; cột `geom geometry(Point,4326) NOT NULL`
    - `CHECK (lat BETWEEN -90 AND 90)`, `CHECK (lng BETWEEN -180 AND 180)`; CHECK enum `type`/`role`/`status`
    - _Requirements: 2.3, 3.4_

  - [ ] 3.3 Bổ sung migration SQL cho các chỉ mục
    - GiST `idx_pins_geom`; `idx_pins_map_memory (map_id, memory_date DESC)`; partial unique `uniq_pending_invitation ON invitations(map_id) WHERE status='pending'`
    - _Requirements: 7.3, 8.1, 4.3_

  - [ ]* 3.4 Static check schema không lưu nhị phân media
    - Kiểm tra không có cột `bytea`/`blob` cho media; `media_files` chỉ có `object_key` + metadata
    - _Requirements: 3.4_

- [ ] 4. Auth Module — OAuth, JWT, denylist (Req 1)
  - [ ] 4.1 Viết token verifier thuần (`auth/token.ts`)
    - Hàm thuần kiểm chữ ký + `exp > now` + `jti` không trong denylist → accept/reject
    - _Requirements: 1.4, 1.6_

  - [ ]* 4.2 Viết property test cho token verifier
    - **Property 14: Xác thực token — hết hạn hoặc bị thu hồi đều bị từ chối**
    - **Validates: Requirements 1.4, 1.6**

  - [ ] 4.3 Viết logic upsert tài khoản OAuth (`auth.service` + repo)
    - Upsert theo `(provider, provider_user_id)`, idempotent, không tạo bản ghi trùng
    - _Requirements: 1.2_

  - [ ]* 4.4 Viết property test cho upsert OAuth
    - **Property 15: Upsert tài khoản OAuth idempotent**
    - **Validates: Requirements 1.2**

  - [ ] 4.5 Triển khai luồng OAuth + JWT + logout + AuthGuard
    - Endpoint `start`/`callback` (đổi code), cấp access/refresh, `refresh`, `logout` (đưa `jti` vào Redis denylist), `AuthGuard` từ chối 401 khi token thiếu/sai/hết hạn/thu hồi
    - Tạo Personal_Map mặc định khi tạo user mới
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.6_

  - [ ]* 4.6 Viết unit/example test luồng OAuth
    - Thành công cấp token; thất bại/hủy → 401 `oauth_failed` không cấp token
    - _Requirements: 1.1, 1.3_

- [ ] 5. Pins Module — CRUD + validate tọa độ + cascade delete (Req 2)
  - [ ] 5.1 Viết hàm thuần `validateCoordinates` (`pins/coordinates.ts`)
    - Chấp nhận khi và chỉ khi `lat ∈ [-90,90]` và `lng ∈ [-180,180]`, ngược lại lỗi validate
    - _Requirements: 2.3_

  - [ ]* 5.2 Viết property test cho validate tọa độ
    - **Property 1: Validate tọa độ đúng biên**
    - **Validates: Requirements 2.3**

  - [ ] 5.3 Triển khai PinsService CRUD + đồng bộ `geom`
    - Create/update Pin set `geom = ST_SetSRID(ST_MakePoint(lng,lat),4326)` qua `$queryRaw`; lưu `updated_at`; repository đọc lại Pin
    - _Requirements: 2.1, 2.2, 2.4_

  - [ ]* 5.4 Viết property test round-trip Pin
    - **Property 2: Round-trip tạo & đọc Pin**
    - **Validates: Requirements 2.1, 2.4**

  - [ ] 5.5 Triển khai xóa Pin kèm cascade media (R2 + DB)
    - Xóa Pin → xóa toàn bộ `media_files` của Pin trong DB và yêu cầu xóa `object_key` trên R2
    - _Requirements: 2.5_

  - [ ]* 5.6 Viết property test xóa Pin → xóa Media
    - **Property 3: Xóa Pin xóa kèm toàn bộ Media**
    - **Validates: Requirements 2.5**

  - [ ] 5.7 Triển khai PinsController (POST/GET/PATCH/DELETE)
    - `POST /maps/:mapId/pins`, `GET /pins/:pinId`, `PATCH /pins/:pinId`, `DELETE /pins/:pinId`; trả 422 khi tọa độ sai
    - _Requirements: 2.1, 2.3, 2.4, 2.5_

- [ ] 6. Authorization resolver — phân quyền không rò rỉ (Req 2, 5, 10)
  - [ ] 6.1 Viết resolver quyền thuần (`common/authorization.ts`)
    - Cấp quyền khi và chỉ khi Owner của Personal_Map, Member của Duo_Map, hoặc giữ Share_Link hợp lệ đúng phạm vi 1 Pin
    - _Requirements: 2.6, 2.7, 3.7, 5.3, 5.5, 10.1_

  - [ ]* 6.2 Viết property test phân quyền
    - **Property 4: Phân quyền nhất quán, không rò rỉ dữ liệu giữa người dùng**
    - **Validates: Requirements 2.6, 2.7, 3.7, 5.3, 5.5, 10.1**

  - [ ] 6.3 Tích hợp resolver vào Pins/Media controller
    - Sửa/xóa không quyền → 403; truy vấn Pin của Personal_Map không sở hữu → kết quả rỗng
    - _Requirements: 2.6, 2.7, 5.5_

- [ ] 7. Media Module — presigned R2, chỉ lưu tham chiếu (Req 3)
  - [ ] 7.1 Triển khai R2 S3 client + signer (`infra/r2`)
    - Interface ký presigned PUT/GET (mockable cho test), không truyền nhị phân qua backend
    - _Requirements: 3.3, 3.7_

  - [ ] 7.2 Triển khai MediaService (upload-url / register / get-url / delete)
    - Sinh presigned PUT (kiểm `sizeBytes ≤ maxSize`, 413 nếu vượt), đăng ký reference (`status pending→ready`), presigned GET có hạn, xóa object + reference
    - _Requirements: 3.3, 3.5, 3.6, 3.7_

  - [ ]* 7.3 Viết property test DB chỉ lưu tham chiếu
    - **Property 18: DB chỉ lưu tham chiếu Media, không lưu nhị phân**
    - **Validates: Requirements 3.3, 3.4**

  - [ ] 7.4 Triển khai MediaController
    - `POST /pins/:pinId/media/upload-url`, `POST /pins/:pinId/media`, `GET /media/:mediaId/url`, `DELETE /media/:mediaId`
    - _Requirements: 3.3, 3.5, 3.7_

- [ ] 8. Maps Module — bounding-box, timeline, cache (Req 7, 8)
  - [ ] 8.1 Viết hàm thuần `filterByBbox` (`maps/bbox.ts`)
    - Trả đúng tập Pin có tọa độ nằm trong Bounding_Box (soundness + completeness)
    - _Requirements: 7.1, 7.2_

  - [ ]* 8.2 Viết property test bounding-box
    - **Property 8: Tính đúng & đủ của truy vấn Bounding_Box**
    - **Validates: Requirements 7.1, 7.2**

  - [ ] 8.3 Viết hàm thuần `sortTimeline` (`maps/timeline.ts`)
    - Hoán vị đầy đủ tập Pin, sắp đơn điệu theo `memoryDate` (asc/desc), Pin thiếu `memoryDate` đẩy cuối (không loại bỏ)
    - _Requirements: 8.1, 8.2, 8.3_

  - [ ]* 8.4 Viết property test sắp xếp timeline
    - **Property 10: Sắp xếp Timeline đơn điệu và bảo toàn tập Pin**
    - **Validates: Requirements 8.1, 8.2, 8.3**

  - [ ] 8.5 Triển khai MapsService truy vấn PostGIS (bbox + timeline)
    - Bbox qua `$queryRaw` `geom && ST_MakeEnvelope(...,4326)`; timeline `ORDER BY memory_date`
    - _Requirements: 7.1, 7.3, 8.1_

  - [ ] 8.6 Triển khai Redis tiling cache + invalidation (`maps/cache.service.ts`)
    - Snap bbox về lưới → cacheKey, `SETEX` TTL, tập ngược `mm:tiles:{mapId}`; khi Pin thay đổi/xóa → invalidate tile liên quan; fail-open khi Redis lỗi
    - _Requirements: 7.4, 7.5_

  - [ ]* 8.7 Viết property test nhất quán cache
    - **Property 9: Nhất quán cache với nguồn dữ liệu sau invalidation**
    - **Validates: Requirements 7.5**

  - [ ] 8.8 Triển khai MapsController
    - `POST /maps`, `GET /maps/:mapId/pins?bbox=...`, `GET /maps/:mapId/timeline?order=...`
    - _Requirements: 7.1, 8.1_

- [ ] 9. Sharing Module — Duo Map + Share Link (Req 4, 5, 6)
  - [ ] 9.1 Viết hàm thuần bất biến thành viên (`sharing/membership.ts`)
    - Duo_Map ≤ 2 Member; map mới có đúng Owner; join chỉ thành công khi đã xác thực + invitation hợp lệ + chưa đầy
    - _Requirements: 4.1, 4.4, 4.5, 5.1_

  - [ ]* 9.2 Viết property test bất biến thành viên
    - **Property 5: Bất biến thành viên Duo_Map (đúng tối đa 2)**
    - **Validates: Requirements 4.1, 4.4, 4.5, 5.1**

  - [ ] 9.3 Viết hàm thuần vòng đời invitation (`sharing/invitation.ts`)
    - Tối đa 1 invitation `pending`/map; sau accept/revoke/expire → vô hiệu hóa, dùng lại bị từ chối
    - _Requirements: 4.2, 4.3, 4.6, 4.7, 5.2_

  - [ ]* 9.4 Viết property test vòng đời invitation
    - **Property 6: Bất biến một Invitation pending & vô hiệu hóa sau dùng/thu hồi/hết hạn**
    - **Validates: Requirements 4.2, 4.3, 4.6, 4.7, 5.2**

  - [ ] 9.5 Viết hàm thuần share-link (`sharing/share-link.ts`)
    - Resolve token → đúng nội dung + tọa độ của đúng 1 Pin, không lộ Pin/map khác; sau revoke → resolve bị từ chối
    - _Requirements: 6.1, 6.2, 6.3, 6.4_

  - [ ]* 9.6 Viết property test share-link
    - **Property 7: Round-trip & cách ly Share_Link**
    - **Validates: Requirements 6.1, 6.2, 6.3, 6.4**

  - [ ] 9.7 Triển khai SharingService — Duo (invite/accept/revoke/remove)
    - Tạo Duo_Map; sinh invitation (partial unique chặn pending trùng → 409); accept trong transaction `SELECT ... FOR UPDATE` (410 nếu invalid, 409 nếu `map_full`); revoke; remove member
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 5.1, 5.2, 5.6_

  - [ ] 9.8 Triển khai SharingService — Share Link (create/revoke/public resolve)
    - Tạo Share_Link cho đúng 1 Pin; revoke; public resolve trả nội dung + tọa độ; sau revoke → 410
    - _Requirements: 6.1, 6.2, 6.3, 6.4_

  - [ ] 9.9 Triển khai Sharing controllers
    - `/maps/:mapId/invitations`, `/invitations/:id`, `/invitations/accept`, `/maps/:mapId/members/:userId`, `/pins/:pinId/share-links`, `/share-links/:id`, `GET /public/share/:token`
    - _Requirements: 4.2, 4.7, 5.1, 5.6, 6.1, 6.2, 6.4_

- [ ] 10. Account Module — export + xóa tài khoản nguyên tử (Req 10)
  - [ ] 10.1 Triển khai logic export đúng phạm vi người dùng
    - Trả đúng tập Pin + tham chiếu Media thuộc chính người dùng, không lẫn dữ liệu người khác
    - _Requirements: 10.6, 10.7_

  - [ ]* 10.2 Viết property test export đúng phạm vi
    - **Property 16: Xuất dữ liệu đúng phạm vi người dùng**
    - **Validates: Requirements 10.6, 10.7**

  - [ ] 10.3 Triển khai xóa tài khoản nguyên tử (all-or-nothing)
    - Soft-delete + xóa Pin/Personal_Map/media refs + yêu cầu xóa `object_key` R2 + gỡ tư cách Member; chỉ báo thành công khi tất cả hoàn tất, ngược lại giữ trạng thái để thử lại
    - _Requirements: 10.2, 10.3, 10.4_

  - [ ]* 10.4 Viết property test xóa tài khoản nguyên tử
    - **Property 13: Xóa tài khoản nguyên tử (all-or-nothing) và sạch dữ liệu**
    - **Validates: Requirements 10.2, 10.3, 10.4**

  - [ ] 10.5 Triển khai cleanup job + AccountController
    - Job thử lại xóa R2/DB dở dang; `GET /account/export`, `DELETE /account`
    - _Requirements: 10.2, 10.3, 10.6_

- [ ] 11. Tích hợp (wiring) backend — error handling, guard, bootstrap
  - [ ] 11.1 Triển khai `HttpExceptionFilter` chuẩn hóa lỗi
    - Ánh xạ tình huống → mã/`error` theo bảng lỗi (401/403/409/410/413/422/...), định dạng `{error,message,details,requestId}`
    - _Requirements: 1.3, 1.4, 2.3, 2.6, 3.5, 4.3, 4.5, 5.2, 6.4_

  - [ ] 11.2 Đăng ký toàn bộ module + bootstrap `main.ts`
    - Wire `AuthGuard` global, helmet, đăng ký Auth/Pins/Maps/Media/Sharing/Account vào `app.module`
    - _Requirements: 1.4, 1.5, 10.5_

  - [ ]* 11.3 Smoke/static check không có quảng cáo/tracking
    - Kiểm dependency không chứa SDK quảng cáo/analytics hành vi
    - _Requirements: 1.5_

- [ ] 12. Checkpoint backend
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 13. Mobile — tầng dữ liệu offline-first (drift + repository + api client)
  - [ ] 13.1 Triển khai drift database (`data/db`)
    - Bảng `local_pins` (kèm cờ `synced`), `upload_queue` (status/attempts/next_attempt_at); DAO + migration
    - _Requirements: 9.1, 9.2_

  - [ ] 13.2 Triển khai `api_client.dart` (dio) + DTO models
    - REST client theo hợp đồng OpenAPI backend; model lỗi/`error` thống nhất
    - _Requirements: 7.1, 8.1, 10.5_

  - [ ] 13.3 Triển khai repository offline-first (single source of truth)
    - Đọc/ghi qua Local_Cache trước; ghi optimistic; hợp nhất dữ liệu từ API
    - _Requirements: 9.1, 9.2_

- [ ] 14. Mobile — sync engine + retry + network monitor (Req 9)
  - [ ] 14.1 Viết hàm thuần `retry_selector.dart`
    - Chọn đúng tập mục cần retry = mục `pending`/`failed` có `next_attempt_at <= now` (gồm chưa từng thử và đã thất bại)
    - _Requirements: 9.4_

  - [ ]* 14.2 Viết property test retry selector (glados)
    - **Property 12: Tập mục được retry đúng**
    - **Validates: Requirements 9.4**

  - [ ] 14.3 Viết mô hình hội tụ đồng bộ thuần trong `sync_engine.dart`
    - Mô hình hóa trạng thái offline/queue: sau đồng bộ thành công mọi Pin `synced`, queue rỗng; mục chỉ bị xóa khi upload thành công
    - _Requirements: 9.2, 9.3, 9.5_

  - [ ]* 14.4 Viết property test hội tụ đồng bộ (glados)
    - **Property 11: Hội tụ đồng bộ offline (Upload_Queue)**
    - **Validates: Requirements 9.2, 9.3, 9.5**

  - [ ] 14.5 Triển khai network monitor + retry nền
    - `network_monitor.dart` (connectivity_plus); kích hoạt sync khi có mạng; lập lịch nền bằng `workmanager`, backoff khi thất bại
    - _Requirements: 9.3, 9.4_

- [ ] 15. Mobile — nén ảnh client (Req 3)
  - [ ] 15.1 Triển khai `image_compressor.dart` (logic ngưỡng thuần + wrap `flutter_image_compress`)
    - Sau nén: độ phân giải ≤ max cấu hình, byte ≤ ảnh gốc; vượt ngưỡng kích thước → từ chối kèm thông báo, trong giới hạn → không cảnh báo
    - _Requirements: 3.2, 3.5, 3.6_

  - [ ]* 15.2 Viết property test nén ảnh & giới hạn (glados)
    - **Property 17: Nén ảnh client giảm kích thước trong ngưỡng & validate giới hạn**
    - **Validates: Requirements 3.2, 3.5, 3.6**

- [ ] 16. Mobile — điều hướng, splash/onboarding, đăng nhập OAuth
  - [ ] 16.1 Cấu hình `go_router` + bootstrap app
    - Routes chính + deep link `/p/:token` (Public Shared Pin tách biệt); khởi tạo DI, l10n
    - _Requirements: 6.3_

  - [ ] 16.2 Màn hình Splash + Onboarding
    - Kiểm phiên im lặng (token hết hạn → về Login); slide giới thiệu triết lý + xin quyền vị trí/ghi âm
    - _Requirements: 1.4_

  - [ ] 16.3 Màn hình đăng nhập OAuth + lưu/đăng xuất token
    - `google_sign_in`/`sign_in_with_apple`; lưu token an toàn; banner lỗi đăng nhập; đăng xuất gọi `/auth/logout`
    - _Requirements: 1.1, 1.2, 1.3, 1.6_

  - [ ]* 16.4 Viết widget test màn hình đăng nhập
    - Hiển thị banner lỗi khi OAuth thất bại/hủy
    - _Requirements: 1.3_

- [ ] 17. Mobile — Map View (màn hình gốc)
  - [ ] 17.1 Triển khai Map View
    - `flutter_map`/`mapbox_maps_flutter`; render marker theo bbox (debounce pan/zoom → query viewport); FAB thả ghim; long-press tạo Pin; segmented control Map↔Timeline
    - _Requirements: 7.1, 7.2, 2.1_

  - [ ] 17.2 Triển khai Map Switcher + privacy badge
    - Đổi Personal ⇄ Duo; nhãn phạm vi 🔒/👥 cập nhật theo không gian
    - _Requirements: 5.3, 10.1_

  - [ ]* 17.3 Viết widget test chỉ render marker trong viewport
    - _Requirements: 7.2_

- [ ] 18. Mobile — Pin Editor (tạo/sửa)
  - [ ] 18.1 Triển khai màn hình Pin Editor
    - Form title/note/memoryDate; mini-map xác nhận/kéo tọa độ; validate tọa độ inline; nút đính kèm Ảnh/Văn bản/Ghi âm; lưu offline với badge "chờ đồng bộ"
    - _Requirements: 2.1, 2.2, 2.3, 9.2_

  - [ ] 18.2 Triển khai recorder + image picker + đính văn bản
    - `record` cho ghi âm (+ caption), `image_picker` + gọi `image_compressor`, ô ghi chú văn bản
    - _Requirements: 3.1, 3.2_

  - [ ] 18.3 Wire upload progress vào Upload_Queue
    - Thumbnail + thanh tiến trình theo trạng thái queue; báo lỗi vượt kích thước (413/giới hạn client)
    - _Requirements: 3.2, 3.5, 9.2_

  - [ ]* 18.4 Viết widget test Pin Editor (validate/offline)
    - Lỗi tọa độ inline; lưu offline tạo badge chờ đồng bộ
    - _Requirements: 2.3, 3.5, 9.2_

- [ ] 19. Mobile — Pin Detail + Media Viewer
  - [ ] 19.1 Triển khai Pin Detail (bottom sheet)
    - Peek/expanded; badge phạm vi; nút Sửa/Xóa/Chia sẻ; "Xem trên bản đồ" (fly-to); offline hiện đủ text/tọa độ
    - _Requirements: 2.4, 8.4, 9.1_

  - [ ] 19.2 Triển khai Media Viewer
    - Ảnh pinch-zoom; trình phát audio (play/seek) + caption; placeholder khi chưa cache
    - _Requirements: 3.7, 9.1_

  - [ ]* 19.3 Viết widget test Pin Detail offline placeholder
    - _Requirements: 9.1_

- [ ] 20. Mobile — Timeline View
  - [ ] 20.1 Triển khai Timeline View
    - Segmented control; bộ chọn thứ tự (mới→cũ / cũ→mới); list item; nhãn "Chưa rõ ngày" cho Pin thiếu memoryDate; tap → Pin Detail
    - _Requirements: 8.1, 8.2, 8.3, 8.4_

  - [ ]* 20.2 Viết widget test thứ tự timeline + điều hướng chi tiết
    - _Requirements: 8.3, 8.4_

- [ ] 21. Mobile — Duo Map Management
  - [ ] 21.1 Triển khai màn hình quản lý Duo Map
    - Tạo Duo Map; Invitation modal (generate mã+link+hạn / enter-code); danh sách thành viên (gỡ/thu hồi); hiển thị lỗi 409/410 inline
    - _Requirements: 4.1, 4.2, 4.3, 4.5, 4.7, 5.1, 5.2, 5.6_

  - [ ]* 21.2 Viết widget test lỗi Duo (409/410)
    - _Requirements: 4.3, 4.5, 5.2_

- [ ] 22. Mobile — Share Moment + Public Shared Pin View
  - [ ] 22.1 Triển khai Share Moment modal
    - Toggle tạo link; sao chép + share sheet hệ thống; thu hồi; trạng thái Đang chia sẻ/Đã thu hồi
    - _Requirements: 6.1, 6.4_

  - [ ] 22.2 Triển khai Public Shared Pin View (deep link, không cần đăng nhập)
    - Mở từ `/p/:token`; mini-map 1 marker + nội dung + tọa độ; xử lý 410 "liên kết đã thu hồi"; không dẫn vào phần còn lại của app
    - _Requirements: 6.2, 6.3, 6.4_

  - [ ]* 22.3 Viết widget test Public view khi link bị thu hồi (410)
    - _Requirements: 6.4_

- [ ] 23. Mobile — Settings & Privacy
  - [ ] 23.1 Triển khai màn hình Settings & Privacy
    - Xuất dữ liệu; Xóa tài khoản (xác nhận 2 bước + tiến trình "đang xóa"); Đăng xuất; thông tin "Không quảng cáo/không tracking"; chọn ngôn ngữ
    - _Requirements: 1.5, 1.6, 10.2, 10.3, 10.6_

- [ ] 24. Mobile — lớp xuyên suốt: offline UX, theming, i18n, accessibility
  - [ ] 24.1 Triển khai component offline/sync dùng chung
    - Offline banner; badge "chờ đồng bộ"/"đã đồng bộ"; Upload Progress Indicator (queued/uploading%/failed/done)
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

  - [ ] 24.2 Triển khai theming (Light/Dark + token tập trung)
    - Token màu/biến theme tập trung sẵn sàng cho theme tương lai (không refactor)
    - _Requirements: 1.5_

  - [ ] 24.3 Triển khai i18n ARB (intl + flutter_localizations)
    - Tách toàn bộ chuỗi ra ARB theo namespace; tiếng Việt mặc định; định dạng ngày/số theo locale; sẵn sàng RTL
    - _Requirements: 8.3_

  - [ ] 24.4 Triển khai accessibility xuyên màn hình
    - `Semantics` cho marker/card/badge; `MediaQuery.textScaler` (Dynamic Type); reduce motion; touch target ≥ 44pt
    - _Requirements: 7.2, 8.4_

- [ ] 25. Checkpoint mobile
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 26. Integration tests (hạ tầng thật)
  - [ ]* 26.1 PostGIS spatial integration (Testcontainers)
    - Insert tập Pin, chạy `ST_MakeEnvelope(...) && geom`, đối chiếu lọc thuần (so khớp Property 8); `EXPLAIN` xác minh dùng GiST
    - _Requirements: 7.3_

  - [ ]* 26.2 Redis cache integration (hit + invalidation)
    - Lần truy vấn thứ 2 phục vụ từ cache; sau mutate → key tile bị xóa (đối chiếu Property 9 end-to-end)
    - _Requirements: 7.4, 7.5_

  - [ ]* 26.3 R2/MinIO presigned integration
    - Upload qua presigned PUT, đọc qua presigned GET; xác minh DB chỉ lưu `object_key`
    - _Requirements: 3.3, 3.7_

  - [ ]* 26.4 OAuth mock integration
    - authorizationUrl đúng; callback thành công cấp token; callback lỗi/hủy → 401 không token
    - _Requirements: 1.1, 1.2, 1.3_

  - [ ]* 26.5 Offline/retry integration (mock connectivity)
    - Tạo Pin offline → khôi phục mạng → đồng bộ + queue rỗng (đối chiếu Property 11 end-to-end)
    - _Requirements: 9.2, 9.3, 9.5_

- [ ] 27. Tích hợp cuối (wiring) + smoke/static checks
  - [ ] 27.1 Wire mobile end-to-end (repository ↔ api_client ↔ sync engine ↔ network monitor)
    - Kết nối tạo/sửa/xóa Pin offline-first → đồng bộ → cập nhật UI; không còn code mồ côi
    - _Requirements: 9.1, 9.2, 9.3, 9.5_

  - [ ]* 27.2 Smoke check TLS/HTTPS
    - Redirect HTTP→HTTPS, HSTS bật, traffic client↔backend mã hóa
    - _Requirements: 10.5_

  - [ ]* 27.3 Static checks bảo mật & lưu trữ
    - Không SDK quảng cáo/tracking (manifest); không cột nhị phân media; không ghi file media trên đĩa server
    - _Requirements: 1.5, 3.4_

- [ ] 28. Checkpoint cuối
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Task có hậu tố `*` là test (unit/property/integration) — **tùy chọn**, có thể bỏ qua để tăng tốc MVP; task không có `*` là cốt lõi và bắt buộc.
- Mỗi task tham chiếu requirement cụ thể (`_Requirements: X.Y_`) để truy vết; task property test gắn số Property + requirement được kiểm.
- Property test backend dùng **fast-check** (Jest), mobile dùng **glados** (flutter test), tối thiểu **100 vòng**, nhãn `Feature: ban-do-ky-niem, Property {n}: {property_text}`.
- Pure function được viết và property-test sớm (ưu tiên test-first) trước/cùng lúc với service tích hợp DB/Redis/R2.
- Checkpoint đảm bảo kiểm tra tăng dần; task cuối (27.1) tích hợp toàn bộ luồng offline-first end-to-end.
- Phạm vi chỉ MVP (Phase 1). Group Map/real-time, AI, video, monetization (Phase 2–4) KHÔNG nằm trong danh sách này.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2"] },
    { "id": 1, "tasks": ["2.1", "2.2", "2.3", "3.1", "7.1", "4.1", "5.1", "6.1", "8.1", "8.3", "9.1", "9.3", "9.5", "13.1", "13.2", "14.1", "14.3", "15.1", "16.1"] },
    { "id": 2, "tasks": ["3.2", "4.2", "5.2", "6.2", "8.2", "8.4", "9.2", "9.4", "9.6", "14.2", "14.4", "15.2", "13.3", "16.2"] },
    { "id": 3, "tasks": ["3.3", "3.4", "14.5", "16.3", "24.1", "24.2", "24.3"] },
    { "id": 4, "tasks": ["4.3", "5.3", "7.2", "8.5", "8.6", "10.1", "10.3", "16.4", "17.1", "17.2", "18.1", "18.2", "19.1", "19.2", "20.1", "21.1", "22.1", "22.2", "23.1"] },
    { "id": 5, "tasks": ["4.4", "4.5", "5.4", "5.5", "6.3", "7.3", "8.7", "9.7", "9.8", "10.2", "10.4", "17.3", "18.3", "18.4", "19.3", "20.2", "21.2", "22.3"] },
    { "id": 6, "tasks": ["4.6", "5.6", "5.7", "7.4", "8.8", "9.9", "10.5", "24.4"] },
    { "id": 7, "tasks": ["11.1", "11.2", "11.3", "27.1"] },
    { "id": 8, "tasks": ["26.1", "26.2", "26.3", "26.4", "26.5", "27.2", "27.3"] }
  ]
}
```
