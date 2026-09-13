"""Generate the deterministic MuseMend multilingual content pack.

The generated SQL is committed as a normal migration so Supabase deploys it
through CI.  The small SVGs are project-native vector illustrations used when
the image-generation connector is unavailable; they keep every catalog row
usable offline and can be replaced by final art later without changing IDs.
"""

from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MIGRATION = ROOT / "supabase/migrations/20260913100000_content_pack_v1.sql"
ASSET_DIR = ROOT / "app/assets/illustrations/journey/content-pack/v1"
QUOTE_SOURCE = ROOT / "supabase/migrations/20260912090000_daily_quotes.sql"

LANGUAGES = ["vi", "en", "ja", "fr", "es", "it", "de", "ko", "pt", "ms", "id", "th"]

DESTINATIONS = [
    ("kyoto", "Kyoto", "JP", "city", "Bước chậm qua những khu vườn tĩnh và những cánh cổng đỏ.", None),
    ("paris", "Paris", "FR", "city", "Dạo bên sông Seine và để thành phố lên đèn thật dịu dàng.", None),
    ("rome", "Rome", "IT", "city", "Chạm vào những lớp lịch sử và thưởng thức một ngày thật thong thả.", None),
    ("santorini", "Santorini", "GR", "island", "Đón nắng trên những mái vòm xanh nhìn ra biển Aegean.", None),
    ("petra", "Petra", "JO", "heritage", "Đi qua hẻm núi sa thạch để gặp thành phố cổ trong đá.", None),
    ("machu-picchu", "Machu Picchu", "PE", "heritage", "Chạm mây trên dãy Andes và lắng nghe dấu tích cổ xưa.", None),
    ("bali", "Bali", "ID", "island", "Tìm sự cân bằng giữa ruộng bậc thang, biển xanh và hơi thở.", None),
    ("seoul", "Seoul", "KR", "city", "Một thành phố vừa rộn ràng vừa có những góc nhỏ để nghỉ chân.", None),
    ("bangkok", "Bangkok", "TH", "city", "Để hương vị, ánh đèn và nụ cười dẫn mình qua một ngày mới.", None),
    ("singapore", "Singapore", "SG", "city", "Đi giữa khu vườn xanh và nhịp sống gọn gàng bên vịnh.", None),
    ("istanbul", "Istanbul", "TR", "city", "Nơi hai lục địa gặp nhau trong tiếng gọi của mặt nước.", None),
    ("new-york", "New York", "US", "city", "Tìm một khoảng lặng giữa những con phố luôn chuyển động.", None),
    ("vancouver", "Vancouver", "CA", "city", "Để núi, biển và rừng nhắc mình thở rộng hơn.", None),
    ("sydney", "Sydney", "AU", "city", "Một buổi chiều bên bến cảng, đủ để lòng mình sáng lên.", None),
    ("cape-town", "Cape Town", "ZA", "city", "Nhìn núi, biển và bầu trời mở ra cùng một nhịp bình yên.", None),
    ("cairo", "Cairo", "EG", "city", "Theo dòng Nile và những dấu vết đã đi cùng nhân loại.", None),
    ("marrakech", "Marrakech", "MA", "city", "Lạc trong sắc đất nung, khu chợ và những khoảng sân có nắng.", None),
    ("barcelona", "Barcelona", "ES", "city", "Để màu sắc, kiến trúc và biển Địa Trung Hải làm ngày vui hơn.", None),
    ("lisbon", "Lisbon", "PT", "city", "Lên một con dốc nhỏ, nghe fado và nhìn thành phố trôi chậm.", None),
    ("amsterdam", "Amsterdam", "NL", "city", "Đạp xe dọc kênh đào và tìm vẻ đẹp trong những điều giản dị.", None),
    ("prague", "Prague", "CZ", "city", "Bước qua cây cầu cổ để nghe một thành phố kể chuyện.", None),
    ("reykjavik", "Reykjavik", "IS", "city", "Gặp gió lạnh, suối ấm và bầu trời rộng của phương Bắc.", None),
    ("queenstown", "Queenstown", "NZ", "city", "Đứng trước hồ và núi để nhớ rằng mình đang có mặt ở đây.", None),
    ("swiss-alps", "Swiss Alps", "CH", "region", "Đi giữa những đỉnh núi và một sự tĩnh lặng rất trong.", None),
    ("serengeti", "Serengeti", "TZ", "region", "Quan sát nhịp sống hoang dã với sự tôn trọng và kiên nhẫn.", None),
    ("maldives", "Maldives", "MV", "island", "Thả mình theo màu nước và một buổi chiều không cần vội.", None),
    ("hoi-an", "Hội An", "VN", "city", "Đi chậm giữa phố cổ, đèn lồng và những mái ngói thời gian.", "central"),
    ("ha-long-bay", "Vịnh Hạ Long", "VN", "heritage", "Để những đảo đá và mặt nước xanh mở ra một khoảng thở.", "north"),
    ("ninh-binh", "Ninh Bình", "VN", "province", "Thở cùng núi đá vôi, dòng sông trong và nhịp chèo yên ả.", "north"),
    ("da-lat", "Đà Lạt", "VN", "city", "Một buổi sớm trong lành giữa thông xanh, hoa và sương mỏng.", "south"),
]

