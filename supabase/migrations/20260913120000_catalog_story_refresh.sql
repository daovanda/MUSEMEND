-- Curated catalog story refresh.
-- The Vietnamese catalog remains the editorial source; the other locales use
-- natural, short story templates that preserve the same meaning and tone.
BEGIN;

-- Destination descriptions are introductions, not generic wellness copy.
UPDATE public.destination_translations dt
SET description = CASE dt.language_code
  WHEN 'vi' THEN d.description
  WHEN 'en' THEN 'A gentle introduction to ' || dt.name || ': slow down, notice the place, and let the journey unfold.'
  WHEN 'ja' THEN dt.name || 'をゆっくり歩き、景色を感じながら旅の物語を始める場所です。'
  WHEN 'fr' THEN 'Une douce introduction à ' || dt.name || ' : ralentir, regarder autour de soi et laisser le voyage commencer.'
  WHEN 'es' THEN 'Una introducción serena a ' || dt.name || ': baja el ritmo, observa el lugar y deja que comience el viaje.'
  WHEN 'it' THEN 'Un’introduzione gentile a ' || dt.name || ': rallenta, osserva il luogo e lascia iniziare il viaggio.'
  WHEN 'de' THEN 'Eine sanfte Einführung in ' || dt.name || ': werde langsamer, schau dich um und lass die Reise beginnen.'
  WHEN 'ko' THEN dt.name || '에서 잠시 속도를 늦추고 풍경을 바라보며 여행을 시작해 보세요.'
  WHEN 'pt' THEN 'Uma introdução tranquila a ' || dt.name || ': desacelere, observe o lugar e deixe a viagem começar.'
  WHEN 'ms' THEN 'Pengenalan lembut kepada ' || dt.name || ': perlahanlah, perhatikan tempat ini dan biarkan perjalanan bermula.'
  WHEN 'id' THEN 'Pengantar lembut untuk ' || dt.name || ': pelankan langkah, amati tempat ini, lalu biarkan perjalanan dimulai.'
  WHEN 'th' THEN 'ทำความรู้จัก ' || dt.name || ' อย่างอ่อนโยน ค่อย ๆ มองรอบตัวและปล่อยให้การเดินทางเริ่มขึ้น'
  ELSE d.description
END
FROM public.destinations d
WHERE d.id = dt.destination_id
  AND d.code LIKE 'content-%';

UPDATE public.destinations d
SET description = dt.description
FROM public.destination_translations dt
WHERE dt.destination_id = d.id
  AND dt.language_code = 'vi'
  AND d.code LIKE 'content-%';

-- Checkpoints read as one connected three-part story for every destination.
UPDATE public.destination_checkpoints cp
SET description = CASE cp.checkpoint_number
  WHEN 1 THEN 'Mở đầu câu chuyện bằng một bước chậm, để nơi này hiện ra qua hơi thở đầu tiên.'
  WHEN 2 THEN 'Từ bước đầu tiên, hãy dừng lại lâu hơn một chút và nhận ra điều đang nối mình với nơi này.'
  ELSE 'Khép lại chặng đường bằng một điều muốn mang theo, để câu chuyện tiếp tục trong ngày mai.'
END
FROM public.destinations d
WHERE d.id = cp.destination_id
  AND d.code LIKE 'content-%';

