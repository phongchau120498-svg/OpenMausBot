# So sánh Plus và onhandbot (Rakazo): ngữ cảnh và kết quả thử 11/11/2026

## Việc gốc

So sánh công tâm hai repo trong `CTP DESKTOP`:
- `OnHand Bot Plus` (fork OpenMausBot): bot chạy nguyên CLI (Claude Code, Codex).
- `onhandbot` (Rakazo): bot chạy qua runtime pi, production ở `https://bot.onehand.space` (Dokploy).

Anh thấy bot Rakazo "tù, cứng nhắc", nên cần thử thật với cùng model.

## Phân tích code (phiên trước)

Các nguyên nhân có thể khiến bot Rakazo cứng nhắc, đọc từ `onhandbot/packages/adapters/src`:
1. Prompt mặc định rất mỏng và có "Be concise" (`pi-runtime.ts:374`).
2. Mỗi lượt chỉ thấy 50 tin gần nhất cộng tóm tắt 20.000 ký tự (`history-compaction.ts:47-49`). Kết quả công cụ chỉ giữ 3 cái gần nhất (`runtime-context.ts:25`).
3. Khoảng 107 công cụ được khai báo, chưa tính app tích hợp và MCP.
4. Mức suy nghĩ mặc định là `medium` (`pi-runtime-models.ts:44`).
5. Chế độ duyệt Auto dùng một model rẻ để chấm hành động.

## Bài thử 11/11 (Cách A)

**Cấu hình:**
- Model: GPT 6.1 Sol, mức medium, qua gói ChatGPT, giống nhau cho cả hai bên.
  - Plus: instance `codex`.
  - Rakazo: provider `openai-codex`, trùng cấu hình bot Gia Huy trên production.
- Hai bot thử đều không có hướng dẫn riêng.
- Dữ liệu được dán thẳng vào tin nhắn dưới dạng CSV, không tải file lên.

| Bài | Plus | Rakazo |
|---|---|---|
| 1. CSV 30 đơn, 6 lỗi, viết `bao-cao.md` | Đúng hết, 97 giây | Đúng hết, 190 giây, tự làm thêm trang web |
| Câu đệm: sản phẩm bán chạy, đơn TikTok | Đúng, 6–15 giây | Đúng, 14–15 giây |
| 2. Nhớ lượt đầu (DH1020, Facebook cộng đơn hủy) | Đúng, 7 giây | Đúng, 14 giây |
| 3. Yêu cầu mơ hồ "cho sếp xem nhanh" | Không hỏi lại, viết tóm tắt một trang, 32 giây | Không hỏi lại, cập nhật trang web, 47 giây |

**Đáp án:**
- Doanh thu hợp lệ: 8.922.000đ.
- Theo kênh: Shopee 3.122.000, Facebook 2.701.000, Website 2.545.000, TikTok Shop 554.000.
- Khách mua nhiều đơn nhất trên Shopee: Minh, 3 đơn.
- Sản phẩm bán chạy nhất: Mặt nạ, 16 cái.
- TikTok có 2 đơn hợp lệ: DH1006, DH1027.
- Facebook nếu cộng đơn hủy DH1024: 3.497.000đ.
- Các lỗi cài sẵn: DH1005 thành tiền sai, DH1010 số lượng âm, DH1004 trùng mã, DH1020 ngày 31/11, DH1024 đã hủy, DH1028 đơn giá gấp 10.

## Kết luận tạm

- Với việc ngắn và cùng model, chất lượng hai bên ngang nhau. Plus nhanh hơn 1,5 đến 2 lần.
- Hai nguyên nhân 2 và 3 ở trên (giới hạn trí nhớ, quá nhiều công cụ) chưa lộ ra ở bài ngắn.
- Ngay sau tin đầu tiên, bot Rakazo **tự viết lại hướng dẫn của chính nó** (`update_bot`) và tự gắn skill `giao-thuc-doi-bot` dùng chung trong space. Từ đó lượt nào nó cũng đọc lại skill này, nên chậm hơn.
- Prompt của các routine production có hàng chục ràng buộc. Cảm giác "tù" nhiều khả năng đến từ cấu hình đội bot, không phải do model hay pi.

