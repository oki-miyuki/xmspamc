#################################################################
## @filename isp.inc
## @brief プロバイダから送信されるメールの特徴を元にしたルール
#################################################################
##
## スパマーにとって、既知であるプロバイダから送信されたメールを
## 装うのは、一般人に安心感を与えるという効果が期待されるから
## …と勝手に推察。これらを撲滅する事には、それなりの意義がある
## 
#################################################################

##
## INVALID_XXX_MSGID は、プラグインにして、
## From: タグと、Message-ID: タグの後ろ(@以降等)を比較して
## マッチするかどうかという関数を EvalTests.pm に書いて、
## eval:from_and_msgid_match()
## なんて風にした方がスマートか？
##
## 断っておくが、プロバイダがメールのMessage-IDを付加する方法を
## 変更する可能性は、いつの時期でも十分にある。
## 本ルールは、それを承知の上で定義したものである。
##
## どうも、ルールのスコアは <> 0.0 でないと、meta ルールも
## 該当しないようである。仕様と考えた方が良い？
##

#=================================================================
#  Yahoo
#-----------------------------------------------------------------
# yahoo.co.jp
header    JP_YAHOO1  From:addr =~ /.*\@yahoo\.co\.jp/i
describe  JP_YAHOO1  ISP: From JP_YAHOO(yahoo)
score     JP_YAHOO1  0.001

header    JP_YAHOO1_REPLY Reply-To:addr =~ /.*\@yahoo\.co\.jp/i
describe  JP_YAHOO1_REPLY ISP: Reply-To JP_YAHOO(yahoo)
score     JP_YAHOO1_REPLY 0.001

# ybb.ne.jp
header    JP_YAHOO2 From:addr =~ /.*\@ybb\.ne\.jp/i
describe  JP_YAHOO2 ISP: From JP_YAHOO(ybb)
score     JP_YAHOO2 0.001

header    JP_YAHOO2_REPLY Reply-To:addr =~ /.*\@ybb\.ne\.jp/i
describe  JP_YAHOO2_REPLY ISP: From JP_YAHOO(ybb)
score     JP_YAHOO2_REPLY 0.001

# both yahoo.co.jp and ybb.ne.jp
meta      JP_YAHOO  (JP_YAHOO1 || JP_YAHOO2)
describe  JP_YAHOO  ISP: From JP_YAHOO
score     JP_YAHOO  -0.001

meta      JP_YAHOO_REPLY  (JP_YAHOO1_REPLY || JP_YAHOO2_REPLY)
describe  JP_YAHOO_REPLY  ISP: Reply-To JP_YAHOO
score     JP_YAHOO_REPLY  -0.001

#yahoo.com
header    US_YAHOO  From:addr =~ /.*\@yahoo\.com/i
describe  US_YAHOO  ISP: From US_YAHOO
score     US_YAHOO  0.001

header    US_YAHOO_REPLY  Reply-To:addr =~ /.*\@yahoo\.com/i
describe  US_YAHOO_REPLY  ISP: Reply-To US_YAHOO
score     US_YAHOO_REPLY  0.001

# Message-ID
header    JP_YAHOO_MSGID Message-ID =~ /<.*\.yahoo\.co\.jp>/
describe  JP_YAHOO_MSGID ISP: MID YAHOO JP
score     JP_YAHOO_MSGID -0.001

header    US_YAHOO_MSGID Message-ID =~ /<.*\.yahoo\.com>/
describe  US_YAHOO_MSGID ISP: MID YAHOO US
score     US_YAHOO_MSGID -0.001

meta      INVALID_JP_YAHOO_MSGID   !JP_YAHOO_MSGID && JP_YAHOO
describe  INVALID_JP_YAHOO_MSGID   ISP: Not YAHOO JP MID
score     INVALID_JP_YAHOO_MSGID   1.0

meta      INVALID_US_YAHOO_MSGID   !US_YAHOO_MSGID && US_YAHOO
describe  INVALID_US_YAHOO_MSGID   ISP: Not YAHOO US MID
score     INVALID_US_YAHOO_MSGID   1.0

#=================================================================
#  Goo
#-----------------------------------------------------------------
# mail.goo.ne.jp
header    JP_GOO    From:addr =~ /.*\@mail\.goo\.ne\.jp/i
describe  JP_GOO    ISP: From JP_GOO
score     JP_GOO    0.001

