#/usr/bin/bash -ex

# pcre (ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre)
# openssl (http://www.openssl.org)
# apr
# apr-util
# httpd


# $1 URL
# $2 File
#
function download {
  if [ ! -e "$2" ]; then
    echo "Downloading $(basename $1)"
    wget --no-check-certificate -O "$2" "$1"
  fi
}
function extract {
  #echo "Checking $2/$(basename $1 .tar.gz)"
  if [ ! -e "$2/$(basename $1 .tar.gz)" ]; then
    echo "Extracting $(basename $1)"
    gtar -zxf "$1" -C "$2"
  fi
}

export PATH="/usr/sbin:/usr/bin:/usr/openwin/bin:/usr/ucb:/usr/sfw/bin:/usr/ccs/bin"
HTTPD_VERSION='2.4.10'
APR_VERSION='1.5.1'
APR_UTIL_VERSION='1.5.4'
PCRE_VERSION="8.36"
OPENSSL_VERSION="1.0.1j"
LUA_VERSION="5.2.3"

DIST_DIR="/tmp/dist"
SOURCE_DIR="/tmp/source"

export LDFLAGS=" -L/usr/sfw/lib -R/usr/sfw/lib -L/usr/X/lib -R/usr/X/lib -L/usr/X11/lib -R/usr/X11/lib -L/usr/ccs/lib -R/usr/ccs/lib "
export LD_LIBRARY_PATH='/usr/lib:/usr/sfw/lib'
export export LD_LIBRARY_PATH_64='/usr/lib/64:/usr/sfw/lib/64'
export CC='gcc'
export CFLAGS='--quiet -m64 -O3'
export CPP_FLAGS='--quiet -m64 -O3'
ROOT_INSTALL_PREFIX="/tmp/opt_httpd-${HTTPD_VERSION}"
LUA_INSTALL_PREFIX="${ROOT_INSTALL_PREFIX}/lua-${LUA_VERSION}"
OPENSSL_INSTALL_PREFIX="${ROOT_INSTALL_PREFIX}/openssl-${OPENSSL_VERSION}"
PCRE_INSTALL_PREFIX="${ROOT_INSTALL_PREFIX}/pcre-${PCRE_VERSION}"
APR_INSTALL_PREFIX="${ROOT_INSTALL_PREFIX}/apr-${APR_VERSION}"
APR_UTIL_INSTALL_PREFIX="${ROOT_INSTALL_PREFIX}/apr-util-${APR_UTIL_VERSION}"
HTTPD_INSTALL_PREFIX="${ROOT_INSTALL_PREFIX}/httpd-${HTTPD_VERSION}"
INSTALL_LOG_PREFIX="/mnt/sf_shared"

mkdir -p "${ROOT_INSTALL_PREFIX}"
rm -rf "${ROOT_INSTALL_PREFIX}"
mkdir -p "${ROOT_INSTALL_PREFIX}"

mkdir -p "${DIST_DIR}"
download "http://apache.mirror.vexxhost.com/httpd/httpd-${HTTPD_VERSION}.tar.gz" "${DIST_DIR}/httpd-${HTTPD_VERSION}.tar.gz"
download "http://mirror.csclub.uwaterloo.ca/apache/apr/apr-${APR_VERSION}.tar.gz" "${DIST_DIR}/apr-${APR_VERSION}.tar.gz"
download "http://mirror.csclub.uwaterloo.ca/apache/apr/apr-util-${APR_UTIL_VERSION}.tar.gz" "${DIST_DIR}/apr-util-${APR_UTIL_VERSION}.tar.gz"
download "ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-${PCRE_VERSION}.tar.gz" "${DIST_DIR}/pcre-${PCRE_VERSION}.tar.gz"
download "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz" "${DIST_DIR}/openssl-${OPENSSL_VERSION}.tar.gz"
download "http://www.lua.org/ftp/lua-${LUA_VERSION}.tar.gz" "${DIST_DIR}/lua-${LUA_VERSION}.tar.gz"
rm -rf "${SOURCE_DIR}"
mkdir -p "${SOURCE_DIR}"
extract "${DIST_DIR}/httpd-${HTTPD_VERSION}.tar.gz" "${SOURCE_DIR}"
extract "${DIST_DIR}/apr-${APR_VERSION}.tar.gz" "${SOURCE_DIR}"
extract "${DIST_DIR}/apr-util-${APR_UTIL_VERSION}.tar.gz" "${SOURCE_DIR}"
extract "${DIST_DIR}/pcre-${PCRE_VERSION}.tar.gz" "${SOURCE_DIR}"
extract "${DIST_DIR}/openssl-${OPENSSL_VERSION}.tar.gz" "${SOURCE_DIR}"
extract "${DIST_DIR}/lua-${LUA_VERSION}.tar.gz" "${SOURCE_DIR}"

