#!/usr/bin/bash
#
# Install Haskell with Stackage
#
# Copyright (c) 2014 Ondra Pelech
# license GPL-3.0+
#
# https://github.com/sideeffffect/install-haskell-stackage
#

GHC_VER="7.8.3"
GHC_VER_STACKAGE="78"

CABAL_VER="1.20.0.3"
GHC_TAR="ghc-${GHC_VER}-x86_64-unknown-linux-deb7.tar.xz"
CABAL_TAR="cabal-install-${CABAL_VER}.tar.gz"
GHC_SOURCE="https://www.haskell.org/ghc/dist"
CABAL_SOURCE="https://hackage.haskell.org/package"
STACKAGE_SOURCE="http://www.stackage.org/stackage"
STACKAGE_ALIAS="http://www.stackage.org/alias/fpcomplete/unstable-ghc${GHC_VER_STACKAGE}"
PREFIX=$HOME/.local
set -e
NOW=$(date +"%Y_%m_%d__%H_%M_%S")

echo
echo Install Haskell with Stackage, $NOW
echo
echo

echo -e "\033[1m###  Backing up old installation...  #########################################\033[m"

function backup {
  if [ -e $1 ]; then
    OLD=$1.$NOW
    echo "Moving old ${1} to ${OLD}"
    mv $1 $OLD
  fi
}

backup $HOME/.ghc
backup $HOME/.cabal
backup $PREFIX/ghc-${GHC_VER}

echo


echo -e "\033[1m###  Setting up environment...  ##############################################\033[m"

TMPDIR=/tmp/install-haskell
mkdir -p $TMPDIR

if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  echo 'export PATH=$HOME/.local/bin:$PATH'
  echo 'export PATH=$HOME/.local/bin:$PATH' >> $HOME/.profile
  echo 'export PATH=$HOME/.local/bin:$PATH' >> $HOME/.bash_profile
  export PATH=$HOME/.local/bin:$PATH
fi

if [[ ":$PATH:" != *":$HOME/.cabal/bin:"* ]]; then
  echo 'export PATH=$HOME/.cabal/bin:$PATH'
  echo 'export PATH=$HOME/.cabal/bin:$PATH' >> $HOME/.profile
  echo 'export PATH=$HOME/.cabal/bin:$PATH' >> $HOME/.bash_profile
  export PATH=$HOME/.cabal/bin:$PATH
fi

echo


echo -e "\033[1m###  Installing GHC...  ######################################################\033[m"

cd $TMPDIR

if [ ! -e $GHC_TAR ]; then
  echo -e "\033[1mDownloading GHC\033[m"
  wget "${GHC_SOURCE}/${GHC_VER}/${GHC_TAR}"
else
  echo -e "\033[1mUsing already downloaded GHC in \033[m${TMPDIR}"
fi

[ -e SHA256SUMS ] && rm SHA256SUMS
wget "${GHC_SOURCE}/${GHC_VER}/SHA256SUMS"
CHECK=`sha256sum -c SHA256SUMS 2>&1 | grep "${GHC_TAR}: "`
if [ "${CHECK}" != "${GHC_TAR}: OK" ]; then
  echo
  echo -e "\033[1mChecksum of\033[m ${GHC_TAR} \033[1mfailed! Please run the script again.\033[m"
  mv $GHC_TAR $GHC_TAR.$NOW
  exit 1
fi

tar xf $GHC_TAR
cd ghc-${GHC_VER}

echo -e "\033[1mConfiguring GHC\033[m"
./configure --prefix=$PREFIX

echo -e "\033[1mInstalling GHC\033[m"
make install

echo


echo -e "\033[1m###  Checking GHC...  ########################################################\033[m"

cd
ghc --version
ghc-pkg list
echo


echo -e "\033[1m###  Installing cabal-install...  ############################################\033[m"

cd $TMPDIR
[ -e $CABAL_TARBALL ] && rm $CABAL_TARBALL

echo -e "\033[1mDownloading cabal-install\033[m"
wget ${CABAL_SOURCE}/cabal-install-${CABAL_VER}/${CABAL_TARBALL}

echo -e "\033[1mInstalling cabal-install\033[m"
tar xf $CABAL_TARBALL
cd cabal-install-${CABAL_VER}
./bootstrap.sh

echo


echo -e "\033[1m###  Checking cabal-install...  ##############################################\033[m"

cd
cabal --version
ghc-pkg list
echo


echo -e "\033[1m###  Getting Stackage snapshots...  ##########################################\033[m"

STACKAGE_SNAPSHOT_INCLUSIVE=`wget -q -O - ${STACKAGE_ALIAS}-inclusive/ | tr -c '[[:alnum:]]' '\n' | grep -E '^[0-9a-z]{40}$' | head -n1`
STACKAGE_SNAPSHOT_EXCLUSIVE=`wget -q -O - ${STACKAGE_ALIAS}-exclusive/ | tr -c '[[:alnum:]]' '\n' | grep -E '^[0-9a-z]{40}$' | head -n1`

if [ $STACKAGE_SNAPSHOT_INCLUSIVE == ""  ] ; then
  echo "Unable to get STACKAGE_SNAPSHOT_INCLUSIVE"
  exit 1
fi
if [ $STACKAGE_SNAPSHOT_EXCLUSIVE == ""  ] ; then
  echo "Unable to get STACKAGE_SNAPSHOT_EXCLUSIVE"
  exit 1
fi

echo -e "\033[1mUsing the Stackage snapshots\033[m"
echo "Inclusive: ${STACKAGE_SOURCE}/${STACKAGE_SNAPSHOT_INCLUSIVE}"
echo "Exclusive: ${STACKAGE_SOURCE}/${STACKAGE_SNAPSHOT_EXCLUSIVE}"

echo


echo -e "\033[1m###  Intalling Stackage...  ##################################################\033[m"

rm -rf $HOME/.cabal
rm -rf $HOME/.ghc

cabal info >/dev/null 2>&1
perl -pi.bak -e 's#^remote-repo: .*$#remote-repo: 'stackage:${STACKAGE_SOURCE}/${STACKAGE_SNAPSHOT_INCLUSIVE}'#' $HOME/.cabal/config
cabal update

echo


echo -e "\033[1m###  Intalling cabal-install from Stackage...  ###############################\033[m"

cabal install cabal-install
hash -r
echo


echo -e "\033[1m###  Checking cabal-install from Stackage...  ################################\033[m"

cabal --version
ghc-pkg list
echo


echo -e "\033[1m###  Installing alex and happy  ##############################################\033[m"

cabal install alex happy
echo


echo -e "\033[1m###  Final check  ############################################################\033[m"

ghc --version
cabal --version
ghc-pkg list
echo

echo -e "\033[1m###  FINISHED  ###############################################################\033[m"

