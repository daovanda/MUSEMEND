# Backend documentation

Trạng thái: `implemented`  
Cập nhật: 2026-09-05

Backend MVP hiện gồm Supabase Edge Functions và tích hợp vận hành; không có server
Docker riêng. Logic cần transaction vẫn đặt trong Database RPC, còn Edge Function
chỉ điều phối Supabase Storage/Auth hoặc dịch vụ ngoài.

## Components

- [`musemend-cleanup`](./musemend-cleanup.md): xóa vật lý object Storage và Auth
  user sau khi database đã tạo cleanup job.

Khi thêm function mới, tạo file `docs/be/<function-name>.md`, mô tả contract,
authentication, quyền, retry/idempotency, timeout, logging, deploy và rollback,
sau đó liên kết tại đây.
