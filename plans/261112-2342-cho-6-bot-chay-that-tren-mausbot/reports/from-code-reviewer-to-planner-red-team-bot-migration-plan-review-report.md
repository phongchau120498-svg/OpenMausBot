# Phản biện đỏ: plan "Cho 6 bot chạy được thật trên MausBot"

Người viết: code-reviewer (red team). Ngày 13/11/2026. Chỉ đọc repo, không sửa gì ngoài file này.
Nguồn kiểm: code ở `HEAD` (server trùng `v0.1.153`: `git diff --stat v0.1.153 HEAD -- server` rỗng), docs, `gh repo view`.

## Kết luận nhanh

Plan **chưa được chạy**. Có 3 lỗi Critical:
1. Desktop VPS trên máy dùng chung trao quyền root của `onehand-vps` cho mọi bot. Lý do: bot chạy shell không sandbox, ở mức Full.
2. Bấm "Run now" không thêm được câu dặn "chỉ báo / nhóm thử / không nộp". Vì vậy lượt chạy tay đầu tiên của nhóm B, C, D, E là lượt **thật**.
3. Repo **PUBLIC**, mà plan sẽ commit nguyên văn soul, routine và hạ tầng.

Thêm vào đó, cả nhóm E (Upwork dùng Mac) **không làm được trên server tự host này**.

---

## Findings (nặng nhất trước)

### 1. [Critical] Phase 5: SSH key cộng docker CLI cho mọi bot quyền root trên máy chạy mysql, nginx và app khác
- **Vấn đề:**
  - Khóa `/data/.ssh/maus-vps` không có passphrase. Server có thêm docker CLI.
  - Mọi bot chạy shell bằng user `maus` (HOME=`/data`) và không có sandbox, nên đọc được khóa và gọi `docker -H ssh://maus-vps run -v /:/host …`. Như vậy là root trên `onehand-vps`.
  - Cả 6 bot ở mức Full. Bot đọc nội dung không tin cậy hằng ngày: job Upwork, bình luận Threads, review Shopee, tin Zalo, KOC. Một prompt injection là đủ để chiếm máy có mysql.
  - Plan coi rủi ro này là "đã nêu với anh" (phase-05 dòng 31). Thực tế phạm vi lớn hơn nhiều: không chỉ "bot vào desktop đó", mà **bất kỳ bot nào, kể cả qua injection**.
- **Bằng chứng:**
  - `docs/byo-vps.md:42-45`: "membership in the `docker` group is root-equivalent … Give bots a dedicated server, not one that also holds things you would not hand to the agent".
  - `plans/261112-1439-chuyen-dokploy-sang-mausbot/plan.md:48`: bản này chưa có sandbox AppArmor cho bot.
  - `docs/approval-levels.md:38`: Full chạy lệnh không hỏi lại.
  - `server/vps-computer.ts:792-797`: server còn tự `docker pull`/`build` trên VPS.
  - Plan tự chứng minh bot chạy được shell tùy ý: `phase-01-kiem-ke-va-sao-luu.md:22`.
- **Cách sửa:**
  - Đổi mặc định thành **VPS riêng** (đúng khuyến nghị của docs). Câu hỏi mở số 1 nên được trả lời *trước* phase 5, không để làm phương án dự phòng.
  - Nếu anh vẫn chọn máy dùng chung thì ghi rõ "chấp nhận root-equivalent", rồi tối thiểu:
    - thêm `from="<IP máy Dokploy>"` vào `authorized_keys`;
    - firewall cổng 2018 chỉ mở cho IP Dokploy;
    - đặt `vpsAlias` riêng cho Gia Huy (`server/routes/bot-patch.ts:396-400`) thay cho alias mặc định toàn app ở Settings → API keys (`docs/byo-vps.md:96`).

