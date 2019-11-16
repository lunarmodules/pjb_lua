# Note: No more RK! RUNGE means Runge-Kutta; KEY means Term::ReadKey 
ALSAVER = 1.24
CLUIVER = 1.78
DBMVER  = 20150425.52
DFILVER = 2.2
DUMPVER = 1.1
ECASVER = 0.4
EVVER   = 1.14
FENVER  = 1.7
FSVER   = 2.2
KEYVER  = 1.6
MIDIVER = 6.9
MTVER   = 1.18
RANDVER = 1.5
RLVER   = 2.6
RUNGEVER = 1.09
SOXVER  = 0.1
TIVER   = 1.8
TCVER   = 0.1
TIFVER  = 0.5
WTVER   = 1.19

# NO! should make these Math-* modules independent of their CPAN equivalents!
# and give them dist* targets!
ALSADIR  = /home/pjb/www/comp/lua
CLUIDIR  = /home/pjb/www/comp/lua
DFILDIR  = /home/pjb/www/comp/lua
DUMPDIR  = /home/pjb/www/comp/lua
ECASDIR  = /home/pjb/www/comp/lua
EVDIR    = /home/pjb/www/comp/lua
FENDIR   = /home/pjb/www/comp/lua
FSDIR    = /home/pjb/www/comp/lua
KEYDIR   = /home/pjb/www/comp/lua
DBMDIR   = /home/pjb/www/comp/lua
MIDIDIR  = /home/pjb/www/comp/lua
RANDDIR  = /home/pjb/www/comp/lua
RLDIR    = /home/pjb/www/comp/lua
RUNGEDIR = /home/pjb/www/comp/lua
TIDIR    = /home/pjb/www/comp/lua
WTDIR    = /home/pjb/www/comp/lua
SOXDIR   = /home/pjb/www/comp/lua
DISTDIR  = /home/pjb/www/comp/lua
TESTDIR  = /home/pjb/lua/test

ALSASRC = midialsa-0.0
CLUISRC = /home/pjb/lua/lib
DFILSRC = /home/pjb/lua/lib
DUMPSRC = /home/pjb/lua/lib
ECASSRC = ecasound-0.0
FSSRC   = fluidsynth-0.0
RANDSRC = /home/pjb/lua/lib
RLSRC   = readline-0.0
SOXSRC  = sox-0.0
TISRC   = terminfo-0.0
TCSRC   = testcases-0.0
TIFSRC  = /home/pjb/lua/lib

DOCDIR = /home/pjb/www/comp/lua

ALSAROCKSPEC = ${ALSADIR}/midialsa-${ALSAVER}-0.rockspec
ALSATARBALL  = ${ALSADIR}/midialsa-${ALSAVER}.tar.gz
CLUIROCKSPEC = ${CLUIDIR}/commandlineui-${CLUIVER}-0.rockspec
CLUITARBALL  = ${CLUIDIR}/CommandLineUI-${CLUIVER}.tar.gz
DBMROCKSPEC  = ${DBMDIR}/lgdbm-${DBMVER}-0.rockspec
DFILROCKSPEC = ${DFILDIR}/digitalfilter-${DFILVER}-0.rockspec
DFILTARBALL  = ${DFILDIR}/digitalfilter-${DFILVER}.tar.gz
DUMPROCKSPEC = ${DUMPDIR}/datadumper-${DUMPVER}-0.rockspec
DUMPTARBALL  = ${DUMPDIR}/DataDumper-${DUMPVER}.tar.gz
ECASROCKSPEC = ${ECASDIR}/ecasound-${ECASVER}-0.rockspec
ECASTARBALL  = ${ECASDIR}/ecasound-${ECASVER}.tar.gz
EVROCKSPEC   = ${EVDIR}/math-evol-${EVVER}-0.rockspec
EVTARBALL    = ${EVDIR}/math-evol-${EVVER}.tar.gz
FENROCKSPEC  = ${FENDIR}/chess-fen-${FENVER}-0.rockspec
FENTARBALL   = ${FENDIR}/chess-fen-${FENVER}.tar.gz
FSROCKSPEC   = ${FSDIR}/fluidsynth-${FSVER}-0.rockspec
FSTARBALL    = ${FSDIR}/fluidsynth-${FSVER}.tar.gz
KEYROCKSPEC  = ${KEYDIR}/readkey-${KEYVER}-0.rockspec
KEYTARBALL   = ${KEYDIR}/readkey-${KEYVER}.tar.gz
MIDIROCKSPEC = ${MIDIDIR}/midi-${MIDIVER}-0.rockspec
MIDITARBALL  = ${MIDIDIR}/MIDI-${MIDIVER}.tar.gz
RANDROCKSPEC = ${RANDDIR}/randomdist-${RANDVER}-0.rockspec
RANDTARBALL  = ${RANDDIR}/randomdist-${RANDVER}.tar.gz
RLROCKSPEC   = ${RLDIR}/readline-${RLVER}-0.rockspec
RLTARBALL    = ${RLDIR}/readline-${RLVER}.tar.gz
RUNGEROCKSPEC = ${RUNGEDIR}/math-rungekutta-${RUNGEVER}-0.rockspec
RUNGETARBALL = ${RUNGEDIR}/math-rungekutta-${RUNGEVER}.tar.gz
TIROCKSPEC   = ${TIDIR}/terminfo-${TIVER}-0.rockspec
TITARBALL    = ${TIDIR}/terminfo-${TIVER}.tar.gz
TCROCKSPEC   = ${TIDIR}/testcases-${TCVER}-0.rockspec
TCTARBALL    = ${DISTDIR}/testcases-${TCVER}.tar.gz
SOXROCKSPEC  = ${SOXDIR}/sox-${SOXVER}-0.rockspec
SOXTARBALL   = ${SOXDIR}/sox-${SOXVER}.tar.gz
TIFROCKSPEC  = ${DISTDIR}/terminfofont-${TIFVER}-0.rockspec
TIFTARBALL   = ${DISTDIR}/terminfofont-${TIFVER}.tar.gz
WTROCKSPEC   = ${WTDIR}/math-walshtransform-${WTVER}-0.rockspec
WTTARBALL    = ${WTDIR}/math-walshtransform-${WTVER}.tar.gz

