# Tài liệu Yêu cầu (Requirements Document)

## Introduction

"Bản Đồ Kỷ Niệm" (Memory Map) là một ứng dụng di động cho phép người dùng ghim các kỷ niệm đa phương tiện (ảnh, ghi chú văn bản, ghi âm) lên một bản đồ tương tác. Mỗi tọa độ trên bản đồ là một chương trong câu chuyện cuộc đời người dùng. Khác với mạng xã hội truyền thống vốn ồn ào và làm phân mảnh ký ức, ứng dụng hướng đến triết lý "anti-social media": một không gian riêng tư, tập trung, không quảng cáo, không theo dõi (tracking), nơi người dùng "du hành" qua các tọa độ cuộc đời để hồi tưởng và kể lại hành trình.

Tài liệu này đặc tả yêu cầu cho sản phẩm, tập trung chủ yếu vào **MVP (Phase 1)**, đồng thời ghi nhận ngắn gọn các yêu cầu của **Phase 2–4** ở mức cao để định hướng kiến trúc.

### Phạm vi MVP (Phase 1)

Nền tảng đích của MVP là **ứng dụng di động (mobile)** xây dựng bằng React Native (Expo) hoặc Flutter (lưu ý: tên file tài liệu ý tưởng gốc là "YtuongWeb" nhưng định hướng đã chốt là mobile). MVP gồm:

- Xác thực qua Apple/Google (OAuth).
- Bản đồ kỷ niệm cá nhân (thả ghim theo tọa độ).
- Bản đồ Cặp đôi (Duo Map): mời **đúng 1 người** vào không gian chung qua mã/link.
- Đính kèm Media: Ảnh (nén client-side), Văn bản, Ghi âm (Audio).
- Hai chế độ xem: Bản đồ (Map view, với truy vấn bounding-box) và Dòng thời gian (Timeline list).
- Chia sẻ một khoảnh khắc (1 pin) ra ngoài qua link.
- Cache cục bộ offline và cơ chế retry upload.
- Quyền riêng tư và quản lý/xóa dữ liệu.

### Quyết định làm rõ phạm vi (mâu thuẫn giữa tài liệu ý tưởng gốc và SRS)

- **Bản đồ Nhóm vs Duo Map:** Tài liệu ý tưởng gốc đề cập "Bản đồ Nhóm" ngay từ đầu, nhưng SRS giới hạn MVP chỉ là Duo Map (1-1). Tài liệu này **ưu tiên Duo Map (đúng 2 người) cho MVP** và đẩy Group Map (3–10 người) sang Phase 2.
- **Web vs Mobile:** MVP nhắm tới mobile.
- **Video:** Hỗ trợ video ngắn được đẩy sang Phase 2; MVP chỉ hỗ trợ Ảnh, Văn bản, Audio.

### Lộ trình ngoài MVP (mức cao, định hướng kiến trúc)

- **Phase 2:** Bản đồ Nhóm (3–10 người); cập nhật real-time qua WebSockets + Redis Pub/Sub; gom cụm marker (Supercluster) khi zoom out; video ngắn 10–15s.
- **Phase 3:** AI Agents (ưu tiên Local LLM) tóm tắt hành trình theo ngữ cảnh chuỗi kỷ niệm; thông báo "Ngày này năm xưa"; đính kèm nhạc.
- **Phase 4:** Monetization — Print-on-demand (Photobook/Poster tọa độ); Freemium (tăng dung lượng, Theme Darkmode/Vintage, Icon custom).

## Glossary (Bảng thuật ngữ)