header    JP_GOO_REPLY    Reply-To:addr =~ /.*\@mail\.goo\.ne\.jp/i
describe  JP_GOO_REPLY    ISP: Reply-To JP_GOO
score     JP_GOO_REPLY    0.001

# Message-ID
header    JP_GOO_MSGID   Message-ID =~ /<.*\@mail\.goo\.ne\.jp>/
describe  JP_GOO_MSGID   ISP: MID JP_GOO
score     JP_GOO_MSGID   -0.001

meta      INVALID_JP_GOO_MSGID     !JP_GOO_MSGID && JP_GOO
describe  INVALID_JP_GOO_MSGID     ISP: Not GOO MID
score     INVALID_JP_GOO_MSGID     1.5

#=================================================================
#  Excite
#-----------------------------------------------------------------
# excite.co.jp
header    JP_EXCITE   From:addr =~ /.*\@excite\.co\.jp/i
describe  JP_EXCITE   ISP: From JP_EXCITE
score     JP_EXCITE   0.001

header    JP_EXCITE_REPLY   Reply-To:addr =~ /.*\@excite\.co\.jp/i
describe  JP_EXCITE_REPLY   ISP: Reply-To JP_EXCITE
score     JP_EXCITE_REPLY   0.001

# Message-ID
header    JP_EXCITE_MSGID   Message-ID =~ /<.*\.mail\.excite\.co\.jp>/
describe  JP_EXCITE_MSGID   ISP: MID JP_EXCITE
score     JP_EXCITE_MSGID   -0.001

meta      INVALID_JP_EXCITE_MSGID     !JP_EXCITE_MSGID && JP_EXCITE
describe  INVALID_JP_EXCITE_MSGID     ISP: Not EXCITE MID
score     INVALID_JP_EXCITE_MSGID     1.5

#=================================================================
#  Docomo
#-----------------------------------------------------------------
# docomo.ne.jp
header    JP_DOCOMO   From:addr =~ /.*\@docomo\.ne\.jp/i
describe  JP_DOCOMO   ISP: From JP_DOCOMO
score     JP_DOCOMO   0.001

header    JP_DOCOMO_REPLY   Reply-To:addr =~ /.*\@docomo\.ne\.jp/i
describe  JP_DOCOMO_REPLY   ISP: Reply-To JP_DOCOMO
score     JP_DOCOMO_REPLY   0.001

# Message-ID
header    JP_DOCOMO_MSGID   Message-ID =~ /<.*\@docomo\.ne\.jp>/
describe  JP_DOCOMO_MSGID   ISP: MID JP_DOCOMO
score     JP_DOCOMO_MSGID   -0.001

meta      INVALID_JP_DOCOMO_MSGID     !JP_DOCOMO_MSGID && JP_DOCOMO
describe  INVALID_JP_DOCOMO_MSGID     ISP: Not DOCOMO MID
score     INVALID_JP_DOCOMO_MSGID     1.5

#=================================================================
#  AU
#-----------------------------------------------------------------
# ezweb.ne.jp
header    JP_EZWEB   From:addr =~ /.*\@ezweb\.ne\.jp/i
describe  JP_EZWEB   ISP: From JP_EZWEB
score     JP_EZWEB   0.001

header    JP_EZWEB_REPLY   Reply-To:addr =~ /.*\@ezweb\.ne\.jp/i
describe  JP_EZWEB_REPLY   ISP: Reply-To JP_EZWEB
score     JP_EZWEB_REPLY   0.001

# Message-ID
header    JP_EZWEB_MSGID   Message-ID =~ /<.*\.ezweb\.ne\.jp>/
describe  JP_EZWEB_MSGID   ISP: MID JP_EZWEB
score     JP_EZWEB_MSGID   -0.001

meta      INVALID_JP_EZWEB_MSGID     !JP_EZWEB_MSGID && JP_EZWEB
describe  INVALID_JP_EZWEB_MSGID     ISP: Not EZWEB MID
score     INVALID_JP_EZWEB_MSGID     1.5

#=================================================================
#  Softbank
#-----------------------------------------------------------------
# softbank.jp
header    JP_SOFTBANK  From:addr =~ /.*\@i\.softbank\.jp>/
describe  JP_SOFTBANK  ISP: From JP_SOFTBANK
score     JP_SOFTBANK  0.001