ALSAMD5 ?= $(shell md5sum -b ${ALSATARBALL} | sed 's/\s.*//')
CLUIMD5 ?= $(shell md5sum -b ${CLUITARBALL} | sed 's/\s.*//')
DFILMD5 ?= $(shell md5sum -b ${DFILTARBALL} | sed 's/\s.*//')
DUMPMD5 ?= $(shell md5sum -b ${DUMPTARBALL} | sed 's/\s.*//')
ECASMD5 ?= $(shell md5sum -b ${ECASTARBALL} | sed 's/\s.*//')
FSMD5   ?= $(shell md5sum -b ${FSTARBALL} | sed 's/\s.*//')
KEYMD5  ?= $(shell md5sum -b ${KEYTARBALL} | sed 's/\s.*//')
MIMD5   ?= $(shell md5sum -b ${MIDITARBALL} | sed 's/\s.*//')
RLMD5   ?= $(shell md5sum -b ${RLTARBALL} | sed 's/\s.*//')
RANDMD5 ?= $(shell md5sum -b ${RANDTARBALL} | sed 's/\s.*//')
RUNGEMD5 ?= $(shell md5sum -b ${RUNGETARBALL} | sed 's/\s.*//')
WTMD5   ?= $(shell md5sum -b ${WTTARBALL} | sed 's/\s.*//')
EVMD5   ?= $(shell md5sum -b ${EVTARBALL} | sed 's/\s.*//')
FENMD5  ?= $(shell md5sum -b ${FENTARBALL} | sed 's/\s.*//')
TIMD5   ?= $(shell md5sum -b ${TITARBALL} | sed 's/\s.*//')
TCMD5   ?= $(shell md5sum -b ${TCTARBALL} | sed 's/\s.*//')
SOXMD5  ?= $(shell md5sum -b ${SOXTARBALL} | sed 's/\s.*//')
TIFMD5  ?= $(shell md5sum -b ${TIFTARBALL} | sed 's/\s.*//')
DATESTAMP ?= $(shell /home/pbin/datestamp)

all: \
 ${ALSAROCKSPEC} ${KEYROCKSPEC} ${TIROCKSPEC} ${FSROCKSPEC} \
 ${CLUIROCKSPEC} ${DBMROCKSPEC} ${CLUITARBALL} \
 ${DOCDIR}/Sequence.lua \
 ${DUMPROCKSPEC} ${DUMPTARBALL} ${RLROCKSPEC} ${ECASROCKSPEC} \
 ${EVDIR}/Evol.lua ${EVDIR}/Evol.html \
 ${FENDIR}/fen.lua ${FENDIR}/fen.html \
 ${MIDIDIR}/MIDI.lua ${MIDIDIR}/test_mi.lua ${MIDIROCKSPEC} ${MIDITARBALL} \
 ${RUNGEROCKSPEC} ${RUNGETARBALL} \
 ${WTROCKSPEC} ${WTTARBALL} ${SOXROCKSPEC} ${SOXTARBALL} ${TIFTARBALL}

dev : ${SOXROCKSPEC}

distrunge: ${RUNGEROCKSPEC}
	/home/pbin/upload ${RUNGEDIR}/RungeKutta.lua
	# /home/pbin/upload ${RUNGEDIR}/test_runge.lua
	/home/pbin/upload ${RUNGEROCKSPEC}
	/home/pbin/upload ${RUNGETARBALL}
	# If a trial install works on 5.1, 5.2 and 5.3:
	#  luarocks remove math-rungekutta
	#  luarocks install http://www.pjb.com.au/comp/lua/math-rungekutta-${RUNGEVER}-0.rockspec
	#  box8 (debian) ~> cd ~/www/comp/lua/
	#  box8 (debian) lua> luarocks upload math-rungekutta-${RUNGEVER}-0.rockspec

distwt: ${WTROCKSPEC}
	/home/pbin/upload ${WTDIR}/WalshTransform.lua
	# /home/pbin/upload ${WTDIR}/test_wt.lua
	/home/pbin/upload ${WTROCKSPEC}
	/home/pbin/upload ${WTTARBALL}
	# If a trial install works on 5.1, 5.2 and 5.3:
	#  luarocks remove math-walshtransform
	#  luarocks install http://www.pjb.com.au/comp/lua/math-walshtransform-${WTVER}-0.rockspec
	#  box8 (debian) ~> cd ~/www/comp/lua/
	#  box8 (debian) lua> luarocks upload math-walshtransform-${WTVER}-0.rockspec

distev: ${EVROCKSPEC}
	/home/pbin/upload ${EVDIR}/Evol.lua
	# /home/pbin/upload ${EVDIR}/test_ev.lua
	/home/pbin/upload ${EVROCKSPEC}
	/home/pbin/upload ${EVTARBALL}
	# If a trial install works on 5.1, 5.2 and 5.3:
	#  luarocks remove math-evol
	#  luarocks install http://www.pjb.com.au/comp/lua/math-evol-${EVVER}-0.rockspec
	#  box8 (debian) ~> cd ~/www/comp/lua/
	#  box8 (debian) lua> luarocks upload math-evol-${EVVER}-0.rockspec

distfen: ${FENROCKSPEC}
	cp /home/pbin/pgn2eco ${FENDIR}/pgn2eco
	/home/pbin/upload ${FENDIR}/pgn2eco
	cp /home/pbin/pgn2fen ${FENDIR}/pgn2fen
	/home/pbin/upload ${FENDIR}/pgn2fen
	/home/pbin/upload ${FENDIR}/fen.lua
	/home/pbin/upload ${FENDIR}/fen.html
	# /home/pbin/upload ${FENDIR}/test_fen.lua
	/home/pbin/upload ${FENROCKSPEC}
	/home/pbin/upload ${FENTARBALL}
	# If a trial install works on 5.1, 5.2 and 5.3:
	#  luarocks remove chess-fen
	#  luarocks install http://www.pjb.com.au/comp/lua/chess-fen-${FENVER}-0.rockspec
	#  box8 (debian) ~> cd ~/www/comp/lua/
	#  box8 (debian) lua> luarocks upload chess-fen-${FENVER}-0.rockspec