- **Memory_Map_System**: Toàn bộ hệ thống "Bản Đồ Kỷ Niệm" bao gồm ứng dụng di động (client) và dịch vụ backend.
- **Mobile_Client**: Ứng dụng di động chạy trên thiết bị người dùng (React Native/Expo hoặc Flutter).
- **Backend_Service**: Dịch vụ phía máy chủ (Node.js — NestJS hoặc Express) xử lý nghiệp vụ, xác thực, và truy cập dữ liệu.
- **Auth_Service**: Thành phần của Backend_Service xử lý xác thực và phiên đăng nhập qua OAuth (Apple/Google).
- **Pin (Ghim kỷ niệm)**: Một đơn vị kỷ niệm gắn với một tọa độ địa lý, gồm tiêu đề/ghi chú, thời điểm kỷ niệm, và các media đính kèm.
- **Personal_Map (Bản đồ cá nhân)**: Không gian bản đồ riêng tư, chỉ chủ sở hữu được xem và quản lý Pin.
- **Duo_Map (Bản đồ Cặp đôi)**: Không gian bản đồ dùng chung cho **đúng 2 người dùng**, cả hai cùng xem và ghim Pin.
- **Invitation (Lời mời)**: Mã/liên kết do một người dùng sinh ra để mời đúng một người dùng khác tham gia một Duo_Map.
- **Media**: Tệp đính kèm vào Pin. Trong MVP gồm 3 loại: Ảnh (Image), Văn bản (Text), Ghi âm (Audio).
- **Object_Storage (R2)**: Dịch vụ lưu trữ đối tượng tương thích S3 (Cloudflare R2) dùng để lưu Media.
- **Spatial_Database**: PostgreSQL kèm extension PostGIS, lưu dữ liệu Pin và hỗ trợ truy vấn không gian (GeoSpatial).
- **Cache_Service**: Redis, dùng đệm tọa độ Lat/Lng và Pin được truy cập thường xuyên.
- **Local_Cache**: Bộ nhớ đệm phía Mobile_Client (SQLite/AsyncStorage) lưu text/tọa độ phục vụ chế độ offline.
- **Bounding_Box (Khung nhìn)**: Vùng địa lý hình chữ nhật tương ứng với khu vực bản đồ đang hiển thị trên màn hình.
- **Map_View**: Chế độ xem hiển thị Pin trên bản đồ tương tác.
- **Timeline_View**: Chế độ xem hiển thị danh sách Pin sắp xếp theo thời gian.
- **Share_Link**: Liên kết công khai/có thể truy cập để chia sẻ nội dung của một Pin đơn lẻ ra ngoài ứng dụng.
- **Owner (Chủ sở hữu)**: Người dùng tạo ra Personal_Map hoặc khởi tạo một Duo_Map.
- **Member (Thành viên)**: Người dùng có quyền truy cập một Duo_Map (gồm Owner và người được mời).
- **OAuth_Provider**: Nhà cung cấp xác thực bên thứ ba (Apple hoặc Google).
- **Access_Token**: Mã thông báo phiên do Auth_Service cấp sau khi xác thực thành công.
- **Upload_Queue**: Hàng đợi tải lên phía Mobile_Client lưu các Media chờ tải lên Object_Storage khi mạng không khả dụng.

## Requirements

### Requirement 1: Xác thực qua Apple/Google (OAuth)

**User Story:** Là một người dùng, tôi muốn đăng nhập bằng tài khoản Apple hoặc Google, để tôi truy cập không gian kỷ niệm riêng tư của mình một cách an toàn mà không cần tạo mật khẩu mới.

#### Acceptance Criteria

1. WHEN người dùng chọn đăng nhập bằng một OAuth_Provider, THE Auth_Service SHALL khởi tạo luồng xác thực OAuth với OAuth_Provider được chọn.
2. WHEN OAuth_Provider trả về xác thực thành công, THE Auth_Service SHALL tạo hoặc liên kết một tài khoản người dùng và cấp một Access_Token cho Mobile_Client.
3. IF luồng xác thực OAuth thất bại hoặc bị người dùng hủy, THEN THE Auth_Service SHALL trả về thông báo lỗi xác thực và không cấp Access_Token.
4. WHEN Mobile_Client gửi yêu cầu kèm Access_Token hết hạn, THE Backend_Service SHALL từ chối yêu cầu với mã lỗi xác thực 401.
5. THE Memory_Map_System SHALL hoạt động mà không tích hợp bất kỳ thành phần quảng cáo hoặc theo dõi (tracking) hành vi nào.
6. WHEN người dùng yêu cầu đăng xuất, THE Auth_Service SHALL vô hiệu hóa Access_Token hiện tại của phiên đó.

### Requirement 2: Tạo và quản lý ghim kỷ niệm (Pin) trên bản đồ cá nhân

**User Story:** Là một cá nhân, tôi muốn thả ghim kỷ niệm lên bản đồ với tọa độ, ghi chú và thời điểm, để tôi lưu lại các dấu mốc trong hành trình của mình.

