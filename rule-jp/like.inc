#################################################################
## @filename bot.inc
## @brief 組み合わせの妙による、ボットらしさの検出ルール
#################################################################

# 自分のところでは、スパム以外に該当せず
# undisclosed-recipients
score       UNDISC_RECIPS  3.0

# スパム・ツールっぽい
meta        LIKE_MAYBE_SPAMTOOL  (SPF_SOFTFAIL || SPF_HELO_SOFTFAIL) && MISSING_MID
describe    LIKE_MAYBE_SPAMTOOL  LIKE: may be spam tool
score       LIKE_MAYBE_SPAMTOOL  1.5

# ボットっぽい
meta        LIKE_BOT1   DATE_IN_FUTURE_12_24 && MISSING_MID
describe    LIKE_BOT1   LIKE: just bot
score       LIKE_BOT1   0.8

# ボットっぽい２
meta        LIKE_BOT2   (INVALID_MSGID || MISSING_MID) && MISSING_DATE
describe    LIKE_BOT2   LIKE: like a spam
score       LIKE_BOT2   0.5

# ボットっぽい３
meta        LIKE_BOT3   (INVALID_MSGID || MISSING_MID) && (!SPF_PASS)
describe    LIKE_BOT3   LIKE: just bot
score       LIKE_BOT3   0.45

# BODY中の yahoo アドレス
body        BODY_YAHOO  /.*\@yahoo\.co\.jp.+/i
describe    BODY_YAHOO  LIKE: has yahoo mail
score       BODY_YAHOO  0.01

# ボットっぽい４
meta        LIKE_BOT4   (INVALID_MSGID || MISSING_MID) && BODY_YAHOO
describe    LIKE_BOT4   LIKE: just bot?
score       LIKE_BOT4   0.5

# そろそろ SPF をまじめに設定するスパムも目立ってきたので・・・
meta        LIKE_SPAM1  RDNS_NONE && MISSING_MID
describe    LIKE_SPAM1  LIKE: SPF spam
score       LIKE_SPAM1  3.2

# 正攻法のスパム
meta        LIKE_SPAM2   (RCVD_IN_SBL || URIBL_WS_SURBL || RCVD_IN_BL_SPAMCOP_NET || URIBL_BLACK) && RDNS_NONE
describe    LIKE_SPAM2   LIKE: traditional spam
score       LIKE_SPAM2   3.2

# いまどき SPF ぐらいは・・・
meta        LIKE_BOT5    (SPF_FAIL || SPF_HELO_FAIL) && RDNS_NONE
describe    LIKE_BOT5    LIKE: bot spam?
score       LIKE_BOT5    1.2

# 残念だがRDNS-NONEは・・・
meta        LIKE_SPAM2   RDNS_NONE && FH_HELO_EQ_D_D_D_D
describe    LIKE_SPAM2   LIKE: SPF spam2
score       LIKE_SPAM2   2.9

# 短縮URL
body        BODY_BITLY  /\/\/bit\.ly\/.+/i 
describe    BODY_BITLY  LIKE: using bit.ly
score       BODY_BITLY  0.01

meta        LIKE_SPAM3  (INVALID_MSGID || MISSING_MID) && BODY_BITLY
describe    LIKE_SPAM3  LIKE: BIT spam
score       LIKE_SPAM3  0.75

# スパムその４
meta        LIKE_SPAM4  RDNS_NONE && (IP_LINK_PLUS || NORMAL_HTTP_TO_IP || SUBJECT_NEEDS_ENCODING)
describe    LIKE_SPAM4  LIKE: spam4
score       LIKE_SPAM4  0.75

# これも、まあスパムかな
meta        LIKE_SPAM5   RDNS_NONE && URIBL_BLACK
describe    LIKE_SPAM5   LIKE: SPF spam3
score       LIKE_SPAM5   2.3

# 海外のリレーからのスパムが度を越しているらしい
meta        LIKE_SPAM6   URIBL_BLACK && RDNS_NONE && (RCVD_IN_XBL || RCVD_IN_PSBL || RCVD_IN_RP_RNBL || RCVD_IN_PBL || RCVD_IN_BL_SPAMCOP_NET) && FSL_HELO_NON_FQDN_1
describe    LIKE_SPAM6   LIKE: MAJOR spam
score       LIKE_SPAM6   15.0

# この組み合わせ、アウトだろ
meta        LIKE_SPAM7   RDNS_NONE && INVALID_DATE
describe    LIKE_SPAM7   LIKE: I bet this is spam
score       LIKE_SPAM7   2.8

meta        LIKE_SPAM7   RDNS_NONE && HTML_MESSAGE
describe    LIKE_SPAM7   LIKE: may be this is spam
score       LIKE_SPAM7   1.2