distmidi: ${MIDIDIR}/MIDI.lua ${MIDIDIR}/MIDI.html ${MIDIROCKSPEC} \
	${MIDIDIR}/test_mi.lua
	/home/pbin/upload ${MIDIDIR}/midi-${MIDIVER}-0.rockspec
	/home/pbin/upload ${MIDIDIR}/MIDI-${MIDIVER}.tar.gz
	/home/pbin/upload ${MIDIDIR}/MIDI.lua
	#/home/pbin/upload ${MIDIDIR}/MIDI.html
	/home/pbin/upload ${MIDIDIR}/test_mi.lua
	# If a trial install works on 5.1, 5.2 and 5.3:
	#  luarocks remove midi
	#  luarocks install http://www.pjb.com.au/comp/lua/midi-${MIDIVER}-0.rockspec
	#  box8 (debian) ~> cd ~/www/comp/lua/
	#  box8 (debian) lua> luarocks upload midi-${MIDIVER}-0.rockspec

distalsa: ${ALSADIR}/midialsa.html ${ALSAROCKSPEC}
	/home/pbin/upload ${ALSADIR}/midialsa.html
	/home/pbin/upload ${ALSADIR}/midialsa-${ALSAVER}-0.rockspec
	/home/pbin/upload ${ALSADIR}/midialsa-${ALSAVER}.tar.gz
	# If a trial install works on 5.1, 5.2 and 5.3:
	#  luarocks remove midialsa
	#  luarocks install http://www.pjb.com.au/comp/lua/midialsa-${ALSAVER}-0.rockspec ALSA_LIBDIR=/usr/lib/i386-linux-gnu/
	#  box8 (debian) ~> cd ~/www/comp/lua/
	#  box8 (debian) lua> luarocks upload midialsa-${ALSAVER}-0.rockspec

distclui : ${CLUIDIR}/commandlineui.html ${CLUIROCKSPEC}
	/home/pbin/upload ${CLUIDIR}/commandlineui.html
	/home/pbin/upload ${CLUIDIR}/commandlineui-${CLUIVER}-0.rockspec
	/home/pbin/upload ${CLUIDIR}/CommandLineUI-${CLUIVER}.tar.gz
	cp /home/pbin/audio_stuff.lua ${CLUIDIR}/
	# /home/pbin/upload ${CLUIDIR}/audio_stuff.lua
	# If a trial install works on 5.1, 5.2 and 5.3:
	#  luarocks remove commandlineui
	#  luarocks install http://www.pjb.com.au/comp/lua/commandlineui-${CLUIVER}-0.rockspec
	#  box8 (debian) ~> cd ~/www/comp/lua/
	#  box8 (debian) lua> luarocks upload commandlineui-${CLUIVER}-0.rockspec

${DFILDIR}/test_digitalfilter.lua : test/test_digitalfilter.lua
	cp test/test_digitalfilter.lua $@
	/home/pbin/upload $@
distdfil : ${DFILROCKSPEC} ${DFILDIR}/test_digitalfilter.lua
	/home/pbin/upload ${DFILDIR}/digitalfilter-${DFILVER}-0.rockspec
	/home/pbin/upload ${DFILDIR}/digitalfilter-${DFILVER}.tar.gz
	# If a trial install works on 5.1, 5.2 and 5.3:
	#  luarocks remove digitalfilter
	#  luarocks install http://www.pjb.com.au/comp/lua/digitalfilter-${DFILVER}-0.rockspec
	#  box8 (debian) ~> cd ~/www/comp/lua/
	#  box8 (debian) lua> luarocks upload digitalfilter-${DFILVER}-0.rockspec

distdump : ${DUMPROCKSPEC}
	/home/pbin/upload ${DUMPDIR}/datadumper-${DUMPVER}-0.rockspec
	/home/pbin/upload ${DUMPDIR}/DataDumper-${DUMPVER}.tar.gz
	# If a trial install works on 5.1, 5.2 and 5.3:
	#  luarocks remove datadumper
	#  luarocks install http://www.pjb.com.au/comp/lua/datadumper-${DUMPVER}-0.rockspec
	#  box8 (debian) ~> cd ~/www/comp/lua/
	#  box8 (debian) lua> luarocks upload datadumper-${DUMPVER}-0.rockspec

distecas: ${ECASDIR}/ecasound.html ${ECASROCKSPEC}
	/home/pbin/upload ${ECASDIR}/ecasound.html
	/home/pbin/upload ${ECASDIR}/ecasound-${ECASVER}-0.rockspec
	/home/pbin/upload ${ECASDIR}/ecasound-${ECASVER}.tar.gz
	# If a trial install works on 5.1, 5.2 and 5.3:
	#  luarocks remove ecasound
	#  luarocks install http://www.pjb.com.au/comp/lua/ecasound-${ECASVER}-0.rockspec ECAS_LIBDIR=/usr/lib/i386-linux-gnu/
	#  box8 (debian) ~> cd ~/www/comp/lua/
	#  box8 (debian) lua> luarocks upload ecasound-${ECASVER}-0.rockspec

distfs: ${FSROCKSPEC}
	/home/pbin/upload ${FSDIR}/fluidsynth.html
	/home/pbin/upload ${FSDIR}/fluidsynth-${FSVER}-0.rockspec
	/home/pbin/upload ${FSDIR}/fluidsynth-${FSVER}.tar.gz
	# If a trial install works on 5.1, 5.2 and 5.3:
	#  luarocks remove fluidsynth
	#  luarocks install http://www.pjb.com.au/comp/lua/fluidsynth-${FSVER}-0.rockspec
	# or:
	#  luarocks install http://www.pjb.com.au/comp/lua/fluidsynth-${FSVER}-0.rockspec FSSA_LIBDIR=/usr/lib/i386-linux-gnu/
	#  box8 (debian) ~> cd ~/www/comp/lua/
	#  box8 (debian) lua> luarocks upload fluidsynth-${FSVER}-0.rockspec

distrand : ${RANDROCKSPEC}
	/home/pbin/upload ${RANDDIR}/randomdist-${RANDVER}-0.rockspec
	/home/pbin/upload ${RANDDIR}/randomdist-${RANDVER}.tar.gz
	# If a trial install works on 5.1, 5.2 and 5.3:
	#  luarocks remove randomdist
	#  luarocks install http://www.pjb.com.au/comp/lua/randomdist-${RANDVER}-0.rockspec
	#  box8 (debian) ~> cd ~/www/comp/lua/
	#  box8 (debian) lua> luarocks upload randomdist-${RANDVER}-0.rockspec