header    JP_SOFTBANK_REPLY  Reply-To:addr =~ /.*\@i\.softbank\.jp>/
describe  JP_SOFTBANK_REPLY  ISP: Reply-To JP_SOFTBANK
score     JP_SOFTBANK_REPLY  0.001

header    JP_SOFTBANK_MSGID   Message-ID =~ /<.*\@i\.softbank\.jp>/
describe  JP_SOFTBANK_MSGID   ISP: MID JP_SOFTBANK
score     JP_SOFTBANK_MSGID   -0.001

meta      INVALID_JP_SOFTBANK_MSGID     !JP_SOFTBANK_MSGID && JP_SOFTBANK
describe  INVALID_JP_SOFTBANK_MSGID     ISP: Not SOFTBANK MID
score     INVALID_JP_SOFTBANK_MSGID     1.5


#=================================================================
#  Nifty
#-----------------------------------------------------------------
# nifty.com
header	  JP_NIFTY    From:addr =~ /.*\@nifty\.com/i
describe  JP_NIFTY    ISP: From NIFTY
score     JP_NIFTY    0.001

header	  JP_NIFTY_REPLY    Reply-To:addr =~ /.*\@nifty\.com/i
describe  JP_NIFTY_REPLY    ISP: Reply-To NIFTY
score     JP_NIFTY_REPLY    0.001

# Message-ID
header	  JP_NIFTY_MSGID   Message-ID =~ /<.*\@nifty\.com>/
describe  JP_NIFTY_MSGID   ISP: MID NIFTY
score     JP_NIFTY_MSGID   -0.001

meta      INVALID_JP_NIFTY_MSGID   !JP_NIFTY_MSGID && JP_NIFTY
describe  INVALID_JP_NIFTY_MSGID   ISP: Not NIFTY MID
score     INVALID_JP_NIFTY_MSGID   1.5

#=================================================================
#  hi-ho
#-----------------------------------------------------------------
# hi-ho.ne.jp
header	  JP_HIHO    From:addr =~ /.*\@hi-ho\.ne\.jp/i
describe  JP_HIHO    ISP: From HIHO
score     JP_HIHO    0.001

header	  JP_HIHO_REPLY    Reply-To:addr =~ /.*\@hi-ho\.ne\.jp/i
describe  JP_HIHO_REPLY    ISP: Reply-To HIHO
score     JP_HIHO_REPLY    0.001

# Message-ID
header	  JP_HIHO_MSGID   Message-ID =~ /<.*\@hi-ho\.ne\.jp>/
describe  JP_HIHO_MSGID   ISP: MID HIHO
score     JP_HIHO_MSGID   -0.001

meta      INVALID_JP_HIHO_MSGID   !JP_HIHO_MSGID && JP_HIHO
describe  INVALID_JP_HIHO_MSGID   ISP: Not HIHO MID
score     INVALID_JP_HIHO_MSGID   1.5

#=================================================================
#  Gmail
#-----------------------------------------------------------------
# 今や Gmail はスパム避けメールアドレスとして利用するのが
# トレンドのようで、From を gmail で名乗るパターンのhamメールも
# 現実問題として多数存在する。よってスコアは少し低め
#-----------------------------------------------------------------
# gmail.com
header    US_GMAIL    From:addr =~ /.*\@gmail\.com/i
describe  US_GMAIL    ISP: From GMAIL
score     US_GMAIL    0.001

header    US_GMAIL_REPLY    Reply-To:addr =~ /.*\@gmail\.com/i
describe  US_GMAIL_REPLY    ISP: Reply-To GMAIL
score     US_GMAIL_REPLY    0.001

# Message-ID
header    US_GMAIL_MSGID   Message-ID =~ /<.*\.gmail\.com>/
describe  US_GMAIL_MSGID   ISP: MID GMAIL
score     US_GMAIL_MSGID   -0.001

meta      INVALID_US_GMAIL_MSGID   !US_GMAIL_MSGID && US_GMAIL
describe  INVALID_US_GMAIL_MSGID   ISP: Not GMAIL MID 
score     INVALID_US_GMAIL_MSGID   0.7

# Message-Check
meta      SPAMMERS_US_GMAIL_MSG    US_GMAIL && MIME_HTML_ONLY
describe  SPAMMERS_US_GMAIL_MSG    ISP: Spammer s GMAIL MSG
score     SPAMMERS_US_GMAIL_MSG    1.0