### 2. [Critical] Phase 6: "Run now" chạy đúng prompt đã lưu, không có chỗ thêm "câu dặn giới hạn"
- **Vấn đề:**
  - `phase-06-bat-routine-theo-nhom.md:31` muốn lượt chạy tay đầu của nhóm C, D, E có thêm "chỉ báo, không sửa", "gửi vào nhóm thử" hoặc "không nộp".
  - Nhóm B thì "anh duyệt nội dung lượt chạy tay đầu" (dòng 24).
  - Nhưng `POST /api/routines/:id/run` không đọc body, và `runNow()` dùng nguyên prompt đã lưu. Bấm Run now sẽ:
    - **sửa giá Shopee thật**;
    - **gửi Zalo vào nhóm công ty thật**;
    - **đăng Threads thật**;
    - **nộp proposal thật**.
  - Không có bước duyệt nào chen vào trước khi đăng.
  - Thêm nữa, nhóm A ("chỉ đọc, nội bộ") được xếp **trước khi đọc prompt** (`routines-before.md` chưa có). Báo cáo 8h50 của Tiêu Băng hay tổng kết tuần của Gia Huy có thể vẫn gửi ra ngoài.
- **Bằng chứng:**
  - `server/index.ts:14617-14620`: route run chỉ gọi `routines!.runNow(routineMatch[1])`.
  - `server/routines.ts:718-741`: `runNow` tạo run từ chính routine.
- **Cách sửa:**
  - Lượt thử của B, C, D, E làm bằng **bản sao tạm**: `POST /api/routines` với `enabled:false`, prompt = prompt gốc + điều khoản dry-run, đích là nhóm thử. Chạy bản sao, đọc kết quả, rồi xóa bản sao.
  - Hoặc dán prompt vào một chat mới với câu dặn. Không bao giờ Run now routine gốc trước khi anh duyệt.
  - Xếp nhóm sau khi đọc `routines-before.md`. Prompt nào có Zalo, đăng, gửi, sửa hoặc nộp thì không được vào nhóm A.

### 3. [Critical] Repo PUBLIC: soul, routine và hạ tầng sẽ bị công khai
- **Vấn đề:**
  - `gh repo view` của `phongchau120498-svg/OpenMausBot` trả `PUBLIC`.
  - Plan ghi nguyên văn soul và prompt vào `reports/souls-before/`, `souls-after/`, `routines-*.md`, rồi commit (`plan.md:73`, `phase-06…:43`). Nội dung gồm:
    - luật giá và camp Shopee, chiến lược Upwork;
    - tên nhóm Zalo công ty, quy trình KOC.
  - `plan.md:50-52` ghi IP, cổng SSH, user root và danh sách dịch vụ của `onehand-vps`.
  - Phase 5 bước 3 **bắt buộc push** để Dokploy build, nên mọi thứ đã commit lúc đó sẽ lên GitHub công khai.
  - Chỉ ẩn "mật khẩu, token, số điện thoại, KOC" là không đủ: bí mật kinh doanh và bản đồ hạ tầng cho kẻ tấn công cũng lộ.
- **Bằng chứng:**
  - `git check-ignore` cho `reports/souls-before/x.md` trả NOT IGNORED.
  - Plan cũ đã lộ IP Dokploy trên `origin/main`: `plans/261112-1439-chuyen-dokploy-sang-mausbot/plan.md:30,43`.
- **Cách sửa:**
  - Lưu snapshot soul và routine **ngoài repo**, ví dụ `~/Downloads/` cạnh file backup, hoặc thêm `.gitignore` cho `plans/*/reports/souls-*` và `routines-*`.
  - Bỏ IP, cổng và tên dịch vụ khỏi plan trước khi push, hoặc chuyển repo sang private.
  - Hỏi anh có muốn gỡ IP khỏi lịch sử plan cũ không.

### 4. [High] Phase 4 và 6, nhóm E: server tự host không cho routine dùng máy cho mượn, và không có My Chrome
- **Vấn đề:**
  - Luật trích từ `server/cloud-lending.ts` (`plan.md:43`, `phase-06:16`) **chỉ áp dụng cho Cloud home**.
  - Trên server tự host (`CLOUD_HOME` null), `sharedComputerPrincipal` chỉ nhận lượt có tin nhắn do người viết. Dòng prompt của routine không có `sender`, nên **mọi** routine bị từ chối, dù chạy theo lịch hay Run now, dù anh tạo hay không. Phương án "anh tạo lại routine" (`phase-06:37,51`) cũng không cứu được.
  - "My Chrome" cho mượn chỉ có trên My Cloud cá nhân.
  - Kéo theo: tiêu chí nghiệm thu "săn job trên Chrome của Mac", cả nhóm E (10 lượt/ngày) và phase 4 bước 2 đều không làm được như viết.