#if [ ! -e "${SOURCE_DIR}/httpd-${HTTPD_VERSION}/srclib/apr" ]; then
#  mv "${SOURCE_DIR}/apr-${APR_VERSION}" "${SOURCE_DIR}/httpd-${HTTPD_VERSION}/srclib/apr"
#  ln -s "${SOURCE_DIR}/httpd-${HTTPD_VERSION}/srclib/apr" "${SOURCE_DIR}/apr-${APR_VERSION}"
#fi

#if [ ! -e "${SOURCE_DIR}/httpd-${HTTPD_VERSION}/srclib/apr-util" ]; then
#  mv "${SOURCE_DIR}/apr-util-${APR_UTIL_VERSION}" "${SOURCE_DIR}/httpd-${HTTPD_VERSION}/srclib/apr-util"
#  ln -s "${SOURCE_DIR}/httpd-${HTTPD_VERSION}/srclib/apr-util" "${SOURCE_DIR}/apr-util-${APR_UTIL_VERSION}"
#fi

##LUA
echo "Building LUA ${LUA_VERSION} to ${LUA_INSTALL_PREFIX}" | tee "${INSTALL_LOG_PREFIX}/lua.log"
cd "${SOURCE_DIR}/lua-${LUA_VERSION}"
gmake solaris install "INSTALL_TOP=${LUA_INSTALL_PREFIX}" 'INSTALL=cp -p' 'INSTALL_EXEC=$(INSTALL)' 'INSTALL_DATA=$(INSTALL)' >> "${INSTALL_LOG_PREFIX}/lua.log" 2>&1
"${LUA_INSTALL_PREFIX}/bin/lua" -e 'print ("Hello World!")'
##man says that it is no longer required
ranlib "${SOURCE_DIR}/lua-${LUA_VERSION}/install/lib/liblua.a"  >> "${INSTALL_LOG_PREFIX}/lua.log"

#export CC='gcc -m32'
echo "Building OPENSSL ${OPENSSL_VERSION} to ${OPENSSL_INSTALL_PREFIX}" | tee "${INSTALL_LOG_PREFIX}/openssl.log"
cd "${SOURCE_DIR}/openssl-${OPENSSL_VERSION}"
./config "--prefix=${OPENSSL_INSTALL_PREFIX}" shared >> "${INSTALL_LOG_PREFIX}/openssl.log"
# "--openssldir=${OPENSSL_INSTALL_PREFIX}"
gmake clean >> "${INSTALL_LOG_PREFIX}/openssl.log" 2>&1
gmake  >> "${INSTALL_LOG_PREFIX}/openssl.log" 2>&1
echo "Installing OPENSSL ${OPENSSL_VERSION} to ${OPENSSL_INSTALL_PREFIX}" | tee "${INSTALL_LOG_PREFIX}/openssl.log"
gmake install >> "${INSTALL_LOG_PREFIX}/openssl.log"

#Install PCRE
#The -m64 flag is FUNDAMENTAL!!! Not sure about the others
echo "Building PCRE ${PCRE_VERSION} to ${PCRE_INSTALL_PREFIX}" | tee "${INSTALL_LOG_PREFIX}/pcre.log"
cd "${SOURCE_DIR}/pcre-${PCRE_VERSION}"
./configure --disable-cpp CFLAGS="-g -O3" CC="gcc -m64" "--prefix=${PCRE_INSTALL_PREFIX}" >> "${INSTALL_LOG_PREFIX}/pcre.log" 2>&1
gmake clean >> "${INSTALL_LOG_PREFIX}/pcre.log" 2>&1
gmake >> "${INSTALL_LOG_PREFIX}/pcre.log" 2>&1
echo "Installing ..."
gmake install >> "${INSTALL_LOG_PREFIX}/pcre.log" 2>&1

