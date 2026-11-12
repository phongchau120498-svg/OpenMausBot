---
phase: 1
title: "Sao lưu cấu hình Rakazo"
status: pending
priority: P1
dependencies: []
---

# Phase 1: Sao lưu cấu hình Rakazo

## Overview
Xuất cấu hình đang dùng của Rakazo ra máy local trước khi tạm ngưng, gồm bot, hướng dẫn, routine và skill. Phase này chỉ đọc, không sửa production.

## Requirements
- Chỉ dùng RPC đọc (`*/list`, `*/get`), gọi từ tab `bot.onehand.space` mà anh đã đăng nhập.
- Lưu bản xuất **ngoài git**, ở `~/CTP DESKTOP/onhandbot-export-261112/`, đặt quyền `chmod 700`. Bản xuất chứa nội dung kinh doanh nên không được commit.
- Không lưu secret. Credential, token và mã OAuth không xuất ra.

## Implementation Steps
1. `spaces/list` → lấy id của space "Personal".
2. `bots/list` với header `x-rakazo-space-id` → lấy các trường name, description, instructions, model, thinkingLevel của 5 bot.
3. Với mỗi bot, gọi `skills/list {botId}`. Gọi thêm danh sách routine nếu RPC có. Tra tên RPC trong `onhandbot/packages/api` trước khi gọi, không đoán.
4. Ghi ra `bots.json`, `routines.json` và `skills.json`, rồi mỗi bot một file `<tên>.md` chứa hướng dẫn để anh dễ chép.
5. So khớp: số bot phải là 5 và độ dài hướng dẫn phải đúng như đã ghi trong plan.md.

## Success Criteria
- [ ] Có đủ 5 file hướng dẫn, độ dài khớp với `bots/list`.
- [ ] Có danh sách routine (tên, lịch, prompt) và skill.
- [ ] `git status` trong cả hai repo không có file mới.

## Risk Assessment
- Gọi nhầm RPC ghi. Cách tránh: chỉ gọi tên có `list` hoặc `get`, và đọc router trước khi gọi.