#=================================================================
#  HOTMAIL
#-----------------------------------------------------------------
# 昔は、????@hotmail.com という Message-ID パターンだった？
# フリーメールでは老舗なので、From を hotmail で名乗るパターン
# のhamメールも現実問題として多数存在する。よってスコアは少し低め
#-----------------------------------------------------------------
# hotmail.co.jp
header    JP_HOTMAIL    From:addr =~ /.*\@hotmail\.co\.jp/i
describe  JP_HOTMAIL    ISP: From JP HOTMAIL
score     JP_HOTMAIL    0.001

header    JP_HOTMAIL_REPLY    Reply-To:addr =~ /.*\@hotmail\.co\.jp/i
describe  JP_HOTMAIL_REPLY    ISP: Reply-To JP HOTMAIL
score     JP_HOTMAIL_REPLY    0.001

# hotmail.com
header    US_HOTMAIL    From:addr =~ /.*\@hotmail\.com/i
describe  US_HOTMAIL    ISP: From US HOTMAIL
score     US_HOTMAIL    0.001

header    US_HOTMAIL_REPLY    Reply-To:addr =~ /.*\@hotmail\.com/i
describe  US_HOTMAIL_REPLY    ISP: Reply-To US HOTMAIL
score     US_HOTMAIL_REPLY    0.001

# msn.com
header    US_MSN        From:addr =~ /.*\@msn\.com/i
describe  US_MSN        ISP: From US MSN
score     US_MSN        0.001

header    US_MSN_REPLY        Reply-To:addr =~ /.*\@msn\.com/i
describe  US_MSN_REPLY        ISP: Reply-To US MSN
score     US_MSN_REPLY        0.001

# hotmail
meta      HOTMAIL   JP_HOTMAIL || US_HOTMAIL || US_MSN
describe  HOTMAIL   ISP: From HOTMAIL
score     HOTMAIL   -0.001

meta      HOTMAIL_REPLY   JP_HOTMAIL_REPLY || US_HOTMAIL_REPLY || US_MSN_REPLY
describe  HOTMAIL_REPLY   ISP: Reply-To HOTMAIL
score     HOTMAIL_REPLY   -0.001


# Message-ID
header    HOTMAIL_MSGID   Message-ID =~ /<BAY.*\@phx\.gbl>/
describe  HOTMAIL_MSGID   ISP: MID HOTMAIL
score     HOTMAIL_MSGID   -0.001

meta      INVALID_HOTMAIL_MSGID     !HOTMAIL_MSGID && HOTMAIL
describe  INVALID_HOTMAIL_MSGID     ISP: Not HOTMAIL MID
score     INVALID_HOTMAIL_MSGID     0.5

#=================================================================
#  IIJ4u
#-----------------------------------------------------------------
# iij4u.or.jp
header    JP_IIJ4U    From:addr =~ /.*\.iij4u\.or\.jp/i
describe  JP_IIJ4U    ISP: From IIJ4U
score     JP_IIJ4U    0.001

header    JP_IIJ4U_REPLY    From:addr =~ /.*\.iij4u\.or\.jp/i
describe  JP_IIJ4U_REPLY    ISP: Reply-To IIJ4U
score     JP_IIJ4U_REPLY    0.001

# Message-ID
header    JP_IIJ4U_MSGID   Message-ID =~ /<.*\.iij4u\.or\.jp>/
describe  JP_IIJ4U_MSGID   ISP: MID IIJ4U
score     JP_IIJ4U_MSGID   -0.001

meta      INVALID_JP_IIJ4U_MSGID     !JP_IIJ4U_MSGID && JP_IIJ4U
describe  INVALID_JP_IIJ4U_MSGID     ISP: Not IIJ4U MID
score     INVALID_JP_IIJ4U_MSGID     1.5

#=================================================================
#  rim.or.jp
#-----------------------------------------------------------------
# rim.or.jp
header    JP_RIM    From:addr =~ /.*\.rim\.or\.jp/i
describe  JP_RIM    ISP: From RIM
score     JP_RIM    0.001

header    JP_RIM_REPLY    Reply-To:addr =~ /.*\.rim\.or\.jp/i
describe  JP_RIM_REPLY    ISP: Reply-To RIM
score     JP_RIM_REPLY    0.001