- **Bằng chứng:**
  - `server/index.ts:896-900`: nếu không phải CLOUD_HOME thì dùng `provenRequestPerson`.
  - `server/shared-computers.ts:140-147`.
  - `server/index.ts:7678` và `:8833`: routine gọi `startTurn` không truyền `sender`.
  - `docs/self-hosting.md:669-670`: "Only conversations you start yourself on that server can use what you share; other people's bots, **routines** and webhooks there cannot".
  - `server/index.ts:2388`: `lentChrome: CLOUD_PERSONAL ? … : undefined`.
  - `src/locales/en.json:3831-3832`: My Chrome chỉ có trên desktop app hoặc My Cloud, "in conversations you started yourself".
- **Cách sửa:** sửa lại phần "Đã kiểm tra", rồi trình anh 3 lựa chọn:
  - (a) Upwork qua trình duyệt tích hợp trên server (rủi ro IP datacenter hoặc khóa tài khoản);
  - (b) bỏ routine, anh tự mở chat với Như Phương khi muốn săn job;
  - (c) tạm bỏ nhóm E.

### 5. [High] Phase 1 và 2: soul Gia Huy có thể đã bị cắt khi import; soul mới có thể vượt giới hạn
- **Vấn đề:**
  - Grok import **cắt im lặng** soul ở 24.000 byte UTF-8. Tiếng Việt có dấu tốn khoảng 1,5–1,6 byte mỗi ký tự, nên 15.281 ký tự xấp xỉ 24.000 byte. Con số này rất khớp với một soul đã bị cắt.
  - Câu "toàn bộ rules.md nằm sẵn trong soul" (`plan.md:54`) chưa được kiểm.
  - Nếu soul đã chạm trần, mọi câu thêm ở phase 2 bước 2 sẽ bị PATCH trả 400.
- **Bằng chứng:**
  - `shared/grok-import.ts:424`: `fitBytes(bot.instructions.trim(), BOT_PROFILE_LIMITS.soul)`.
  - `shared/grok-import.ts:309-313`: cắt, không báo.
  - `shared/bot-profile.ts:10`: `soul: 24_000`.
  - `server/bot-profile.ts:55`: PATCH kiểm `Buffer.byteLength`.
- **Cách sửa:**
  - Phase 1 ghi thêm `bytes` của từng soul (`GET /api/bots/:id/soul` trả `bytes` và `limit`: `server/index.ts:14800-14812`), rồi so đoạn cuối với file Grok export gốc.
  - Nếu soul ≥ 23.500 byte: chuyển luật dài sang một skill riêng của Gia Huy hoặc một topic trong trí nhớ. Phase 2 phải tính ngân sách byte.

### 6. [High] Phase 3: không có API `PUT` để sửa nội dung skill; một số skill không xóa được
- **Vấn đề:**
  - Phase 3 bước 4 ghi "`PUT` skill; app tự lưu bản cũ". Route `/api/bots/:id/skills/:name` chỉ có:
    - `GET`;
    - `PATCH` (chỉ nhận `{enabled}`);
    - `DELETE`.
  - Skill có origin `imported`/`native` trả 404 khi DELETE.
  - Agent thực thi sẽ phải tự xoay, ví dụ nhờ bot sửa `SKILL.md` qua shell. Làm vậy là vượt luật cứng 1 (chỉ sửa qua API hoặc giao diện).
- **Bằng chứng:**
  - `server/routes/bot-skills.ts:82-91`: PATCH chỉ có `z.object({ enabled: z.boolean() })`.
  - `server/routes/bot-skills.ts:110-127`: DELETE từ chối imported và native.
  - UI cũng chỉ gọi PATCH enabled hoặc DELETE: `src/components/bot-settings/SkillsSection.tsx:150-170`.