UPDATE public.checkpoint_translations ct
SET description = CASE ct.language_code
  WHEN 'vi' THEN cp.description
  WHEN 'en' THEN CASE cp.checkpoint_number
    WHEN 1 THEN 'Begin the story with one slow step, letting this place meet you through your first breath.'
    WHEN 2 THEN 'From that first step, pause a little longer and notice what connects you to this place.'
    ELSE 'Close this chapter with something to carry forward, so the story can continue tomorrow.'
  END
  WHEN 'ja' THEN CASE cp.checkpoint_number
    WHEN 1 THEN 'ゆっくり一歩を踏み出し、最初の呼吸とともにこの場所の物語を始めましょう。'
    WHEN 2 THEN '最初の一歩から少し長く立ち止まり、この場所と自分を結ぶものを感じましょう。'
    ELSE '明日へ持ち帰りたいものをそっと選び、物語を次へつなげましょう。'
  END
  WHEN 'fr' THEN CASE cp.checkpoint_number
    WHEN 1 THEN 'Commencez l’histoire par un pas lent, en laissant ce lieu vous rejoindre dès le premier souffle.'
    WHEN 2 THEN 'Après ce premier pas, arrêtez-vous un peu et remarquez ce qui vous relie à ce lieu.'
    ELSE 'Fermez ce chapitre avec quelque chose à emporter, pour que l’histoire continue demain.'
  END
  WHEN 'es' THEN CASE cp.checkpoint_number
    WHEN 1 THEN 'Empieza la historia con un paso lento y deja que este lugar te encuentre en la primera respiración.'
    WHEN 2 THEN 'Después de ese primer paso, detente un poco más y observa qué te une a este lugar.'
    ELSE 'Cierra este capítulo con algo que quieras llevar contigo, para que la historia continúe mañana.'
  END
  WHEN 'it' THEN CASE cp.checkpoint_number
    WHEN 1 THEN 'Inizia la storia con un passo lento e lascia che questo luogo ti raggiunga al primo respiro.'
    WHEN 2 THEN 'Dopo il primo passo, fermati un po’ e nota ciò che ti lega a questo luogo.'
    ELSE 'Chiudi questo capitolo con qualcosa da portare con te, così la storia potrà continuare domani.'
  END
  WHEN 'de' THEN CASE cp.checkpoint_number
    WHEN 1 THEN 'Beginne die Geschichte mit einem langsamen Schritt und lass diesen Ort dich beim ersten Atemzug erreichen.'
    WHEN 2 THEN 'Nach diesem ersten Schritt halte etwas länger inne und spüre, was dich mit diesem Ort verbindet.'
    ELSE 'Schließe dieses Kapitel mit etwas, das du mitnehmen möchtest, damit die Geschichte morgen weitergeht.'
  END
  WHEN 'ko' THEN CASE cp.checkpoint_number
    WHEN 1 THEN '천천히 한 걸음 내디디며 첫 호흡과 함께 이곳의 이야기를 시작해 보세요.'
    WHEN 2 THEN '첫걸음 뒤에 잠시 더 머물며 나와 이곳을 이어 주는 것을 느껴 보세요.'
    ELSE '내일로 가져갈 한 가지를 고르며 다음 이야기로 이어 가세요.'
  END
  WHEN 'pt' THEN CASE cp.checkpoint_number
    WHEN 1 THEN 'Comece a história com um passo lento e deixe este lugar chegar até você no primeiro suspiro.'
    WHEN 2 THEN 'Depois do primeiro passo, pare um pouco mais e perceba o que liga você a este lugar.'
    ELSE 'Feche este capítulo com algo para levar consigo, para que a história continue amanhã.'
  END
  WHEN 'ms' THEN CASE cp.checkpoint_number
    WHEN 1 THEN 'Mulakan cerita dengan satu langkah perlahan dan biarkan tempat ini menyapa melalui nafas pertama.'
    WHEN 2 THEN 'Selepas langkah pertama, berhenti seketika dan perhatikan perkara yang menghubungkan anda dengan tempat ini.'
    ELSE 'Tutup bab ini dengan sesuatu untuk dibawa, supaya cerita dapat bersambung esok.'
  END
  WHEN 'id' THEN CASE cp.checkpoint_number
    WHEN 1 THEN 'Mulailah cerita dengan satu langkah pelan, biarkan tempat ini menyapa lewat tarikan napas pertama.'
    WHEN 2 THEN 'Setelah langkah pertama, berhentilah sejenak dan perhatikan hal yang menghubungkanmu dengan tempat ini.'
    ELSE 'Tutup bab ini dengan sesuatu untuk dibawa, agar ceritanya berlanjut esok.'
  END
  WHEN 'th' THEN CASE cp.checkpoint_number
    WHEN 1 THEN 'เริ่มเรื่องราวด้วยก้าวช้า ๆ และให้สถานที่แห่งนี้ทักทายคุณผ่านลมหายใจแรก'
    WHEN 2 THEN 'จากก้าวแรก ลองหยุดนานขึ้นอีกนิดและสัมผัสสิ่งที่เชื่อมโยงคุณกับที่แห่งนี้'
    ELSE 'ปิดบทนี้ด้วยสิ่งหนึ่งที่อยากพกไป เพื่อให้เรื่องราวดำเนินต่อในวันพรุ่งนี้'
  END
  ELSE cp.description
END
FROM public.destination_checkpoints cp
JOIN public.destinations d ON d.id = cp.destination_id
WHERE ct.checkpoint_id = cp.id
  AND d.code LIKE 'content-%';

