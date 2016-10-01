■はじめに
  このドキュメントは、2005/08/24 に書かれました。
ここに書かれてある内容は、古くなっている可能性があります。

  サポートはしませんが、何かありましたら blade2001jp@ybb.ne.jp まで
連絡ください。公開は http://www.hunes.co.jp/oki/xmail_spamc/ で行っています。

xmspamc は、SpamAssassin 3.0.2 の spamc.c をベースに改造されています。
xmail は、バージョン 1.2.0 以降で、SpamAssassin 3.0.2, 3.0.3, 3.0.4 
での動作を確認しています。

  windows 環境以外でも、コンパイルすれば xmail 用のフィルタとして
利用できると思いますが、xmspamc.c 内で パスを分解するのに _splitpath
というランタイム関数を利用しており、これは他のプラットフォームとは
互換性がないかもしれません。ビルドする場合は、SpamAssassin の spamc.c 
の代わりに xmspamc.c を利用するように makefile を書き換えてビルドを
行ってください。

■重要事項

  自己の責任において使用してください。

Perl は、C:\usr\Perl にインストールされているものとして spamd.bat を作成しています。

SpamAssassin の設定において C:\usr\Perl\site\etc\mail\spamassassin\local.cf において 
report_safe = 0 
という行の設定は、もはや不要になりました。

OutlookExpress 等のメールヘッダの詳細な項目に応じたフィルタ処理ができないものに
対しては、local.cf において、
rewrite_header Subject *****SPAM*****
という行を追加すれば、件名でフィルタ処理ができるようになります。

  spamassassin.tab 内で、オプションを指定する場合の注意点として、"-D 15.0" という
 書き方をするとエラーになります。"-D"<tab>"15.0" というようにスペース部分は分離して
 指定してください。

  XMailのフィルタ用 tab ファイルは、区切り文字に <tab> （タブ文字）を使用するので、
スペースを使うとフィルタが正しく動作しない点に注意してください。

  添付の Spamd.bat 内の記述にて、SET RES_NAMESERVERS=[dns ip address] (例: 192.168.1.1)
の記述を入れて、ocal.cf に dns_available yes の記述を行うと 確実にRBL のチェックを行って
くれるようです。


■変更履歴

ver 0.11
 2005/01/13 FIX -b オプションを指定しなくても、-b オプション扱いになっていた
ver 0.12
 2005/01/23 FIX spamd.bat 内のPerlへのパスが D:\Perl とデタラメだったのを修正
ver 0.2
 2005/08/20 FIX spamd.bat 内のコメントミスを修正（起動時のエラーメッセージが減った）
 2005/08/20 FIX XMail フィルタ用の返却値を 5 から 4 に修正（スプールしないように）
 2005/08/20 FIX spamassassin の local.cf で report_safe = 0 と指定しなくても良い
              ように修正
 2005/08/24 FIX 変更されたスプール・メールの最終２バイトをチェックし、LF のみの
              改行を CR+LF の組の改行に書き換え処理を追加（そうしないと、
              メーラがタイムアウトを引き起こす現象が発生したため）
 2005/08/26 Release 安定して稼動できそうなので、正式に公開
ver 0.21
 2005/08/31 ADD XMail フィルタ用の返却値 5, 4 (スプールする,しない）を選択できるように
              -P オプションを追加
ver 0.22
 2005/11/01 FIX 0.21 で混入したバグ（SPAMと判定された場合は、常に受信拒否状態になっていた）

■ xmspamc.exe

SpamAssassin Client Filter ver 0.22 for XMailServer
  based on spamc ver 3.0.2 mixed spamc ver 3.0.4

Usage: xmspamc [@@FILE] [tempdir] [options]

Options:
  -d host             Specify host to connect to.
                      [default: localhost]
  -H                  Randomize IP addresses for the looked-up
                      hostname.
  -p port             Specify port for connection to spamd.
                      [default: 783]
  -t timeout          Timeout in seconds for communications to
                      spamd. [default: 600]
  -s size             Specify maximum message size, in k-bytes.
                      [default: 250k]
  -u username         User for spamd to process this message under.
                      [default: current user]
  -x                  Don't fallback safely.
  -l                  Log errors and warnings to stderr.
  -D remove_score     Spam Score that reject and remove mail.
                      [default:11.0]
  -b                  Reject on error EX_TOOBIG and filterd IS_SPAM.
                      [default accept mail]
  -h                  Print this help message and exit.
  -V                  Print xmspamc version and exit.
  -P spool            Spool specification. 0 = without spool, 1 = spool
                      [default: 0]

===========================================================================
  @@FILE は、XMailServerFilter のパラメタです。

  tempdir は、一時的に出力するテンポラリファイル用のフォルダを
  指定してください。

  -D 15.0  というオプションで、スパム判定スコアが 15.0 以上の評価を受けた
  ものを受信拒否します。ただし、SpamAssassinのスレッシュホールド値
  （スパムと判定する設定値）以上でないと動作しません。デフォルトは 11.0 です。

  -s 4000 と指定すると 4000k バイトのメッセージを判定するようになりますが、
  毎回 4000k バイトのメモリを確保するので、実験した限りでは、よほど速い
  マシンでメモリをたくさん積んでいる環境以外では、処理が重すぎてハングした
  ように見えてしまいます。ですので、初期値の 250k バイトで運用する事を
  お勧めします。

  -b オプションは、上記 -s オプションで指定したサイズより大きいファイルだと、
  サイズが大きい事を示す EX_TOOBIG というエラーコードにより、スパム判定を
  行いませんので、これでは不都合もあるかな？と思い、このオプションを指定
  した場合、擬似的に途中までしか読み込んでいないメールの部分をフィルタに
  かけてスパムと判定定された場合に受信拒否をするオプションです。
  部分的にしかフィルタにかけないので、信頼のおけるものかどうかわかりません。
  よって、このオプションを指定しない場合は、通常と同じくエラーにより正常
  終了します。

■spamd.bat

spamd.bat は、SpamAssassin-3.0.2 に付属の /spamd/spamd.raw を 
http://wiki.apache.org/spamassassin/SpamdOnWindows
に書かれてある記事を元に変更したものです。

  Perl のインストール先が c:\usr\perl だと仮定して作成してあります
ので、他のフォルダにインストールした場合は、spamd.bat 内にある
c:/usr/perl を違うフォルダに置換して下さい。

  spamd.bat は、SpamAssassin のデーモンなので、常に実行させておく
必要があります。

SpamAssassin を windows 環境で使用する場合は
http://wiki.apache.org/spamassassin/InstallingOnWindows
を参考にインストールしてみてください。
http://www.hunes.co.jp/oki/xmail_spamc/InstallSpamAssassinOnWin32jp.html
に、同様の解説を載せていますので、そちらも参考にしてみてください。

■ spamassassin.tab
  XMailServer で、xmspamc.exe というフィルタを利用する場合の雛形です。
中身の Path_to_spamc は、xmspamc.exe を置いたフォルダへの絶対パス（フルパス）に
置き換えて利用してください。

Path_to_tempdir は、テンポラリ用のフォルダに置き換えてください。
テンポラリフォルダの最後に '\' マークは不要です。

  xmail/MailRoot/filters.in.tab に

"*"	"*"	"0.0.0.0/0"	"0.0.0.0/0"	spamassassin.tab

の一行を追加し、xmail/MailRoot/filters フォルダに
spamassassin.tab をコピーすればＯＫです。