#### Acceptance Criteria

1. WHEN người dùng đã xác thực tạo một Pin với tọa độ Lat/Lng hợp lệ, THE Backend_Service SHALL lưu Pin vào Spatial_Database và gắn Pin với Personal_Map của người dùng đó.
2. THE Mobile_Client SHALL cho phép người dùng nhập tiêu đề, ghi chú văn bản, và thời điểm kỷ niệm cho mỗi Pin.
3. IF người dùng gửi yêu cầu tạo Pin với tọa độ nằm ngoài khoảng hợp lệ (vĩ độ ngoài [-90, 90] hoặc kinh độ ngoài [-180, 180]), THEN THE Backend_Service SHALL từ chối yêu cầu và trả về thông báo lỗi xác thực dữ liệu.
4. WHEN người dùng chỉnh sửa một Pin do mình sở hữu, THE Backend_Service SHALL cập nhật nội dung Pin và lưu thời điểm cập nhật.
5. WHEN người dùng xóa một Pin do mình sở hữu, THE Backend_Service SHALL xóa Pin và toàn bộ Media liên kết khỏi Spatial_Database và Object_Storage.
6. IF một người dùng yêu cầu chỉnh sửa hoặc xóa một Pin mà người dùng đó không có quyền truy cập, THEN THE Backend_Service SHALL từ chối yêu cầu với mã lỗi phân quyền 403.
7. IF một người dùng yêu cầu xem các Pin thuộc một Personal_Map mà người dùng đó không sở hữu, THEN THE Backend_Service SHALL trả về kết quả rỗng (không có Pin nào).

### Requirement 3: Đính kèm và quản lý Media (Ảnh, Văn bản, Ghi âm)

**User Story:** Là một người dùng, tôi muốn đính kèm ảnh, ghi chú văn bản và đoạn ghi âm vào mỗi ghim kỷ niệm, để mỗi kỷ niệm trở thành một câu chuyện trọn vẹn.

#### Acceptance Criteria

1. THE Mobile_Client SHALL cho phép đính kèm vào một Pin ít nhất ba loại Media: Ảnh, Văn bản, và Ghi âm (Audio).
2. WHEN người dùng chọn một ảnh để đính kèm, THE Mobile_Client SHALL nén ảnh và giảm độ phân giải ở phía client trước khi tải ảnh lên Object_Storage.
3. WHEN Mobile_Client tải Media lên, THE Backend_Service SHALL lưu Media vào Object_Storage và chỉ lưu tham chiếu (đường dẫn/khóa đối tượng) của Media trong Spatial_Database.
4. THE Memory_Map_System SHALL KHÔNG lưu tệp Media trên ổ đĩa cục bộ của máy chủ hoặc trong cơ sở dữ liệu dưới dạng nhị phân.
5. IF tệp Media được chọn vượt quá giới hạn kích thước cho phép sau khi nén, THEN THE Mobile_Client SHALL từ chối tải lên và hiển thị thông báo về giới hạn kích thước.
6. WHILE tệp Media nằm trong giới hạn kích thước cho phép, THE Mobile_Client SHALL KHÔNG hiển thị thông báo về giới hạn kích thước.
7. WHEN người dùng có quyền truy cập một Pin yêu cầu xem Media của Pin đó, THE Backend_Service SHALL cung cấp đường dẫn truy cập Media tương ứng từ Object_Storage.

### Requirement 4: Bản đồ Cặp đôi (Duo Map) — Tạo lời mời

**User Story:** Là một người dùng, tôi muốn tạo một không gian bản đồ chung và mời đúng một người, để hai chúng tôi cùng xây dựng bản đồ tình yêu/kỷ niệm chung.

#### Acceptance Criteria