# Message-ID
header    JP_RIM_MSGID   Message-ID =~ /<.*\.rim\.or\.jp>/
describe  JP_RIM_MSGID   ISP: MID RIM
score     JP_RIM_MSGID   -0.001

meta      INVALID_JP_RIM_MSGID     !JP_RIM_MSGID && JP_RIM
describe  INVALID_JP_RIM_MSGID     ISP: Not RIM MID
score     INVALID_JP_RIM_MSGID     1.5

#=================================================================
#  GMO
#-----------------------------------------------------------------
# interq.or.jp
header    JP_GMO    From:addr =~ /.*\.interq\.or\.jp/i
describe  JP_GMO    ISP: From GMO
score     JP_GMO    0.001

header    JP_GMO_REPLY    Reply-To:addr =~ /.*\.interq\.or\.jp/i
describe  JP_GMO_REPLY    ISP: Reply-To GMO
score     JP_GMO_REPLY    0.001

# Message-ID
header    JP_GMO_MSGID   Message-ID =~ /<.*\.interq\.or\.jp>/
describe  JP_GMO_MSGID   ISP: MID GMO
score     JP_GMO_MSGID   -0.001

meta      INVALID_JP_GMO_MSGID     !JP_GMO_MSGID && JP_GMO
describe  INVALID_JP_GMO_MSGID     ISP: Not GMO MID
score     INVALID_JP_GMO_MSGID     1.5

#=================================================================
#  Infoseek
#-----------------------------------------------------------------
# infoseek.jp
header    JP_INFOSEEK    From:addr =~ /.*\@infoseek\.jp/i
describe  JP_INFOSEEK    ISP: From INFOSEEK
score     JP_INFOSEEK    0.001

header    JP_INFOSEEK_REPLY    Reply-To:addr =~ /.*\@infoseek\.jp/i
describe  JP_INFOSEEK_REPLY    ISP: Reply-To INFOSEEK
score     JP_INFOSEEK_REPLY    0.001

# Message-ID
header    JP_INFOSEEK_MSGID   Message-ID =~ /<.*\@infoseek\.jp>/
describe  JP_INFOSEEK_MSGID   ISP: MID INFOSEEK
score     JP_INFOSEEK_MSGID   -0.001

meta      INVALID_JP_INFOSEEK_MSGID     !JP_INFOSEEK_MSGID && JP_INFOSEEK
describe  INVALID_JP_INFOSEEK_MSGID     ISP: Not INFOSEEK MID
score     INVALID_JP_INFOSEEK_MSGID     1.5


#=================================================================
#  163.com
#-----------------------------------------------------------------
# 気になって調べてみたら、SPFにも対応しているし、まじめに
# 運営していそうな感じなので追加
header    CN_163       From:addr =~ /.*\@163\.com/i
describe  CN_163       ISP: From 163
score     CN_163       0.001

# Message-ID
header    CN_163_MSGID   Message-ID =~ /<.*\.163\.com>/
describe  CN_163_MSGID   ISP: MID 163
score     CN_163_MSGID   -0.001

meta      INVALID_CN_163_MSGID   !CN_163_MSGID && CN_163
describe  INVALID_CN_163_MSGID   ISP: Not 163 MID
score     INVALID_CN_163_MSGID   1.0 

#  126.com
#headerr   CN_126       From:addr =~ /.*\@126.com/i
#describe  CN_126       ISP: From 126
#score     CN_126       0.001

#header    CN_126_MSGID   Message-ID =~ /<.*\.126\.com>/
#describe  CN_126_MSGID   ISP: MID 126
#score     CN_126_MSGID   -0.001

