#!/usr/bin/perl -w

use strict;
binmode(STDOUT, ":utf8");
binmode(STDIN, ":utf8");

while(<STDIN>) {
  s/\x{ff01}/\!/g;   # !
  s/\x{ff20}/\@/g;   # @ 
  s/\x{ff03}/\#/g;   # # 
  s/\x{ffe5}/\$/g;   # $ 
  s/\x{ff05}/\%/g;   # % 
  s/\x{2026}/.../g; # ... 
  s/\x{ff06}/\&/g;   # & 
  s/\x{ff08}/\(/g;   # ( 
  s/\x{ff09}/\)/g;   # ) 
  s/\x{ff10}/0/g;    # 0
  s/\x{ff11}/1/g;    # 1
  s/\x{ff12}/2/g;    # 2
  s/\x{ff13}/3/g;    # 3
  s/\x{ff14}/4/g;    # 4
  s/\x{ff15}/5/g;    # 5
  s/\x{ff16}/6/g;    # 6
  s/\x{ff17}/7/g;    # 7
  s/\x{ff18}/8/g;    # 8
  s/\x{ff19}/9/g;    # 9
  s/\x{ff0D}/\-/g;    # -
  s/\x{ff1D}/\=/g;    # =
  s/\x{2014}/\-/g;    # -
  s/\x{ff0b}/\+/g;    # +
  s/\x{ff5b}/\{/g;    # {
  s/\x{ff5d}/\}/g;    # }
  s/\x{ff5c}/\|/g;    # |
  s/\x{3010}/\[/g;    # [
  s/\x{3011}/\]/g;    # ]
  s/\x{3001}/\,/g;    # parallel ,
  s/\x{ff1b}/\;/g;    # ;
  s/\x{2018}/\'/g;    # left '
  s/\x{2019}/\'/g;    # right '
  s/\x{ff1a}/\:/g;    # :
  s/\x{201c}/\"/g;    # left "
  s/\x{201d}/\"/g;    # right "
  s/\x{ff0c}/\,/g;    # normal ,
  s/\x{3002}/\./g;    # .
  s/\x{300a}/\</g;    # <
  s/\x{300b}/\>/g;    # > 
  s/\x{ff1f}/\?/g;    # ?
  print $_;
}
