-- Curated MuseMend travel content pack. Catalog rows are server-owned and the
-- migration is replay-safe for local reset/staging rebuilds.

ALTER TABLE public.province_checkpoints
  ADD COLUMN IF NOT EXISTS asset_path text;

ALTER TABLE public.provinces
  ADD COLUMN IF NOT EXISTS country_code text,
  ADD COLUMN IF NOT EXISTS destination_type text NOT NULL DEFAULT 'province';

-- Existing progress points to immutable IDs, so changing catalog order does not
-- move a user who is already travelling. New users see curated routes first.
UPDATE public.provinces
SET order_index = CASE code
  WHEN 'demo-ha-noi' THEN 1010
  WHEN 'demo-da-nang' THEN 1020
  WHEN 'demo-lam-dong' THEN 1030
END
WHERE code IN ('demo-ha-noi', 'demo-da-nang', 'demo-lam-dong');

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'provinces_country_code_check'
      AND conrelid = 'public.provinces'::regclass
  ) THEN
    ALTER TABLE public.provinces
      ADD CONSTRAINT provinces_country_code_check
      CHECK (country_code IS NULL OR country_code ~ '^[A-Z]{2}$');
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'provinces_destination_type_check'
      AND conrelid = 'public.provinces'::regclass
  ) THEN
    ALTER TABLE public.provinces
      ADD CONSTRAINT provinces_destination_type_check
      CHECK (destination_type IN ('province', 'city', 'island', 'heritage', 'region'));
  END IF;
END
$$;

WITH destinations(code, name, description, region, order_index, country_code, destination_type) AS (
  VALUES
    ('curated-hoi-an', 'Hội An', 'Đi chậm giữa phố cổ, đèn lồng và những mái ngói nhuốm màu thời gian.', 'central'::public.region_type, 10, 'VN', 'city'),
    ('curated-ninh-binh', 'Ninh Bình', 'Thở cùng núi đá vôi, dòng sông trong và nhịp chèo yên ả.', 'north'::public.region_type, 20, 'VN', 'province'),
    ('curated-hue', 'Huế', 'Một hành trình dịu dàng qua thành quách, sông Hương và ký ức cố đô.', 'central'::public.region_type, 30, 'VN', 'city'),
    ('curated-phu-quoc', 'Phú Quốc', 'Tìm khoảng lặng bên biển xanh, cát sáng và những chiều hoàng hôn.', 'south'::public.region_type, 40, 'VN', 'island'),
    ('curated-ha-giang', 'Hà Giang', 'Băng qua cao nguyên đá để gặp những cung đường rộng mở.', 'north'::public.region_type, 50, 'VN', 'province'),
    ('curated-paris', 'Paris', 'Dạo bên sông Seine và ngắm thành phố lên đèn trong một nhịp thật chậm.', NULL, 60, 'FR', 'city'),
    ('curated-kyoto', 'Kyoto', 'Bước qua những cổng torii và khu vườn tĩnh để trở về với hơi thở.', NULL, 70, 'JP', 'city'),
    ('curated-santorini', 'Santorini', 'Đón nắng trên triền đảo trắng xanh nhìn ra biển Aegean.', NULL, 80, 'GR', 'island'),
    ('curated-petra', 'Petra', 'Đi qua hẻm núi sa thạch để gặp thành phố cổ ẩn trong đá.', NULL, 90, 'JO', 'heritage'),
    ('curated-machu-picchu', 'Machu Picchu', 'Chạm mây trên dãy Andes và lắng nghe dấu tích của một nền văn minh cổ.', NULL, 100, 'PE', 'heritage')
)
INSERT INTO public.provinces(
  code, name, description, region, order_index, country_code, destination_type
)
SELECT code, name, description, region, order_index, country_code, destination_type
FROM destinations
ON CONFLICT (code) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  region = EXCLUDED.region,
  order_index = EXCLUDED.order_index,
  country_code = EXCLUDED.country_code,
  destination_type = EXCLUDED.destination_type,
  is_active = true;