#meta      INVALID_CN_126_MSGID   !CN_126_MSGID && CN_126
#describe  INVALID_CN_126_MSGID   ISP: Not 126 MID
#score     INVALID_CN_126_MSGID   1.0

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#  About Fake Spammer
#-----------------------------------------------------------------
# fake jp
header    JP_FAKE_MSGID      Message-ID =~ /<.*\.co\.jp\..+>/
describe  JP_FAKE_MSGID      ISP: MID Fake jp
score     JP_FAKE_MSGID      0.3
# fake jp mail
header    JP_FAKE_FROM       From:addr =~ /.*\.co\.jp\..+/iheader
describe  JP_FAKE_FROM       ISP: FROM Fake jp
score     JP_FAKE_FROM       0.7
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#  About Mailer Service Provider
#-----------------------------------------------------------------
# blayn.com
header    JP_BLAYN_MSGID    Message-ID =~ /<.*\.blayn\.com>/
describe  JP_BLAYN_MSGID    ISP: MID BLAYN
score     JP_BLAYN_MSGID    -0.001
# combzmail.jp
header    JP_COMBZMAIL_MSGID  Message-ID =~ /<.*\.combzmail\.jp>/
describe  JP_COMBZMAIL_MSGID  ISP: MID COMBZMAIL
score     JP_COMBZMAIL_MSGID  -0.001
# coreserver.jp フリー・放置プレー・スコアは少し上げときます
# つか、スパム支援サイトじゃねーの？
header    JP_CORESERVER_MSGID  Message-ID =~ /<.*\.coreserver\.jp>/
describe  JP_CORESERVER_MSGID  ISP: MID CORESERVER
score     JP_CORESERVER_MSGID  0.9
# smp.ne.jp
header    JP_SPIRAL_MSGID   Message-ID =~ /<.*\.smp\.ne\.jp>/
describe  JP_SPIRAL_MSGID   ISP: MID SPIRAL
score     JP_SPIRAL_MSGID  -0.001
# shopserve.jp スパム対策に消極的な印象（直感）
header    JP_SHOPSERVE_MSGID  Message-ID =~ /<.*\.shopserve\.jp>/
describe  JP_SHOPSERVE_MSGID  ISP: MID SHOPSERVE
score     JP_SHOPSERVE_MSGID  3.5
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#  About Mailer Service Provider 別格扱い
#-----------------------------------------------------------------
# bizmail.jp  スパムの巣窟（ほぼスパム）
header    JP_BIZMAIL_MSGID  Message-ID =~ /<.*\.bizmail\.jp>/
describe  JP_BIZMAIL_MSGID  ISP: MID BIZMAIL
score     JP_BIZMAIL_MSGID  4.0
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#  About Mailer Service Tool
#-----------------------------------------------------------------
# forcast.jp
header    JP_FORCAST_MSGID    Message-ID =~ /<.*\.forcast\@.*>/
describe  JP_FORCAST_MSGID    ISP: MID FORCAST
score     JP_FORCAST_MSGID    -0.001

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#  About Message-ID
#-----------------------------------------------------------------
# Message-IDをちゃんと付加するプロバイダ
meta     ISP_APPEND_MSGID  JP_YAHOO || US_YAHOO || JP_GOO || JP_NIFTY || US_GMAIL || JP_IIJ4U || JP_GMO || JP_INFOSEEK || HOTMAIL || JP_RIM || JP_EXCITE || JP_DOCOMO || JP_EZWEB || JP_SOFTBANK || JP_HIHO || CN_163 # || CN_126
describe ISP_APPEND_MSGID  ISP: Valid MID provider
score    ISP_APPEND_MSGID  -0.001

meta     ISP_REPLY  JP_YAHOO_REPLY || US_YAHOO_REPLY || JP_GOO_REPLY || JP_NIFTY_REPLY || US_GMAIL_REPLY || JP_IIJ4U_REPLY || JP_GMO_REPLY || JP_INFOSEEK_REPLY || HOTMAIL_REPLY || JP_RIM_REPLY || JP_EXCITE_REPLY || JP_DOCOMO_REPLY || JP_EZWEB_REPLY || JP_SOFTBANK_REPLY || JP_HIHO_REPLY || CN_163_REPLY # || CN_126_REPLY
describe ISP_REPLY  ISP: Reply-To is a provider
score    ISP_REPLY  -0.001

# 成りすましメール（MessageID 判定) 
# Message-ID ヘッダを付加するプロバイダからのメールなのに、
# Message-ID が付加されていない。メールの規格上は Message-ID は
# 必須なので、MISSING_MID だけの判定でも良さそうであるが、
# 実世界に流通しているメールでは、これが守られていないため
# MISSING_MID != スパム である。
meta     INVALID_ISP_MSGID      MISSING_MID && ISP_APPEND_MSGID
describe INVALID_ISP_MSGID      ISP: fake mail by MID
score    INVALID_ISP_MSGID      2.5