1. WHEN một người dùng đã xác thực yêu cầu tạo Duo_Map, THE Backend_Service SHALL tạo một Duo_Map mới với người dùng đó là Owner.
2. WHEN Owner yêu cầu sinh lời mời cho một Duo_Map chưa có người được mời đang chờ và chưa có Member thứ hai, THE Backend_Service SHALL sinh một Invitation duy nhất (mã hoặc link) gắn với Duo_Map đó.
3. IF Owner yêu cầu sinh Invitation mới trong khi đang tồn tại một Invitation chưa được phản hồi và chưa hết hạn, THEN THE Backend_Service SHALL từ chối yêu cầu cho đến khi Invitation hiện tại được phản hồi hoặc hết hạn.
4. THE Duo_Map SHALL chứa tối đa đúng 2 Member.
5. IF một người dùng cố gắng sử dụng Invitation cho một Duo_Map đã đủ 2 Member, THEN THE Backend_Service SHALL từ chối yêu cầu tham gia với thông báo không gian đã đầy.
6. WHERE một Invitation đã được chấp nhận bởi một người dùng, THE Backend_Service SHALL vô hiệu hóa Invitation đó để ngăn việc dùng lại.
7. WHEN Owner yêu cầu thu hồi một Invitation chưa được chấp nhận, THE Backend_Service SHALL vô hiệu hóa Invitation đó.

### Requirement 5: Bản đồ Cặp đôi (Duo Map) — Tham gia và cộng tác

**User Story:** Là một người được mời, tôi muốn tham gia không gian bản đồ chung bằng mã/link và cùng ghim kỷ niệm, để cả hai cùng đóng góp vào câu chuyện chung.

#### Acceptance Criteria

1. WHEN một người dùng đã xác thực chấp nhận một Invitation hợp lệ, THE Backend_Service SHALL thêm người dùng đó làm Member thứ hai của Duo_Map tương ứng, với điều kiện bắt buộc gồm cả Invitation hợp lệ và người dùng đã được xác thực.
2. IF một Invitation đã hết hạn, bị thu hồi, hoặc đã được sử dụng, THEN THE Backend_Service SHALL từ chối yêu cầu tham gia và trả về thông báo lời mời không hợp lệ.
3. THE Backend_Service SHALL cho phép cả hai Member của một Duo_Map xem toàn bộ Pin thuộc Duo_Map đó.
4. WHEN một Member tạo, chỉnh sửa, hoặc xóa Pin do chính Member đó tạo trong Duo_Map, THE Backend_Service SHALL áp dụng thay đổi cho Duo_Map chung.
5. IF một người dùng không phải Member của một Duo_Map yêu cầu truy cập Pin của Duo_Map đó, THEN THE Backend_Service SHALL từ chối yêu cầu với mã lỗi phân quyền 403.
6. WHEN Owner xóa một Member khỏi Duo_Map, THE Backend_Service SHALL thu hồi quyền truy cập của Member đó vào toàn bộ Pin của Duo_Map.

### Requirement 6: Chia sẻ một khoảnh khắc (1 Pin) ra ngoài qua link

**User Story:** Là một người dùng, tôi muốn chia sẻ một ghim kỷ niệm cụ thể qua liên kết, để gửi cho người khác như một tấm bưu thiếp số mà không phải chia sẻ cả bản đồ.

#### Acceptance Criteria

1. WHEN người dùng có quyền truy cập một Pin yêu cầu chia sẻ Pin đó, THE Backend_Service SHALL sinh một Share_Link tham chiếu đến nội dung và vị trí của đúng Pin đó.
2. WHEN một người truy cập một Share_Link hợp lệ, THE Backend_Service SHALL trả về đồng thời cả nội dung kỷ niệm và tọa độ của Pin được chia sẻ.
3. THE Share_Link SHALL chỉ cấp quyền xem một Pin đơn lẻ và SHALL KHÔNG cấp quyền truy cập các Pin khác hoặc bản đồ chứa Pin đó.
4. WHEN người dùng thu hồi một Share_Link, THE Backend_Service SHALL vô hiệu hóa Share_Link đó ngay lập tức để mọi truy cập tiếp theo bị từ chối.

### Requirement 7: Chế độ xem Bản đồ với truy vấn Bounding Box

**User Story:** Là một người dùng, tôi muốn xem các ghim trên bản đồ tương tác mà không bị giật/crash, để tôi du hành mượt mà qua các kỷ niệm dù có rất nhiều ghim.

#### Acceptance Criteria