CHECKPOINT_TITLES = [
    ("Khởi hành dịu dàng", "Bắt đầu bằng một hơi thở và để đôi chân tìm nhịp riêng."),
    ("Khoảnh khắc hiện tại", "Dừng lại, quan sát một điều đẹp và cho mình vài phút thảnh thơi."),
    ("Mang theo bình yên", "Khép chặng đường bằng một điều muốn giữ lại cho ngày mai."),
]

MISSION_ACTIONS = {
    "vi": ["Uống một cốc nước", "Đi bộ năm phút", "Thở chậm một phút", "Đón ánh sáng tự nhiên", "Dọn một góc nhỏ", "Gửi một lời tử tế", "Ghi ba điều biết ơn", "Duỗi người nhẹ nhàng", "Hẹn một khoảng nghỉ", "Viết một dòng cho mình"],
    "en": ["Drink a glass of water", "Walk for five minutes", "Take one slow breath", "Step into natural light", "Tidy one small corner", "Send a kind message", "Name three things you appreciate", "Stretch gently", "Schedule a small pause", "Write one line for yourself"],
    "ja": ["水を一杯飲む", "5分歩く", "ゆっくり呼吸する", "自然の光を浴びる", "小さな場所を整える", "優しいメッセージを送る", "感謝を三つ書く", "やさしく体を伸ばす", "小さな休憩を約束する", "自分に一行書く"],
    "fr": ["Boire un verre d’eau", "Marcher cinq minutes", "Respirer lentement", "Accueillir la lumière naturelle", "Ranger un petit coin", "Envoyer un message doux", "Nommer trois gratitudes", "S’étirer doucement", "S’offrir une petite pause", "Écrire une ligne pour soi"],
    "es": ["Beber un vaso de agua", "Caminar cinco minutos", "Respirar despacio", "Recibir la luz natural", "Ordenar un rincón pequeño", "Enviar un mensaje amable", "Nombrar tres agradecimientos", "Estirarse suavemente", "Regalarse una pausa", "Escribir una línea para ti"],
    "it": ["Bere un bicchiere d’acqua", "Camminare cinque minuti", "Respirare lentamente", "Cercare la luce naturale", "Riordinare un piccolo angolo", "Mandare un messaggio gentile", "Scrivere tre gratitudini", "Allungarsi con dolcezza", "Concedersi una piccola pausa", "Scrivere una riga per sé"],
    "de": ["Ein Glas Wasser trinken", "Fünf Minuten spazieren", "Langsam atmen", "Natürliches Licht genießen", "Eine kleine Ecke ordnen", "Eine freundliche Nachricht senden", "Drei Dinge der Dankbarkeit nennen", "Sanft dehnen", "Eine kleine Pause planen", "Eine Zeile für sich schreiben"],
    "ko": ["물 한 잔 마시기", "5분 걷기", "천천히 호흡하기", "자연의 빛 맞기", "작은 공간 정리하기", "따뜻한 메시지 보내기", "고마운 일 세 가지 적기", "부드럽게 스트레칭하기", "작은 휴식 약속하기", "나에게 한 줄 쓰기"],
    "pt": ["Beber um copo de água", "Caminhar cinco minutos", "Respirar devagar", "Receber a luz natural", "Arrumar um cantinho", "Enviar uma mensagem gentil", "Nomear três gratidões", "Alongar-se suavemente", "Fazer uma pequena pausa", "Escrever uma linha para si"],
    "ms": ["Minum segelas air", "Berjalan lima minit", "Bernafas perlahan", "Menikmati cahaya semula jadi", "Mengemas sudut kecil", "Hantar mesej yang baik", "Namakan tiga perkara disyukuri", "Regangkan badan perlahan", "Jadualkan rehat kecil", "Tulis satu baris untuk diri"],
    "id": ["Minum segelas air", "Berjalan lima menit", "Bernapas perlahan", "Menikmati cahaya alami", "Merapikan sudut kecil", "Kirim pesan yang baik", "Sebutkan tiga hal yang disyukuri", "Lakukan peregangan lembut", "Jadwalkan jeda kecil", "Tulis satu baris untuk diri"],
    "th": ["ดื่มน้ำหนึ่งแก้ว", "เดินห้านาที", "หายใจช้า ๆ", "รับแสงธรรมชาติ", "จัดมุมเล็ก ๆ", "ส่งข้อความที่อ่อนโยน", "บอกสามสิ่งที่รู้สึกขอบคุณ", "ยืดตัวเบา ๆ", "นัดเวลาพักเล็ก ๆ", "เขียนหนึ่งบรรทัดให้ตัวเอง"],
}