- **Cách sửa:**
  - Skill thừa: dùng `PATCH {enabled:false}` (đảo ngược được) thay cho DELETE.
  - Skill cần sửa text: tắt bản cũ, rồi tạo skill mới bằng skill authoring trong chat của anh. Plan phải ghi rõ cách này.

### 7. [High] Phase 5: Provision tạo container 4 GB/2 CPU trên máy chỉ còn khoảng 2,2 GB trống; giới hạn 2 GB mất khi image Cua đổi
- **Vấn đề:**
  - Bước 6 (Provision) build image Cua ngay trên VPS, rồi tạo container `--memory 4g --cpus 2`. Bước 7 mới hạ xuống 2 GB.
  - Trong khoảng giữa, Chrome và trình biên dịch có thể đẩy máy vào OOM. Kernel thường giết tiến trình RSS lớn nhất, tức **mysqld**, chứ không giết container (vì giới hạn 4 GB của container lớn hơn RAM còn trống).
  - Khi server nâng version (Cua driver hoặc image layer đổi), app từ chối container cũ. Container phải tạo lại với 4 GB, và **mất toàn bộ đăng nhập**: Zalo QR, Shopee, TikTok, Stella.
  - Ngưỡng "còn 300 MB" cho mysql, nginx, node và hub là quá mỏng.
- **Bằng chứng:**
  - `server/vps-computer.ts:751-756` (4g/4g/2 cứng).
  - `server/vps-computer.ts:776-788` (`imageMatches` sai thì từ chối).
  - `server/vps-computer.ts:792-797` (build trên VPS).
  - `docs/byo-vps.md:144-148`, `:158-161` ("recreate that follows a Cua image upgrade … wipes it").
- **Cách sửa:**
  - Dùng VPS riêng (finding 1).
  - Nếu vẫn dùng máy chung:
    - làm vào giờ thấp điểm;
    - đặt `oom_score_adj=-900` cho mysqld trước khi Provision;
    - chạy `docker update` ngay khi container xuất hiện, trước Take control;
    - ghi vào rollback và quy trình nâng version: "sau mỗi lần nâng server: update lại giới hạn và đăng nhập lại 5 trang".

### 8. [Medium] Phase 1 bước 3: kiểm sai chỗ, có thể bỏ mất dữ liệu còn cứu được
- **Vấn đề:**
  - `/workspace/...` nằm trong "box" của Grok. Nó chưa bao giờ có trong container Docker mới này, nên `ls` trên server chắc chắn ra "không có" và không chứng minh được gì.
  - Thứ có thể còn là workspace bên Grok. File export chỉ mang instructions, memories, skills và routines, không mang file workspace. Vì vậy sổ tay `so-tay-pix/rules.md`, `lessons.csv` và dữ liệu `se.py` có thể vẫn lấy lại được từ Grok.
  - Trong khi đó, sổ tay Tiêu Băng hiện "chỉ có tóm tắt" (`plan.md:56`).
- **Bằng chứng:**
  - `shared/grok-import.ts:29`: export được lưu "in your workspace" bên Grok.
  - `shared/grok-import.ts:33-52`: schema export không có file workspace.
- **Cách sửa:**
  - Bỏ lệnh `ls /workspace`. Hỏi anh tài khoản Grok còn hoạt động không.
  - Nếu còn: nhờ bot Grok dán nội dung `rules.md`, `lessons.csv` và bảng bài học (top N), rồi đưa vào soul, skill hoặc trí nhớ.
  - Chỉ giữ phần `which docker ssh` cho phase 5.

### 9. [Medium] Trí nhớ được seed từ Grok (`MEMORY.md`) không được quét đường dẫn chết
- **Vấn đề:**
  - Grok `memories` được nạp vào `MEMORY.md`, file nạp vào **mọi** cuộc chat. Nhiều khả năng file này còn ghi `lock.sh`, `se.py`, `/workspace`, giờ chia Zalo.
  - Tiêu chí nghiệm thu và phase 2 bước 8 chỉ quét soul, routine và skill.
