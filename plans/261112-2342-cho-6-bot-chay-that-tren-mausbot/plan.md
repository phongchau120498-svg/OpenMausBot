---
title: Cho 6 bot chạy được thật trên MausBot
description: >-
  Viết lại hướng dẫn và routine của các bot nhập từ Grok/Rakazo để bỏ phụ thuộc
  file cũ, đặt model, nơi làm việc, đăng nhập trình duyệt trên server, rồi bật
  routine theo từng nhóm. Không dựng desktop.
status: in-progress
priority: P1
branch: main
tags:
  - bots
  - routines
  - production
  - mausbot
blockedBy: []
blocks: []
created: '2026-11-12T16:50:13.714Z'
createdBy: 'ck:plan'
source: skill
---

# Cho 6 bot chạy được thật trên MausBot

## Overview

6 bot trên `https://bot.onehand.space` (MausBot 0.1.153, compose `mausbot` trên Dokploy) được nạp từ file Grok export, cùng một bot lấy từ Rakazo. Hướng dẫn (soul), trí nhớ, skill và 19 routine vẫn gọi file và script của máy cũ, nên bật lên sẽ lỗi.

Plan này viết lại để bot chạy bằng những gì MausBot có sẵn trên server:
- **trình duyệt riêng** của từng bot;
- **thư mục riêng** và **dòng lệnh** (Python, `uv`) để xử lý file;
- **app đã kết nối**.

Sau đó bật routine dần dần. Toàn bộ là **thiết lập production qua giao diện hoặc API của app**. Không sửa code, không dựng desktop.

## Đã kiểm tra (12/11 23:00 – 13/11 00:20, chỉ đọc)

Nguồn: `GET /api/bots`, `/api/routines`, `/api/bots/<id>/skills` bằng phiên email của anh; mã nguồn repo (server ở `HEAD` trùng v0.1.153); một reviewer độc lập (xem Red Team Review).

- **Bot:**
  - Chiêu Giao (Chief of Staff): `claude/claude-opus-5-5`.
  - 5 bot còn lại (Như Phương - SALE, UX UI PROMAX, Tiêu Băng - CONTENT, Minh Đăng - SEFT EVOLUTION, Gia Huy - ECOM): `codex/gpt-6.1-sol/medium`.
  - Cả 6 bot ở mức duyệt `full`.
  - Chiêu Giao đã được đưa lên đầu danh sách (`PUT /api/bots/order`, anh cho phép).
- **Soul:** không bị cắt khi import. Soul dài nhất là Gia Huy, 18.278 byte, dưới trần 24.000 byte (`shared/bot-profile.ts:10`), và câu cuối còn trọn vẹn.
- **19 routine đều `enabled:false`:** Như Phương 2, Tiêu Băng 7, Minh Đăng 1, Gia Huy 9 (có 1 routine chạy một lần đã quá hạn từ 04/11).
- **Phụ thuộc chết:**
  - `/workspace/...`, `lock.sh`, `zalo-lock.sh`, `se.py` nằm trên máy "box" của Grok, chưa từng có trên server này;
  - `/home/rakazo/...` đã mất cùng Rakazo.
  - Các phụ thuộc này nằm trong soul, prompt routine, có thể cả trong skill và `MEMORY.md` (`shared/grok-import.ts:471`).
- **Skill:**
  - Export đã chép cùng một bộ 14 skill vào mọi bot.
  - Route skill **chỉ có** GET, `PATCH {enabled}` và DELETE. DELETE **từ chối** skill gốc `imported` hoặc `native` (`server/routes/bot-skills.ts:82-127`). **Không có API sửa nội dung skill.**
- **Run now** chạy đúng prompt đã lưu, không nhận câu dặn thêm (`server/index.ts:14616-14620`). Vì vậy **không thể chạy thử bằng Run now**.
- **Máy cho mượn (Mac, PC công ty):** trên server tự host, chỉ cuộc chat do anh tự nhắn mới dùng được (`server/index.ts:896-900`). **Routine không bao giờ dùng được.** Hồ sơ "My Chrome" chỉ có trên My Cloud.
- **Desktop:** MausBot chỉ tạo desktop bằng cách điều khiển Docker (`server/routes/bot-patch.ts:389`, `docs/byo-vps.md:42-45`).
  - Trên máy Dokploy dùng chung, quyền đó gần như là root với khoảng 15 dự án khác.
  - Vì vậy **không dựng desktop**. Mọi việc của team là việc web cộng xử lý file.
