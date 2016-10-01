#################################################################
## @filename whitelist.inc
## @brief 取引先・友人・ビジネスレター・メーリングリスト等の
##    スパムでないと断言できるメールを設定する
#################################################################
##
## このページの設定は、使う人によって変わってくるので、
## 各人が自分の状況にあわせて設定してください
## 
#################################################################

#===============================================================
#   信頼のおけるネットワーク
#---------------------------------------------------------------
# ブーイング・・・アドレスしか指定できません
#  昔はアドレスじゃなくても設定できたような気がするのだが…
#---------------------------------------------------------------

#trusted_networks 212.17.35.
#trusted_networks impress.co.jp
#trusted_networks twave.co.jp
#trusted_networks sec.or.jp
#trusted_networks xmailserver.org
#trusted_networks xmailserver.jp
#trusted_networks spamassassin.jp

#===============================================================
#   送信アドレスと受信先によるホワイトリスト
#---------------------------------------------------------------
# 送信サーバなんて、負荷に応じて増強するだろうし、ハードの構成が
# 変更されれば、設定が意味を成さなくなる。個々のサーバを指定しな
# ければならないのは、ちょっと、しんどい
#---------------------------------------------------------------

#whitelist_from_rcvd *@twave.co.jp djv.twave.co.jp
#whitelist_from_rcvd *@xmailserver.org x35.xmailserver.org
#whitelist_from_rcvd *@ml.users.gr.jp ml1.firstserver.ne.jp
#whitelist_from_rcvd *@ml.users.gr.jp ml2.firstserver.ne.jp
#whitelist_from_rcvd *@ml.users.gr.jp ml3.firstserver.ne.jp
#whitelist_from_rcvd *@ml.users.gr.jp ml4.firstserver.ne.jp
#whitelist_from_rcvd *@ml.users.gr.jp ml5.firstserver.ne.jp
#whitelist_from_rcvd *@ml.users.gr.jp ml6.firstserver.ne.jp
#whitelist_from_rcvd *@ml.users.gr.jp ml7.firstserver.ne.jp
#whitelist_from_rcvd *@ml.users.gr.jp ml8.firstserver.ne.jp
#whitelist_from_rcvd *@ml.users.gr.jp ml9.firstserver.ne.jp

#===============================================================
#   送信アドレスによるホワイトリスト
#---------------------------------------------------------------
# 送信アドレス(From)なんか、なんぼでも偽装できまっせ…
# そういう観点から考えれば whitelist_from_rcvd の方が良いけど
# 無名なアドレスならば、使われる事もないかな？
#---------------------------------------------------------------

# whitelist_from *@xxxxxxxxx.go.jp
# whitelist_from *@xxxxxxxxx.ac.jp
# whitelist_from *@xxxxxxxxx.co.jp

