# Journey, checkpoints và rewards

Trạng thái: `implemented`  
Cập nhật: 2026-09-06

## Mục tiêu và phạm vi

Miền journey chuyển năng lượng tích lũy thành tiến độ checkpoint, mở phần thưởng và
ghi lịch sử khám phá. Client hiển thị trạng thái; quyết định vượt trạm và unlock
luôn nằm ở database.

## Mô hình dữ liệu

Catalog server-owned:

- `provinces` → `province_checkpoints` theo `order_index`;
- mỗi tỉnh có `landmarks`, `foods`, `province_items`;
- `checkpoint_rewards` trỏ đúng một loại reward: landmark, food, province item
  hoặc energy. Constraint yêu cầu đúng cột đích và số lượng/năng lượng dương.
- `province_checkpoints.required_energy > 0` là số điểm cần phân bổ cho từng trạm.

Dữ liệu user-owned:

- `travel_progress`: con trỏ tỉnh/trạm, energy và trạng thái toàn hành trình;
- `user_checkpoint_progress`: trạng thái/energy tại từng checkpoint;
- `unlocked_provinces`, `unlocked_landmarks`, `unlocked_foods`,
  `unlocked_province_items`: bộ sưu tập unique theo user/item;
- `travel_events`: audit timeline của journey, energy và reward.

Trigger từ chối `current_checkpoint_id` không thuộc `current_province_id`.

## Luồng và RPC

### `start_journey()`

Chọn tỉnh active đầu tiên theo `(order_index, id)` mà user chưa hoàn thành, sau đó
chọn checkpoint active đầu tiên. RPC upsert unlock/progress, ghi event bắt đầu và
gọi engine advance. Nếu đã có checkpoint hiện tại, hàm trả trạng thái hiện có. Sau
khi hoàn thành một tỉnh, gọi lại để bắt đầu tỉnh tiếp theo.

### `advance_journey()`

RPC retry-safe gọi engine nội bộ rồi trả `travel_progress`. Engine tính:

```text
available = current_energy - journey_energy_used
```

Nếu đủ `required_energy`, checkpoint được hoàn thành và
`journey_energy_used` tăng; `current_energy` không bị trừ vì energy là điểm tích
lũy. Engine có thể vượt nhiều checkpoint trong một transaction. Reward collection
được upsert chống trùng; energy reward được cộng vào cả current/lifetime và có thể
giúp đi tiếp ngay. Cuối tỉnh, trạng thái tạm là `paused`; nếu mọi tỉnh active đều
đã hoàn thành thì chuyển `completed`.

`complete_mission()` gọi engine tự động sau khi cộng năng lượng.

### `set_item_equipped(p_item_id, p_equipped)`

Chỉ cho trang bị item đã unlock. Khi bật, mọi item khác cùng `item_type` bị tháo để
mỗi category chỉ có một item equipped. RPC đồng thời đánh dấu item đã xem.

## RLS và quyền client

User active được đọc catalog active và dữ liệu hành trình của chính mình. Client
không có INSERT/UPDATE/DELETE trực tiếp vào progress, event hay unlock. Ba bảng
unlock item cho phép cập nhật duy nhất `is_viewed`; equip phải gọi RPC. Các hàm
`SECURITY DEFINER` cố định `search_path` và guard bằng `require_user()`.

## Seed MVP

Migration demo seed idempotent tạo:

- 3 tỉnh mẫu: Hà Nội, Đà Nẵng, Lâm Đồng;
- mỗi tỉnh 5 checkpoint, mỗi checkpoint cần 10 energy;
- 15 landmark, 15 food và 3 badge hoàn thành tỉnh;
- 33 reward mapping: landmark + food cho từng trạm, thêm badge ở trạm 5.

Mã catalog có prefix `demo-`; đây không phải catalog địa lý/nội dung production.

Các cột `provinces.cover_asset_path`, `provinces.map_asset_path` và
`landmarks.asset_path`, `foods.asset_path`, `province_items.asset_path` đã được
repository Flutter đọc vào domain model. Seed demo hiện vẫn để các cột catalog
ở `NULL`: export cloud mascot dùng chung không phải asset của một dòng catalog,
còn sprite Figma đang chứa nhiều object/crop nên chưa thể gán đúng từng item.
Không ghi đường dẫn Figma tạm hoặc URL ký hạn vào migration; asset động chỉ được
publish cùng catalog content đã duyệt, qua bucket/policy server-owned và
migration/seed idempotent.

## Kiểm thử

Integration test bắt đầu journey, hoàn thành hai custom mission, xác nhận energy
10, checkpoint đầu hoàn tất, `journey_energy_used=10` và mở landmark + food. Gọi
complete lặp được kiểm tra không cộng đôi. Chưa test hết tỉnh, đổi tỉnh, energy
bonus, equip category, catalog inactive hoặc concurrency nhiều request.

## Migration và rollback

`mvp_journey` chứa engine và RPC; `mvp_demo_catalog` chứa seed. Thay đổi thứ tự,
required energy hoặc reward trên dữ liệu đã có có thể làm con trỏ user không còn
nhất quán; cần migration dữ liệu và kế hoạch rollback riêng, không update thủ công
trên Dashboard.

## Giới hạn và việc còn lại

- Cần catalog nội dung/asset được duyệt thay cho demo seed và quy trình publish
  `asset_path` an toàn.
- App phải gọi `start_journey()` khi user muốn chuyển sang tỉnh kế tiếp.
- Chưa có admin/content publishing workflow hay version catalog.
- Chưa có test tải/lock contention và invariant toàn hành trình.

Liên quan: [missions-energy.md](./missions-energy.md),
[migrations-testing.md](./migrations-testing.md).

