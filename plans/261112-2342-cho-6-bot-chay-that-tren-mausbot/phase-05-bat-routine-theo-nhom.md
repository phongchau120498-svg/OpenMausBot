---
phase: 5
title: "Bật routine theo nhóm"
status: pending
priority: P1
dependencies: [4]
---

# Phase 5: Bật routine theo nhóm

## Overview
Bật các routine còn dùng được theo thứ tự rủi ro tăng dần. Mỗi nhóm: **chạy thử trong chat** có câu dặn giới hạn, anh xem kết quả, bật lịch, rồi chờ lượt chạy theo lịch đầu tiên đạt mới sang nhóm sau. Routine của Minh Đăng giữ tắt.

## Requirements
- **Không dùng Run now để thử.** Run now chạy đúng prompt đã lưu và không nhận câu dặn thêm (`server/index.ts:14616-14620`), nên một lần bấm là một lượt thật.
- **Cách thử:** mở chat mới với bot, dán nguyên prompt routine (lấy từ bản chụp ngoài repo), thêm câu dặn giới hạn ở đầu.
- **Nhóm đăng công khai, sửa giá, gửi Zalo, nộp Upwork:** chỉ bật khi anh xác nhận trong chat. Mỗi nhóm một lần xác nhận.
- Một lượt lỗi thì tắt lại nhóm đó, sửa prompt hoặc soul, rồi thử lại. Không sang nhóm sau.

## Các nhóm

Chia theo **bảng phân loại ở phase 1 bước 7** (dựa trên nội dung prompt). Dự kiến:

| Nhóm | Gồm | Câu dặn khi thử | Điều kiện bật |
|---|---|---|---|
| **A. Chỉ đọc, nội bộ** | Các routine báo cáo, phân tích, tổng kết của Tiêu Băng; tổng kết tuần của Gia Huy | "CHẠY THỬ: làm đúng như dưới, nếu có bước gửi hay đăng ra ngoài thì dừng trước bước đó" | Lượt thử đạt và phase 1 xác nhận nhóm này không gửi ra ngoài |
| **B. Đăng công khai** | Tiêu Băng: Threads 12h30, 18h30, 20h30, 22h30 (bài ảnh); Instagram 21h15 | "CHẠY THỬ: soạn đầy đủ nhưng **không đăng**, gửi bản nháp cho anh" | Anh duyệt bản nháp. Bài 22h30 chỉ bật khi đã có kho ảnh |
| **C. Sửa giá và camp** | Gia Huy: kiểm giá Shopee 6h30, review Shopee T3/T6, health check TikTok T2/T5 | "CHẠY THỬ: **chỉ báo, không sửa, không rút, không đăng ký**" | Anh xem báo cáo rồi cho chạy đủ quyền như luật |
| **D. Gửi Zalo** | Gia Huy: dán báo cáo Threads 9h15, lời mời KOC 10h30, báo cáo GMV 11h55 và 20h55 | "CHẠY THỬ: soạn tin đầy đủ và gửi vào **nhóm thử do anh chỉ định**, không gửi nhóm thật" (anh chưa chỉ định thì chỉ soạn, không gửi) | Anh duyệt mẫu tin rồi mới bật |
| **E. Upwork** | Như Phương: kiểm phản hồi (8h–20h, 2 giờ một lần), săn job (7h, 14h, 20h, 22h) | Kiểm phản hồi: "CHẠY THỬ: chỉ đọc". Săn job: "CHẠY THỬ: **không nộp**, liệt kê job sẽ nộp" | Bật kiểm phản hồi trước. Săn job chỉ bật sau khi anh duyệt danh sách job |

Không bật: routine của Minh Đăng (đang nghỉ). Routine quá hạn đã xóa ở phase 2.

## Implementation Steps
1. Với mỗi nhóm theo thứ tự A → E:
   1. Chạy thử từng routine bằng chat mới, kèm câu dặn trong bảng.
   2. Agent kiểm kết quả:
      - không có lỗi đường dẫn cũ;
      - không có gửi, đăng hay sửa nào ngoài câu dặn;
      - thời gian chạy;
      - hạn mức engine còn lại.
      Ghi Nhật ký ngắn.
   3. Anh xác nhận, với các nhóm B, C, D, E.
   4. `PATCH /api/routines/<id>` với `{ "enabled": true }`, đọc lại.
   5. Chờ lượt chạy theo lịch đầu tiên của nhóm, đọc kết quả (`GET /api/routines`, phần `runs`), đạt rồi mới sang nhóm sau.
2. **Chồng giờ:** 11h55 (GMV), 12h30 (Threads), 20h30 (Threads) và 20h55 (GMV) là hai bot khác nhau, dùng hai trình duyệt khác nhau, nên không tranh nhau. Chỉ cần theo dõi hạn mức engine.
3. **Theo dõi 3 ngày** sau khi bật đủ:
   - mỗi ngày đọc kết quả các lượt và hạn mức Codex/Claude;
   - kiểm không có tin, bài hay thay đổi nào ngoài routine;
   - có lỗi lặp hoặc vi phạm luật "hỏi trước" thì tắt routine đó, hạ bot xuống **Approve for me**, rồi báo anh.
4. Kiểm toàn bộ theo "Tiêu chí nghiệm thu" ở `plan.md`. Chạy `ck plan check 5`, rồi commit thư mục plan (không có bản chụp). Chưa push nếu anh chưa cho.

## Success Criteria
- [ ] Nhóm A–E đã bật theo thứ tự, mỗi nhóm có lượt thử và lượt chạy theo lịch đạt, ghi trong Nhật ký.
- [ ] Không có tin, bài hay thay đổi giá nào ngoài nội dung anh đã duyệt.
- [ ] 3 ngày theo dõi không có lỗi lặp, hoặc lỗi đã được xử lý và ghi lại.

## Risk Assessment
- **Lượt thử làm quá câu dặn:** chạy ở chat có người trông; kiểm ngay; vi phạm thì dừng và hạ mức duyệt.
- **Kết quả lượt thử trong chat khác lượt routine thật** (ngữ cảnh khác): vì vậy vẫn phải kiểm lượt chạy theo lịch đầu tiên của mỗi nhóm.
- **Hạn mức:** nhiều routine chạy sát giờ nhau. Nếu cần thì lệch giờ vài phút hoặc chuyển Tiêu Băng sang Codex.
- **Quay lại:** `PATCH enabled:false` theo nhóm.