- **Xử lý file không cần desktop:**
  - trình duyệt server tải về và upload từ đường dẫn trên server (`server/browser/cdp/files.ts`);
  - image có `python3`, `uv`, `poppler-utils`, `unzip` (`Dockerfile:143`);
  - có công cụ `generate_image` (`docs/image-generation.md`).
- **Repo `phongchau120498-svg/OpenMausBot` đang PUBLIC.** Không ghi vào repo: soul, prompt, luật nghiệp vụ, tên nhóm Zalo, IP, mã định danh hạ tầng.

## Quyết định của anh (12/11 23:45 và 13/11 00:23)

1. Giữ đủ phạm vi.
2. **Không dựng desktop.** Gia Huy làm mọi việc trên trình duyệt trên server.
3. Routine đã duyệt mẫu được tự gửi. Tin gửi ngoài routine thì soạn nháp và hỏi anh trước.
4. Model:
   - Chiêu Giao: Opus 5.5.
   - Gia Huy: gpt-6.1-sol high.
   - Như Phương, Tiêu Băng: Sonnet 5.
   - UX UI: Opus 5.5.
5. Upwork làm trên trình duyệt trên server, routine chạy tự động (mặc định theo đề xuất, anh đồng ý 00:23).
6. **Minh Đăng tạm nghỉ** (mặc định theo đề xuất).
7. Không lấy lại sổ tay từ Grok. Chỉ dùng luật đang có trong soul (mặc định theo đề xuất).

## Hướng dẫn cho agent thực thi

**Thứ tự đọc:** file này, rồi `AGENTS.md`, rồi chỉ file phase đang làm.

**Luật cứng:**
1. **Sửa production chỉ qua giao diện hoặc API của app**, bằng phiên email của anh ở `https://bot.onehand.space`.
   - Mỗi lần ghi phải đọc lại để đối chiếu.
   - Trước khi gửi, tra tên trường trong code: `server/routes/bot-patch.ts` (`modelSelection` :139, `approvalMode` :162, `computer` :204-218).
2. **Không tự đăng nhập, không nhập mật khẩu, OTP hay QR.** Mọi đăng nhập do anh làm.
3. **Không bật routine nào ngoài phase 5.** Không chạy thử bằng Run now. Thử bằng cách mở chat mới với bot, dán prompt routine kèm câu dặn giới hạn (phase 5).
4. **Bản chụp trước và sau** (soul, prompt, trí nhớ, skill) lưu **ngoài repo**, ở `~/OMB-private/261113-bot-migration/` trên Mac. Nhật ký trong repo chỉ ghi mô tả ngắn, số đếm và mã băm, **không** ghi nội dung luật, tên nhóm, tài khoản, IP hay ID hạ tầng.
5. Không commit bản chụp. Commit thư mục plan dùng tên và email GitHub của anh (`git -c user.name=… -c user.email=… commit`). **Push cần anh cho phép riêng.**
6. **Dừng và báo anh khi:**
   - một bot làm việc ngoài lệnh;
   - một lượt thử gửi, đăng hoặc sửa ngoài dự kiến;
   - hết hạn mức engine;
   - cần quyết định ngoài plan.
7. Xong mỗi phase: chạy `cd "plans/261112-2342-cho-6-bot-chay-that-tren-mausbot" && ck plan check <số>` và ghi bằng chứng ngắn vào Nhật ký.

## Phases

| Phase | Name | Status |
|-------|------|--------|
| 1 | [Kiem ke va sao luu](./phase-01-kiem-ke-va-sao-luu.md) | Completed |
| 2 | [Viet lai huong dan 6 bot](./phase-02-viet-lai-huong-dan-6-bot.md) | Completed |
| 3 | [Model noi lam viec muc duyet va skill](./phase-03-model-noi-lam-viec-muc-duyet-va-skill.md) | Completed |
| 4 | [Dang nhap trinh duyet](./phase-04-dang-nhap-trinh-duyet.md) | In Progress |
| 5 | [Bat routine theo nhom](./phase-05-bat-routine-theo-nhom.md) | Pending |