distrkey: ${KEYDIR}/readkey.html ${KEYROCKSPEC}
	/home/pbin/upload ${KEYDIR}/readkey.html
	/home/pbin/upload ${KEYDIR}/readkey-${KEYVER}-0.rockspec
	/home/pbin/upload ${KEYDIR}/readkey-${KEYVER}.tar.gz
	# If a trial install works on 5.1, 5.2 and 5.3:
	#  luarocks remove readkey
	#  luarocks install http://www.pjb.com.au/comp/lua/readkey-${KEYVER}-0.rockspec
	#  box8 (debian) ~> cd ~/www/comp/lua/
	#  box8 (debian) lua> luarocks upload readkey-${KEYVER}-0.rockspec

${RLDIR}/test_rl.lua : readline-0.0/test_rl.lua
	cp readline-0.0/test_rl.lua $@
	upload $@
distrlin : ${RLDIR}/readline.html ${RLROCKSPEC} ${RLDIR}/test_rl.lua
	/home/pbin/upload ${RLDIR}/readline.html
	/home/pbin/upload ${RLDIR}/readline-${RLVER}-0.rockspec
	/home/pbin/upload ${RLDIR}/readline-${RLVER}.tar.gz
	# If a trial install works on 5.1, 5.2 and 5.3:
	#  luarocks remove readline
	#  luarocks install http://www.pjb.com.au/comp/lua/readline-${RLVER}-0.rockspec
	#  box8 (debian) ~> cd ~/www/comp/lua/
	#  box8 (debian) lua> luarocks upload readline-${RLVER}-0.rockspec

distterm : ${TIDIR}/terminfo.html ${TIROCKSPEC}
	/home/pbin/upload ${TIDIR}/terminfo.html
	/home/pbin/upload ${TIDIR}/terminfo-${TIVER}-0.rockspec
	/home/pbin/upload ${TIDIR}/terminfo-${TIVER}.tar.gz
	# If a trial install works on 5.1, 5.2 and 5.3:
	#  luarocks remove terminfo
	#  luarocks install http://www.pjb.com.au/comp/lua/terminfo-${TIVER}-0.rockspec
	#  box8 (debian) ~> cd ~/www/comp/lua/
	#  box8 (debian) lua> luarocks upload terminfo-${TIVER}-0.rockspec

disttc : ${DISTDIR}/testcases.html ${TCROCKSPEC}
	/home/pbin/upload ${DISTDIR}/testcases.html
	/home/pbin/upload ${DISTDIR}/testcases-${TCVER}-0.rockspec
	/home/pbin/upload ${DISTDIR}/testcases-${TCVER}.tar.gz
	# Install by:
	#  luarocks remove testcases
	#  luarocks install http://www.pjb.com.au/comp/lua/testcases-${TCVER}-0.rockspec

distgdbm: ${DBMDIR}/lgdbm.html ${DBMROCKSPEC}
	/home/pbin/upload ${DBMDIR}/lgdbm.html
	/home/pbin/upload ${DBMDIR}/lgdbm-${DBMVER}-0.rockspec
	# If a trial install works on 5.2 and 5.3:
	#  luarocks remove lgdbm
	#  luarocks install http://www.pjb.com.au/comp/lua/lgdbm-${DBMVER}-0.rockspec
	#  box8 (debian) ~> cd ~/www/comp/lua/
	#  box8 (debian) lua> luarocks upload lgdbm-${DBMVER}-0.rockspec

distsox : ${SOXDIR}/sox.html ${SOXROCKSPEC}
	/home/pbin/upload ${SOXDIR}/sox.html
	/home/pbin/upload ${SOXDIR}/sox-${SOXVER}-0.rockspec
	/home/pbin/upload ${SOXDIR}/sox-${SOXVER}.tar.gz
	# If a trial install works on 5.1, 5.2 and 5.3:
	#  luarocks remove sox
	#  luarocks install http://www.pjb.com.au/comp/lua/sox-${SOXVER}-0.rockspec
	#  box8 (debian) ~> cd ~/www/comp/lua/
	#  box8 (debian) lua> luarocks upload sox-${SOXVER}-0.rockspec

${DISTDIR}/test_terminfofont.lua : ${TESTDIR}/test_terminfofont.lua
	cp ${TESTDIR}/test_terminfofont.lua $@
	upload $@
disttif : ${DISTDIR}/terminfofont.html \
  ${DISTDIR}/test_terminfofont.lua ${TIFROCKSPEC}
	/home/pbin/upload ${DISTDIR}/terminfofont.html
	/home/pbin/upload ${DISTDIR}/terminfofont-${TIFVER}-0.rockspec
	/home/pbin/upload ${DISTDIR}/terminfofont-${TIFVER}.tar.gz
	# If a trial install works on 5.1, 5.2 and 5.3:
	#  luarocks remove terminfofont
	#  luarocks install http://www.pjb.com.au/comp/lua/terminfofont-${TIFVER}-0.rockspec
	#  box8 (debian) ~> cd ~/www/comp/lua/
	#  box8 (debian) lua> luarocks upload terminfofont-${TIFVER}-0.rockspec

${RUNGEDIR}/RungeKutta.lua: lib/RungeKutta.lua
	perl -pe "s/VERSION/${RUNGEVER}/ ; s/DATESTAMP/${DATESTAMP}/" \
	  lib/RungeKutta.lua > $@
${RUNGEDIR}/test_runge.lua: test/test_runge.lua
	cp test/test_runge.lua $@
${RUNGETARBALL} : ${RUNGEDIR}/RungeKutta.lua ${RUNGEDIR}/test_runge.lua \
 ${RUNGEDIR}/RungeKutta.html
	mkdir math-rungekutta-${RUNGEVER}
	mkdir math-rungekutta-${RUNGEVER}/test
	mkdir math-rungekutta-${RUNGEVER}/doc
	cp ${RUNGEDIR}/RungeKutta.lua  math-rungekutta-${RUNGEVER}/
	cp ${RUNGEDIR}/RungeKutta.html math-rungekutta-${RUNGEVER}/doc/
	cp test/test_runge.lua math-rungekutta-${RUNGEVER}/test/
	tar cvzf $@ math-rungekutta-${RUNGEVER}
	rm -rf math-rungekutta-${RUNGEVER}