echo "Building APR ${APR_VERSION} to ${APR_INSTALL_PREFIX}" | tee "${INSTALL_LOG_PREFIX}/apr.log"
cd "${SOURCE_DIR}/apr-${APR_VERSION}"
./configure "--prefix=${APR_INSTALL_PREFIX}" --with-gnu-ld --enable-threads >> "${INSTALL_LOG_PREFIX}/apr.log" 2>&1
gmake clean >> "${INSTALL_LOG_PREFIX}/apr.log" 2>&1
gmake >> "${INSTALL_LOG_PREFIX}/apr.log" 2>&1
gmake install >> "${INSTALL_LOG_PREFIX}/apr.log" 2>&1

#Install ARP-UTIL
echo "Building APR-UTIL ${APR_UTIL_VERSION} to ${APR_UTIL_INSTALL_PREFIX}" | tee "${INSTALL_LOG_PREFIX}/apr-util.log"
cd "${SOURCE_DIR}/apr-util-${APR_UTIL_VERSION}"
./configure "--prefix=${APR_UTIL_INSTALL_PREFIX}" "--with-openssl=${OPENSSL_INSTALL_PREFIX}" "--with-apr=${APR_INSTALL_PREFIX}" --with-crypto --enable-threads >> "${INSTALL_LOG_PREFIX}/apr-util.log" 2>&1
gmake clean >> "${INSTALL_LOG_PREFIX}/apr-util.log" 2>&1
gmake >> "${INSTALL_LOG_PREFIX}/apr-util.log" 2>&1
echo "Installing ..."
gmake install >> "${INSTALL_LOG_PREFIX}/apr-util.log" 2>&1

#Install Apache. THE HOT PART!!
echo "Building HTTPD ${HTTPD_VERSION} to ${HTTPD_INSTALL_PREFIX}" | tee "${INSTALL_LOG_PREFIX}/httpd.log"
cd "${SOURCE_DIR}/httpd-${HTTPD_VERSION}"
./configure "--prefix=${HTTPD_INSTALL_PREFIX}" --enable-so --enable-pie --enable-lua "--with-lua=${LUA_INSTALL_PREFIX}" --enable-module=all --enable-mods-shared=all --enable-proxy --enable-proxy-connect --enable-proxy-ftp --enable-proxy-http --enable-proxy-ajp --enable-proxy-balancer --enable-ssl=shared "--with-ssl=${OPENSSL_INSTALL_PREFIX}" --enable-static-support --enable-static-htpasswd --enable-static-htdigest --enable-static-rotatelogs --enable-static-logresolve --enable-cgi --enable-vhost --enable-imagemap --with-mpm=prefork "--with-pcre=${PCRE_INSTALL_PREFIX}" "--with-apr=${APR_INSTALL_PREFIX}" "--with-apr-util=${APR_UTIL_INSTALL_PREFIX}" >> "${INSTALL_LOG_PREFIX}/httpd.log" 2>&1
gmake clean >> "${INSTALL_LOG_PREFIX}/httpd.log" 2>&1
gmake >> "${INSTALL_LOG_PREFIX}/httpd.log" 2>&1
echo "Installing ..."
gmake install >> "${INSTALL_LOG_PREFIX}/httpd.log" 2>&1
echo "LD_LIBRARY_PATH=\"\"" > "${HTTPD_INSTALL_PREFIX}/bin/envvars"
echo "LD_LIBRARY_PATH=\"${LUA_INSTALL_PREFIX}/lib:\$LD_LIBRARY_PATH\"" >> "${HTTPD_INSTALL_PREFIX}/bin/envvars"
echo "LD_LIBRARY_PATH=\"${PCRE_INSTALL_PREFIX}/lib:\$LD_LIBRARY_PATH\"" >> "${HTTPD_INSTALL_PREFIX}/bin/envvars"
echo "LD_LIBRARY_PATH=\"${APR_INSTALL_PREFIX}/lib:\$LD_LIBRARY_PATH\"" >> "${HTTPD_INSTALL_PREFIX}/bin/envvars"
echo "LD_LIBRARY_PATH=\"${APR_UTIL_INSTALL_PREFIX}/lib:\$LD_LIBRARY_PATH\"" >> "${HTTPD_INSTALL_PREFIX}/bin/envvars"
echo "LD_LIBRARY_PATH=\"${OPENSSL_INSTALL_PREFIX}/lib:\$LD_LIBRARY_PATH\"" >> "${HTTPD_INSTALL_PREFIX}/bin/envvars"
echo "LD_LIBRARY_PATH=\"${HTTPD_INSTALL_PREFIX}/lib:\$LD_LIBRARY_PATH\"\"" >> "${HTTPD_INSTALL_PREFIX}/bin/envvars"

