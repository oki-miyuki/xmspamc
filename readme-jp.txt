���͂��߂�
  ���̃h�L�������g�́A2005/08/24 �ɏ�����܂����B
�����ɏ�����Ă�����e�́A�Â��Ȃ��Ă���\��������܂��B

  �T�|�[�g�͂��܂��񂪁A��������܂����� blade2001jp@ybb.ne.jp �܂�
�A�����������B���J�� http://www.hunes.co.jp/oki/xmail_spamc/ �ōs���Ă��܂��B

xmspamc �́ASpamAssassin 3.0.2 �� spamc.c ���x�[�X�ɉ�������Ă��܂��B
xmail �́A�o�[�W���� 1.2.0 �ȍ~�ŁASpamAssassin 3.0.2, 3.0.3, 3.0.4 
�ł̓�����m�F���Ă��܂��B

  windows ���ȊO�ł��A�R���p�C������� xmail �p�̃t�B���^�Ƃ���
���p�ł���Ǝv���܂����Axmspamc.c ���� �p�X�𕪉�����̂� _splitpath
�Ƃ��������^�C���֐��𗘗p���Ă���A����͑��̃v���b�g�t�H�[���Ƃ�
�݊������Ȃ���������܂���B�r���h����ꍇ�́ASpamAssassin �� spamc.c 
�̑���� xmspamc.c �𗘗p����悤�� makefile �����������ăr���h��
�s���Ă��������B

���d�v����

  ���Ȃ̐ӔC�ɂ����Ďg�p���Ă��������B

Perl �́AC:\usr\Perl �ɃC���X�g�[������Ă�����̂Ƃ��� spamd.bat ���쐬���Ă��܂��B

SpamAssassin �̐ݒ�ɂ����� C:\usr\Perl\site\etc\mail\spamassassin\local.cf �ɂ����� 
report_safe = 0 
�Ƃ����s�̐ݒ�́A���͂�s�v�ɂȂ�܂����B

OutlookExpress ���̃��[���w�b�_�̏ڍׂȍ��ڂɉ������t�B���^�������ł��Ȃ����̂�
�΂��ẮAlocal.cf �ɂ����āA
rewrite_header Subject *****SPAM*****
�Ƃ����s��ǉ�����΁A�����Ńt�B���^�������ł���悤�ɂȂ�܂��B

  spamassassin.tab ���ŁA�I�v�V�������w�肷��ꍇ�̒��ӓ_�Ƃ��āA"-D 15.0" �Ƃ���
 ������������ƃG���[�ɂȂ�܂��B"-D"<tab>"15.0" �Ƃ����悤�ɃX�y�[�X�����͕�������
 �w�肵�Ă��������B

  XMail�̃t�B���^�p tab �t�@�C���́A��؂蕶���� <tab> �i�^�u�����j���g�p����̂ŁA
�X�y�[�X���g���ƃt�B���^�����������삵�Ȃ��_�ɒ��ӂ��Ă��������B

  �Y�t�� Spamd.bat ���̋L�q�ɂāASET RES_NAMESERVERS=[dns ip address] (��: 192.168.1.1)
�̋L�q�����āAocal.cf �� dns_available yes �̋L�q���s���� �m����RBL �̃`�F�b�N���s����
�����悤�ł��B


���ύX����

ver 0.11
 2005/01/13 FIX -b �I�v�V�������w�肵�Ȃ��Ă��A-b �I�v�V���������ɂȂ��Ă���
ver 0.12
 2005/01/23 FIX spamd.bat ����Perl�ւ̃p�X�� D:\Perl �ƃf�^�����������̂��C��
ver 0.2
 2005/08/20 FIX spamd.bat ���̃R�����g�~�X���C���i�N�����̃G���[���b�Z�[�W���������j
 2005/08/20 FIX XMail �t�B���^�p�̕ԋp�l�� 5 ���� 4 �ɏC���i�X�v�[�����Ȃ��悤�Ɂj
 2005/08/20 FIX spamassassin �� local.cf �� report_safe = 0 �Ǝw�肵�Ȃ��Ă��ǂ�
              �悤�ɏC��
 2005/08/24 FIX �ύX���ꂽ�X�v�[���E���[���̍ŏI�Q�o�C�g���`�F�b�N���ALF �݂̂�
              ���s�� CR+LF �̑g�̉��s�ɏ�������������ǉ��i�������Ȃ��ƁA
              ���[�����^�C���A�E�g�������N�������ۂ������������߁j
 2005/08/26 Release ���肵�ĉғ��ł������Ȃ̂ŁA�����Ɍ��J
ver 0.21
 2005/08/31 ADD XMail �t�B���^�p�̕ԋp�l 5, 4 (�X�v�[������,���Ȃ��j��I���ł���悤��
              -P �I�v�V������ǉ�
ver 0.22
 2005/11/01 FIX 0.21 �ō��������o�O�iSPAM�Ɣ��肳�ꂽ�ꍇ�́A��Ɏ�M���ۏ�ԂɂȂ��Ă����j

�� xmspamc.exe

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
c:/usr/perl ���Ⴄ�t�H���_�ɒu�����ĉ������B

  spamd.bat �́ASpamAssassin �̃f�[�����Ȃ̂ŁA��Ɏ��s�����Ă���
�K�v������܂��B

SpamAssassin �� windows ���Ŏg�p����ꍇ��
http://wiki.apache.org/spamassassin/InstallingOnWindows
���Q�l�ɃC���X�g�[�����Ă݂Ă��������B
http://www.hunes.co.jp/oki/xmail_spamc/InstallSpamAssassinOnWin32jp.html
�ɁA���l�̉�����ڂ��Ă��܂��̂ŁA��������Q�l�ɂ��Ă݂Ă��������B

�� spamassassin.tab
  XMailServer �ŁAxmspamc.exe �Ƃ����t�B���^�𗘗p����ꍇ�̐��`�ł��B
���g�� Path_to_spamc �́Axmspamc.exe ��u�����t�H���_�ւ̐�΃p�X�i�t���p�X�j��
�u�������ė��p���Ă��������B

Path_to_tempdir �́A�e���|�����p�̃t�H���_�ɒu�������Ă��������B
�e���|�����t�H���_�̍Ō�� '\' �}�[�N�͕s�v�ł��B

  xmail/MailRoot/filters.in.tab ��

"*"	"*"	"0.0.0.0/0"	"0.0.0.0/0"	spamassassin.tab

�̈�s��ǉ����Axmail/MailRoot/filters �t�H���_��
spamassassin.tab ���R�s�[����΂n�j�ł��B