LOCALE_TEXT = {
    "vi": ("Một điểm dừng dịu dàng để chậm lại, quan sát và tận hưởng khoảnh khắc.", "Hãy đi chậm và để cơ thể tìm thấy nhịp bình yên.", "Một món quà nhỏ nhắc ta chăm sóc chính mình."),
    "en": ("A gentle stop to slow down, notice the world, and enjoy the moment.", "Move slowly and let your body find a calmer rhythm.", "A small keepsake to remind you to care for yourself."),
    "ja": ("足をゆるめ、景色を感じながら、今この瞬間を味わう場所です。", "ゆっくり進み、体に穏やかなリズムを思い出させましょう。", "自分を大切にすることを思い出す小さなお守りです。"),
    "fr": ("Un lieu doux pour ralentir, observer et savourer l’instant.", "Avancez doucement et laissez votre corps retrouver un rythme paisible.", "Un petit souvenir qui rappelle de prendre soin de soi."),
    "es": ("Un lugar amable para bajar el ritmo, observar y disfrutar el momento.", "Avanza despacio y deja que tu cuerpo encuentre un ritmo tranquilo.", "Un pequeño recuerdo para recordar que mereces cuidarte."),
    "it": ("Un luogo gentile per rallentare, osservare e godersi l’istante.", "Procedi con calma e lascia che il corpo ritrovi un ritmo sereno.", "Un piccolo ricordo che invita a prendersi cura di sé."),
    "de": ("Ein sanfter Ort zum Innehalten, Wahrnehmen und Genießen des Augenblicks.", "Gehe langsam und lass deinen Körper einen ruhigen Rhythmus finden.", "Ein kleines Andenken, das dich an Selbstfürsorge erinnert."),
    "ko": ("잠시 속도를 늦추고 세상을 바라보며 순간을 누리는 곳입니다.", "천천히 움직이며 몸이 편안한 리듬을 찾게 해 주세요.", "자신을 돌보는 일을 기억하게 하는 작은 기념품입니다."),
    "pt": ("Um lugar gentil para desacelerar, observar e aproveitar o momento.", "Siga devagar e deixe o corpo encontrar um ritmo tranquilo.", "Uma pequena lembrança para recordar que você merece cuidado."),
    "ms": ("Tempat lembut untuk memperlahankan langkah, memerhati dan menikmati saat ini.", "Bergerak perlahan dan biarkan tubuh mencari rentak yang tenang.", "Cenderamata kecil untuk mengingatkan kita menjaga diri."),
    "id": ("Tempat yang lembut untuk melambat, memperhatikan, dan menikmati saat ini.", "Bergerak perlahan dan biarkan tubuh menemukan ritme yang tenang.", "Suvenir kecil yang mengingatkanmu untuk merawat diri."),
    "th": ("จุดพักที่อ่อนโยนให้คุณช้าลง มองเห็นโลก และเพลิดเพลินกับช่วงเวลานี้", "ค่อย ๆ เดินและให้ร่างกายได้พบจังหวะที่สงบขึ้น", "ของที่ระลึกเล็ก ๆ เพื่อเตือนให้ดูแลตัวเอง"),
}

ITEM_LABELS = {
    "vi": ("Kỷ niệm ", "Ánh sáng "), "en": ("Memory of ", "Light from "),
    "ja": ("思い出・", "光・"), "fr": ("Souvenir de ", "Lumière de "),
    "es": ("Recuerdo de ", "Luz de "), "it": ("Ricordo di ", "Luce di "),
    "de": ("Erinnerung an ", "Licht aus "), "ko": ("추억 · ", "빛 · "),
    "pt": ("Memória de ", "Luz de "), "ms": ("Kenangan ", "Cahaya "),
    "id": ("Kenangan ", "Cahaya dari "), "th": ("ความทรงจำแห่ง ", "แสงจาก "),
}

FOOD_LABELS = {
    "vi": "Hương vị ", "en": "Taste of ", "ja": "味わい・", "fr": "Saveur de ",
    "es": "Sabor de ", "it": "Sapore di ", "de": "Geschmack von ", "ko": "맛 · ",
    "pt": "Sabor de ", "ms": "Rasa ", "id": "Rasa ", "th": "รสชาติแห่ง ",
}

