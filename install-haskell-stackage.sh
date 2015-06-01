#!/bin/bash
#
# Install Haskell with Stackage
#
# Copyright (c) 2014 Ondra Pelech
# license GPL-3.0+
#
# https://github.com/sideeffffect/install-haskell-stackage
#

GHC_VER="7.8.4"
CABAL_VER="1.22.4.0"

HASKELL_PLATFORM_PACKAGES="array async attoparsec base bytestring case-insensitive containers deepseq directory extensible-exceptions fgl filepath GLURaw GLUT hashable haskell2010 haskell98 hpc hscolour html HTTP HUnit mtl network old-locale old-time OpenGL OpenGLRaw parallel parsec pretty primitive process QuickCheck random regex-base regex-compat regex-posix split stm syb template-haskell text time transformers unix unordered-containers vector xhtml zlib"
GHC_TAR="ghc-${GHC_VER}-x86_64-unknown-linux-deb7.tar.xz"
CABAL_TAR="cabal-install-${CABAL_VER}.tar.gz"
GHC_SOURCE="https://www.haskell.org/ghc/dist"
CABAL_SOURCE="https://hackage.haskell.org/package"
STACKAGE="https://www.stackage.org"
STACKAGE_BRANCH="lts"
PREFIX=$HOME/.local
NOW=$(date +"%Y_%m_%d__%H_%M_%S")


function backup {
  if [ -e "$1" ]; then
    OLD=$1.$NOW
    echo "Moving old ${1} to ${OLD}"
    mv "$1" "$OLD"
  fi
}

function cabal_install_insist {
  until cabal install "$@"
    do echo -e "\033[1mcabal install failed, trying again...\033[m"
  done
}

function install_stackage {
  [ -e "$HOME/.cabal/bin/cabal" ] && mv "$HOME/.cabal/bin/cabal" "$TMPDIR"
  rm -rf "$HOME/.cabal"
  rm -rf "$HOME/.ghc"
  mkdir -p "$HOME/.cabal/bin"
  [ -e "$TMPDIR/cabal" ] && mv "$TMPDIR/cabal" "$HOME/.cabal/bin/"
  
  hash -r
  
  cabal info > /dev/null 2>&1
  curl -sf -L "${STACKAGE}/${STACKAGE_BRANCH}/cabal.config?global=true" >> "$HOME/.cabal/config"
  echo
  cabal update
  echo
}


echo
echo "Install Haskell with Stackage, $NOW"
echo
echo

echo -e "\033[1m###  Backing up old installation...  #########################################\033[m"

backup "$HOME/.ghc"
backup "$HOME/.cabal"

echo


echo -e "\033[1m###  Setting up environment...  ##############################################\033[m"

TMPDIR=/tmp/install-haskell-stackage
mkdir -p $TMPDIR

if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  echo 'export PATH=$HOME/.local/bin:$PATH'
  echo 'export PATH=$HOME/.local/bin:$PATH' >> "$HOME/.profile"
  echo 'export PATH=$HOME/.local/bin:$PATH' >> "$HOME/.bash_profile"
  export PATH=$HOME/.local/bin:$PATH
fi

if [[ ":$PATH:" != *":$HOME/.cabal/bin:"* ]]; then
  echo 'export PATH=$HOME/.cabal/bin:$PATH'
  echo 'export PATH=$HOME/.cabal/bin:$PATH' >> "$HOME/.profile"
  echo 'export PATH=$HOME/.cabal/bin:$PATH' >> "$HOME/.bash_profile"
  export PATH=$HOME/.cabal/bin:$PATH
fi

echo


echo -e "\033[1m###  Installing GHC...  ######################################################\033[m"

if [[ "$(ghc --version)" != *"${GHC_VER}"* ]]; then
  
  cd $TMPDIR
  
  if [ ! -e $GHC_TAR ]; then
    echo -e "\033[1mDownloading GHC\033[m"
    curl -O -L "${GHC_SOURCE}/${GHC_VER}/${GHC_TAR}"
  else
    echo -e "\033[1mUsing already downloaded GHC in \033[m${TMPDIR}"
  fi
  
  [ -e SHA256SUMS ] && rm SHA256SUMS
  curl -O -L "${GHC_SOURCE}/${GHC_VER}/SHA256SUMS"
  CHECK=$(sha256sum -c SHA256SUMS 2>&1 | grep "${GHC_TAR}: ")
  if [ "${CHECK}" != "${GHC_TAR}: OK" ]; then
    echo
    echo -e "\033[1mChecksum of\033[m ${GHC_TAR} \033[1mfailed! Please run the script again.\033[m"
    mv $GHC_TAR "$GHC_TAR.$NOW"
    exit 1
  else
    echo -e "\033[1mChecksum of\033[m ${GHC_TAR} \033[1mOK.\033[m"
  fi
  
  [ -e ghc-${GHC_VER} ] && rm -rf ghc-${GHC_VER}
  tar xf $GHC_TAR
  cd ghc-${GHC_VER}
  
  echo -e "\033[1mConfiguring GHC\033[m"
  ./configure --prefix="$PREFIX"
  
  echo -e "\033[1mInstalling GHC\033[m"
  make install
  
  echo
else
  echo -e "Using already installed GHC"
  echo
fi


echo -e "\033[1m###  Checking GHC...  ########################################################\033[m"

cd
which ghc
ghc --version
ghc-pkg list
echo


echo -e "\033[1m###  Installing cabal-install...  ############################################\033[m"

if [ ! -e "$(which cabal)" ]; then
  
  cd $TMPDIR
  [ -e $CABAL_TAR ] && rm $CABAL_TAR
  
  echo -e "\033[1mDownloading cabal-install\033[m"
  curl -O -L ${CABAL_SOURCE}/cabal-install-${CABAL_VER}/${CABAL_TAR}
  
  echo -e "\033[1mInstalling cabal-install\033[m"
  [ -e cabal-install-${CABAL_VER} ] && rm -rf cabal-install-${CABAL_VER}
  tar xf $CABAL_TAR
  cd cabal-install-${CABAL_VER}
  ./bootstrap.sh
  
  echo
else
  echo -e "Using already installed cabal-install"
  echo
fi


echo -e "\033[1m###  Checking cabal-install...  ##############################################\033[m"

cd
which cabal
cabal --version
ghc-pkg list
echo


echo -e "\033[1m###  Bootstrapping cabal-install from Stackage...  ###########################\033[m"

install_stackage

cabal_install_insist cabal-install

install_stackage

cabal_install_insist cabal-install


echo -e "\033[1m###  Checking cabal-install from Stackage...  ################################\033[m"

which cabal
cabal --version
echo


echo -e "\033[1m###  Installing packages in Haskell Platform  ################################\033[m"

cabal_install_insist alex happy
cabal_install_insist cpphs gtk2hs-buildtools
#cabal_install_insist $HASKELL_PLATFORM_PACKAGES
echo


echo -e "\033[1m###  Final check  ############################################################\033[m"

which ghc
ghc --version
which cabal
cabal --version
ghc-pkg list
echo

echo -e "\033[1m###  FINISHED  ###############################################################\033[m"

