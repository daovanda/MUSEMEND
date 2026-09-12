create table public.daily_quotes (
  rotation_order smallint primary key,
  topic text not null,
  content text not null unique,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  constraint daily_quotes_rotation_order_check
    check (rotation_order > 0),
  constraint daily_quotes_topic_check
    check (topic in ('love_life', 'enjoy_moment', 'life', 'smile', 'happiness')),
  constraint daily_quotes_content_check
    check (char_length(btrim(content)) between 1 and 240)
);

alter table public.daily_quotes enable row level security;

revoke all on table public.daily_quotes from public, anon, authenticated;

insert into public.daily_quotes (rotation_order, topic, content) values
  (1, 'love_life', 'Mỗi bình minh là một lời mời để mình yêu cuộc đời thêm một chút.'),
  (2, 'love_life', 'Cuộc sống dịu dàng hơn khi ta học cách trân trọng những điều rất nhỏ.'),
  (3, 'love_life', 'Hôm nay vẫn đáng yêu, chỉ cần mình chịu mở lòng để nhìn thấy.'),
  (4, 'love_life', 'Có những ngày bình thường nhưng vẫn đủ đẹp để ta biết ơn.'),
  (5, 'love_life', 'Yêu đời không phải vì mọi thứ hoàn hảo, mà vì mình vẫn tìm thấy điều đáng yêu.'),
  (6, 'love_life', 'Một tách trà ấm cũng có thể là lý do để ngày dài trở nên dễ thương.'),
  (7, 'love_life', 'Hãy để trái tim tò mò trước những niềm vui chưa kịp ghé qua.'),
  (8, 'love_life', 'Ngày mới không cần rực rỡ, chỉ cần có một điều khiến mình muốn bước tiếp.'),
  (9, 'love_life', 'Càng để ý, ta càng thấy cuộc đời gửi đến mình nhiều món quà bé xinh.'),
  (10, 'love_life', 'Đôi khi yêu cuộc sống bắt đầu từ việc chăm sóc chính mình thật tử tế.'),
  (11, 'love_life', 'Mỗi con đường đều có một góc trời đáng để mình ngước nhìn.'),
  (12, 'love_life', 'Thế giới còn nhiều điều ấm áp đang chờ mình chạm tới.'),
  (13, 'love_life', 'Hãy sống như thể hôm nay có một điều tốt đẹp sắp tìm thấy bạn.'),
  (14, 'love_life', 'Một ngày đáng yêu được góp nhặt từ những lựa chọn dịu dàng.'),
  (15, 'love_life', 'Cho mình thêm một cơ hội cũng là một cách nói rằng mình yêu cuộc đời.'),
  (16, 'love_life', 'Cuộc sống luôn có chỗ cho một khởi đầu nhỏ và chân thành.'),
  (17, 'love_life', 'Ta không cần đi xa để thấy đẹp, chỉ cần nhìn gần hơn bằng đôi mắt biết thương.'),
  (18, 'love_life', 'Niềm yêu đời lớn lên từ những lần mình chọn hy vọng.'),
  (19, 'love_life', 'Hôm nay là một trang mới, mình có thể viết lên đó bằng màu mình thích.'),
  (20, 'love_life', 'Hãy để lòng mình có một ô cửa luôn mở về phía ánh sáng.'),
  (21, 'enjoy_moment', 'Khoảnh khắc này không cần hoàn hảo để trở thành một kỷ niệm đẹp.'),
  (22, 'enjoy_moment', 'Chậm lại một nhịp, bạn sẽ nghe thấy ngày hôm nay đang thở.'),
  (23, 'enjoy_moment', 'Hãy uống ngụm nước thật chậm và để tâm trí được nghỉ một lát.'),
  (24, 'enjoy_moment', 'Có mặt trọn vẹn là món quà dịu dàng nhất ta dành cho hiện tại.'),
  (25, 'enjoy_moment', 'Đừng vội đi qua buổi chiều khi nắng vẫn còn đang kể chuyện.'),
  (26, 'enjoy_moment', 'Một phút bình yên được cảm nhận trọn vẹn cũng là một phút đáng giá.'),
  (27, 'enjoy_moment', 'Hít sâu, thở chậm và để khoảnh khắc này ôm lấy bạn.'),
  (28, 'enjoy_moment', 'Hiện tại trở nên rộng lớn khi ta thôi vội vàng.'),
  (29, 'enjoy_moment', 'Hãy nhìn quanh, có thể điều bạn cần đang nằm trong một chi tiết rất nhỏ.'),
  (30, 'enjoy_moment', 'Niềm vui thường ghé qua khi ta thật sự có mặt.'),
  (31, 'enjoy_moment', 'Để điện thoại xuống một lát và ngắm thế giới bằng đôi mắt của mình.'),
  (32, 'enjoy_moment', 'Mùi của cơn mưa, vị của bữa cơm, tiếng của người thương đều là hiện tại.'),
  (33, 'enjoy_moment', 'Bạn không cần làm gì thêm để khoảnh khắc nghỉ ngơi này trở nên xứng đáng.'),
  (34, 'enjoy_moment', 'Ngày hôm nay chỉ đến một lần, hãy chạm vào nó bằng sự chú tâm.'),
  (35, 'enjoy_moment', 'Một bước chân chậm cũng có thể đưa ta đến gần chính mình hơn.'),
  (36, 'enjoy_moment', 'Hãy để bữa ăn là bữa ăn và cuộc trò chuyện là một cuộc gặp thật sự.'),
  (37, 'enjoy_moment', 'Đừng để mong chờ ngày mai lấy mất vẻ đẹp đang có hôm nay.'),
  (38, 'enjoy_moment', 'Bình yên không ở cuối hành trình, nó có thể nằm trong nhịp thở này.'),
  (39, 'enjoy_moment', 'Lắng nghe một bài hát đến hết cũng là cách tận hưởng cuộc sống.'),
  (40, 'enjoy_moment', 'Khoảnh khắc được nâng niu sẽ ở lại lâu hơn trong trái tim.'),
  (41, 'life', 'Cuộc sống không đi theo đường thẳng, nhưng mỗi khúc quanh đều dạy ta điều gì đó.'),
  (42, 'life', 'Có những câu trả lời chỉ xuất hiện sau khi mình đã đủ kiên nhẫn sống tiếp.'),
  (43, 'life', 'Một ngày khó khăn không phải là toàn bộ câu chuyện của bạn.'),
  (44, 'life', 'Trưởng thành đôi khi chỉ là biết nghỉ khi mệt và đi tiếp khi đã sẵn sàng.'),
  (45, 'life', 'Đi chậm không có nghĩa là đứng yên.'),
  (46, 'life', 'Mỗi lựa chọn tử tế đều âm thầm làm cuộc sống đổi khác.'),
  (47, 'life', 'Không phải ngày nào cũng tốt, nhưng ngày nào cũng có điều để hiểu thêm.'),
  (48, 'life', 'Ta có thể bắt đầu lại từ nơi mình đang đứng, với những gì mình đang có.'),
  (49, 'life', 'Cuộc sống nhẹ hơn khi ta thôi mang theo những điều đã không còn thuộc về mình.'),
  (50, 'life', 'Thay đổi nhỏ được lặp lại có thể tạo nên một hành trình lớn.'),
  (51, 'life', 'Bạn không cần biết hết con đường, chỉ cần nhìn rõ bước kế tiếp.'),
  (52, 'life', 'Có lúc tiến lên là dũng cảm, có lúc dừng lại cũng là dũng cảm.'),
  (53, 'life', 'Những mùa khác nhau đều có lý do để tồn tại trong đời.'),
  (54, 'life', 'Sai một lần không khiến bạn trở thành một người sai.'),
  (55, 'life', 'Cuộc đời rộng hơn những điều đang làm bạn lo lắng hôm nay.'),
  (56, 'life', 'Mỗi ngày ta hiểu mình hơn một chút là mỗi ngày đã không trôi qua vô ích.'),
  (57, 'life', 'Đường dài được tạo nên từ những bước chân rất đỗi bình thường.'),
  (58, 'life', 'Không cần vội trở thành ai khác, hãy kiên nhẫn lớn lên theo cách của mình.'),
  (59, 'life', 'Điều đã qua là bài học, không phải căn phòng để ta ở mãi.'),
  (60, 'life', 'Cuộc sống vẫn tiếp tục mở cửa khi ta còn sẵn lòng thử lại.'),
  (61, 'smile', 'Một nụ cười nhỏ có thể làm mềm cả một ngày dài.'),
  (62, 'smile', 'Hãy mỉm cười với mình trong gương như cách bạn chào một người bạn.'),
  (63, 'smile', 'Nụ cười không xóa hết nỗi buồn, nhưng có thể mở một khe sáng.'),
  (64, 'smile', 'Có những niềm vui bắt đầu từ một khóe môi vừa kịp cong lên.'),
  (65, 'smile', 'Mỉm cười là lời nhắc rằng trái tim mình vẫn còn ấm.'),
  (66, 'smile', 'Hãy giữ lại một nụ cười cho điều bất ngờ dễ thương của hôm nay.'),
  (67, 'smile', 'Nụ cười chân thành luôn tìm được đường đến một trái tim khác.'),
  (68, 'smile', 'Đôi khi lý do để cười chỉ là mình đã cố gắng đến tận lúc này.'),
  (69, 'smile', 'Cười với một chuyện nhỏ cũng là cách cho tâm hồn thêm khoảng thở.'),
  (70, 'smile', 'Một gương mặt dịu lại có thể khiến thế giới trước mắt dịu theo.'),
  (71, 'smile', 'Bạn xứng đáng với những khoảnh khắc khiến mình bật cười thật tự nhiên.'),
  (72, 'smile', 'Nụ cười hôm nay có thể là ký ức ấm áp của ngày mai.'),
  (73, 'smile', 'Hãy kể cho mình một câu chuyện vui và lắng nghe lòng nhẹ đi.'),
  (74, 'smile', 'Có thể hôm nay chưa hoàn hảo, nhưng nụ cười của bạn vẫn thật đẹp.'),
  (75, 'smile', 'Mỉm cười với điều đã qua là dấu hiệu mình đang học cách bình yên.'),
  (76, 'smile', 'Một tiếng cười bên người thân có thể chữa lành nhiều mỏi mệt.'),
  (77, 'smile', 'Khi chưa tìm thấy nắng, hãy thử thắp một nụ cười.'),
  (78, 'smile', 'Nụ cười là khoảng nghỉ ngắn giữa những suy nghĩ dài.'),
  (79, 'smile', 'Hãy để niềm vui được biểu lộ, dù nó chỉ nhỏ như một hạt nắng.'),
  (80, 'smile', 'Mỗi lần bạn cười thật lòng, ngày hôm nay lại sáng thêm một chút.'),
  (81, 'happiness', 'Hạnh phúc có thể là cảm giác đủ đầy trong một phút rất bình thường.'),
  (82, 'happiness', 'Đừng đợi mọi thứ hoàn hảo mới cho phép mình vui.'),
  (83, 'happiness', 'Biết đủ không làm ước mơ nhỏ lại, chỉ làm trái tim bình yên hơn.'),
  (84, 'happiness', 'Hạnh phúc lớn lên khi được sẻ chia bằng sự chân thành.'),
  (85, 'happiness', 'Một mái nhà ấm, một người lắng nghe, một giấc ngủ ngon đều là kho báu.'),
  (86, 'happiness', 'Bạn có thể tự tạo niềm vui bằng một việc nhỏ mình thật sự yêu thích.'),
  (87, 'happiness', 'Hạnh phúc không cần ồn ào để được nhận ra.'),
  (88, 'happiness', 'Cảm ơn một điều đang có là cách mời thêm bình yên vào lòng.'),
  (89, 'happiness', 'Niềm vui không phải phần thưởng cuối đường, nó là người bạn đồng hành.'),
  (90, 'happiness', 'Được là chính mình trong sự an toàn cũng là một dạng hạnh phúc.'),
  (91, 'happiness', 'Có những ngày hạnh phúc chỉ đơn giản là lòng mình không còn vội.'),
  (92, 'happiness', 'Tử tế với bản thân là nền đất để niềm vui nảy mầm.'),
  (93, 'happiness', 'Hạnh phúc thường đến trong hình dáng của điều ta từng xem là bình thường.'),
  (94, 'happiness', 'Một cuộc trò chuyện thật lòng có thể làm ngày hôm nay đáng nhớ.'),
  (95, 'happiness', 'Hãy dành chỗ trong lịch cho những điều khiến tâm hồn mình vui.'),
  (96, 'happiness', 'Niềm vui bền lâu bắt đầu từ việc sống đúng với điều mình trân trọng.'),
  (97, 'happiness', 'Khi biết ôm lấy cả ngày vui lẫn ngày buồn, ta sẽ thấy lòng tự do hơn.'),
  (98, 'happiness', 'Hạnh phúc không ở đâu xa khi mình còn nhận ra hơi ấm quanh mình.'),
  (99, 'happiness', 'Một lòng biết ơn là chiếc túi nhỏ luôn đựng vừa niềm vui.'),
  (100, 'happiness', 'Hôm nay, hãy chọn một điều khiến bạn thấy sống thật gần với trái tim mình.');

