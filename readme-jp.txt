■重要事項

  自己の責任において使用してください。

Perl は、C:\usr\Perl にインストールされているものとします。

SpamAssassin の設定において C:\usr\Perl\site\etc\mail\spamassassin\local.cf 
において

report_safe 0

というように・・・必ず・・・必ず・・・必ず・・・これを 0 に設定して下さい
また 行先頭の # は コメント・・・コメント・・・コメント・・・ですので、
絶対に！ report_safe 0 としてください。

  そうしないと、Spam と判定された場合の挙動は未定になり、メールが
無条件に削除されてしまいます！！！

■変更履歴

 2005/01/13 FIX -b オプションを指定しなくても、-b オプション扱いになっていた
 2005/01/23 FIX spamd.bat 内のPerlへのパスが D:\Perl とデタラメだったのを修正

■
  このドキュメントは、2005/01/11 に書かれました。
ここに書かれてある内容は、古くなっている可能性があります。

  サポートはしませんが、何かありましたら blade2001jp@ybb.ne.jp まで
連絡ください。

XMail-1.20
SpamAssassin 3.0.2

の環境において、spamc.exe を xmail のフィルタとして使用
できるように xmspamc.exe として変更を加えたものです。
中身は、xmspamc.c で、_splitpath という関数を利用しているので、
Windows 以外の環境では、xmspamc.c を修正する必要があります。
ビルドする場合は、spamc.c の代わりに xmspamc.c を使うように
してください。

■ xmspamc.exe

SpamAssassin Client for XMailServer Filter version 3.0.2

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
c:\usr\perl を違うフォルダに置換して下さい。

SpamAssassin-3.0.2 を windows 環境で使用する場合は
http://wiki.apache.org/spamassassin/InstallingOnWindows
を参考にインストールしてみてください。

■ spamassassin.tab
  利用する場合の雛形です。中身の Path_to_spamc は、
xmspamc.exe を置いたフォルダへの絶対パス（フルパス）に
置き換えて利用してください。

TEMPDIR は、テンポラリ用のフォルダに置き換えてください。
テンポラリフォルダの最後に '\' マークは不要です。

  xmail/MailRoot/filters.in.tab に

"*"	"*"	"0.0.0.0/0"	"0.0.0.0/0"	spamassassin.tab

の一行を追加し、xmail/MailRoot/filters フォルダに
spamassassin.tab をコピーすればＯＫです。