WITH catalog(
  province_code, checkpoint_title, checkpoint_description, required_energy, asset_path,
  landmark_code, landmark_name, landmark_description, latitude, longitude,
  food_code, food_name, food_description,
  item_code, item_name, item_description, item_type, rarity
) AS (
  VALUES
    ('curated-hoi-an', 'Ánh đèn phố Hội', 'Dừng lại bên dòng Hoài và gom một khoảnh khắc ấm áp.', 10, 'assets/illustrations/journey/checkpoints/hoi-an.png', 'curated-hoi-an-old-town', 'Phố cổ Hội An', 'Không gian phố cổ bên sông với những dãy nhà vàng và đèn lồng.', 15.8801::numeric, 108.3380::numeric, 'curated-hoi-an-cao-lau', 'Cao lầu', 'Món mì đặc trưng với rau thơm, thịt xá xíu và sợi mì dai.', 'curated-hoi-an-lantern', 'Ghim đèn lồng', 'Một chiếc ghim nhỏ nhắc về ánh sáng ấm áp trong phố cổ.', 'badge'::public.province_item_type, 'uncommon'::public.rarity_type),
    ('curated-ninh-binh', 'Nhịp chèo Tràng An', 'Theo dòng nước len qua núi đá và để tâm trí được thảnh thơi.', 15, 'assets/illustrations/journey/checkpoints/ninh-binh.png', 'curated-ninh-binh-trang-an', 'Tràng An', 'Quần thể sông, hang động và núi đá vôi xanh thẳm.', 20.2527::numeric, 105.9179::numeric, 'curated-ninh-binh-com-chay', 'Cơm cháy', 'Miếng cơm vàng giòn thường dùng cùng sốt đậm vị.', 'curated-ninh-binh-limestone', 'Huy hiệu núi đá', 'Dấu ấn của sự vững chãi và bình yên.', 'badge'::public.province_item_type, 'uncommon'::public.rarity_type),
    ('curated-hue', 'Sớm mai cố đô', 'Đi qua cổng thành trong ánh sáng dịu và nghe nhịp thời gian chậm lại.', 20, 'assets/illustrations/journey/checkpoints/hue.png', 'curated-hue-imperial-city', 'Đại Nội Huế', 'Quần thể cung điện và thành quách của cố đô bên sông Hương.', 16.4637::numeric, 107.5909::numeric, 'curated-hue-com-hen', 'Cơm hến', 'Món cơm dân dã kết hợp hến, rau thơm và vị cay đặc trưng.', 'curated-hue-fan', 'Quạt sắc tím', 'Chiếc quạt nhỏ mang sắc tím trầm của Huế.', 'cloud_accessory'::public.province_item_type, 'rare'::public.rarity_type),
    ('curated-phu-quoc', 'Hoàng hôn biển ngọc', 'Ngồi bên bờ cát và nhìn một ngày khép lại thật nhẹ.', 25, 'assets/illustrations/journey/checkpoints/phu-quoc.png', 'curated-phu-quoc-sunset', 'Bãi Trường', 'Bờ biển dài nổi tiếng với những buổi hoàng hôn rực ấm.', 10.1760::numeric, 103.9660::numeric, 'curated-phu-quoc-bun-quay', 'Bún quậy', 'Bát bún tươi với hải sản và nước chấm tự pha.', 'curated-phu-quoc-shell', 'Vỏ sò bình yên', 'Món quà nhỏ lưu lại âm thanh của biển.', 'souvenir'::public.province_item_type, 'rare'::public.rarity_type),
    ('curated-ha-giang', 'Con đường trên mây', 'Qua một khúc đèo cao để nhìn thấy khoảng trời rộng hơn.', 30, 'assets/illustrations/journey/checkpoints/ha-giang.png', 'curated-ha-giang-ma-pi-leng', 'Đèo Mã Pí Lèng', 'Cung đèo cao giữa núi đá và dòng Nho Quế xanh sâu.', 23.2384::numeric, 105.4142::numeric, 'curated-ha-giang-thang-den', 'Thắng dền', 'Những viên bột nếp ấm trong nước đường gừng.', 'curated-ha-giang-scarf', 'Khăn sắc cao nguyên', 'Dải màu nhỏ gợi nhớ những phiên chợ vùng cao.', 'cloud_accessory'::public.province_item_type, 'epic'::public.rarity_type),
    ('curated-paris', 'Paris lên đèn', 'Đi dọc sông Seine khi tháp Eiffel vừa bừng sáng.', 35, 'assets/illustrations/journey/checkpoints/paris.png', 'curated-paris-eiffel', 'Tháp Eiffel', 'Biểu tượng bằng sắt bên sông Seine nhìn ra Paris.', 48.8584::numeric, 2.2945::numeric, 'curated-paris-croissant', 'Croissant', 'Chiếc bánh ngàn lớp thơm bơ với lớp vỏ giòn nhẹ.', 'curated-paris-beret', 'Mũ beret mây', 'Phụ kiện nhỏ cho một chuyến dạo phố đầy cảm hứng.', 'cloud_accessory'::public.province_item_type, 'rare'::public.rarity_type),
    ('curated-kyoto', 'Lối cổng ngàn đỏ', 'Bước chậm qua triền núi và để mỗi cánh cổng đánh dấu một hơi thở.', 40, 'assets/illustrations/journey/checkpoints/kyoto.png', 'curated-kyoto-fushimi-inari', 'Fushimi Inari', 'Ngôi đền nổi bật với những lối đi phủ kín cổng torii đỏ.', 34.9671::numeric, 135.7727::numeric, 'curated-kyoto-yatsuhashi', 'Yatsuhashi', 'Bánh gạo mềm thơm quế, thường có nhân đậu ngọt.', 'curated-kyoto-maple', 'Lá phong Kyoto', 'Một chiếc lá lưu giữ sắc mùa yên tĩnh.', 'sticker'::public.province_item_type, 'rare'::public.rarity_type),
    ('curated-santorini', 'Ban mai Aegean', 'Đón ánh sáng tràn qua những mái vòm xanh và tường trắng.', 45, 'assets/illustrations/journey/checkpoints/santorini.png', 'curated-santorini-oia', 'Làng Oia', 'Ngôi làng trên vách đá với kiến trúc trắng và mái vòm xanh.', 36.4618::numeric, 25.3753::numeric, 'curated-santorini-tomatokeftedes', 'Tomatokeftedes', 'Bánh cà chua chiên thơm thảo mộc của đảo Santorini.', 'curated-santorini-shell-frame', 'Khung biển Aegean', 'Khung ảnh xanh trắng gợi một ô cửa nhìn ra biển.', 'frame'::public.province_item_type, 'epic'::public.rarity_type),
    ('curated-petra', 'Kho báu trong đá', 'Ra khỏi khe núi hẹp và đón ánh nắng trên mặt đá hồng.', 50, 'assets/illustrations/journey/checkpoints/petra.png', 'curated-petra-treasury', 'Al-Khazneh', 'Mặt tiền cổ được tạc trực tiếp vào vách đá sa thạch ở Petra.', 30.3225::numeric, 35.4517::numeric, 'curated-petra-mansaf', 'Mansaf', 'Món cơm với thịt và sốt sữa chua khô truyền thống Jordan.', 'curated-petra-sandstone', 'Bùa đá hồng', 'Một kỷ vật màu sa thạch tượng trưng cho sức bền.', 'souvenir'::public.province_item_type, 'epic'::public.rarity_type),
    ('curated-machu-picchu', 'Thành phố giữa mây', 'Đứng giữa ruộng bậc thang và ngắm mây trôi qua những đỉnh Andes.', 55, 'assets/illustrations/journey/checkpoints/machu-picchu.png', 'curated-machu-picchu-citadel', 'Thành cổ Machu Picchu', 'Di tích Inca trên sườn núi cao giữa dãy Andes.', -13.1631::numeric, -72.5450::numeric, 'curated-machu-picchu-quinoa', 'Súp quinoa', 'Món súp ấm với hạt quinoa và rau củ vùng Andes.', 'curated-machu-picchu-sun', 'Huy hiệu mặt trời Andes', 'Dấu ấn vàng cho một chặng đường trên mây.', 'badge'::public.province_item_type, 'legendary'::public.rarity_type)
), checkpoint_rows AS (
  INSERT INTO public.province_checkpoints(
    province_id, checkpoint_number, title, description, required_energy, order_index, asset_path
  )
  SELECT p.id, 1, c.checkpoint_title, c.checkpoint_description,
    c.required_energy, 1, c.asset_path
  FROM catalog c
  JOIN public.provinces p ON p.code = c.province_code
  ON CONFLICT (province_id, checkpoint_number) DO UPDATE SET
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    required_energy = EXCLUDED.required_energy,
    order_index = EXCLUDED.order_index,
    asset_path = EXCLUDED.asset_path,
    is_active = true
  RETURNING id
), landmark_rows AS (
  INSERT INTO public.landmarks(
    province_id, code, name, description, asset_path, latitude, longitude, order_index, rarity
  )
  SELECT p.id, c.landmark_code, c.landmark_name, c.landmark_description,
    c.asset_path, c.latitude, c.longitude, 1, c.rarity
  FROM catalog c
  JOIN public.provinces p ON p.code = c.province_code
  ON CONFLICT (code) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    asset_path = EXCLUDED.asset_path,
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude,
    rarity = EXCLUDED.rarity,
    is_active = true
  RETURNING id
), food_rows AS (
  INSERT INTO public.foods(
    province_id, code, name, description, order_index, rarity
  )
  SELECT p.id, c.food_code, c.food_name, c.food_description, 1, c.rarity
  FROM catalog c
  JOIN public.provinces p ON p.code = c.province_code
  ON CONFLICT (code) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    rarity = EXCLUDED.rarity,
    is_active = true
  RETURNING id
)
INSERT INTO public.province_items(
  province_id, code, name, item_type, description, order_index, rarity
)
SELECT p.id, c.item_code, c.item_name, c.item_type, c.item_description, 1, c.rarity
FROM catalog c
JOIN public.provinces p ON p.code = c.province_code
ON CONFLICT (code) DO UPDATE SET
  name = EXCLUDED.name,
  item_type = EXCLUDED.item_type,
  description = EXCLUDED.description,
  rarity = EXCLUDED.rarity,
  is_active = true;

