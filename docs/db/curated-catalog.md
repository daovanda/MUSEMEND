# Curated travel và mission catalog

Trạng thái: `implemented`  
Cập nhật: 2026-09-08

## Phạm vi

Migration `20260908110000_curated_world_catalog.sql` bổ sung một content pack mẫu
do server quản lý, gồm:

- 10 điểm đến: Hội An, Ninh Bình, Huế, Phú Quốc, Hà Giang, Paris, Kyoto,
  Santorini, Petra và Machu Picchu;
- 10 checkpoint, mỗi điểm đến một checkpoint có yêu cầu năng lượng tăng dần;
- 10 landmark, 10 món ăn, 10 vật phẩm và 30 liên kết reward;
- 10 mission template về chăm sóc bản thân, quan sát hiện tại và viết phản tư.

Các route curated đứng trước ba route `demo-*` đối với user chưa khởi hành. Việc
đổi `order_index` không làm chuyển user đang đi dở vì con trỏ hành trình lưu ID
tỉnh/trạm. Trạm Hội An đầu tiên cần 10 năng lượng để giữ nhịp MVP hai nhiệm vụ
5 điểm; các trạm sau tăng dần tới 55.

Đây là dữ liệu mẫu hư cấu theo phong cách MuseMend, không phải hướng dẫn du lịch
hay nội dung thương mại. Tọa độ chỉ phục vụ metadata catalog; app MVP chưa dùng
cho chỉ đường.

## Tương thích mô hình hiện tại

Tên bảng `provinces` được giữ để không phá RPC và client hiện có, nhưng bản ghi có
thể đại diện cho tỉnh, thành phố, đảo, di sản hoặc vùng. Hai cột mới mô tả rõ hơn:

- `country_code`: mã quốc gia ISO hai ký tự viết hoa;
- `destination_type`: một trong `province`, `city`, `island`, `heritage`, `region`.

`region` cũ vẫn dùng cho ba miền Việt Nam và để `NULL` với điểm đến quốc tế.
`province_checkpoints.asset_path` là đường dẫn artwork do server quyết định; client
không được ghi cột này.

## Seed, idempotency và bảo mật

Các catalog có mã ổn định với prefix `curated-`. Seed dùng batch insert và
`ON CONFLICT DO UPDATE`; reward dùng `NOT EXISTS`, nên replay không tạo bản ghi
trùng. Migration không ghi bảng user-owned, không cấp thêm quyền và không thay đổi
RLS. Người dùng authenticated chỉ đọc catalog active; tiến độ và unlock vẫn chỉ
được cập nhật qua RPC hành trình.

Ảnh checkpoint được đóng gói trong Flutter tại
`assets/illustrations/journey/checkpoints/`. Giá trị DB khớp chính xác với asset
path; khi thay ảnh phải giữ tên file hoặc cập nhật migration mới cùng app release.

## Kiểm thử và vận hành

`supabase/tests/mvp_integration.sql` xác nhận đủ số bản ghi của từng nhóm, mọi
checkpoint có artwork, mọi điểm đến có country code và mỗi checkpoint có ba
reward. Trước khi deploy cần chạy database validation từ schema sạch, sau đó build
Flutter để kiểm tra asset manifest.

Không xóa hoặc đổi mã catalog đã có user progress. Muốn ngừng một điểm đến, dùng
migration mới đặt `is_active=false`; cần đánh giá user đang ở checkpoint đó trước
khi rollout.