create function muse_private.daily_quote_for_date(p_date date)
returns table (
  rotation_order smallint,
  content text,
  topic text
)
language sql
stable
strict
security definer
set search_path = ''
as $$
  with ranked as (
    select
      q.rotation_order,
      q.content,
      q.topic,
      row_number() over (order by q.rotation_order) - 1 as quote_index,
      count(*) over ()::integer as quote_count
    from public.daily_quotes q
    where q.is_active
  )
  select r.rotation_order, r.content, r.topic
  from ranked r
  where r.quote_index = (
    mod(mod(p_date - date '2026-09-12', r.quote_count) + r.quote_count, r.quote_count)
  )::bigint;
$$;

revoke all on function muse_private.daily_quote_for_date(date)
  from public, anon, authenticated;

create function public.get_daily_quote()
returns table (
  rotation_order smallint,
  content text,
  topic text,
  quote_date date
)
language sql
stable
security definer
set search_path = ''
as $$
  select quote.rotation_order, quote.content, quote.topic, context.quote_date
  from (
    select (now() at time zone 'Asia/Ho_Chi_Minh')::date as quote_date
  ) context
  cross join lateral muse_private.daily_quote_for_date(context.quote_date) quote
  where auth.uid() is not null
    and muse_private.active_user();
$$;

revoke all on function public.get_daily_quote() from public, anon;
grant execute on function public.get_daily_quote() to authenticated;