1. WHEN người dùng mở Map_View hoặc thay đổi khung nhìn bản đồ, THE Backend_Service SHALL chỉ trả về các Pin nằm trong Bounding_Box hiện tại.
2. THE Mobile_Client SHALL KHÔNG render đồng thời toàn bộ Pin của một bản đồ; THE Mobile_Client SHALL render các Pin nằm trong Bounding_Box hiện tại.
3. WHEN Backend_Service truy vấn Pin theo Bounding_Box, THE Backend_Service SHALL sử dụng truy vấn không gian của Spatial_Database (PostGIS).
4. WHERE một Duo_Map đang ở trạng thái active, THE Backend_Service SHALL sử dụng Cache_Service (Redis) để đệm các Pin/tọa độ được truy cập thường xuyên nhằm giảm độ trễ tải bản đồ.
5. WHEN một Pin trong Bounding_Box bị thay đổi hoặc xóa, THE Backend_Service SHALL làm mới (invalidate) dữ liệu đệm liên quan trong Cache_Service.

### Requirement 8: Chế độ xem Dòng thời gian (Timeline)

**User Story:** Là một người dùng, tôi muốn xem các kỷ niệm dưới dạng danh sách theo thời gian, để dễ dàng hồi tưởng theo trình tự đã xảy ra.

#### Acceptance Criteria

1. WHEN người dùng chuyển sang Timeline_View của một bản đồ mà người dùng có quyền truy cập, THE Backend_Service SHALL trả về các Pin của bản đồ đó được sắp xếp theo thời điểm kỷ niệm.
2. IF Backend_Service không sắp xếp được các Pin theo thời điểm kỷ niệm, THEN THE Mobile_Client SHALL hiển thị các Pin chưa sắp xếp và cho phép người dùng tiếp tục thao tác.
3. THE Timeline_View SHALL hiển thị các Pin theo thứ tự thời gian nhất quán (từ mới đến cũ hoặc từ cũ đến mới) do người dùng lựa chọn.
4. WHEN người dùng chọn một Pin trong Timeline_View, THE Mobile_Client SHALL hiển thị nội dung chi tiết và vị trí tương ứng của Pin đó.

### Requirement 9: Cache cục bộ offline và cơ chế retry upload

**User Story:** Là một người dùng ở nơi mạng yếu, tôi muốn vẫn xem được kỷ niệm dạng text/tọa độ và tạo ghim mới, để trải nghiệm không bị gián đoạn khi mất mạng.

#### Acceptance Criteria

1. WHILE Mobile_Client không có kết nối mạng, THE Mobile_Client SHALL hiển thị dữ liệu text và tọa độ của Pin từ Local_Cache.
2. WHEN người dùng tạo hoặc chỉnh sửa Pin trong khi không có mạng, THE Mobile_Client SHALL lưu thay đổi vào Local_Cache và đưa các Media liên quan vào Upload_Queue.
3. WHEN kết nối mạng được khôi phục, THE Mobile_Client SHALL tự động đồng bộ các thay đổi từ Local_Cache lên Backend_Service và tải các Media trong Upload_Queue lên Object_Storage.
4. WHILE còn mục chưa tải lên thành công trong Upload_Queue, THE Mobile_Client SHALL thử lại việc tải lên các mục đó theo cơ chế retry nền, bao gồm cả các mục chưa từng được thử và các mục đã thất bại trước đó.
5. WHEN một mục trong Upload_Queue được tải lên thành công, THE Mobile_Client SHALL xóa mục đó khỏi Upload_Queue.

### Requirement 10: Quyền riêng tư, phân quyền và xóa dữ liệu

**User Story:** Là một người dùng, tôi muốn kiểm soát dữ liệu vị trí và media nhạy cảm của mình, bao gồm quyền xóa toàn bộ tài khoản, để bảo vệ sự riêng tư của tôi.

#### Acceptance Criteria