**Thứ tự:** 1 → 2 → 3 → 4 → 5, tuần tự. Phase 4 cần anh có mặt để đăng nhập.

**Bước khó đảo ngược:** phase 5, khi bật routine đăng bài, sửa giá, gửi Zalo hoặc nộp proposal thật.

## Dependencies

- Dựa trên plan `261112-1439-chuyen-dokploy-sang-mausbot` (server, đăng nhập CLI). Phase 4 của plan đó (4 tài khoản Codex còn lại) vẫn dở. Có 1 tài khoản Codex thì Gia Huy ở mức high sẽ tốn hạn mức nhanh hơn.

## Tiêu chí nghiệm thu

- [ ] Soul, prompt routine, skill còn bật và `MEMORY.md` của 5 bot đang làm việc không còn chuỗi `/workspace`, `/home/rakazo`, `/home/box`, `lock.sh`, `zalo-lock`, `se.py`, `trang-thai.csv`, `daily_log`, `task_catalog`, `message_bot`. Kiểm bằng API, kết quả bằng 0.
- [ ] Model, nơi làm việc và mức duyệt khớp bảng ở phase 3.
- [ ] Mỗi bot chỉ còn **bật** các skill đúng việc của mình (skill không xóa được thì tắt).
- [ ] Gia Huy đã đăng nhập Shopee, TikTok, Stella, Zalo và Google trong trình duyệt của mình. Một lượt thử chỉ đọc chạy xong, có đọc sheet và tạo file Excel trên server.
- [ ] Tiêu Băng đã đăng nhập Threads và Instagram. Một lượt thử soạn bài (không đăng) có xử lý ảnh WebP.
- [ ] Như Phương đã đăng nhập Upwork trên server. Một lượt thử không nộp đã dựng lại danh sách proposal đã gửi.
- [ ] Các routine còn dùng được đã bật theo nhóm, mỗi nhóm có lượt thử và lượt chạy theo lịch đạt. Minh Đăng vẫn tắt.
- [ ] Không có bản chụp nội dung nào nằm trong repo.

## Cách quay lại

- **Từng bot:** PATCH lại soul, model, mức duyệt, nơi làm việc từ bản chụp trong `~/OMB-private/…`, hoặc dùng lịch sử hồ sơ bot (`server/routes/bot-patch.ts:721`).
- **Skill:** PATCH `enabled` về giá trị cũ. Skill đã DELETE thì cài lại từ bản chụp.
- **Routine:** `PATCH enabled:false`.
- **Không dùng Import backup để quay lại từng phần.** Thao tác đó thay toàn bộ bản cài, cần restart và mật khẩu (`server/workspace-backup-http.ts:22`). Chỉ dùng khi hỏng nặng.

## Red Team Review (13/11 00:04)

Một reviewer độc lập (code-reviewer) soi plan theo 4 góc: bảo mật, giả định, sự cố, phạm vi. Báo cáo: [reports/from-code-reviewer-to-planner-red-team-bot-migration-plan-review-report.md](reports/from-code-reviewer-to-planner-red-team-bot-migration-plan-review-report.md). Agent chính đã kiểm lại bằng code trước khi chấp nhận.