${RUNGEROCKSPEC} : ${RUNGETARBALL} dist/math-rungekutta.rockspec
	perl -pe \
	 "s/VERSION/${RUNGEVER}/ ; s/TARBALL/math-rungekutta-${RUNGEVER}.tar.gz/ ; s/MD5/${RUNGEMD5}/" dist/math-rungekutta.rockspec > $@
	lua $@

${WTDIR}/WalshTransform.lua: lib/WalshTransform.lua
	perl -pe "s/VERSION/${WTVER}/ ; s/DATESTAMP/${DATESTAMP}/" \
	  lib/WalshTransform.lua > $@
${WTDIR}/test_wt.lua: test/test_wt.lua
	cp test/test_wt.lua $@
${WTTARBALL} : ${WTDIR}/WalshTransform.lua ${WTDIR}/test_wt.lua \
 ${WTDIR}/WalshTransform.html
	mkdir math-walshtransform-${WTVER}
	mkdir math-walshtransform-${WTVER}/test
	mkdir math-walshtransform-${WTVER}/doc
	cp ${WTDIR}/WalshTransform.lua  math-walshtransform-${WTVER}/
	cp ${WTDIR}/WalshTransform.html math-walshtransform-${WTVER}/doc/
	cp test/test_wt.lua math-walshtransform-${WTVER}/test/
	tar cvzf $@ math-walshtransform-${WTVER}
	rm -rf math-walshtransform-${WTVER}
${WTROCKSPEC} : ${WTTARBALL} dist/math-walshtransform.rockspec
	perl -pe \
	 "s/VERSION/${WTVER}/ ; s/TARBALL/math-walshtransform-${WTVER}.tar.gz/ ; s/MD5/${WTMD5}/" dist/math-walshtransform.rockspec > $@
	lua $@

${EVDIR}/Evol.lua: lib/Evol.lua
	perl -pe "s/VERSION/${EVVER}/ ; s/DATESTAMP/${DATESTAMP}/" \
	  lib/Evol.lua > $@
${EVDIR}/test_ev.lua: test/test_ev.lua
	cp test/test_ev.lua $@
${EVTARBALL} : ${EVDIR}/Evol.lua ${EVDIR}/test_ev.lua \
 ${EVDIR}/Evol.html
	mkdir math-evol-${EVVER}
	mkdir math-evol-${EVVER}/test
	mkdir math-evol-${EVVER}/doc
	cp ${EVDIR}/Evol.lua  math-evol-${EVVER}/
	cp ${EVDIR}/Evol.html math-evol-${EVVER}/doc/
	cp test/test_ev.lua math-evol-${EVVER}/test/
	tar cvzf $@ math-evol-${EVVER}
	rm -rf math-evol-${EVVER}
${EVROCKSPEC} : ${EVTARBALL} dist/math-evol.rockspec
	perl -pe \
	 "s/VERSION/${EVVER}/ ; s/TARBALL/math-evol-${EVVER}.tar.gz/ ; s/MD5/${EVMD5}/" dist/math-evol.rockspec > $@
	lua $@

${FENDIR}/fen.lua: lib/fen.lua
	perl -pe "s/VERSION/${FENVER}/ ; s/DATESTAMP/${DATESTAMP}/" \
	  lib/fen.lua > $@
${FENDIR}/test_fen.lua: test/test_fen.lua
	cp test/test_fen.lua $@
${FENTARBALL} : ${FENDIR}/fen.lua ${FENDIR}/test_fen.lua \
 ${FENDIR}/fen.html
	mkdir chess-fen-${FENVER}
	mkdir chess-fen-${FENVER}/bin
	mkdir chess-fen-${FENVER}/doc
	mkdir chess-fen-${FENVER}/test
	cp ${FENDIR}/fen.lua  chess-fen-${FENVER}/
	cp /home/pbin/pgn2eco chess-fen-${FENVER}/bin/
	cp /home/pbin/pgn2fen chess-fen-${FENVER}/bin/
	cp ${FENDIR}/fen.html chess-fen-${FENVER}/doc/
	cp test/test_fen.lua chess-fen-${FENVER}/test/
	tar cvzf $@ chess-fen-${FENVER}
	rm -rf chess-fen-${FENVER}
${FENROCKSPEC} : ${FENTARBALL} dist/chess-fen.rockspec
	perl -pe \
	 "s/VERSION/${FENVER}/ ; s/TARBALL/chess-fen-${FENVER}.tar.gz/ ; s/MD5/${FENMD5}/" dist/chess-fen.rockspec > $@
	lua $@

${MIDIDIR}/MIDI.lua: lib/MIDI.lua
	perl -pe "s/VERSION/${MIDIVER}/ ; s/DATESTAMP/${DATESTAMP}/" \
	  lib/MIDI.lua > $@
	cp $@ /home/pjb/www/midi/free/MIDI.lua
${MIDIDIR}/test_mi.lua: test/test_mi.lua
	cp test/test_mi.lua ${MIDIDIR}/test_mi.lua
${MIDITARBALL} : lib/MIDI.lua test/test_mi.lua ${MIDIDIR}/MIDI.html
	mkdir MIDI-${MIDIVER}
	mkdir MIDI-${MIDIVER}/test
	mkdir MIDI-${MIDIVER}/doc
	cp lib/MIDI.lua MIDI-${MIDIVER}
	cp ${MIDIDIR}/MIDI.html MIDI-${MIDIVER}/doc
	cp test/test_mi.lua MIDI-${MIDIVER}/test
	tar cvzf $@ MIDI-${MIDIVER}
	rm -rf MIDI-${MIDIVER}
${MIDIROCKSPEC} : ${MIDITARBALL} dist/midi.rockspec
	perl -pe \
	 "s/VERSION/${MIDIVER}/ ; s/TARBALL/MIDI-${MIDIVER}.tar.gz/ ; s/MD5/${MIMD5}/" dist/midi.rockspec > $@
	lua $@