WITH catalog(province_code, landmark_code, food_code, item_code) AS (
  VALUES
    ('curated-hoi-an', 'curated-hoi-an-old-town', 'curated-hoi-an-cao-lau', 'curated-hoi-an-lantern'),
    ('curated-ninh-binh', 'curated-ninh-binh-trang-an', 'curated-ninh-binh-com-chay', 'curated-ninh-binh-limestone'),
    ('curated-hue', 'curated-hue-imperial-city', 'curated-hue-com-hen', 'curated-hue-fan'),
    ('curated-phu-quoc', 'curated-phu-quoc-sunset', 'curated-phu-quoc-bun-quay', 'curated-phu-quoc-shell'),
    ('curated-ha-giang', 'curated-ha-giang-ma-pi-leng', 'curated-ha-giang-thang-den', 'curated-ha-giang-scarf'),
    ('curated-paris', 'curated-paris-eiffel', 'curated-paris-croissant', 'curated-paris-beret'),
    ('curated-kyoto', 'curated-kyoto-fushimi-inari', 'curated-kyoto-yatsuhashi', 'curated-kyoto-maple'),
    ('curated-santorini', 'curated-santorini-oia', 'curated-santorini-tomatokeftedes', 'curated-santorini-shell-frame'),
    ('curated-petra', 'curated-petra-treasury', 'curated-petra-mansaf', 'curated-petra-sandstone'),
    ('curated-machu-picchu', 'curated-machu-picchu-citadel', 'curated-machu-picchu-quinoa', 'curated-machu-picchu-sun')
), rewards AS (
  SELECT cp.id AS checkpoint_id, l.id AS landmark_id, f.id AS food_id, i.id AS item_id
  FROM catalog c
  JOIN public.provinces p ON p.code = c.province_code
  JOIN public.province_checkpoints cp ON cp.province_id = p.id AND cp.checkpoint_number = 1
  JOIN public.landmarks l ON l.code = c.landmark_code
  JOIN public.foods f ON f.code = c.food_code
  JOIN public.province_items i ON i.code = c.item_code
)
INSERT INTO public.checkpoint_rewards(
  checkpoint_id, reward_type, landmark_id, food_id, province_item_id, order_index
)
SELECT rewards.checkpoint_id, reward.reward_type, reward.landmark_id,
  reward.food_id, reward.item_id, reward.order_index