| # | Mức | Phát hiện | Xử lý |
|---|---|---|---|
| 1 | Critical | Desktop VPS: mọi bot có quyền root trên máy dùng chung | Completed |
| 2 | Critical | Run now không chạy thử được, nên lượt chạy tay là lượt thật | Completed |
| 3 | Critical | Repo public sẽ lộ soul, luật và hạ tầng | Completed |
| 4 | High | Routine không dùng được máy cho mượn; không có My Chrome | In Progress |
| 5 | High | Soul Gia Huy có thể đã bị cắt | **Bác bỏ.** Đã đo: 18.278 byte, dưới 24.000 byte, câu cuối trọn vẹn |
| 6 | High | Không có API sửa skill; DELETE từ chối skill imported | **Chấp nhận.** Phase 3 dùng PATCH `enabled:false`; luật cần thiết đưa vào soul |
| 7 | High | Provision cố định 4 GB làm VPS hết RAM | **Hết liên quan** sau khi bỏ desktop |
| 8 | Medium | Kiểm `ls /workspace` vô ích | **Chấp nhận.** Phase 1 đổi sang kiểm công cụ xử lý file |
| 9 | Medium | `MEMORY.md` chưa được quét | **Chấp nhận.** Thêm vào phase 2 |
| 10 | Medium | "Hỏi trước khi gửi" chỉ là chữ trong soul | **Chấp nhận như rủi ro còn lại.** Thêm luật "không tự tạo hay bật routine" vào soul; theo dõi 3 ngày ở phase 5 |
| 11 | Medium | Không có công cụ `message_bot`; Minh Đăng không đọc được trí nhớ bot khác | **Chấp nhận.** Đổi sang `send_to_bot`/`delegate_bot`; Minh Đăng tạm nghỉ |
| 12 | Medium | Import backup thay toàn bộ bản cài | **Chấp nhận.** Quay lại theo từng bot |

### Whole-Plan Consistency Sweep
Sau khi sửa, đã đọc lại `plan.md` và 5 phase, rồi tìm các chuỗi cũ: `desktop VPS`, `maus-vps`, `My Chrome`, `onehand-vps`, `Run now`, `message_bot`, `reports/souls`. Không còn chỉ dẫn mâu thuẫn. Những chỗ còn nhắc tới các chuỗi này đều là lời giải thích vì sao **không** dùng chúng.

## Câu hỏi còn mở

1. Plan cũ `261112-1439` đã lên GitHub công khai, kèm IP máy Dokploy và ID compose. Repo fork từ repo công khai thì không chuyển sang private được. Anh có muốn tạo repo private riêng cho các plan vận hành, rồi gỡ thông tin hạ tầng khỏi repo công khai không?
2. Nhóm Zalo để thử ở phase 5 là nhóm nào? Anh chỉ định khi tới bước đó.

## Nhật ký thực thi

Agent thực thi ghi vào đây sau mỗi phase. Chỉ ghi mô tả ngắn, không ghi nội dung.

### Phase 1 (13/11 01:00–01:20)
- **Không chạy theo subagent:** cả plan dùng phiên email của anh trong khung trình duyệt của agent chính, nên agent chính tự làm. Đây là điểm khác với quy trình "giao cả plan".
- **Bản chụp:**
  - Trình duyệt trong app không tải file, không ghi clipboard, và bị chặn gọi `127.0.0.1`. Vì vậy bản chụp được lưu **trên server** qua `POST /api/files` (ngoài repo, trong `/data/.openmausbot/attachments/`):
    - bot (soul, model, mức duyệt, nơi làm việc), routine (prompt, lịch) và danh sách skill: 105.609 byte;
    - trí nhớ (`MEMORY.md` của 6 bot và 3 topic của Chiêu Giao): 71.507 byte.
  - Rủi ro: file đính kèm có thể bị dọn nếu không chat nào tham chiếu. Anh vẫn nên tự **Export backup** từ app trên Mac.
- **Trí nhớ có chuỗi chết:** Gia Huy 16, Tiêu Băng 20, Minh Đăng 8, UX UI 6, Chiêu Giao 0, Như Phương 0.
- **Công cụ trên server** (Chiêu Giao chạy `Bash`):
  - user `maus`, HOME `/data`, Debian 12, Node v24.22.2, npm 11.19.1, `curl`, `git`;
  - **không có** `python3`, `uv`, `unzip`, `pdftotext`, `ffmpeg`;
  - ổ `/data` còn trống 35 GB (dùng 82%).
  - **Đổi cách làm:** xử lý file bằng Node, cài gói npm vào thư mục bot (`exceljs` cho Excel, `sharp` cho WebP) thay cho Python/uv. Không cần sửa image.