# Message-IDをちゃんと付加するメーラサービス・ツールは除外しても
# 良いのでは？というのは間違い。ＭＬにおいても、送信者が付加した
# 正規の Message-ID を書き換えるなんて、ナンセンスであり、
# 悪意ありと見なして良いと思う。
meta     MSP_APPEND_MSGID   JP_BLAYN_MSGID || JP_COMBZMAIL_MSGID || JP_CORESERVER_MSGID || JP_SPIRAL_MSGID || JP_FORCAST_MSGID || JP_SHOPSERVE_MSGID
describe MSP_APPEND_MSGID   ISP: Valid Mailer MID provider
score    MSP_APPEND_MSGID   0.001

# 成りすましメール（MessageID 判定)
# メーラ・サービスを利用したスパムメール
# スパム業者さん、がんばってるので、ご褒美としてスコアを分離
meta     INVALID_ISP_MSP_MSGID     MSP_APPEND_MSGID && ISP_APPEND_MSGID
describe INVALID_ISP_MSP_MSGID     ISP: fake mail by Mailer Service Provider
score    INVALID_ISP_MSP_MSGID     4.0

# メーラ・サービス・プロバイダによる形骸化したSPFを弾く。
# ちゃんと運営してください。SPAM業者を支援して知らん顔を
# して、お金貰ってるからいいもんねという態度をとり続ける
# 場合には、ブラックリストの刑に処します。
meta     ISP_MSP_ASSIST_SPAM     MSP_APPEND_MSGID && SPF_HELO_PASS && !SPF_PASS
describe ISP_MSP_ASSIST_SPAM     ISP: Crack bone SPF_HELO only MSP
score    ISP_MSP_ASSIST_SPAM     3.5

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#  About SPF
#-----------------------------------------------------------------
# SPF をサポートするプロバイダからのメール
#  プロバイダが SPF をサポートしているかどうかは、
#  command> nslookup -type=TXT provider.com
# を実行すればわかる。
meta     ISP_SUPPORT_SPF  JP_YAHOO || JP_GOO || JP_NIFTY || US_GMAIL || JP_GMO || JP_IIJ4U || HOTMAIL || JP_EXCITE || JP_DOCOMO || JP_EZWEB || JP_SOFTBANK || JP_HIHO || CN_163 # || CN_126
describe ISP_SUPPORT_SPF  ISP: SPF supported provider
score    ISP_SUPPORT_SPF  -0.001

# ML の設定によっては、まだ問題がある。
# SPF は Envelope-from, Return-Path を判定するが
# これらをちゃんとしていないMLでは、このルールに引っかかってしまう。
# 2008年2月の時点では、このルールがとても有効に働くのだが、諸刃の剣である。
# ちゃんとしていないMLは、whitelist_from_rcvd 等のルールをメンテナンスしたい。
# スコアを上げるのであれば、この問題を把握した上で行ってほしい。
#  ちなみに、何の関係も無い From を見ているが、これは意図的に行っている事で
#  バグではない。
# 成りすましメール (SPF 判定)
meta     INVALID_ISP_FROM  ISP_SUPPORT_SPF && (SPF_FAIL || SPF_SOFTFAIL || SPF_HELO_SOFTFAIL)
describe INVALID_ISP_FROM  ISP: fake mail by SPF
score    INVALID_ISP_FROM  1.5

# SPF_HELO_PASS は、あまり信用ならない感じがするので、SPF_PASS にこだわってみた。
# 上記同様の問題を抱えている。スコアは、やや低め
meta     INVALID_ISP_FAKE_FROM  ISP_SUPPORT_SPF && !(SPF_PASS)
describe INVALID_ISP_FAKE_FROM  ISP: fogged fake mail by SPF
score    INVALID_ISP_FAKE_FROM  1.0

# ボットっぽい偽ISPメールのスコアを追加
meta     LIKE_BOT_ISP_FAKE_FROM INVALID_ISP_FAKE_FROM && RDNS_NONE
describe LIKE_BOT_ISP_FAKE_FROM ISP: fogged fake mail by SPF & RDNS
score    LIKE_BOT_ISP_FAKE_FROM 0.5

# SPFにちゃんと対応して、Reply-To をちゃんと指定する努力賞の
# スパマーさんに、手土産
meta     ISP_REPLY_TO_SPAM  INVALID_ISP_FAKE_FROM && ISP_REPLY
describe ISP_REPLY_TO_SPAM  ISP: Bronze medal to the spammer
score    ISP_REPLY_TO_SPAM  3.8

