# ADR-0003 — Mô hình điểm đến toàn cầu

Trạng thái: `accepted`  
Ngày: 2026-09-12

## Bối cảnh

Schema MVP ban đầu dùng `provinces`, `province_checkpoints` và `province_items`.
Tên này đúng với tuyến Việt Nam đầu tiên nhưng gây hiểu sai khi catalog đã có
Paris, Kyoto, Santorini, Petra và Machu Picchu. Giữ tên cũ lâu dài cũng khiến API,
domain Flutter và tài liệu tiếp tục mang giả định “mọi nơi đều là tỉnh”.

## Quyết định

Dùng `destination` làm khái niệm gốc cho mọi tỉnh, thành phố, đảo, di sản và vùng
đất. Đổi tên bảng, khóa ngoại, enum value, RPC implementation và domain Flutter
trong một migration versioned. Không tạo bộ bảng song song và không sao chép dữ
liệu.

`country_code` là metadata bắt buộc. `destination_type` mô tả loại điểm đến;
`vietnam_region` là thuộc tính tùy chọn chỉ dành cho nội dung Việt Nam. ID hiện có
được giữ nguyên để progress, reward và unlock của người dùng không bị mất.

## Hệ quả

- Client phát hành cùng migration phải dùng các tên mới; đây là thay đổi contract
  không tương thích với APK cũ ở các truy vấn journey.
- RLS, grants, sequence ownership và foreign key được giữ bởi thao tác rename,
  nhưng integration test vẫn phải xác nhận schema cũ không còn được public expose.
- Content mới có thể mở rộng toàn cầu mà không cần thêm bảng theo từng quốc gia.
- Nếu cần tương thích nhiều phiên bản client trong production, phải dùng chiến
  lược expand–migrate–contract hoặc compatibility views trước khi đổi contract.

## Rollout và rollback

Deploy database migration trước hoặc đồng thời với Flutter build đã dùng contract
mới trong cùng pipeline Development. Sau deploy, kiểm tra `start_journey`,
`advance_journey`, `complete_mission` và màn Khám phá bằng tài khoản QA.

Không rollback bằng cách xóa dữ liệu. Nếu có lỗi sau deploy, ưu tiên forward-fix;
chỉ rename ngược bằng migration mới khi APK mới chưa được phân phối.