- **Phát hiện thêm:** Chiêu Giao và Như Phương đang đặt nơi làm việc là `cloud` (Boat, chưa có khóa), nên mọi lượt chạy bị từ chối. Đã PATCH `computer: "browser"` cho cả hai (đọc lại đúng). Đây là bước của phase 3 nhưng phải làm trước để chạy được kiểm tra.
- **Engine** (`GET /api/instances`): `codex` (1 instance, chỉ 1 tài khoản Codex), `chatgpt`, `claude`, `grok` đều available.
- **App đã nối:** `GET /api/connectors` trả `configured:false`, tức server chưa bật dịch vụ Connect apps. Gia Huy sẽ đọc Google Sheet qua trình duyệt (đăng nhập Google, tải CSV vào thư mục bot), không qua app.
- **Phân loại routine theo nội dung:**
  - Nhóm A (chỉ đọc, chỉ báo trong chat): Tiêu Băng tổng kết Chủ nhật, Tiêu Băng phân tích 17h, Gia Huy tổng kết tuần.
  - B (đăng công khai): Tiêu Băng Threads ×4, Instagram 21h15.
  - C (sửa giá hoặc camp): Gia Huy giá Shopee 6h30, review Shopee, health check TikTok.
  - D (gửi Zalo): Gia Huy GMV ×2, lời mời KOC 10h30, dán báo cáo 9h15; **Tiêu Băng báo cáo 8h50** (nhờ Gia Huy dán vào nhóm Zalo).
  - E (Upwork): Như Phương ×2.
  - Nghỉ: Minh Đăng. Quá hạn: Gia Huy "Kiểm lại giá KM COMBO 3 (04/11)".
- **Chưa làm (cần anh):** Export backup từ app.

### Phase 2 (13/11 01:20–01:50)
- **Soul** (PATCH, đọc lại; tìm chuỗi chết trong 6 bot ra 0):
  - Gia Huy: sửa từng dòng, bỏ 6 dòng và sửa 5 dòng (khóa, `se.py`, đường dẫn box). Dòng luật `- [` còn 80/83; 3 dòng bỏ đều là luật khóa. Thêm mục "Cách làm trên MausBot" (Node + `exceljs`, Google Sheet qua trình duyệt, nhận báo cáo Threads từ Tiêu Băng rồi dán Zalo) và luật chung. 18.559 byte.
  - Tiêu Băng: thay 1 dòng, thêm mục ảnh (Node + `sharp`, `memory/anh-da-dung.md`, báo cáo 9h gửi Gia Huy) và luật chung.
  - Chiêu Giao, Như Phương: viết lại, giữ toàn bộ luật; thêm luật máy cho mượn và luật chung.
  - Minh Đăng: soul "tạm nghỉ".
  - UX UI: thêm luật trả lời tiếng Việt và luật chung.
- **Trí nhớ** (PUT `/api/bots/<id>/memory`; tìm chuỗi chết ra 0):
  - Gia Huy bỏ 4 dòng sổ tay, đổi đường dẫn ở 4 dòng.
  - Tiêu Băng bỏ 5, đổi 4.
  - UX UI bỏ 2.
- **Routine:**
  - 16 prompt đã sửa theo từng câu. Đã đọc từng câu bị bỏ: chỉ là đọc sổ tay, `se.py`, khóa, `daily_log`.
  - 3 chỗ suýt mất luật đã giữ hoặc viết bù: ảnh talent 3 ngày của Instagram, nguồn số liệu tổng kết tuần của Tiêu Băng, việc đọc chat và luật mới khi tổng kết tuần của Gia Huy.
  - Đã xóa routine quá hạn "COMBO 3 (04/11)". Routine 9h15 của Gia Huy được đánh dấu "giữ TẮT", vì báo cáo giờ đi thẳng từ Tiêu Băng sang Gia Huy. Routine Minh Đăng không đụng tới.
  - Còn 18 routine, tất cả `enabled:false`. Tìm chuỗi chết ra 0 (trừ Minh Đăng).

### Phase 3 (13/11 01:50–02:05)
- **Model** (PATCH, đọc lại):
  - Gia Huy `codex/gpt-6.1-sol/high`;
  - Như Phương, Tiêu Băng `claude/claude-sonnet-5`;
  - UX UI và Chiêu Giao `claude/claude-opus-5-5`;
  - Minh Đăng giữ nguyên.
