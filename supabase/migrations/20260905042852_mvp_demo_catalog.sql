-- Small demonstration route, not a complete geographic or content catalog.
INSERT INTO public.provinces(code,name,region,order_index,description) VALUES
 ('demo-ha-noi','Hà Nội','north',10,'Tuyến khám phá mẫu MVP'),
 ('demo-da-nang','Đà Nẵng','central',20,'Tuyến khám phá mẫu MVP'),
 ('demo-lam-dong','Lâm Đồng','central',30,'Tuyến khám phá mẫu MVP')
ON CONFLICT(code) DO NOTHING;
WITH data(province_code,n,landmark,food) AS (VALUES
 ('demo-ha-noi',1,'Hồ Hoàn Kiếm','Phở'),('demo-ha-noi',2,'Văn Miếu','Bún chả'),('demo-ha-noi',3,'Chùa Một Cột','Bánh cuốn'),('demo-ha-noi',4,'Cầu Long Biên','Cốm'),('demo-ha-noi',5,'Hồ Tây','Chả cá'),
 ('demo-da-nang',1,'Cầu Rồng','Mì Quảng'),('demo-da-nang',2,'Bán đảo Sơn Trà','Bánh tráng cuốn thịt heo'),('demo-da-nang',3,'Biển Mỹ Khê','Bún chả cá'),('demo-da-nang',4,'Ngũ Hành Sơn','Bánh xèo'),('demo-da-nang',5,'Đèo Hải Vân','Bánh bèo'),
 ('demo-lam-dong',1,'Hồ Xuân Hương','Bánh căn'),('demo-lam-dong',2,'Hồ Tuyền Lâm','Bánh tráng nướng'),('demo-lam-dong',3,'Ga Đà Lạt','Bánh mì xíu mại'),('demo-lam-dong',4,'Thác Datanla','Sữa đậu nành'),('demo-lam-dong',5,'Langbiang','Dâu tây')
), lm AS (
 INSERT INTO public.landmarks(province_id,code,name,order_index)
 SELECT p.id,d.province_code||'-landmark-'||d.n,d.landmark,d.n FROM data d JOIN public.provinces p ON p.code=d.province_code ON CONFLICT(code) DO NOTHING RETURNING id
)
INSERT INTO public.foods(province_id,code,name,order_index)
SELECT p.id,d.province_code||'-food-'||d.n,d.food,d.n FROM data d JOIN public.provinces p ON p.code=d.province_code ON CONFLICT(code) DO NOTHING;
INSERT INTO public.province_checkpoints(province_id,checkpoint_number,title,required_energy,order_index)
SELECT p.id,n,'Trạm '||n,10,n FROM public.provinces p CROSS JOIN generate_series(1,5) n
WHERE p.code IN ('demo-ha-noi','demo-da-nang','demo-lam-dong')
ON CONFLICT(province_id,checkpoint_number) DO NOTHING;
INSERT INTO public.province_items(province_id,code,name,item_type,description)
SELECT id,code||'-badge','Dấu ấn '||name,'badge','Huy hiệu mẫu khi hoàn thành tỉnh; artwork chưa được cung cấp.'
FROM public.provinces WHERE code IN ('demo-ha-noi','demo-da-nang','demo-lam-dong') ON CONFLICT(code) DO NOTHING;
INSERT INTO public.checkpoint_rewards(checkpoint_id,reward_type,landmark_id)
SELECT c.id,'landmark',l.id FROM public.province_checkpoints c JOIN public.provinces p ON p.id=c.province_id
JOIN public.landmarks l ON l.code=p.code||'-landmark-'||c.checkpoint_number
WHERE p.code LIKE 'demo-%' AND NOT EXISTS(SELECT 1 FROM public.checkpoint_rewards r WHERE r.checkpoint_id=c.id AND r.landmark_id=l.id);
INSERT INTO public.checkpoint_rewards(checkpoint_id,reward_type,food_id)
SELECT c.id,'food',f.id FROM public.province_checkpoints c JOIN public.provinces p ON p.id=c.province_id
JOIN public.foods f ON f.code=p.code||'-food-'||c.checkpoint_number
WHERE p.code LIKE 'demo-%' AND NOT EXISTS(SELECT 1 FROM public.checkpoint_rewards r WHERE r.checkpoint_id=c.id AND r.food_id=f.id);
INSERT INTO public.checkpoint_rewards(checkpoint_id,reward_type,province_item_id)
SELECT c.id,'province_item',i.id FROM public.province_checkpoints c JOIN public.provinces p ON p.id=c.province_id
JOIN public.province_items i ON i.code=p.code||'-badge' WHERE c.checkpoint_number=5 AND p.code LIKE 'demo-%'
AND NOT EXISTS(SELECT 1 FROM public.checkpoint_rewards r WHERE r.checkpoint_id=c.id AND r.province_item_id=i.id);
INSERT INTO public.mission_templates(code,title,description,mission_type,target_mood,default_energy_reward,estimated_minutes) VALUES
 ('demo-water','Uống một cốc nước','Dành một chút quan tâm cho cơ thể.','daily','all',5,1),
 ('demo-screen-break','Rời mắt khỏi màn hình','Nghỉ mắt một lát khi cậu thấy phù hợp.','daily','all',5,2),
 ('demo-stretch','Vươn vai nhẹ nhàng','Chọn chuyển động vừa sức với cậu.','daily','all',5,1),
 ('demo-journal','Viết vài dòng cho hôm nay','Không cần viết hay, chỉ cần là lời của cậu.','daily','all',5,3),
 ('demo-rest','Cho mình một khoảng nghỉ','Hôm nay cậu có thể đi chậm một chút.','daily','sad',5,3),
 ('demo-small-step','Chọn một việc thật nhỏ','Chỉ một bước nhỏ, nếu cậu muốn.','daily','awful',5,1),
 ('demo-thanks','Nói lời cảm ơn','Gửi một lời cảm ơn chân thành.','daily','good',5,2),
 ('demo-memory','Ghi lại một khoảnh khắc vui','Lưu lại điều cậu muốn nhớ.','daily','great',5,3),
 ('demo-listen','Nghe một bài nhạc yêu thích','Chọn âm nhạc khiến cậu thấy dễ chịu.','daily','okay',5,4),
 ('demo-weekly-reflection','Nhìn lại tuần qua','Ghi nhận một điều cậu đã cố gắng.','weekly','all',5,5)
ON CONFLICT(code) DO NOTHING;

