���d�v����

  ���Ȃ̐ӔC�ɂ����Ďg�p���Ă��������B

Perl �́AC:\usr\Perl �ɃC���X�g�[������Ă�����̂Ƃ��܂��B

SpamAssassin �̐ݒ�ɂ����� C:\usr\Perl\site\etc\mail\spamassassin\local.cf 
�ɂ�����

report_safe 0

�Ƃ����悤�ɁE�E�E�K���E�E�E�K���E�E�E�K���E�E�E����� 0 �ɐݒ肵�ĉ�����
�܂� �s�擪�� # �� �R�����g�E�E�E�R�����g�E�E�E�R�����g�E�E�E�ł��̂ŁA
��΂ɁI report_safe 0 �Ƃ��Ă��������B

  �������Ȃ��ƁASpam �Ɣ��肳�ꂽ�ꍇ�̋����͖���ɂȂ�A���[����
�������ɍ폜����Ă��܂��܂��I�I�I

���ύX����

 2005/01/13 FIX -b �I�v�V�������w�肵�Ȃ��Ă��A-b �I�v�V���������ɂȂ��Ă���
 2005/01/23 FIX spamd.bat ����Perl�ւ̃p�X�� D:\Perl �ƃf�^�����������̂��C��

��
  ���̃h�L�������g�́A2005/01/11 �ɏ�����܂����B
�����ɏ�����Ă�����e�́A�Â��Ȃ��Ă���\��������܂��B

  �T�|�[�g�͂��܂��񂪁A��������܂����� blade2001jp@ybb.ne.jp �܂�
�A�����������B

XMail-1.20
SpamAssassin 3.0.2

�̊��ɂ����āAspamc.exe �� xmail �̃t�B���^�Ƃ��Ďg�p
�ł���悤�� xmspamc.exe �Ƃ��ĕύX�����������̂ł��B
���g�́Axmspamc.c �ŁA_splitpath �Ƃ����֐��𗘗p���Ă���̂ŁA
Windows �ȊO�̊��ł́Axmspamc.c ���C������K�v������܂��B
�r���h����ꍇ�́Aspamc.c �̑���� xmspamc.c ���g���悤��
���Ă��������B

�� xmspamc.exe

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
  @@FILE �́AXMailServerFilter �̃p�����^�ł��B

  tempdir �́A�ꎞ�I�ɏo�͂���e���|�����t�@�C���p�̃t�H���_��
  �w�肵�Ă��������B

  -D 15.0  �Ƃ����I�v�V�����ŁA�X�p������X�R�A�� 15.0 �ȏ�̕]�����󂯂�
  ���̂���M���ۂ��܂��B�������ASpamAssassin�̃X���b�V���z�[���h�l
  �i�X�p���Ɣ��肷��ݒ�l�j�ȏ�łȂ��Ɠ��삵�܂���B�f�t�H���g�� 11.0 �ł��B

  -s 4000 �Ǝw�肷��� 4000k �o�C�g�̃��b�Z�[�W�𔻒肷��悤�ɂȂ�܂����A
  ���� 4000k �o�C�g�̃��������m�ۂ���̂ŁA������������ł́A��قǑ���
  �}�V���Ń���������������ς�ł�����ȊO�ł́A�������d�����ăn���O����
  �悤�Ɍ����Ă��܂��܂��B�ł��̂ŁA�����l�� 250k �o�C�g�ŉ^�p���鎖��
  �����߂��܂��B

  -b �I�v�V�����́A��L -s �I�v�V�����Ŏw�肵���T�C�Y���傫���t�@�C�����ƁA
  �T�C�Y���傫���������� EX_TOOBIG �Ƃ����G���[�R�[�h�ɂ��A�X�p�������
  �s���܂���̂ŁA����ł͕s�s�������邩�ȁH�Ǝv���A���̃I�v�V�������w��
  �����ꍇ�A�[���I�ɓr���܂ł����ǂݍ���ł��Ȃ����[���̕������t�B���^��
  �����ăX�p���Ɣ���肳�ꂽ�ꍇ�Ɏ�M���ۂ�����I�v�V�����ł��B
  �����I�ɂ����t�B���^�ɂ����Ȃ��̂ŁA�M���̂�������̂��ǂ����킩��܂���B
  ����āA���̃I�v�V�������w�肵�Ȃ��ꍇ�́A�ʏ�Ɠ������G���[�ɂ�萳��
  �I�����܂��B

��spamd.bat

spamd.bat �́ASpamAssassin-3.0.2 �ɕt���� /spamd/spamd.raw �� 
http://wiki.apache.org/spamassassin/SpamdOnWindows
�ɏ�����Ă���L�������ɕύX�������̂ł��B

  Perl �̃C���X�g�[���悪 c:\usr\perl ���Ɖ��肵�č쐬���Ă���܂�
�̂ŁA���̃t�H���_�ɃC���X�g�[�������ꍇ�́Aspamd.bat ���ɂ���
c:\usr\perl ���Ⴄ�t�H���_�ɒu�����ĉ������B

SpamAssassin-3.0.2 �� windows ���Ŏg�p����ꍇ��
http://wiki.apache.org/spamassassin/InstallingOnWindows
���Q�l�ɃC���X�g�[�����Ă݂Ă��������B

�� spamassassin.tab
  ���p����ꍇ�̐��`�ł��B���g�� Path_to_spamc �́A
xmspamc.exe ��u�����t�H���_�ւ̐�΃p�X�i�t���p�X�j��
�u�������ė��p���Ă��������B

TEMPDIR �́A�e���|�����p�̃t�H���_�ɒu�������Ă��������B
�e���|�����t�H���_�̍Ō�� '\' �}�[�N�͕s�v�ł��B

  xmail/MailRoot/filters.in.tab ��

"*"	"*"	"0.0.0.0/0"	"0.0.0.0/0"	spamassassin.tab

�̈�s��ǉ����Axmail/MailRoot/filters �t�H���_��
spamassassin.tab ���R�s�[����΂n�j�ł��B