- **Nơi làm việc:** 5 bot `browser`, Minh Đăng `off`. Mức duyệt cả 6 bot giữ `full`.
- **Thử model:** gửi 4 tin qua `POST /api/bots/<id>/messages`. Cả 4 trả "ok", `turnSucceeded:true`.
- **Skill:** tắt (PATCH `enabled:false`) Chiêu Giao 13, Gia Huy 4, Tiêu Băng 11, UX UI 13, Minh Đăng 14. Không lỗi.
- **Khác plan:** 7 skill được giữ vẫn còn nhắc khóa, sổ tay hoặc đường dẫn cũ, mỗi skill 1–4 dòng (4 của Gia Huy, `upwork-job-filter` và `wiki-upwork` của Như Phương, 1 của Tiêu Băng). App không có API sửa skill, và tắt các skill này thì mất quy trình nghiệp vụ cốt lõi. Vì vậy **giữ bật** và thêm vào soul của Gia Huy, Như Phương, Tiêu Băng luật ưu tiên "skill còn nhắc cách làm cũ thì bỏ qua phần đó, làm theo hướng dẫn". `wiki-upwork` chỉ nhắc đường dẫn ở phần ghi nguồn. Soul vẫn sạch chuỗi chết.
- **Chờ anh quyết:** UX UI thiếu skill "UI UX Pro Max" mà soul có nhắc tới.

### Phase 4, phần không cần anh (13/11 02:05–02:20)
- **UX UI:** tạo `test.html`, mở bằng trình duyệt tích hợp và chụp màn hình. Đạt.
- **Tiêu Băng:** `npm i sharp exceljs` chạy được, nhưng phải dùng cache npm riêng vì `/data/.npm` lỗi quyền. Có sharp 0.35.5, exceljs 4.4.0. PNG → WebP 112 byte, không còn EXIF.
- **Phát hiện:** mặc định bot làm việc trong thư mục tạm của từng cuộc chat (`task-workspaces/<bot>/<chat>/`), nên file không còn giữa các routine.
  - Đã thêm vào soul của 5 bot dòng "Thư mục của em (cố định): `/data/.openmausbot/workspaces/<botId>/data/`".
  - Tiêu Băng đã chuyển `tools/` vào thư mục đó và chạy lại phép thử WebP. Đạt.
- **Đang chờ anh:** đăng nhập cho Gia Huy (Shopee, TikTok, Stella, Zalo, Google), Tiêu Băng (Threads, Instagram) và Như Phương (Upwork).

### Phase 4, lượt chạy thử lần 1 (13/11 09:05–09:20)
- Anh báo đã đăng nhập. Mở chat mới bằng `POST /api/bots/<id>/tasks` rồi gửi câu dặn "CHẠY THỬ" qua `POST /api/bots/<id>/messages`. Gửi thẳng tin vào một `threadId` chưa có chat thì server trả 409.
- **Gia Huy:** đọc được 57 dòng giá trong sheet (sheet mở công khai, lưu thành CSV trong thư mục cố định). Shopee Seller Center hiện **trang đăng nhập**, nên bot dừng: chưa có `.xlsx`, 0 dòng điền. Không upload, không mở Zalo. Đạt phần "không ghi", **chưa đạt** phần Excel.
- **Tiêu Băng:** Instagram hiện **form đăng nhập**. Threads trả HTTP 429 (bị giới hạn tạm). Không thấy ảnh mới nên bỏ phần ảnh. Gửi 2 bản nháp chữ 20h30, không đăng. Đạt phần "không ghi", **chưa đạt** phần đăng nhập và WebP.
- **Như Phương:** Upwork chặn bằng Cloudflare "Verify you are human". Bot dừng, không thử vượt, và hiện thẻ đăng nhập trong chat chờ anh. Chưa dựng log. Đạt phần "không ghi".
- **Kết luận:** cả 3 bot giữ đúng giới hạn. Shopee và Instagram chưa có phiên đăng nhập trong trình duyệt riêng của bot. Có thể anh đã đăng nhập ở một trình duyệt khác (bot của máy local, hoặc tab Trình duyệt của bot khác). Cần anh kiểm lại rồi chạy lượt 2.