- **Bằng chứng:**
  - `shared/grok-import.ts:398` (memories thành facts).
  - `shared/grok-import.ts:471` (`seed["MEMORY.md"]`).
  - `docs/memory.md:20-24` (`MEMORY.md` "loads into every conversation").
- **Cách sửa:**
  - Phase 1 đọc `MEMORY.md` của 6 bot (Bot Settings → Memory, hoặc API memory).
  - Phase 2 sửa chỗ còn đường dẫn chết bằng editor có `expectedHash` (`docs/memory.md:328-344`).
  - Thêm `MEMORY.md` vào bước tìm chuỗi.

### 10. [Medium] Quyết định số 3 ("ngoài routine thì hỏi trước") chỉ nằm ở chữ trong soul; plan hiểu sai về mức duyệt
- **Vấn đề:**
  - Plan ghi "không có mức riêng cho gửi tin" (`plan.md:44`). Thực ra có **Permissions → Sending on your behalf**, nhưng nó chỉ chặn việc gửi qua *connected apps*. Zalo Web gửi bằng trình duyệt hoặc desktop thì không bị chặn gì.
  - Ở mức Full, bot tự tạo, bật hoặc sửa routine và hồ sơ bot mà không cần duyệt lần hai.
  - Chiêu Giao là Chief nên mức Full truyền xuống mọi việc nó giao.
  - Như vậy "Không bật routine ngoài phase 6" chỉ ràng buộc agent thực thi, không ràng buộc bot.