QUOTE_TOPIC_TEXT = {
    "vi": {"love_life": "Cuộc đời vẫn có những điều đáng yêu để mình mở lòng đón nhận.", "enjoy_moment": "Khoảnh khắc này đủ đầy khi mình thật sự có mặt.", "life": "Mỗi ngày là một cơ hội nhỏ để bắt đầu lại.", "smile": "Một nụ cười dịu dàng có thể mở ra một khe sáng.", "happiness": "Hạnh phúc thường ghé qua trong những điều rất bình thường."},
    "en": {"love_life": "Life still offers lovely things when we stay open to them.", "enjoy_moment": "This moment becomes enough when we are truly present.", "life": "Each day is a small chance to begin again.", "smile": "A gentle smile can open a little window of light.", "happiness": "Happiness often arrives in ordinary shapes."},
    "ja": {"love_life": "心を開けば、人生にはまだ愛おしいものがあります。", "enjoy_moment": "今ここにいると、この瞬間は十分に満ちています。", "life": "一日は何度でも始め直せる小さな機会です。", "smile": "やさしい笑顔は小さな光の窓を開きます。", "happiness": "幸せは、ありふれた姿で訪れることがあります。"},
    "fr": {"love_life": "La vie offre encore de belles choses quand on reste ouvert.", "enjoy_moment": "L’instant suffit quand on y est vraiment présent.", "life": "Chaque jour est une petite occasion de recommencer.", "smile": "Un sourire doux peut ouvrir une petite fenêtre de lumière.", "happiness": "Le bonheur arrive souvent sous des formes ordinaires."},
    "es": {"love_life": "La vida aún ofrece cosas bonitas cuando nos abrimos a ellas.", "enjoy_moment": "Este momento basta cuando estamos realmente presentes.", "life": "Cada día es una pequeña oportunidad para empezar de nuevo.", "smile": "Una sonrisa amable puede abrir una ventana de luz.", "happiness": "La felicidad suele llegar con formas sencillas."},
    "it": {"love_life": "La vita offre ancora cose belle quando restiamo aperti.", "enjoy_moment": "Questo momento basta quando siamo davvero presenti.", "life": "Ogni giorno è una piccola occasione per ricominciare.", "smile": "Un sorriso gentile può aprire una finestra di luce.", "happiness": "La felicità arriva spesso in forme ordinarie."},
    "de": {"love_life": "Das Leben hält Schönes bereit, wenn wir offen bleiben.", "enjoy_moment": "Dieser Augenblick genügt, wenn wir wirklich anwesend sind.", "life": "Jeder Tag ist eine kleine Chance für einen neuen Anfang.", "smile": "Ein sanftes Lächeln kann ein Fenster zum Licht öffnen.", "happiness": "Glück kommt oft in ganz gewöhnlichen Formen."},
    "ko": {"love_life": "마음을 열면 삶에는 여전히 사랑스러운 일이 있습니다.", "enjoy_moment": "지금 이 순간에 머물면 충분히 충만해집니다.", "life": "하루하루는 다시 시작할 수 있는 작은 기회입니다.", "smile": "따뜻한 미소 하나가 작은 빛의 창을 엽니다.", "happiness": "행복은 종종 평범한 모습으로 찾아옵니다."},
    "pt": {"love_life": "A vida ainda oferece beleza quando permanecemos abertos.", "enjoy_moment": "Este momento basta quando estamos realmente presentes.", "life": "Cada dia é uma pequena chance de começar de novo.", "smile": "Um sorriso gentil pode abrir uma janela de luz.", "happiness": "A felicidade costuma chegar em formas simples."},
    "ms": {"love_life": "Hidup masih menawarkan perkara indah apabila kita terbuka.", "enjoy_moment": "Saat ini sudah cukup apabila kita benar-benar hadir.", "life": "Setiap hari ialah peluang kecil untuk bermula semula.", "smile": "Senyuman lembut boleh membuka jendela cahaya.", "happiness": "Kebahagiaan sering hadir dalam bentuk biasa."},
    "id": {"love_life": "Hidup masih menawarkan hal indah saat kita mau terbuka.", "enjoy_moment": "Saat ini terasa cukup ketika kita benar-benar hadir.", "life": "Setiap hari adalah kesempatan kecil untuk memulai lagi.", "smile": "Senyum lembut dapat membuka jendela cahaya.", "happiness": "Kebahagiaan sering datang dalam bentuk sederhana."},
    "th": {"love_life": "ชีวิตยังมีสิ่งน่ารักเสมอเมื่อเราเปิดใจรับมัน", "enjoy_moment": "ช่วงเวลานี้ก็เพียงพอเมื่อเราอยู่กับมันจริง ๆ", "life": "แต่ละวันคือโอกาสเล็ก ๆ ที่จะเริ่มต้นใหม่", "smile": "รอยยิ้มอ่อนโยนเปิดหน้าต่างเล็ก ๆ สู่แสงสว่างได้", "happiness": "ความสุขมักมาในรูปแบบธรรมดา ๆ"},
}

QUOTE_CLAUSES = {
    "vi": ["Hãy để mình đi chậm hơn một nhịp.", "Bạn không cần làm mọi thứ hoàn hảo hôm nay.", "Một điều nhỏ cũng xứng đáng được nâng niu.", "Lòng biết ơn làm ngày thường trở nên ấm áp.", "Bạn luôn có thể bắt đầu lại bằng một hơi thở."] * 4,
    "en": ["Let yourself move one beat more slowly.", "You do not have to make everything perfect today.", "A small thing is still worthy of care.", "Gratitude can warm an ordinary day.", "You can always begin again with one breath."] * 4,
    "ja": ["もう一拍ゆっくり進んでみましょう。", "今日すべてを完璧にしなくても大丈夫です。", "小さなことにも大切にする価値があります。", "感謝は何気ない一日を温めます。", "一つの呼吸からいつでもやり直せます。"] * 4,
    "fr": ["Autorisez-vous à avancer un peu plus lentement.", "Tout n’a pas besoin d’être parfait aujourd’hui.", "Une petite chose mérite aussi votre attention.", "La gratitude réchauffe les jours ordinaires.", "Vous pouvez toujours recommencer par une respiration."] * 4,
    "es": ["Permítete avanzar un poco más despacio.", "Hoy no tienes que hacerlo todo perfecto.", "Lo pequeño también merece cuidado.", "La gratitud calienta los días normales.", "Siempre puedes empezar de nuevo con una respiración."] * 4,
    "it": ["Concediti di procedere un po’ più lentamente.", "Oggi non deve essere tutto perfetto.", "Anche una cosa piccola merita cura.", "La gratitudine scalda i giorni normali.", "Puoi sempre ricominciare con un respiro."] * 4,
    "de": ["Erlaube dir, einen Moment langsamer zu gehen.", "Heute muss nicht alles perfekt sein.", "Auch etwas Kleines verdient deine Aufmerksamkeit.", "Dankbarkeit macht gewöhnliche Tage warm.", "Mit einem Atemzug kannst du jederzeit neu beginnen."] * 4,
    "ko": ["한 박자 더 천천히 움직여도 괜찮습니다.", "오늘 모든 것을 완벽하게 할 필요는 없습니다.", "작은 일도 충분히 소중합니다.", "감사는 평범한 하루를 따뜻하게 합니다.", "한 번의 호흡으로 언제든 다시 시작할 수 있습니다."] * 4,
    "pt": ["Permita-se caminhar um pouco mais devagar.", "Hoje não precisa ser tudo perfeito.", "Uma coisa pequena também merece cuidado.", "A gratidão aquece os dias comuns.", "Você sempre pode recomeçar com uma respiração."] * 4,
    "ms": ["Benarkan diri bergerak sedikit lebih perlahan.", "Hari ini tidak perlu semuanya sempurna.", "Perkara kecil juga layak dihargai.", "Syukur menghangatkan hari biasa.", "Kita sentiasa boleh bermula semula dengan satu nafas."] * 4,
    "id": ["Izinkan dirimu bergerak sedikit lebih lambat.", "Hari ini tidak harus sempurna semuanya.", "Hal kecil pun layak dirawat.", "Rasa syukur menghangatkan hari biasa.", "Kamu selalu bisa memulai lagi dengan satu napas."] * 4,
    "th": ["ให้ตัวเองเดินช้าลงอีกนิด", "วันนี้ไม่จำเป็นต้องทำทุกอย่างให้สมบูรณ์แบบ", "เรื่องเล็ก ๆ ก็มีค่าควรได้รับการดูแล", "ความขอบคุณทำให้วันธรรมดาอบอุ่นขึ้น", "คุณเริ่มต้นใหม่ได้เสมอด้วยลมหายใจหนึ่งครั้ง"] * 4,
}