-- Landmark, food and item descriptions are short collectible stories rather
-- than repeated placeholder sentences.
UPDATE public.landmark_translations lt
SET description = CASE lt.language_code
  WHEN 'vi' THEN lt.name || ' là một dấu mốc để bạn dừng lại, nhìn kỹ và lưu giữ một lát cắt của hành trình.'
  WHEN 'en' THEN lt.name || ' is a quiet landmark where you can pause, look closely, and keep one moment of the journey.'
  WHEN 'ja' THEN lt.name || 'は、足を止めて景色を見つめ、旅の一場面を心に残すための場所です。'
  WHEN 'fr' THEN lt.name || ' est un repère paisible où s’arrêter, regarder et garder un instant du voyage.'
  WHEN 'es' THEN lt.name || ' es un lugar sereno para detenerte, mirar con atención y guardar un instante del viaje.'
  WHEN 'it' THEN lt.name || ' è un punto tranquillo dove fermarsi, osservare e custodire un istante del viaggio.'
  WHEN 'de' THEN lt.name || ' ist ein stiller Ort zum Anhalten, genauen Hinsehen und Bewahren eines Reisemoments.'
  WHEN 'ko' THEN lt.name || '은(는) 잠시 멈춰 바라보며 여행의 한 장면을 간직하는 장소입니다.'
  WHEN 'pt' THEN lt.name || ' é um marco tranquilo para parar, observar e guardar um instante da viagem.'
  WHEN 'ms' THEN lt.name || ' ialah mercu tenang untuk berhenti, memerhati dan menyimpan satu detik perjalanan.'
  WHEN 'id' THEN lt.name || ' adalah penanda yang tenang untuk berhenti, mengamati, dan menyimpan satu momen perjalanan.'
  WHEN 'th' THEN lt.name || ' คือจุดพักเงียบ ๆ ให้คุณหยุดมองและเก็บช่วงหนึ่งของการเดินทางไว้ในใจ'
  ELSE lt.description
END,
story_content = CASE lt.language_code
  WHEN 'vi' THEN 'Bạn đã đến đây sau những bước nhỏ. Hãy để dấu mốc này kể tiếp câu chuyện về sự hiện diện của bạn.'
  WHEN 'en' THEN 'You arrived here through small steps. Let this landmark continue the story of your presence.'
  WHEN 'ja' THEN '小さな歩みを重ねて、ここへ来ました。この場所から、あなたがここにいる物語を続けましょう。'
  WHEN 'fr' THEN 'Vous êtes arrivé ici par de petits pas. Laissez ce repère poursuivre l’histoire de votre présence.'
  WHEN 'es' THEN 'Llegaste hasta aquí con pequeños pasos. Deja que este lugar continúe la historia de tu presencia.'
  WHEN 'it' THEN 'Sei arrivato qui con piccoli passi. Lascia che questo luogo continui la storia della tua presenza.'
  WHEN 'de' THEN 'Du bist mit kleinen Schritten hierher gekommen. Lass diesen Ort die Geschichte deiner Gegenwart weitererzählen.'
  WHEN 'ko' THEN '작은 걸음들이 당신을 여기까지 데려왔습니다. 이곳에서 지금 이 순간의 이야기를 이어 가 보세요.'
  WHEN 'pt' THEN 'Você chegou aqui em pequenos passos. Deixe este lugar continuar a história da sua presença.'
  WHEN 'ms' THEN 'Anda tiba di sini melalui langkah-langkah kecil. Biarkan tempat ini menyambung kisah kehadiran anda.'
  WHEN 'id' THEN 'Kamu tiba di sini lewat langkah-langkah kecil. Biarkan tempat ini melanjutkan kisah kehadiranmu.'
  WHEN 'th' THEN 'คุณมาถึงที่นี่ด้วยก้าวเล็ก ๆ ให้สถานที่แห่งนี้เล่าเรื่องการได้อยู่ตรงนี้ของคุณต่อไป'
  ELSE lt.story_content
END
FROM public.landmarks l
WHERE lt.landmark_id = l.id
  AND l.code LIKE 'content-%';

UPDATE public.food_translations ft
SET description = CASE ft.language_code
  WHEN 'vi' THEN ft.name || ' mang theo hương vị của nơi này, để một khoảnh khắc thưởng thức trở thành phần tiếp theo của chuyến đi.'
  WHEN 'en' THEN ft.name || ' carries the flavour of this place, turning a small taste into the next chapter of the journey.'
  WHEN 'ja' THEN ft.name || 'にはこの土地の味わいがあり、ひと口の時間が旅の次の章になります。'
  WHEN 'fr' THEN ft.name || ' porte les saveurs du lieu, transformant une petite dégustation en nouveau chapitre du voyage.'
  WHEN 'es' THEN ft.name || ' guarda el sabor de este lugar y convierte un pequeño bocado en el siguiente capítulo del viaje.'
  WHEN 'it' THEN ft.name || ' racchiude il sapore del luogo e trasforma un assaggio nel capitolo successivo del viaggio.'
  WHEN 'de' THEN ft.name || ' trägt den Geschmack dieses Ortes und macht einen kleinen Bissen zum nächsten Kapitel der Reise.'
  WHEN 'ko' THEN ft.name || '에는 이곳의 맛이 담겨 있어 작은 한입이 여행의 다음 장면이 됩니다.'
  WHEN 'pt' THEN ft.name || ' carrega o sabor deste lugar, transformando uma pequena prova no próximo capítulo da viagem.'
  WHEN 'ms' THEN ft.name || ' membawa rasa tempat ini, menjadikan satu suapan kecil sebagai bab seterusnya perjalanan.'
  WHEN 'id' THEN ft.name || ' membawa cita rasa tempat ini, menjadikan satu suapan kecil sebagai bab berikutnya dalam perjalanan.'
  WHEN 'th' THEN ft.name || ' ถ่ายทอดรสชาติของสถานที่แห่งนี้ ให้การลิ้มรสเล็ก ๆ กลายเป็นบทถัดไปของการเดินทาง'
  ELSE ft.description