#${MIDMIDIIR}/MIDI.html : lib/MIDI.lua
#	pod2html lib/MIDI.lua | sed 's/h1>/h2>/g' > ${DOCDIR}/MIDI.html

${ALSATARBALL} : ${ALSASRC}/midialsa.lua ${ALSASRC}/C-midialsa.c \
 ${ALSASRC}/test_al.lua ${ALSADIR}/midialsa.html
	md5sum ${ALSASRC}/midialsa.lua
	mkdir midialsa-${ALSAVER}
	mkdir midialsa-${ALSAVER}/test
	mkdir midialsa-${ALSAVER}/doc
	cp ${ALSASRC}/midialsa.lua midialsa-${ALSAVER}/
	cp ${ALSASRC}/C-midialsa.c midialsa-${ALSAVER}/
	cp ${ALSADIR}/midialsa.html midialsa-${ALSAVER}/doc
	cp ${ALSASRC}/test_al.lua midialsa-${ALSAVER}/test
	tar cvzf $@ midialsa-${ALSAVER}
	rm -rf midialsa-${ALSAVER}
${ALSAROCKSPEC} : ${ALSATARBALL} ${ALSASRC}/midialsa.rockspec
	perl -pe \
	 "s/VERSION/${ALSAVER}/ ; s/TARBALL/midialsa-${ALSAVER}.tar.gz/ ; s/MD5/${ALSAMD5}/" ${ALSASRC}/midialsa.rockspec > $@
	lua $@
	cp $@ ${ALSASRC}/midialsa-${ALSAVER}-0.rockspec
#${ALSADIR}/midialsa.html : ${ALSASRC}/midialsa.lua
#	pod2html ${ALSASRC}/midialsa.lua | sed 's/h1>/h2>/g' > ${ALSASRC}/midialsa.html
#	cp ${ALSASRC}/midialsa.html $@

${ECASTARBALL} : ${ECASSRC}/ecasound.lua ${ECASSRC}/C-ecasound.c \
 ${ECASSRC}/test_ecasound.lua ${ECASDIR}/ecasound.html
	md5sum ${ECASSRC}/ecasound.lua
	mkdir ecasound-${ECASVER}
	mkdir ecasound-${ECASVER}/test
	mkdir ecasound-${ECASVER}/doc
	cp ${ECASSRC}/ecasound.lua ecasound-${ECASVER}/
	cp ${ECASSRC}/C-ecasound.c ecasound-${ECASVER}/
	cp ${ECASDIR}/ecasound.html ecasound-${ECASVER}/doc
	cp ${ECASSRC}/test_ecasound.lua ecasound-${ECASVER}/test
	tar cvzf $@ ecasound-${ECASVER}
	rm -rf ecasound-${ECASVER}
${ECASROCKSPEC} : ${ECASTARBALL} ${ECASSRC}/ecasound.rockspec
	perl -pe \
	 "s/VERSION/${ECASVER}/ ; s/TARBALL/ecasound-${ECASVER}.tar.gz/ ; s/MD5/${ECASMD5}/" ${ECASSRC}/ecasound.rockspec > $@
	lua $@
	cp $@ ${ECASSRC}/ecasound-${ECASVER}-0.rockspec
#${ECASDIR}/ecasound.html : ${ECASSRC}/ecasound.lua
#	pod2html ${ECASSRC}/ecasound.lua | sed 's/h1>/h2>/g' > ${ECASSRC}/ecasound.html
#	cp ${ECASSRC}/ecasound.html $@

${FSTARBALL} : ${FSSRC}/fluidsynth.lua ${FSSRC}/C-fluidsynth.c \
 ${FSSRC}/test_fs.lua ${FSDIR}/fluidsynth.html
	md5sum ${FSSRC}/fluidsynth.lua
	mkdir fluidsynth-${FSVER}
	mkdir fluidsynth-${FSVER}/test
	mkdir fluidsynth-${FSVER}/doc
	mkdir fluidsynth-${FSVER}/examples
	cp ${FSSRC}/fluidsynth.lua fluidsynth-${FSVER}/
	cp ${FSSRC}/C-fluidsynth.c fluidsynth-${FSVER}/
	cp ${FSSRC}/alsa_client fluidsynth-${FSVER}/examples/
	cp ${FSSRC}/curses_client fluidsynth-${FSVER}/examples/
	cp ${FSSRC}/midi2wav fluidsynth-${FSVER}/examples/
	cp /home/pbin/fluadity  fluidsynth-${FSVER}/examples/
	cp /home/pbin/midi2wavs fluidsynth-${FSVER}/examples/
	cp ${FSSRC}/test_fs.lua fluidsynth-${FSVER}/test/
	cp ${FSSRC}/folkdance.mid fluidsynth-${FSVER}/test/
	cp ${FSDIR}/fluidsynth.html fluidsynth-${FSVER}/doc/
	tar cvzf $@ fluidsynth-${FSVER}
	rm -rf fluidsynth-${FSVER}
${FSROCKSPEC} : ${FSTARBALL} ${FSSRC}/fluidsynth.rockspec
	perl -pe \
	 "s/VERSION/${FSVER}/ ; s/TARBALL/fluidsynth-${FSVER}.tar.gz/ ; s/MD5/${FSMD5}/" ${FSSRC}/fluidsynth.rockspec > $@
	lua $@
	cp $@ ${FSSRC}/fluidsynth-${FSVER}-0.rockspec
#${FSDIR}/fluidsynth.html : ${FSSRC}/fluidsynth.lua
#	pod2html ${FSSRC}/fluidsynth.lua|sed 's/h1>/h2>/g'>${FSSRC}/fluidsynth.html
#	cp ${FSSRC}/fluidsynth.html $@

${DOCDIR}/Sequence.lua : lib/Sequence.lua
	cp lib/Sequence.lua $@
	pod2html lib/Sequence.lua | sed 's/h1>/h2>/g' > ${DOCDIR}/Sequence.html

${KEYDIR}/readkey.lua: lib/readkey.lua
	md5sum lib/readkey.lua
	cp lib/readkey.lua $@
${KEYDIR}/test_key.lua: test/test_key.lua
	cp test/test_key.lua ${KEYDIR}/test_key.lua