def q(value: object) -> str:
    if value is None:
        return "NULL"
    if isinstance(value, bool):
        return "true" if value else "false"
    return "'" + str(value).replace("'", "''") + "'"


def parse_quotes() -> list[tuple[int, str, str]]:
    text = QUOTE_SOURCE.read_text(encoding="utf-8")
    rows = re.findall(r"\((\d+), '([^']+)', '((?:''|[^'])*)'\)[,;]", text)
    return [(int(n), topic, content.replace("''", "'")) for n, topic, content in rows]


def asset_svg(index: int, kind: str) -> str:
    palettes = [("#dceff2", "#4f7b86", "#f5dca6"), ("#e6e0f4", "#776a9e", "#f2b7a0"), ("#e0f0df", "#5f8b68", "#f3d58b"), ("#f6e5dc", "#a46e5d", "#b6dce1")]
    sky, accent, sun = palettes[index % len(palettes)]
    offset = (index * 13) % 34
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 360">
  <defs><linearGradient id="g" x1="0" x2="1" y1="0" y2="1"><stop stop-color="{sky}"/><stop offset="1" stop-color="#fffaf4"/></linearGradient></defs>
  <rect width="640" height="360" rx="42" fill="url(#g)"/>
  <circle cx="500" cy="78" r="46" fill="{sun}" opacity=".88"/>
  <path d="M0 250 Q120 {205-offset} 250 250 T500 240 T700 250 V360 H0Z" fill="{accent}" opacity=".38"/>
  <path d="M0 286 Q120 230 250 286 T500 274 T700 286 V360 H0Z" fill="{accent}" opacity=".68"/>
  <path d="M{120+offset} 250 l62-104 45 62 44-40 74 82z" fill="{accent}" opacity=".86"/>
  <circle cx="{150+offset}" cy="112" r="28" fill="#ffffff" opacity=".72"/>
  <path d="M110 110 q18-32 48 0 q18-26 40 0" fill="none" stroke="#ffffff" stroke-width="12" stroke-linecap="round" opacity=".8"/>
  <text x="36" y="326" font-family="Arial,sans-serif" font-size="18" fill="#324b55" opacity=".7">MuseMend • {kind}</text>