## Tối nay thử tiếp

1. Hội thoại dài hơn 50 tin: hỏi lại chi tiết chỉ nằm trong kết quả công cụ ở lượt đầu.
2. Việc thao tác trình duyệt nhiều bước, để xem số công cụ có làm bot chọn sai không.
3. Đặt bot Rakazo vào một space sạch không có skill dùng chung, rồi so lại tốc độ.
4. Thử thêm mức suy nghĩ `high` cho cả hai bên.

## Cách chạy lại

**Plus cô lập** (không đụng dữ liệu thật):

```bash
cd "/home/thanh-phong/CTP DESKTOP/OnHand Bot Plus"
OMB_DATA_DIR=<thư-mục-tạm> OMB_PORT=19980 OMB_WEBHOOK_PORT=19981 OMB_DISABLE_ANNOUNCEMENTS=1 OMB_DEV_TRUST_LOCAL_BROWSER=1 PATH="$HOME/.npm-global/bin:$PATH" node --experimental-strip-types server/dev-server.ts
```

```bash
node --experimental-strip-types scripts/control-omb.ts new-bot --name TEST-so-sanh --url http://127.0.0.1:19980
```

```bash
node --experimental-strip-types scripts/control-omb.ts set-model --bot <ID> --instance codex --model gpt-6.1-sol --effort medium --url http://127.0.0.1:19980
```

```bash
node --experimental-strip-types scripts/control-omb.ts run --bot <ID> --task <TASK> --text "..." --wait turn --timeout 5m --url http://127.0.0.1:19980
```

**Rakazo production:** anh tự đăng nhập trong trình duyệt. Sau đó gọi RPC từ trang bằng lệnh POST `/rpc/<path>`, body có dạng `{"json": {...}}`:
- `bots/create` với `{name, description, instructions, notifyOnFinish}`.
- `bots/update` với `{botId, modelProvider: "openai-codex", modelId: "gpt-6.1-sol", thinkingLevel: "medium"}`.
- `threads/send` với `{botId, clientNonce, imageHandling: "confirm", text}`.
- `threads/get` với `{botId}`, rồi xem `run.status` và `messages[].blocks`.
- `bots/remove` với `{botId, deleteMemories: true}`. Phải hỏi anh trước khi xóa.

Bot thử bên production đã xóa sau buổi thử.

**Sinh lại dữ liệu thử** (`random.seed(7)`):

```python
import random, csv, io
random.seed(7)
kenh=["Shopee","TikTok Shop","Facebook","Website"]
sp={"Serum C":289000,"Kem chong nang":199000,"Sua rua mat":149000,"Toner":179000,"Mat na":39000}
kh=["Lan","Minh","Huong","Tuan","Mai","Khoa","Thao","Binh"]
rows=[]
for i in range(1,31):
    p=random.choice(list(sp)); q=random.randint(1,4)
    rows.append([f"DH{1000+i}",f"2026-10-{random.randint(1,31):02d}",random.choice(kenh),random.choice(kh),p,q,sp[p],q*sp[p],"Hoan thanh"])
rows[4][7]=rows[4][5]*rows[4][6]+100000
rows[9][5]=-2; rows[9][7]=-2*rows[9][6]
rows[14]=rows[3][:]
rows[19][1]="2026-11-31"
rows[23][8]="Da huy"
rows[27][6]=2890000; rows[27][7]=rows[27][5]*2890000
w=io.StringIO(); c=csv.writer(w,lineterminator="\n")
c.writerow(["ma_don","ngay","kenh","khach","san_pham","so_luong","don_gia","thanh_tien","trang_thai"]); c.writerows(rows)
open("don-hang.csv","w").write(w.getvalue())
```

## Câu hỏi chưa giải quyết

- Bot production thật có đang rơi xuống model dự phòng (fallback) không? Cần xem Settings → Usage.
- Nếu tắt skill dùng chung hoặc rút gọn prompt routine, bot đội có bớt "tù" không?