${KEYTARBALL} : lib/readkey.lua test/test_key.lua ${KEYDIR}/readkey.html
	mkdir readkey-${KEYVER}
	mkdir readkey-${KEYVER}/test
	mkdir readkey-${KEYVER}/doc
	cp lib/readkey.lua readkey-${KEYVER}
	cp ${KEYDIR}/readkey.html readkey-${KEYVER}/doc
	cp test/test_key.lua readkey-${KEYVER}/test
	tar cvzf $@ readkey-${KEYVER}
	rm -rf readkey-${KEYVER}
${KEYROCKSPEC} : ${KEYTARBALL} dist/readkey.rockspec
	perl -pe \
	 "s/VERSION/${KEYVER}/ ; s/TARBALL/readkey-${KEYVER}.tar.gz/ ; s/MD5/${KEYMD5}/" dist/readkey.rockspec > $@
	lua $@
#${KEYDIR}/readkey.html : lib/readkey.lua
#	pod2html lib/readkey.lua | sed 's/h1>/h2>/g' > ${DOCDIR}/readkey.html

${DBMROCKSPEC} : dist/lgdbm.rockspec
	perl -pe "s/VERSION/${DBMVER}/" dist/lgdbm.rockspec > $@
	lua $@

${TITARBALL} : ${TISRC}/terminfo.lua ${TISRC}/C-terminfo.c \
 ${TISRC}/test_ti.lua ${TIDIR}/terminfo.html
	md5sum ${TISRC}/terminfo.lua
	mkdir terminfo-${TIVER}
	mkdir terminfo-${TIVER}/test
	mkdir terminfo-${TIVER}/doc
	cp ${TISRC}/terminfo.lua terminfo-${TIVER}/
	cp ${TISRC}/C-terminfo.c terminfo-${TIVER}/
	cp ${TIDIR}/terminfo.html terminfo-${TIVER}/doc
	cp ${TISRC}/test_ti.lua terminfo-${TIVER}/test
	tar cvzf $@ terminfo-${TIVER}
	rm -rf terminfo-${TIVER}
${TIROCKSPEC} : ${TITARBALL} ${TISRC}/terminfo.rockspec
	perl -pe \
	 "s/VERSION/${TIVER}/ ; s/TARBALL/terminfo-${TIVER}.tar.gz/ ; s/MD5/${TIMD5}/" ${TISRC}/terminfo.rockspec > $@
	lua $@
	cp $@ ${TISRC}/terminfo-${TIVER}-0.rockspec
#${TIDIR}/terminfo.html : ${TISRC}/terminfo.lua
#	pod2html ${TISRC}/terminfo.lua | sed 's/h1>/h2>/g' > ${TISRC}/terminfo.html
#	cp ${TISRC}/terminfo.html $@

${TCTARBALL} : ${TCSRC}/testcases.lua ${TCSRC}/C-testcases.c \
 ${TCSRC}/test_tc.lua ${DISTDIR}/testcases.html
	md5sum ${TCSRC}/testcases.lua
	mkdir testcases-${TCVER}
	mkdir testcases-${TCVER}/test
	mkdir testcases-${TCVER}/doc
	cp ${TCSRC}/testcases.lua testcases-${TCVER}/
	cp ${TCSRC}/C-testcases.c testcases-${TCVER}/
	cp ${DISTDIR}/testcases.html testcases-${TCVER}/doc
	cp ${TCSRC}/test_tc.lua testcases-${TCVER}/test
	tar cvzf $@ testcases-${TCVER}
	rm -rf testcases-${TCVER}
${TCROCKSPEC} : ${TCTARBALL} ${TCSRC}/testcases.rockspec
	perl -pe \
	 "s/VERSION/${TCVER}/ ; s/TARBALL/testcases-${TCVER}.tar.gz/ ; s/MD5/${TCMD5}/" ${TCSRC}/testcases.rockspec > $@
	lua $@
	cp $@ ${TCSRC}/testcases-${TCVER}-0.rockspec
#${DISTDIR}/testcases.html : ${TCSRC}/testcases.lua
#	pod2html ${TCSRC}/testcases.lua | sed 's/h1>/h2>/g' > ${TCSRC}/testcases.html
#	cp ${TCSRC}/testcases.html $@

${RLTARBALL} : ${RLSRC}/readline.lua ${RLSRC}/C-readline.c \
 ${RLSRC}/test_rl.lua ${RLDIR}/readline.html
	md5sum ${RLSRC}/readline.lua
	mkdir readline-${RLVER}
	mkdir readline-${RLVER}/test
	mkdir readline-${RLVER}/doc
	cp ${RLSRC}/readline.lua readline-${RLVER}/
	cp ${RLSRC}/C-readline.c readline-${RLVER}/
	cp ${RLDIR}/readline.html readline-${RLVER}/doc
	cp ${RLSRC}/test_rl.lua readline-${RLVER}/test
	tar cvzf $@ readline-${RLVER}
	rm -rf readline-${RLVER}
${RLROCKSPEC} : ${RLTARBALL} ${RLSRC}/readline.rockspec
	perl -pe \
	 "s/VERSION/${RLVER}/ ; s/TARBALL/readline-${RLVER}.tar.gz/ ; s/MD5/${RLMD5}/" ${RLSRC}/readline.rockspec > $@
	lua $@
	cp $@ ${RLSRC}/readline-${RLVER}-0.rockspec
#${RLDIR}/readline.html : ${RLSRC}/readline.lua
#	pod2html ${RLSRC}/readline.lua | sed 's/h1>/h2>/g' > ${RLSRC}/readline.html
#	cp ${RLSRC}/readline.html $@

${CLUITARBALL} : ${CLUISRC}/CommandLineUI.lua ${CLUIDIR}/commandlineui.html \
  /home/pjb/lua/test/test_clui
	md5sum ${CLUISRC}/CommandLineUI.lua
	mkdir CommandLineUI-${CLUIVER}
	mkdir CommandLineUI-${CLUIVER}/test
	mkdir CommandLineUI-${CLUIVER}/doc
	cp ${CLUISRC}/CommandLineUI.lua CommandLineUI-${CLUIVER}/
	cp ${CLUIDIR}/commandlineui.html CommandLineUI-${CLUIVER}/doc/
	cp /home/pjb/lua/test/test_clui CommandLineUI-${CLUIVER}/test/
	tar cvzf $@ CommandLineUI-${CLUIVER}
	rm -rf CommandLineUI-${CLUIVER}