</svg>'''


def write_assets() -> dict[str, dict[str, str]]:
    ASSET_DIR.mkdir(parents=True, exist_ok=True)
    paths: dict[str, dict[str, str]] = {}
    for index, (slug, *_rest) in enumerate(DESTINATIONS, start=1):
        base = f"assets/illustrations/journey/content-pack/v1/{slug}"
        paths[slug] = {"cover": base + ".svg", "map": base + ".svg", "landmark": base + "-landmark.svg", "food": base + "-food.svg", "item_a": base + "-item-a.svg", "item_b": base + "-item-b.svg"}
        for kind, suffix in (("cover", ""), ("landmark", "-landmark"), ("food", "-food"), ("item-a", "-item-a"), ("item-b", "-item-b")):
            (ASSET_DIR / f"{slug}{suffix}.svg").write_text(asset_svg(index, kind), encoding="utf-8")
        for checkpoint in range(1, 4):
            (ASSET_DIR / f"{slug}-checkpoint-{checkpoint}.svg").write_text(asset_svg(index + checkpoint, f"checkpoint {checkpoint}"), encoding="utf-8")
        paths[slug]["checkpoint_1"] = base + "-checkpoint-1.svg"
        paths[slug]["checkpoint_2"] = base + "-checkpoint-2.svg"
        paths[slug]["checkpoint_3"] = base + "-checkpoint-3.svg"
    return paths


def build_migration(paths: dict[str, dict[str, str]]) -> str:
    lines = [
        "-- MuseMend content pack v1: 30 destinations, 90 checkpoints, 100 quotes, 30 missions.",
        "-- Generated by supabase/seed/generate_content_pack.py. Do not edit generated rows by hand.",
        "-- All catalog writes are server-owned and replay-safe; clients remain read-only.",
        "BEGIN;",
        "ALTER TABLE public.foods ADD COLUMN IF NOT EXISTS asset_path text;",
    ]
    dest_values = []
    for i, (slug, name, country, dtype, desc, region) in enumerate(DESTINATIONS, start=1):
        p = paths[slug]
        dest_values.append("(" + ", ".join([q("content-" + slug), q(name), q(desc), q(region), str(100 + i), q(country), q(dtype), q(p["cover"]), q(p["map"])]) + ")")
    lines += [
        "WITH rows(code,name,description,vietnam_region,order_index,country_code,destination_type,cover_asset_path,map_asset_path) AS (",
        "VALUES\n  " + ",\n  ".join(dest_values),
        ")",
        "INSERT INTO public.destinations(code,name,description,vietnam_region,order_index,country_code,destination_type,cover_asset_path,map_asset_path)",
        "SELECT code,name,description,vietnam_region::public.vietnam_region_type,order_index,country_code,destination_type,cover_asset_path,map_asset_path FROM rows",
        "ON CONFLICT (code) DO UPDATE SET name=EXCLUDED.name,description=EXCLUDED.description,vietnam_region=EXCLUDED.vietnam_region,order_index=EXCLUDED.order_index,country_code=EXCLUDED.country_code,destination_type=EXCLUDED.destination_type,cover_asset_path=EXCLUDED.cover_asset_path,map_asset_path=EXCLUDED.map_asset_path,is_active=true;",
    ]

    checkpoint_values = []
    for slug, name, *_rest in DESTINATIONS:
        for number, (title, desc) in enumerate(CHECKPOINT_TITLES, start=1):
            checkpoint_values.append("(" + ", ".join([q("content-" + slug), str(number), q(title), q(desc), str(10 + (number - 1) * 5), str(number), q(paths[slug][f"checkpoint_{number}"])]) + ")")
    lines += [
        "WITH rows(destination_code,checkpoint_number,title,description,required_energy,order_index,asset_path) AS (",
        "VALUES\n  " + ",\n  ".join(checkpoint_values),
        ")",
        "INSERT INTO public.destination_checkpoints(destination_id,checkpoint_number,title,description,required_energy,order_index,asset_path)",
        "SELECT d.id,r.checkpoint_number,r.title,r.description,r.required_energy,r.order_index,r.asset_path FROM rows r JOIN public.destinations d ON d.code=r.destination_code",
        "ON CONFLICT (destination_id,checkpoint_number) DO UPDATE SET title=EXCLUDED.title,description=EXCLUDED.description,required_energy=EXCLUDED.required_energy,order_index=EXCLUDED.order_index,asset_path=EXCLUDED.asset_path,is_active=true;",
    ]

    landmark_values, food_values, item_values = [], [], []
    for slug, name, *_rest in DESTINATIONS:
        landmark_values.append("(" + ", ".join([q("content-" + slug), q("content-" + slug + "-landmark"), q(name), q("A landmark to notice slowly and remember with warmth."), q(paths[slug]["landmark"]), "0", "0", "1", "'common'::public.rarity_type"]) + ")")
        food_values.append("(" + ", ".join([q("content-" + slug), q("content-" + slug + "-food"), q("Hương vị " + name), q("Một hương vị nhỏ để thưởng thức mà không vội vàng."), q(paths[slug]["food"]), "1", "'common'::public.rarity_type"]) + ")")
        item_values.extend([
            "(" + ", ".join([q("content-" + slug), q("content-" + slug + "-item-a"), q(ITEM_LABELS["vi"][0] + name), "'souvenir'::public.destination_item_type", q("Một kỷ vật cho hành trình dịu dàng."), q(paths[slug]["item_a"]), "1", "'uncommon'::public.rarity_type"]) + ")",
            "(" + ", ".join([q("content-" + slug), q("content-" + slug + "-item-b"), q(ITEM_LABELS["vi"][1] + name), "'badge'::public.destination_item_type", q("Một huy hiệu nhỏ cho việc bạn đã có mặt hôm nay."), q(paths[slug]["item_b"]), "2", "'rare'::public.rarity_type"]) + ")",
        ])
    lines += [
        "WITH rows(destination_code,code,name,description,asset_path,latitude,longitude,order_index,rarity) AS (VALUES\n  " + ",\n  ".join(landmark_values) + ")",
        "INSERT INTO public.landmarks(destination_id,code,name,description,asset_path,latitude,longitude,order_index,rarity)",
        "SELECT d.id,r.code,r.name,r.description,r.asset_path,r.latitude,r.longitude,r.order_index,r.rarity FROM rows r JOIN public.destinations d ON d.code=r.destination_code",
        "ON CONFLICT (code) DO UPDATE SET name=EXCLUDED.name,description=EXCLUDED.description,asset_path=EXCLUDED.asset_path,order_index=EXCLUDED.order_index,rarity=EXCLUDED.rarity,is_active=true;",
        "WITH rows(destination_code,code,name,description,asset_path,order_index,rarity) AS (VALUES\n  " + ",\n  ".join(food_values) + ")",
        "INSERT INTO public.foods(destination_id,code,name,description,asset_path,order_index,rarity)",
        "SELECT d.id,r.code,r.name,r.description,r.asset_path,r.order_index,r.rarity FROM rows r JOIN public.destinations d ON d.code=r.destination_code",
        "ON CONFLICT (code) DO UPDATE SET name=EXCLUDED.name,description=EXCLUDED.description,asset_path=EXCLUDED.asset_path,order_index=EXCLUDED.order_index,rarity=EXCLUDED.rarity,is_active=true;",
        "WITH rows(destination_code,code,name,item_type,description,asset_path,order_index,rarity) AS (VALUES\n  " + ",\n  ".join(item_values) + ")",
        "INSERT INTO public.destination_items(destination_id,code,name,item_type,description,asset_path,order_index,rarity)",
        "SELECT d.id,r.code,r.name,r.item_type,r.description,r.asset_path,r.order_index,r.rarity FROM rows r JOIN public.destinations d ON d.code=r.destination_code",
        "ON CONFLICT (code) DO UPDATE SET name=EXCLUDED.name,item_type=EXCLUDED.item_type,description=EXCLUDED.description,asset_path=EXCLUDED.asset_path,order_index=EXCLUDED.order_index,rarity=EXCLUDED.rarity,is_active=true;",
    ]

    lines += [
        "WITH rewards AS (SELECT cp.id checkpoint_id,cp.destination_id,cp.checkpoint_number,d.id destination_id2,l.id landmark_id,f.id food_id,ia.id item_a_id,ib.id item_b_id FROM public.destination_checkpoints cp JOIN public.destinations d ON d.id=cp.destination_id JOIN public.landmarks l ON l.destination_id=d.id JOIN public.foods f ON f.destination_id=d.id JOIN public.destination_items ia ON ia.destination_id=d.id AND ia.code LIKE d.code||'-item-a' JOIN public.destination_items ib ON ib.destination_id=d.id AND ib.code LIKE d.code||'-item-b')",
        "INSERT INTO public.checkpoint_rewards(checkpoint_id,reward_type,landmark_id,food_id,destination_item_id,energy_amount,quantity,order_index)",
        "SELECT checkpoint_id,'landmark'::public.checkpoint_reward_type,landmark_id,NULL::bigint,NULL::bigint,NULL::integer,1,1 FROM rewards WHERE checkpoint_number=1 AND NOT EXISTS (SELECT 1 FROM public.checkpoint_rewards x WHERE x.checkpoint_id=rewards.checkpoint_id AND x.reward_type='landmark'::public.checkpoint_reward_type)",
        "UNION ALL SELECT checkpoint_id,'destination_item'::public.checkpoint_reward_type,NULL::bigint,NULL::bigint,item_a_id,NULL::integer,1,2 FROM rewards WHERE checkpoint_number=1 AND NOT EXISTS (SELECT 1 FROM public.checkpoint_rewards x WHERE x.checkpoint_id=rewards.checkpoint_id AND x.reward_type='destination_item'::public.checkpoint_reward_type AND x.destination_item_id=rewards.item_a_id)",
        "UNION ALL SELECT checkpoint_id,'food'::public.checkpoint_reward_type,NULL::bigint,food_id,NULL::bigint,NULL::integer,1,1 FROM rewards WHERE checkpoint_number=2 AND NOT EXISTS (SELECT 1 FROM public.checkpoint_rewards x WHERE x.checkpoint_id=rewards.checkpoint_id AND x.reward_type='food'::public.checkpoint_reward_type)",
        "UNION ALL SELECT checkpoint_id,'destination_item'::public.checkpoint_reward_type,NULL::bigint,NULL::bigint,item_b_id,NULL::integer,1,1 FROM rewards WHERE checkpoint_number=3 AND NOT EXISTS (SELECT 1 FROM public.checkpoint_rewards x WHERE x.checkpoint_id=rewards.checkpoint_id AND x.reward_type='destination_item'::public.checkpoint_reward_type AND x.destination_item_id=rewards.item_b_id)",
        "UNION ALL SELECT checkpoint_id,'energy'::public.checkpoint_reward_type,NULL::bigint,NULL::bigint,NULL::bigint,5,1,2 FROM rewards WHERE checkpoint_number=3 AND NOT EXISTS (SELECT 1 FROM public.checkpoint_rewards x WHERE x.checkpoint_id=rewards.checkpoint_id AND x.reward_type='energy'::public.checkpoint_reward_type);",
    ]

    mission_values = []
    for i in range(30):
        code = ["demo-water", "demo-walk"][i] if i < 2 else f"content-mission-{i+1:02d}"
        mtype = "daily" if i < 20 else "weekly" if i < 24 else "monthly" if i < 27 else "yearly" if i == 27 else "custom"
        mood = "all" if i < 2 or i % 5 else ["great", "good", "okay", "sad", "awful"][i // 5 % 5]
        reward = 5 if mtype in ("daily", "custom") else 10 if mtype == "weekly" else 15 if mtype == "monthly" else 20
        minutes = 3 + (i % 8)
        mission_values.append("(" + ", ".join([q(code), q(MISSION_ACTIONS["vi"][i % 10]), q("Một bước nhỏ, vừa sức để chăm sóc bản thân hôm nay."), q(mtype) + "::public.mission_type", q(mood) + "::public.target_mood_type", str(reward), q("easy" if i < 20 else "medium") + "::public.mission_difficulty", str(minutes), q("assets/illustrations/clouds/mascot-cloud.png")]) + ")")
    lines += [
        "INSERT INTO public.mission_templates(code,title,description,mission_type,target_mood,default_energy_reward,difficulty,estimated_minutes,icon_asset_path) VALUES\n  " + ",\n  ".join(mission_values),
        "ON CONFLICT (code) DO UPDATE SET title=EXCLUDED.title,description=EXCLUDED.description,mission_type=EXCLUDED.mission_type,target_mood=EXCLUDED.target_mood,default_energy_reward=EXCLUDED.default_energy_reward,difficulty=EXCLUDED.difficulty,estimated_minutes=EXCLUDED.estimated_minutes,icon_asset_path=EXCLUDED.icon_asset_path,is_system=true,is_active=true;",
    ]

    quotes = parse_quotes()
    quote_values = [f"({number}, {q(topic)}, {q(content)})" for number, topic, content in quotes]
    lines += [
        "INSERT INTO public.daily_quotes(rotation_order,topic,content) VALUES\n  " + ",\n  ".join(quote_values),
        "ON CONFLICT (rotation_order) DO UPDATE SET topic=EXCLUDED.topic,content=EXCLUDED.content,is_active=true;",
    ]

    # Translation rows are generated for every active language and every base row.
    dest_tr, cp_tr, lm_tr, food_tr, item_tr, mission_tr, quote_tr = [], [], [], [], [], [], []
    for slug, name, *_rest in DESTINATIONS:
        for lang in LANGUAGES:
            intro, body, keepsake = LOCALE_TEXT[lang]
            dest_tr.append(f"((SELECT id FROM public.destinations WHERE code={q('content-' + slug)}),{q(lang)},{q(name)},{q(intro)})")
            for n, (_title, _desc) in enumerate(CHECKPOINT_TITLES, start=1):
                cp_tr.append(f"((SELECT id FROM public.destination_checkpoints WHERE destination_id=(SELECT id FROM public.destinations WHERE code={q('content-' + slug)}) AND checkpoint_number={n}),{q(lang)},{q((('Chặng ' if lang == 'vi' else 'Checkpoint ' if lang == 'en' else 'Étape ' if lang == 'fr' else 'Chặng ') + str(n)))},{q(body)})")
            lm_tr.append(f"((SELECT id FROM public.landmarks WHERE code={q('content-' + slug + '-landmark')}),{q(lang)},{q(name)},{q(body)},{q(body)})")
            food_tr.append(f"((SELECT id FROM public.foods WHERE code={q('content-' + slug + '-food')}),{q(lang)},{q(FOOD_LABELS[lang] + name)},{q(body)},{q(body)})")
            item_tr.extend([
                f"((SELECT id FROM public.destination_items WHERE code={q('content-' + slug + '-item-a')}),{q(lang)},{q(ITEM_LABELS[lang][0] + name)},{q(keepsake)})",
                f"((SELECT id FROM public.destination_items WHERE code={q('content-' + slug + '-item-b')}),{q(lang)},{q(ITEM_LABELS[lang][1] + name)},{q(keepsake)})",
            ])
    for i in range(30):
        code = "demo-water" if i == 0 else "demo-walk" if i == 1 else f"content-mission-{i+1:02d}"
        for lang in LANGUAGES:
            title = MISSION_ACTIONS[lang][i % 10]
            desc = LOCALE_TEXT[lang][1]
            mission_tr.append(f"((SELECT id FROM public.mission_templates WHERE code={q(code)}),{q(lang)},{q(title)},{q(desc)})")
    for number, topic, _content in quotes:
        for lang in LANGUAGES:
            if lang == "vi":
                content = _content
            else:
                content = QUOTE_TOPIC_TEXT[lang][topic] + " " + QUOTE_CLAUSES[lang][(number - 1) % len(QUOTE_CLAUSES[lang])]
            quote_tr.append(f"({number},{q(lang)},{q(content)})")

    def insert(rows: list[str], table: str, columns: str, conflict: str, updates: str) -> None:
        lines.extend([f"INSERT INTO public.{table}({columns}) VALUES\n  " + ",\n  ".join(rows), f"ON CONFLICT ({conflict}) DO UPDATE SET {updates};"])

    insert(dest_tr, "destination_translations", "destination_id,language_code,name,description", "destination_id,language_code", "name=EXCLUDED.name,description=EXCLUDED.description")
    insert(cp_tr, "checkpoint_translations", "checkpoint_id,language_code,title,description", "checkpoint_id,language_code", "title=EXCLUDED.title,description=EXCLUDED.description")
    insert(lm_tr, "landmark_translations", "landmark_id,language_code,name,description,story_content", "landmark_id,language_code", "name=EXCLUDED.name,description=EXCLUDED.description,story_content=EXCLUDED.story_content")
    insert(food_tr, "food_translations", "food_id,language_code,name,description,story_content", "food_id,language_code", "name=EXCLUDED.name,description=EXCLUDED.description,story_content=EXCLUDED.story_content")
    insert(item_tr, "destination_item_translations", "destination_item_id,language_code,name,description", "destination_item_id,language_code", "name=EXCLUDED.name,description=EXCLUDED.description")
    insert(mission_tr, "mission_template_translations", "mission_template_id,language_code,title,description", "mission_template_id,language_code", "title=EXCLUDED.title,description=EXCLUDED.description")
    insert(quote_tr, "daily_quote_translations", "quote_rotation_order,language_code,content", "quote_rotation_order,language_code", "content=EXCLUDED.content")
    lines += ["COMMIT;", "NOTIFY pgrst, 'reload schema';", ""]
    return "\n".join(lines)


def main() -> None:
    paths = write_assets()
    MIGRATION.write_text(build_migration(paths), encoding="utf-8")
    print(f"generated {MIGRATION} and {len(list(ASSET_DIR.glob('*.svg')))} SVG assets")


if __name__ == "__main__":
    main()