- **Bằng chứng:**
  - `docs/approval-levels.md:38` (Full: "routine actions … apply without a second approval"; Sending on your behalf).
  - `docs/composio.md:217`.
  - `docs/approval-levels.md:123-128` (Chief's level flows down).
- **Cách sửa:**
  - Sửa lại câu ở "Đã kiểm tra".
  - Bot nào có connected app gửi được ra ngoài thì đặt Sending on your behalf = **Ask every time**.
  - Trong 3 ngày theo dõi, kiểm thêm "routine nào bị bot tự tạo hoặc bật" (so `GET /api/routines` với danh sách đã duyệt).

### 11. [Medium] Phase 2: tên công cụ `message_bot` không tồn tại; cách kiểm Minh Đăng không phải là kiểm
- **Vấn đề:**
  - Soul mới sẽ bảo bot "nhắn Gia Huy (`message_bot`)". Công cụ thật có tên `ask_bot`, `send_to_bot`, `delegate_bot` và `coordinate_bots`.
  - Trí nhớ là workspace **riêng** của từng bot. Không có công cụ memory nào đọc trí nhớ bot khác; chỉ đọc lén được bằng shell (`cat /data/.openmausbot/workspaces/<id>/…`), tức là đi vòng qua thiết kế.
  - "Hỏi Minh Đăng xem có đọc được không" là hỏi một LLM. Câu trả lời của nó không phải bằng chứng.
- **Bằng chứng:**
  - `server/peer-provenance.ts:65` (danh sách delivery thật).
  - `docs/memory.md:18-29` ("The folder is the bot's private workspace").
- **Cách sửa:**
  - Dùng đúng tên công cụ, lấy từ danh sách tool của bot.
  - Theo YAGNI: **tạm tắt** Minh Đăng và routine của nó cho tới khi anh trả lời câu hỏi mở số 2, thay cho "mặc định giữ vai trò mới".

### 12. [Medium] Rollback bằng "Import backup" sẽ xóa sạch mọi thứ, không phải quay lại một bot
- **Vấn đề:**
  - Import backup *thay toàn bộ* bản cài, cần restart và cần mật khẩu backup ≥ 12 ký tự (phase 1 không nhắc gì tới mật khẩu).
  - Dùng nó để quay lại một soul sẽ xóa luôn kết quả phase 3–6: alias VPS, model, routine đã bật.
  - App đã có lịch sử thay đổi hồ sơ, rẻ hơn nhiều.
- **Bằng chứng:**
  - `src/locales/en.json:6273` ("replaces everything … does not merge … Restart is required").
  - `server/workspace-backup-http.ts:22` (`passwordSchema` min 12).
  - `server/routes/bot-patch.ts:721` (`recordProfileChange` mỗi lần PATCH).
- **Cách sửa:**
  - Quay lại từng bot bằng PATCH soul từ snapshot (lưu ngoài repo, xem finding 3) hoặc từ lịch sử hồ sơ.
  - Import backup chỉ dùng khi hỏng toàn bộ. Ghi chỗ cất mật khẩu backup (không ghi vào repo).

---

## Các claim đã kiểm và ĐÚNG

| Claim | Bằng chứng |
|---|---|
| `PATCH /api/bots/:id` tồn tại | `server/routes/bot-patch.ts:102-103` |
| Các trường `modelSelection`, `approvalMode` đúng tên | `server/routes/bot-patch.ts:139`, `:162` |
| `computer` nhận `null`(Auto)/`cloud`/`vm`/`local`/`browser`/`off` | `server/routes/bot-patch.ts:204-218` |
| `cloudBackend: "vps"` và `vpsAlias` theo bot | `server/routes/bot-patch.ts:389-400` |
| `PUT /api/bots/order` (đúng PUT, không phải PATCH) | `server/routes/bot-order.ts:22` |
| `PATCH` và `DELETE /api/routines/:id` | `server/index.ts:14622-14623`, `:14648-14650` |
| Bật một routine "once" đã quá hạn bị từ chối, nên xóa là đúng | `server/routines.ts:601` |
| `DELETE /api/bots/:id/skills/:name` (trừ imported/native) | `server/routes/bot-skills.ts:110-127` |
| Image runtime gốc chỉ cài `ca-certificates curl git`, không có docker và openssh-client | `git show v0.1.153:Dockerfile` dòng 79 |
| Dokploy compose build từ `../local` | `deploy/dokploy/docker-compose.yml:8-11` |
| BYO-VPS cần docker CLI trên server, SSH alias, nhóm docker, nhận host key bằng tay | `docs/byo-vps.md:36-45`, `:113-120` |
| Mặc định 4 GiB/2 CPU, sửa được sau khi tạo | `docs/byo-vps.md:144-148`, `server/vps-computer.ts:751-756` |
| Routine chạy theo lịch hoặc chạy tay luôn tự bật VPS, không rơi về máy server | `docs/byo-vps.md:24-27` |
| Desktop VPS mỗi lúc chỉ một lượt dùng, lượt khác xếp hàng tối đa 30 phút | `docs/byo-vps.md:175-193` |
| Run now của admin được ghi là `ownerStarted` (nhưng vô dụng off-Cloud, xem finding 4) | `server/index.ts:14619` |
| Việc giao qua `coordinate_bots` và webhook không dùng được máy cho mượn | `docs/self-hosting.md:669-670`, `server/cloud-lending.ts:1-4` |
| Mô tả các mức duyệt Ask/Auto-accept/Approve for me/Full/Custom | `docs/approval-levels.md:33-39` |
| Model id `claude-sonnet-5`, `claude-opus-5-5`, `gpt-6.1-sol` có trong catalog | grep `server/` và `shared/` |

## Câu hỏi còn mở
1. Tài khoản Grok cũ còn hoạt động không? Còn thì lấy lại sổ tay và bài học trước khi viết lại soul (finding 8).
2. Máy cho mượn hiện là PC Linux công ty (`plans/261112-1439…/plan.md`, nhật ký phase 6). Mac ở nhà đã ghép và bấm Allow chưa? Câu này chỉ còn quan trọng cho các chat anh tự mở, vì routine không dùng được (finding 4).
3. Anh chọn hướng nào cho Upwork: (a), (b) hay (c) ở finding 4?

Status: DONE_WITH_CONCERNS
Summary: 3 lỗi Critical: quyền root trên VPS dùng chung bị lộ cho mọi bot, Run now không có chế độ thử nên lượt chạy tay đầu là lượt thật, và repo public sẽ công khai soul cùng hạ tầng. Thêm 4 lỗi High: nhóm E không chạy được trên server tự host, soul Gia Huy có thể đã bị cắt, không có API sửa skill, và OOM khi Provision. Phải sửa plan trước khi chạy.