FROM rewards
CROSS JOIN LATERAL (
  VALUES
    ('landmark'::public.checkpoint_reward_type, landmark_id, NULL::bigint, NULL::bigint, 1),
    ('food'::public.checkpoint_reward_type, NULL::bigint, food_id, NULL::bigint, 2),
    ('province_item'::public.checkpoint_reward_type, NULL::bigint, NULL::bigint, item_id, 3)
) AS reward(reward_type, landmark_id, food_id, item_id, order_index)
WHERE NOT EXISTS (
  SELECT 1 FROM public.checkpoint_rewards existing
  WHERE existing.checkpoint_id = rewards.checkpoint_id
    AND existing.reward_type = reward.reward_type
    AND existing.landmark_id IS NOT DISTINCT FROM reward.landmark_id
    AND existing.food_id IS NOT DISTINCT FROM reward.food_id
    AND existing.province_item_id IS NOT DISTINCT FROM reward.item_id
);

INSERT INTO public.mission_templates(
  code, title, description, mission_type, target_mood,
  default_energy_reward, difficulty, estimated_minutes
)
VALUES
  ('curated-breathe', 'Thở chậm một phút', 'Hít vào nhẹ nhàng, thở ra dài hơn và chú ý cơ thể.', 'daily', 'all', 5, 'easy', 1),
  ('curated-sunlight', 'Đón ánh sáng tự nhiên', 'Đứng bên cửa sổ hoặc ra ngoài vài phút nếu thuận tiện.', 'daily', 'sad', 5, 'easy', 3),
  ('curated-tidy-corner', 'Dọn một góc thật nhỏ', 'Chỉ chọn một bề mặt nhỏ để tạo cảm giác nhẹ nhõm.', 'daily', 'okay', 5, 'easy', 5),
  ('curated-kind-message', 'Gửi một lời tử tế', 'Nhắn một câu chân thành cho người bạn đang nghĩ tới.', 'daily', 'good', 5, 'easy', 3),
  ('curated-notice-five', 'Nhìn thấy năm điều quanh mình', 'Gọi tên năm điều bạn thấy để trở về hiện tại.', 'daily', 'awful', 5, 'easy', 2),
  ('curated-tea-pause', 'Uống một thức uống ấm', 'Cho mình vài phút không vội vàng cùng một thức uống dễ chịu.', 'daily', 'all', 5, 'easy', 5),
  ('curated-gratitude-three', 'Ghi ba điều biết ơn', 'Ba điều nhỏ cũng đủ để khép ngày bằng sự dịu dàng.', 'daily', 'great', 5, 'easy', 5),
  ('curated-nature-sound', 'Lắng nghe âm thanh tự nhiên', 'Mở cửa sổ hoặc ra ngoài và lắng nghe trong vài phút.', 'daily', 'all', 5, 'easy', 4),
  ('curated-weekly-reset', 'Chuẩn bị một tuần nhẹ hơn', 'Chọn một điều giữ lại và một điều có thể buông xuống.', 'weekly', 'all', 10, 'medium', 10),
  ('curated-monthly-letter', 'Viết thư cho mình của tháng sau', 'Gửi một lời nhắc tử tế tới chính bạn trong tương lai gần.', 'monthly', 'all', 15, 'medium', 15)
ON CONFLICT (code) DO UPDATE SET
  title = EXCLUDED.title,
  description = EXCLUDED.description,
  mission_type = EXCLUDED.mission_type,
  target_mood = EXCLUDED.target_mood,
  default_energy_reward = EXCLUDED.default_energy_reward,
  difficulty = EXCLUDED.difficulty,
  estimated_minutes = EXCLUDED.estimated_minutes,
  is_system = true,
  is_active = true;

NOTIFY pgrst, 'reload schema';