${CLUIROCKSPEC} : ${CLUITARBALL} /home/pjb/lua/dist/commandlineui.rockspec
	perl -pe \
	 "s/VERSION/${CLUIVER}/ ; s/TARBALL/CommandLineUI-${CLUIVER}.tar.gz/ ; s/MD5/${CLUIMD5}/" /home/pjb/lua/dist/commandlineui.rockspec > $@
	lua $@
#${CLUIDIR}/commandlineui.html : ${CLUISRC}/CommandLineUI.lua
#	pod2html ${CLUISRC}/CommandLineUI.lua | sed 's/h1>/h2>/g' > $@

${DFILTARBALL} : ${DFILSRC}/digitalfilter.lua test/test_digitalfilter.lua
	md5sum ${DFILSRC}/digitalfilter.lua
	mkdir digitalfilter-${DFILVER}
	mkdir digitalfilter-${DFILVER}/test
	cp ${DFILSRC}/digitalfilter.lua digitalfilter-${DFILVER}/
	cp /home/pjb/lua/test/test_digitalfilter.lua digitalfilter-${DFILVER}/test/
	tar cvzf $@ digitalfilter-${DFILVER}
	rm -rf digitalfilter-${DFILVER}
${DFILROCKSPEC} : ${DFILTARBALL} /home/pjb/lua/dist/digitalfilter.rockspec
	perl -pe \
	 "s/VERSION/${DFILVER}/ ; s/TARBALL/digitalfilter-${DFILVER}.tar.gz/ ; s/MD5/${DFILMD5}/" /home/pjb/lua/dist/digitalfilter.rockspec > $@
	lua $@

${DUMPTARBALL} : ${DUMPSRC}/DataDumper.lua test/test_dump
	md5sum ${DUMPSRC}/DataDumper.lua
	mkdir DataDumper-${DUMPVER}
	mkdir DataDumper-${DUMPVER}/test
	cp ${DUMPSRC}/DataDumper.lua DataDumper-${DUMPVER}/
	cp /home/pjb/lua/test/test_dump DataDumper-${DUMPVER}/test/
	tar cvzf $@ DataDumper-${DUMPVER}
	rm -rf DataDumper-${DUMPVER}
${DUMPROCKSPEC} : ${DUMPTARBALL} /home/pjb/lua/dist/datadumper.rockspec
	perl -pe \
	 "s/VERSION/${DUMPVER}/ ; s/TARBALL/DataDumper-${DUMPVER}.tar.gz/ ; s/MD5/${DUMPMD5}/" /home/pjb/lua/dist/datadumper.rockspec > $@
	lua $@

${RANDTARBALL} : ${RANDSRC}/randomdist.lua test/test_randomdist.lua
	md5sum ${RANDSRC}/randomdist.lua
	mkdir randomdist-${RANDVER}
	mkdir randomdist-${RANDVER}/test
	cp ${RANDSRC}/randomdist.lua randomdist-${RANDVER}/
	cp /home/pjb/lua/test/test_randomdist.lua randomdist-${RANDVER}/test/
	tar cvzf $@ randomdist-${RANDVER}
	rm -rf randomdist-${RANDVER}
${RANDROCKSPEC} : ${RANDTARBALL} /home/pjb/lua/dist/randomdist.rockspec
	perl -pe \
	 "s/VERSION/${RANDVER}/ ; s/TARBALL/randomdist-${RANDVER}.tar.gz/ ; s/MD5/${RANDMD5}/" /home/pjb/lua/dist/randomdist.rockspec > $@
	lua $@

${SOXTARBALL} : ${SOXSRC}/sox.lua ${SOXSRC}/C-sox.c \
 ${SOXSRC}/test_sox.lua ${SOXDIR}/sox.html
	md5sum ${SOXSRC}/sox.lua
	mkdir sox-${SOXVER}
	mkdir sox-${SOXVER}/test
	mkdir sox-${SOXVER}/doc
	cp ${SOXSRC}/sox.lua sox-${SOXVER}/
	cp ${SOXSRC}/C-sox.c sox-${SOXVER}/
	cp ${SOXDIR}/sox.html sox-${SOXVER}/doc
	cp ${SOXSRC}/test_sox.lua sox-${SOXVER}/test
	tar cvzf $@ sox-${SOXVER}
	rm -rf sox-${SOXVER}
${SOXROCKSPEC} : ${SOXTARBALL} ${SOXSRC}/sox.rockspec
	perl -pe \
	 "s/VERSION/${SOXVER}/ ; s/TARBALL/sox-${SOXVER}.tar.gz/ ; s/MD5/${SOXMD5}/" ${SOXSRC}/sox.rockspec > $@
	lua $@
	cp $@ ${SOXSRC}/sox-${SOXVER}-0.rockspec
${SOXDIR}/sox.html : ${SOXSRC}/sox.lua
	pod2html ${SOXSRC}/sox.lua | sed 's/h1>/h2>/g' > ${SOXSRC}/sox.html
	cp ${SOXSRC}/sox.html $@

${TIFTARBALL} : ${TIFSRC}/terminfofont.lua test/test_terminfofont.lua
	md5sum ${TIFSRC}/terminfofont.lua
	mkdir terminfofont-${TIFVER}
	mkdir terminfofont-${TIFVER}/test
	mkdir terminfofont-${TIFVER}/doc
	cp ${DISTDIR}/terminfofont.html terminfofont-${TIFVER}/doc
	cp ${TIFSRC}/terminfofont.lua terminfofont-${TIFVER}/
	cp /home/pjb/lua/test/test_terminfofont.lua terminfofont-${TIFVER}/test/
	tar cvzf $@ terminfofont-${TIFVER}
	rm -rf terminfofont-${TIFVER}
${TIFROCKSPEC} : ${TIFTARBALL} /home/pjb/lua/dist/terminfofont.rockspec
	perl -pe \
	 "s/VERSION/${TIFVER}/ ; s/TARBALL/terminfofont-${TIFVER}.tar.gz/ ; s/MD5/${TIFMD5}/" /home/pjb/lua/dist/terminfofont.rockspec > $@
	lua $@
