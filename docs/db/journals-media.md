# Journals, tags và media

Trạng thái: `implemented`  
Cập nhật: 2026-09-05

## Mục tiêu và phạm vi

Miền này lưu phần chung của nhật ký và ba subtype trong một transaction, hỗ trợ tag
và tệp riêng tư. Nội dung future letter được phép đọc/mở/chỉnh sửa trước hạn theo
quyết định MVP.

## Mô hình dữ liệu

```text
journals
├─ daily_journals ── daily_checkins (tùy chọn, cùng chủ sở hữu)
├─ yearly_journals
│  ├─ yearly_goals
│  ├─ yearly_highlights
│  └─ yearly_lessons
├─ future_letters
├─ journal_media
└─ journal_tag_assignments ── journal_tags
```

`journals.user_id` và `journal_type` bất biến. Trigger subtype xác nhận daily,
yearly hoặc future-letter row khớp loại journal; yearly còn xác nhận cùng user.
Parent dùng `deleted_at` để soft-delete và RLS của child dựa vào parent nên child
biến mất khỏi client cùng lúc.

`future_letters.content` là plaintext trong PostgreSQL và chỉ được bảo vệ bằng RLS;
không có mã hóa end-to-end/application-layer.

## RPC `save_journal(p_type, p_data, p_journal_id?)`

`p_data` phải là JSON object. Không truyền ID sẽ tạo journal; có ID sẽ khóa row và
chỉ cho owner cập nhật đúng subtype, chưa soft-delete. Trả về UUID journal.

Trường chung tùy chọn: `title`, `preview_text`, `is_favorite`, `is_archived`.

### Payload `daily`

Hỗ trợ `checkin_id`, `entry_date`, `content`, `mood`, `weather_note`,
`location_note`, `is_draft`. Ngày mặc định theo `Asia/Ho_Chi_Minh`; score mood do
server suy ra. `checkin_id` nếu có phải thuộc cùng user.

### Payload `yearly`

Hỗ trợ `year`, `opening_message`, `reflection_content`, `gratitude_note`, `status`
và ba array:

- `goals[]`: `title`, `description`, `progress_percent`, `is_completed`;
- `highlights[]`: `title`, `description`, `event_date`;
- `lessons[]`: `content`.

Khi một array xuất hiện, tập child tương ứng bị thay toàn bộ theo thứ tự input.
Mỗi user chỉ có một yearly journal cho một năm; năm hợp lệ 1900–2200.

### Payload `future_letter`

Hỗ trợ `content`, `deliver_at`, `recipient_type` (`self`/`other`) và
`recipient_name`. Lần tạo bắt buộc có `deliver_at > written_at`. Letter được lưu
`scheduled`, `allow_edit_before_delivery=true`; đổi thời điểm giao xóa notification
cũ và cho phép scheduler tạo lại.

## Các RPC khác

- `open_future_letter(p_journal_id)`: owner có thể gọi cả trước hạn; đặt `opened_at`
  lần đầu và status `opened`.
- `soft_delete_journal(p_journal_id)`: đặt `deleted_at`, xóa notification và queue
  object để xóa vật lý sau 30 ngày.
- `attach_journal_media(p_journal_id, p_path, p_type, p_thumbnail?)`: chỉ gắn object
  đã upload đúng path/private ownership; trả ID hiện có nếu gắn lặp.
- `soft_delete_journal_media(p_media_id)`: soft-delete metadata và queue object cùng
  thumbnail sau 30 ngày.

Tag được phép tạo/đọc/sửa giới hạn qua table API và assignments được insert/delete
khi cả journal lẫn tag đều nhìn thấy qua RLS. Hiện privilege không cấp `DELETE`
trực tiếp cho `journal_tags`, dù policy là `FOR ALL`; app chưa có contract xóa tag
hoàn chỉnh.

## Storage contract

Bucket `journal-media` là private, giới hạn 50 MiB. MIME allow-list:

```text
image/jpeg, image/png, image/webp, image/heic,
audio/mpeg, audio/mp4, audio/aac, audio/wav, audio/x-m4a,
video/mp4, video/quicktime, application/pdf
```

Object path bắt buộc:

```text
<auth.uid()>/<journal UUID>/<unique filename>
```

Thứ tự client: lưu journal → upload object → gọi `attach_journal_media`. Policy chỉ
cho SELECT/INSERT object của journal own active; không overwrite hoặc xóa trực tiếp.
Thumbnail nếu có phải cùng prefix. Xóa vật lý do cleanup worker thực hiện.

## RLS, privacy và validation

Client chỉ đọc journal/child/media chưa xóa của mình; mọi write journal/subtype qua
RPC. Storage predicate kiểm tra user segment, journal segment, filename không rỗng
và object chưa nằm trong cleanup queue. `SECURITY DEFINER` RPC dùng
`search_path=''` và `require_user()`.

Không log hoặc đưa content/mood/path signed URL vào analytics. `remote_url` là cột
baseline kế thừa, không thuộc secure upload contract và app MVP không nên sử dụng
làm nguồn tin cậy.

## Kiểm thử

Integration test xác nhận lưu daily nguyên tử, chặn check-in khác chủ, thay arrays
yearly, đọc/mở future letter sớm, tạo due notification và ẩn journal sau soft-delete.
Chưa test upload Storage thật, MIME/size, thumbnail, tag privileges, cleanup sau 30
ngày, payload malformed đầy đủ hoặc concurrent save.

## Migration, rollback và giới hạn

`mvp_journals` đổi tên cột gây hiểu nhầm `content_encrypted` thành `content` và tạo
RPC/queue; `mvp_security_storage` tạo bucket/policy/media RPC. Client cũ dùng tên
`content_encrypted` không tương thích và phải nâng cấp cùng release.

Các giới hạn cần xử lý sau MVP:

- Nội dung chưa được mã hóa phía ứng dụng/end-to-end.
- `attach_journal_media` chưa đối chiếu `p_type` với MIME thực và chưa tự điền
  file size/duration/mime metadata.
- Array yearly dùng replace-all, chưa có merge/version conflict cho local-first.
- Chưa có restore journal/media trong 30 ngày hoặc xóa tag hoàn chỉnh.

Liên quan: [notifications-cleanup.md](./notifications-cleanup.md),
[daily-checkins-streak.md](./daily-checkins-streak.md).
