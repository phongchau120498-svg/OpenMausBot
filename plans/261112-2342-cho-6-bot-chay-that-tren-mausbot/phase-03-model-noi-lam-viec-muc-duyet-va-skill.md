---
phase: 3
title: 'Model, nơi làm việc, mức duyệt và skill'
status: completed
priority: P1
dependencies:
  - 2
---

# Phase 3: Model, nơi làm việc, mức duyệt và skill

## Overview
Đặt model và nơi làm việc theo bảng anh đã chốt, giữ mức duyệt, tắt skill thừa, và xử lý các skill còn gọi file chết.

## Requirements
- Mỗi thay đổi: PATCH, đọc lại, ghi Nhật ký. Tên trường lấy theo `server/routes/bot-patch.ts`:
  - `modelSelection` (:139);
  - `approvalMode` (:162);
  - `computer` nhận `browser` hoặc `off`… (:204-218).
- Skill route chỉ có GET, `PATCH {enabled}` và DELETE (`server/routes/bot-skills.ts:82-127`). DELETE từ chối skill `imported` hoặc `native`. **Không có API sửa nội dung skill.**

## Bảng đích

| Bot | Model | Nơi làm việc (`computer`) | Mức duyệt |
|---|---|---|---|
| Chiêu Giao | `claude / claude-opus-5-5` (giữ) | `browser` | Full (giữ) |
| Gia Huy - ECOM | `codex / gpt-6.1-sol / high` | `browser` | Full (giữ) |
| Như Phương - SALE | `claude / claude-sonnet-5` | `browser` | Full (giữ) |
| Tiêu Băng - CONTENT | `claude / claude-sonnet-5` | `browser` | Full (giữ) |
| Minh Đăng - SEFT EVOLUTION | giữ nguyên (đang nghỉ) | `off` | Full (giữ) |
| UX UI PROMAX | `claude / claude-opus-5-5` | `browser` | Full (giữ) |

**Vì sao giữ Full:** app không có mức riêng cho việc gửi tin (`docs/approval-levels.md`). Routine chạy không người trông, nên ở mức Ask sẽ đứng chờ. Quyết định "hỏi trước khi gửi ngoài routine" được thực hiện bằng luật trong soul (phase 2) và việc theo dõi ở phase 5.

## Skill: bật hoặc tắt

| Bot | Giữ bật | Tắt (hoặc xóa nếu app cho xóa) |
|---|---|---|
| Chiêu Giao | `canva-*`, `google-drive`, `google-sheets`, `x-mcp-guide` | Shopee, Stella, TikTok, Threads, Upwork, `tu-tien-hoa-bai-hoc` |
| Gia Huy | `shopee-*`, `stella-*`, `tiktok-shop-*`, `getting-started` | `threads-*`, `upwork-job-filter`, `tu-tien-hoa-bai-hoc` |
| Như Phương | `upwork-job-filter`, `upwork-real-tips`, `wiki-upwork` | (không có) |
| Tiêu Băng | `threads-*`, `getting-started` | Shopee, Stella, TikTok, Upwork, `tu-tien-hoa-bai-hoc` |
| Minh Đăng | (không) | Tắt hết |
| UX UI PROMAX | `getting-started` | Tất cả skill nghiệp vụ |

## Implementation Steps
1. **Model:** PATCH `modelSelection` cho Gia Huy, Như Phương, Tiêu Băng, UX UI. Đọc lại.
2. **Thử model:** mở chat mới gửi "trả lời đúng một chữ: ok" cho 4 bot đó. Bot nào báo hết hạn mức thì dừng và báo anh.
3. **Nơi làm việc:** PATCH `computer` theo bảng. Đọc lại.
4. **Tắt skill thừa:** dùng `PATCH /api/bots/<id>/skills/<name>` với `{ "enabled": false }`. Chỉ DELETE khi skill không phải `imported` hoặc `native`. Lỗi thì giữ ở trạng thái tắt.
5. **Skill còn bật mà gọi file chết:** đọc nội dung (GET), tìm các chuỗi trong bảng thay thế ở phase 2.
   - Có thì **tắt** skill đó, rồi chép phần luật còn cần vào soul của bot (PATCH soul, đối chiếu dòng như phase 2). Phần thủ tục dài thì ghi vào topic trí nhớ `memory/quy-trinh-<ten-skill>.md`.
   - Không sửa trực tiếp file skill, vì app không có API cho việc đó.
6. **UX UI thiếu skill "UI UX Pro Max"** mà soul nhắc tới: ghi thành việc chờ anh quyết. Không tự cài từ internet.

## Success Criteria
- [ ] `GET /api/bots`: model và `computer` khớp bảng.
- [ ] 4 lượt thử model đều trả "ok".
- [ ] Skill đang bật của từng bot khớp cột "Giữ bật". Không skill nào đang bật còn chuỗi chết.

## Risk Assessment
- **Hạn mức Claude:** 4 bot dùng chung một tài khoản Claude. Nếu bị giới hạn ở phase 5, chuyển Tiêu Băng về `codex/gpt-6.1-sol/medium` rồi báo anh.
- **Chép quy trình từ skill vào soul làm soul dài thêm:** trần là 24.000 byte (`shared/bot-profile.ts:10`). Gia Huy đang có 18.278 byte. Vượt trần thì đưa quy trình vào topic trí nhớ thay vì soul.