END,
story_content = CASE ft.language_code
  WHEN 'vi' THEN 'Hãy nếm thật chậm. Đôi khi một hương vị cũng đủ mở lại ký ức về nơi mình vừa đi qua.'
  WHEN 'en' THEN 'Taste it slowly. Sometimes one flavour is enough to reopen a memory of where you have been.'
  WHEN 'ja' THEN 'ゆっくり味わいましょう。ひとつの味が、歩いてきた場所の記憶をそっと開くことがあります。'
  WHEN 'fr' THEN 'Goûtez lentement. Une seule saveur suffit parfois à rouvrir le souvenir d’un lieu traversé.'
  WHEN 'es' THEN 'Saboréalo despacio. A veces un solo gusto basta para despertar el recuerdo de un lugar recorrido.'
  WHEN 'it' THEN 'Assaporalo lentamente. A volte un solo sapore basta a riaprire il ricordo di un luogo attraversato.'
  WHEN 'de' THEN 'Koste langsam. Manchmal genügt ein Geschmack, um die Erinnerung an einen besuchten Ort zu öffnen.'
  WHEN 'ko' THEN '천천히 맛보세요. 때로는 한 가지 맛만으로도 지나온 장소의 기억이 다시 열립니다.'
  WHEN 'pt' THEN 'Saboreie devagar. Às vezes, um único sabor basta para reabrir a memória de um lugar vivido.'
  WHEN 'ms' THEN 'Nikmatilah perlahan. Kadangkala satu rasa sahaja cukup untuk membuka semula kenangan tempat yang dilalui.'
  WHEN 'id' THEN 'Nikmati perlahan. Kadang satu rasa saja cukup untuk membuka kembali kenangan dari tempat yang pernah dilewati.'
  WHEN 'th' THEN 'ค่อย ๆ ลิ้มรส บางครั้งรสชาติเดียวก็พอจะเปิดความทรงจำของสถานที่ที่เราเพิ่งผ่านไป'
  ELSE ft.story_content
END
FROM public.foods f
WHERE ft.food_id = f.id
  AND f.code LIKE 'content-%';

UPDATE public.destination_item_translations it
SET description = CASE it.language_code
  WHEN 'vi' THEN 'Một vật phẩm nhỏ tiếp nối câu chuyện của ' || d.name || ', để bạn mang theo cảm giác đã có mặt ở nơi này.'
  WHEN 'en' THEN 'A small keepsake from ' || d.name || ', carrying forward the feeling of having been present here.'
  WHEN 'ja' THEN d.name || 'で過ごした時間を持ち帰り、ここにいた感覚をつなぐ小さなお守りです。'
  WHEN 'fr' THEN 'Un petit souvenir de ' || d.name || ', pour emporter le sentiment d’avoir été présent ici.'
  WHEN 'es' THEN 'Un pequeño recuerdo de ' || d.name || ' para llevar contigo la sensación de haber estado aquí.'
  WHEN 'it' THEN 'Un piccolo ricordo di ' || d.name || ' per portare con te la sensazione di esserci stato.'
  WHEN 'de' THEN 'Ein kleines Andenken aus ' || d.name || ', das dich an dein Hiersein erinnert.'
  WHEN 'ko' THEN d.name || '에 머문 감각을 간직해 주는 작은 기념품입니다.'
  WHEN 'pt' THEN 'Uma pequena lembrança de ' || d.name || ', para levar a sensação de ter estado aqui.'
  WHEN 'ms' THEN 'Cenderamata kecil dari ' || d.name || ' untuk membawa rasa bahawa anda pernah hadir di sini.'
  WHEN 'id' THEN 'Cendera mata kecil dari ' || d.name || ' untuk membawa rasa pernah hadir di tempat ini.'
  WHEN 'th' THEN 'ของที่ระลึกเล็ก ๆ จาก ' || d.name || ' เพื่อพกความรู้สึกว่าเราเคยอยู่ที่นี่ไปด้วย'
  ELSE it.description
END
FROM public.destination_items i
JOIN public.destinations d ON d.id = i.destination_id
WHERE it.destination_item_id = i.id
  AND i.code LIKE 'content-%';

COMMIT;
NOTIFY pgrst, 'reload schema';
