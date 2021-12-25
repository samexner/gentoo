# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit bash-completion-r1 multiprocessing toolchain-funcs

DESCRIPTION="compiled, garbage-collected systems programming language"
HOMEPAGE="https://nim-lang.org/"
SRC_URI="https://nim-lang.org/download/${P}.tar.xz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm ~x86"
IUSE="debug +readline"
RESTRICT="test"  # need to sort out depends and numerous failures

RDEPEND="readline? ( sys-libs/readline:0= )"
DEPEND="${DEPEND}"
#	test? ( net-libs/nodejs )

PATCHES=( "${FILESDIR}"/${PN}-0.20.0-paths.patch )

QA_FLAGS_IGNORED="
usr/bin/atlas
usr/bin/nim
usr/bin/nim_dbg
usr/bin/nimble
usr/bin/nimgrep
usr/bin/nimpretty
usr/bin/nimsuggest
usr/bin/testament
"

_run() {
	echo "Running: ${@}"
	PATH="${S}/bin:${PATH}" "${@}" || die "Failed: \"${*}\""
}

nim_use_enable() {
	[[ -z "${2}" ]] && die "usage: nim_use_enable <USE flag> <compiler flag>"
	use "${1}" && echo "-d:${2}"
}

src_configure() {
	export XDG_CACHE_HOME="${T}/cache"  #667182
	unset NIMBLE_DIR
	tc-export CC CXX LD

	local build_type
	if use debug ; then
		build_type="debug"
	else
		build_type="release"
	fi
	export NIM_OPTS=( --parallelBuild:$(makeopts_jobs) -d:${build_type} )

	# Override defaults
	echo "gcc.exe            = \"$(tc-getCC)\""  >> config/nim.cfg || die
	echo "gcc.linkerexe      = \"$(tc-getCC)\""  >> config/nim.cfg || die
	echo "gcc.cpp.exe        = \"$(tc-getCXX)\"" >> config/nim.cfg || die
	echo "gcc.cpp.linkerexe  = \"$(tc-getCXX)\"" >> config/nim.cfg || die
}

src_compile() {
	_run bash ./build.sh

	_run ./bin/nim ${NIM_OPTS[@]} compile koch
	_run ./koch boot ${NIM_OPTS[@]} $(nim_use_enable readline useGnuReadline)
	_run ./koch tools ${NIM_OPTS[@]}
}

src_install() {
	_run ./koch install "${ED}"

	# "./koch install" installs only "nim" binary
	# but not the rest
	exeinto /usr/bin
	local exe
	for exe in bin/* ; do
		[[ "${exe}" == bin/nim ]] && continue
		doexe "${exe}"
	done

	newbashcomp tools/nim.bash-completion nim
	newbashcomp dist/nimble/nimble.bash-completion nimble
}

src_test() {
	_run ./koch test
}
