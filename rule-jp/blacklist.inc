#################################################################
## @filename blacklist.inc
## @brief ブラック・リストなのか、どうなのか…若干コンセプトが
##    異なるけど、こんな判定ができるのも SPF のおかげ？
#################################################################

#-----------------------------------------------
#  melmedia.jp
#  デフォルトのホームページも無い。
#-----------------------------------------------
header     BLK_JP_MELMEDIA_RET    Return-Path =~ /.*\.melmedia\.jp/
describe   BLK_JP_MELMEDIA_RET    BLACK: MEDIA NET spam
score      BLK_JP_MELMEDIA_RET    4.0

body       BLK_JP_MELMEDIA_BODY   /.*\.melmedia\.jp.*/i
describe   BLK_JP_MELMEDIA_BODY   BLACK: MEDIA NET spam
score      BLK_JP_MELMEDIA_BODY   2.5

body       BLK_JP_MELMEDIA_BODY2  /.*prize-master\.com.*/i
describe   BLK_JP_MELMEDIA_BODY2  BLACK: MEDIA NET spam
score      BLK_JP_MELMEDIA_BODY2  2.5

#-----------------------------------------------
#  MEDIA NET spam 
#  何故、未承諾広告を付けないのかな？
#-----------------------------------------------
#  http://www.prize-master.com/ は、http://www.media-nets.com に転送
header     BLK_JP_MEDIANET_FROM   From:addr =~ /.*(\.|\@)prize-master\.com/i
describe   BLK_JP_MEDIANET_FROM   BLACK: MEDIA NET spam
score      BLK_JP_MEDIANET_FROM   25.0

header     BLK_JP_MEDIANET_FROM5  From:addr =~ /.*(\.|\@)mail-mag\.info/i
describe   BLK_JP_MEDIANET_FROM5  BLACK: MEDIA NET spam
score      BLK_JP_MEDIANET_FROM5  2.5

header     BLK_JP_MEDIANET_FROM2  From =~ /.*懸.*賞.*マ.*ス.*タ.*/
describe   BLK_JP_MEDIANET_FROM2  BLACK: MEDIA NET spam
score      BLK_JP_MEDIANET_FROM2  25.0

header     BLK_JP_MEDIANET_FROM3  From =~ /.*ス.*ピ.*ー.*ド.*く.*じ.*/
describe   BLK_JP_MEDIANET_FROM3  BLACK: MEDIA NET spam
score      BLK_JP_MEDIANET_FROM3  25.0

header     BLK_JP_MEDIANET_FROM4  From =~ /.*イ.*ー.*チ.*ャ.*ン.*ス.*★.*モ.*バ.*イ.*ル.*/
describe   BLK_JP_MEDIANET_FROM4  BLACK: MEDIA NET spam
score      BLK_JP_MEDIANET_FROM4  25.0

header     BLK_JP_MEDIANET_FROM6  From =~ /.*チ.*ャ.*ン.*ス.*ナ.*ビ.*事.*務.*局.*/
describe   BLK_JP_MEDIANET_FROM6  BLACK: MEDIA NET spam
score      BLK_JP_MEDIANET_FROM6  2.5

header     BLK_JP_MEDIANET_FROM7  From =~ /.*ホ.*ッ.*ト.*ナ.*ビ.*事.*務.*局.*/
describe   BLK_JP_MEDIANET_FROM7  BLACK: MEDIA NET spam
score      BLK_JP_MEDIANET_FROM7  2.5

#-----------------------------------------------
#  他 
#-----------------------------------------------
body      BLK_JP_ZERBINO_BODY   /.*(\.|\/)zerbino\.jp.*/i
describe  BLK_JP_ZERBINO_BODY   BLACK: zerbino spam
score     BLK_JP_AERBINO_BODY   2.5

header    BLK_JP_ZERBINO_FROM   From:addr =~ /.*(\.|\@)zerbino\.jp/i
describe  BLK_JP_ZERBINO_FROM   BLACK: zerbino spam
score     BLK_JP_ZERBINO_FROM   3.5

body      BLK_JP_LAVU_BODY      /.*(\.|\/)lav-u\.com.*/i
describe  BLK_JP_LAVU_BODY      BLACK: lavu spam
score     BLK_JP_LAVU_BODY      2.5

body      BLK_JP_COBALT_BODY    /.*\@cobalt\d\d\.com/i
describe  BLK_JP_COBALT_BODY    BLACK: cobalt spam
score     BLK_JP_COBALT_BODY    2.5

header    BLK_JP_COBALT_FROM    From:addr =~ /.*\@cobalt\d\d\.com/i
describe  BLK_JP_COBALT_FROM    BLACK: cobalt spam
score     BLK_JP_COBALT_FROM    25.0

body      BLK_JP_STRAP_BODY     /.*\strapya\.com/i
describe  BLK_JP_STRAP_BODY     BLACK: strapya spam
score     BLK_JP_STRAP_BODY     1.5

header    BLK_JP_STRAP_FROM     From:addr =~ /.*\@strapya\.com/i
describe  BLK_JP_STRAP_FROM     BLACK: strapya spam
score     BLK_JP_STRAP_FROM     25.0
# NittoGikenTechno Corp,lnc.
body      BLK_JP_URLC_BODY      /.*(\.|\/)url-c\.jp.*/i
describe  BLK_JP_URLC_BODY      BLACK: MEDIA NET spam
score     BLK_JP_URLC_BODY      2.5
# Tanaka  Takasi
body      BLK_JP_AILAND_BODY    /.*(\.|\/)like-ailand\.info.*/i
describe  BLK_JP_AILAND_BODY    BLACK: like-ailand spam
score     BLK_JP_AILAND_BODY    2.5
# Hiroshi Ishikawa
body      BLK_JP_APGET_BODY     /.*(\.|\/)apget\.jp.*/i
describe  BLK_JP_APGET_BODY     BLACK: MEDIA NET spam
score     BLK_JP_APGET_BODY     2.5

