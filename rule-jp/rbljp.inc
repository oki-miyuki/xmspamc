#================================
# Using RBL-JP
#--------------------------------
# http://www.rbl.jp
#--------------------------------
header  RCVD_IN_ALL_RBL_JP   eval:check_rbl_txt('rbl.jp', 'all.rbl.jp.')
describe RCVD_IN_ALL_RBL_JP Received via a relay in all.rbl.jp
tflags RCVD_IN_ALL_RBL_JP   net
score RCVD_IN_ALL_RBL_JP 2.0

# 以下は http://fafdsafasd.domain.com/ を検知する定義
urirhssub URLBL_RBLJP url.rbl.jp. A 2
body URLBL_RBLJP eval:check_uridnsbl('URLBL_RBLJP')
describe URLBL_RBLJP Has URI in url.rbl.jp
tflags URLBL_RBLJP net
score URLBL_RBLJP 4.0

# 以下は http://62.231.95.161/ のようなIPアドレスだけのURLを検知する定義
uridnsbl URLBL_IP_RBLJP url.rbl.jp. TXT
body URLBL_IP_RBLJP eval:check_uridnsbl('URLBL_IP_RBLJP')
describe URLBL_IP_RBLJP Has IP URL in url.rbl.jp
tflags URLBL_IP_RBLJP net
score URLBL_IP_RBLJP 4.0

uridnsbl_skip_domain livedoor.com reset.jp asahi-net.or.jp hi-ho.ne.jp 2ch.net hatena.ne.jp
uridnsbl_skip_domain mixi.jp yahoo.co.jp

