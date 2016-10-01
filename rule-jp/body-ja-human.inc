##########################################################
## @file body-ja-human.inc
## @brief スパムっぽいキーワードを元にしたルール
##########################################################
## 本ルールは、ハンドメイドなスパム・キーワード集です。
##########################################################

# 必死だなオイ
body     BODYH_JA_YAJIRUSI      /↓( |　)*↓/
describe BODYH_JA_YAJIRUSI      YAJIRUSI
score    BODYH_JA_YAJIRUSI      1.8

# こんな表現ねぇーだろ
body     BODYH_JA_MAINICHINYUKIN	/毎日入金/
describe BODYH_JA_MAINICHINYUKIN	MAINICHINYUKIN
score    BODYH_JA_MAINICHINYUKIN	1.0

# 秘密交際
body     BODYH_JA_HIMITUKOUSAI	/秘密交際/
describe BODYH_JA_HIMITUKOUSAI	HIMITUKOUSAI
score    BODYH_JA_HIMITUKOUSAI	1.0

# 謝礼金
body     BODYH_JA_SYAREIKIN		/謝礼金/
describe BODYH_JA_SYAREIKIN		SYAREIKIN
score    BODYH_JA_SYAREIKIN		0.3

# 年齢認証
body     BODYH_JA_NENREININ		/年齢認証/
describe BODYH_JA_NENREININ		NENREININSYO
score    BODYH_JA_NENREININ		0.8

# 直アド
body     BODYH_JA_JIKAADO		/直アド/
describe BODYH_JA_JIKAADO		JIKAADO
score    BODYH_JA_JIKAADO		0.3

# 無料紹介
body     BODYH_JA_MURYOSYO		/無料紹介/
describe BODYH_JA_MURYOSYO		MURYOSYO
score    BODYH_JA_MURYOSYO		0.5

# マネーサポート
body     BODYH_JA_MONEYSUP		/マネーサポート/
describe BODYH_JA_MONEYSUP		MONEYSUPPORT
score    BODYH_JA_MONEYSUP      0.7

# 全額返金
body     BODYH_JA_ZENGAKU		/全額返金/
describe BODYH_JA_ZENGAKU		ZENGAKUHENKIN
score    BODYH_JA_ZENGAKU		0.3

# ネットで稼ぐ
body     BODYH_JA_NETDEKASEGU	/ネットで(儲ける|稼ぐ)/
describe BODYH_JA_NETDEKASEGU	NETDEKASEGU
score    BODYH_JA_NETDEKASEGU	0.3

# 競馬で儲ける
body     BODYH_JA_KEIBADEKASEGU  /競馬で(儲ける|稼ぐ)/
describe BODYH_JA_KEIBADEKASEGU  KEIBADEKASEGU
score    BODYH_JA_KEIBADEKASEGU  0.3

# 入金をご確認
body     BODYH_JA_NYUUKINKAKUNIN	/入金を(ご|御)確認/
describe BODYH_JA_NYUUKINKAKUNIN	NYUUKINKAKUNIN
score    BODYH_JA_NYUUKINKAKUNIN	0.3

# 配信中止
body     BODYH_JA_HAISINTYUSI   /配信(中止|停止)/
describe BODYH_JA_HAISINTYUSI   HAISINTYUSI
score    BODYH_JA_HAISINTYUSI   0.9

# 解除
body     BODYH_JA_KAIJYO        /解除(URL|ＵＲＬ)/i
describe BODYH_JA_KAIJYO        KAIJYO
score    BODYH_JA_KAIJYO        0.9

# メルマガ紹介
body     BODYH_JA_MELMAGASYOKAI  /メルマガを(ご|御)?紹介/
describe BODYH_JA_MELMAGASYOKAI  MELMAGASYOKAI
score    BODYH_JA_MELMAGASYOKAI  1.0

header   SUBJH_JA_MELMAGASYOKAI  Subject =~ /メルマガを(ご|御)?紹介/
describe SUBJH_JA_MELMAGASYOKAI  MELMAGASYOKAI
score    SUBJH_JA_MELMAGASYOKAI  2.0

# 高収入
header   SUBJH_JA_KOUSYUNYU  Subject =~ /高収入/
describe SUBJH_JA_KOUSYUNYU  KOUSYUNYU
score    SUBJH_JA_KOUSYUNYU  1.2

body     BODYH_JA_KOUSYUNYU  /高収入/
describe BODYH_JA_KOUSYUNYU  KOUSYUNYU
score    BODYH_JA_KOUSYUNYU  0.3

body     BODYH_JA_SAIYASU    /最安/
describe BODYH_JA_SAIYASU    SAIYASU
score    BODYH_JA_SAIYASU    0.3

#----------------------------------------
# BEGIN 宣伝スパム・対策
#----------------------------------------
# クリック
body     BODYH_JA_CLICK      /クリック/
describe BODYH_JA_CLICK      CLICK
score    BODYH_JA_CLICK      0.05

# 当選
body     BODYH_JA_TOUSEN     /当選/
describe BODYH_JA_TOUSEN     TOUSEN
score    BODYH_JA_TOUSEN     0.05

# 宣伝
meta     BODYH_JA_SENDEN     BODYH_JA_CLICK && BODYH_JA_TOUSEN
describe BODYH_JA_SENDEN     SENDEN
score    BODYH_JA_SENDEN     1.5

meta     BODYH_JA_BCAS       /B-CAS|Ｂ－ＣＡＳ/i
describe BODYH_JA_BCAS       B-CAS
score    BODYH_JA_BCAS       1.0

meta     BODYH_JA_SKAPA      /スカパ/
describe BODYH_JA_SKAPA      スカパ
score    BODYH_JA_SKAPA      0.5

meta     BODYH_JA_WOWOW      /WOWOW|ＷＯＷＯＷ/i
describe BODYH_JA_WOWOW      スカパ
score    BODYH_JA_WOWOW      0.5


#----------------------------------------
# END 宣伝スパム・対策
#----------------------------------------