1. THE Backend_Service SHALL chỉ cho phép truy cập Pin và Media bởi những người dùng có quyền (Owner của Personal_Map, Member của Duo_Map, hoặc người giữ Share_Link hợp lệ với phạm vi tương ứng).
2. WHEN người dùng yêu cầu xóa tài khoản, THE Backend_Service SHALL xóa hoàn toàn dữ liệu cá nhân, Personal_Map, các Pin do người dùng sở hữu, và Media liên quan khỏi Spatial_Database và Object_Storage trước khi coi việc xóa tài khoản là thành công.
3. IF bất kỳ thao tác xóa dữ liệu nào trong quá trình xóa tài khoản thất bại, THEN THE Backend_Service SHALL coi việc xóa tài khoản là chưa hoàn tất và giữ trạng thái để thử lại.
4. WHEN người dùng xóa tài khoản đang là Member của một Duo_Map, THE Backend_Service SHALL gỡ quyền truy cập của người dùng đó khỏi Duo_Map.
5. THE Memory_Map_System SHALL truyền dữ liệu giữa Mobile_Client và Backend_Service qua kênh được mã hóa (HTTPS/TLS).
6. WHEN người dùng yêu cầu xuất dữ liệu cá nhân, THE Backend_Service SHALL cung cấp dữ liệu Pin và tham chiếu Media của người dùng đó.
7. THE Backend_Service SHALL chỉ cung cấp tham chiếu Media của người dùng khi có yêu cầu xuất dữ liệu rõ ràng từ chính người dùng đó.

## Yêu cầu mức cao cho Phase 2–4 (định hướng kiến trúc, ngoài phạm vi MVP)

> Các yêu cầu dưới đây được ghi nhận ở mức cao để định hướng kiến trúc. Chúng SẼ được đặc tả chi tiết theo EARS trong các vòng spec sau khi triển khai từng phase.

### Requirement 11 (Phase 2): Bản đồ Nhóm và cộng tác real-time

**User Story:** Là một nhóm bạn/gia đình, chúng tôi muốn cùng ghim kỷ niệm lên một bản đồ chung và thấy cập nhật ngay lập tức, để cùng nhau lưu giữ ký ức tập thể.

#### Acceptance Criteria (mức cao)

1. THE Backend_Service SHALL hỗ trợ Bản đồ Nhóm với số Member trong khoảng 3 đến 10.
2. WHEN một Member thay đổi Pin trên Bản đồ Nhóm, THE Backend_Service SHALL phát thay đổi tới các Member đang kết nối qua WebSockets kết hợp Redis Pub/Sub.
3. WHEN người dùng zoom out Map_View, THE Mobile_Client SHALL gom cụm các Pin gần nhau (Marker Clustering qua Supercluster).
4. WHEN người dùng đính kèm video vào Pin, THE Memory_Map_System SHALL chỉ chấp nhận video có độ dài trong khoảng 10–15 giây và từ chối video ngoài khoảng này.

### Requirement 12 (Phase 3): AI Agents và nhắc nhớ

**User Story:** Là một người dùng, tôi muốn hệ thống tự tóm tắt hành trình và nhắc lại kỷ niệm cũ, để hồi tưởng dễ dàng và giàu cảm xúc hơn.

#### Acceptance Criteria (mức cao)

1. THE Memory_Map_System SHALL tạo bản tóm tắt hành trình từ một chuỗi Pin theo ngữ cảnh, ưu tiên sử dụng Local LLM.
2. WHERE người dùng đã bật thông báo và đang sử dụng ứng dụng, WHEN một Pin đạt mốc tròn năm so với thời điểm kỷ niệm, THE Memory_Map_System SHALL gửi thông báo "Ngày này năm xưa".
3. THE Memory_Map_System SHALL cho phép đính kèm nhạc vào Pin hoặc bản tóm tắt hành trình.

### Requirement 13 (Phase 4): Thương mại hóa (Monetization)

**User Story:** Là một người dùng, tôi muốn in kỷ niệm thành sản phẩm vật lý và mở khóa tính năng nâng cao, để lưu giữ và cá nhân hóa trải nghiệm sâu hơn.

#### Acceptance Criteria (mức cao)

1. THE Memory_Map_System SHALL cho phép đặt in theo yêu cầu (Print-on-demand) Photobook/Poster tọa độ từ dữ liệu Pin.
2. WHERE người dùng nâng cấp gói trả phí (Freemium), THE Memory_Map_System SHALL tăng hạn mức dung lượng lưu trữ lên một mức tối thiểu cụ thể lớn hơn 0 so với gói miễn phí.
3. WHERE người dùng nâng cấp gói trả phí, THE Memory_Map_System SHALL mở khóa Theme bản đồ (Darkmode/Vintage) và Icon custom.
