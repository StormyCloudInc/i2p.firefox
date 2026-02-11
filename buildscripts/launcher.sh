#! /usr/bin/env bash
set -e 

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)/..
cd "$SCRIPT_DIR" || exit 1

. "$SCRIPT_DIR/i2pversion"

if [ -f i2pversion_override ]; then
    . "$SCRIPT_DIR/i2pversion_override"
fi

. "$SCRIPT_DIR/config.sh"

if [ -f "$SCRIPT_DIR/config_override.sh" ]; then
  . "$SCRIPT_DIR/config_override.sh"
fi

COUNT="Ten Nine Eight Seven Six Five Four Three Two One"

which java
export JAVA=$(java --version | tr -d 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ\n' | cut -d ' ' -f 2 | cut -d '.' -f 1 | tr -d '\n\t\- ')

if [ "$JAVA" -lt "21" ]; then
  echo "Java 21+ must be used to compile with jpackage, java is $JAVA"
  exit 1
fi

if [ -z "${JAVA_HOME}" ]; then
  export JAVA_HOME=$(type -p java|xargs readlink -f|xargs dirname|xargs dirname)
fi
if [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
  export JAVA_HOME=$(type -p java|xargs readlink -f|xargs dirname|xargs dirname)
fi
echo "Building with: $JAVA, $JAVA_HOME"
sleep 5s

"$SCRIPT_DIR"/buildscripts/version.sh
"$SCRIPT_DIR"/buildscripts/licenses.sh

#SCRIPT_DIR="$PWD"
export I2P_PKG="$SCRIPT_DIR/../i2p.i2p.jpackage-build/pkg-temp"
export RES_DIR="$SCRIPT_DIR/../i2p.i2p.jpackage-build/installer/resources"
export I2P_JARS="$I2P_PKG/lib"
export I2P_JBIGI="$SCRIPT_DIR/../i2p.i2p.jpackage-build/installer/lib/jbigi"
export I2P_JBIGI_JAR="$SCRIPT_DIR/../i2p.i2p.jpackage-build/build/jbigi.jar"
if [ ! -d "$SCRIPT_DIR/../i2p.i2p.jpackage-build/" ]; then
  if [ -d "$SCRIPT_DIR/../i2p.i2p/" ]; then
    echo cloning from local i2p.i2p checkout
    git clone --depth=1 -b "$VERSION" -l "$SCRIPT_DIR/../i2p.i2p/" "$SCRIPT_DIR/../i2p.i2p.jpackage-build/"
  else
    echo cloning from remote i2p.i2p repository
    git clone --depth=1 -b "$VERSION" https://i2pgit.org/i2p-hackers/i2p.i2p "$SCRIPT_DIR/../i2p.i2p.jpackage-build/"
  fi
fi
cd "$SCRIPT_DIR/../i2p.i2p.jpackage-build/"
echo "setting up git branch for build"
OLDEXTRA=$(find . -name RouterVersion.java -exec grep 'String EXTRA' {} \;)
if [ -z "$EXTRA" ]; then
  export EXTRACODE="win"
  export EXTRA="    public final static String EXTRA = \"-$EXTRACODE\";"
fi
if [ "$VERSION" = master ]; then
  VERSIONDATE="$(date +%m%d)"
else
  export TAG_VERSION="$VERSION"
fi
echo "build is: i2p-$TAG_VERSION-$VERSIONDATE-$EXTRACODE"

find . -name RouterVersion.java -exec sed -i "s|$OLDEXTRA|$EXTRA|g" {} \;
git switch - || :
git pull --tags
git checkout -b "i2p-$TAG_VERSION-$VERSIONDATE-$EXTRACODE" || :
git commit -am "i2p-$TAG_VERSION-$VERSIONDATE-$EXTRACODE" || :
git archive --format=tar.gz --output="$SCRIPT_DIR/../i2p.firefox/i2p.i2p.jpackage-build.tar.gz" "i2p-$TAG_VERSION-$VERSIONDATE-$EXTRACODE"
git checkout "i2p-$TAG_VERSION-$VERSIONDATE-$EXTRACODE" || :

for i in $COUNT; do
  echo -n "$i...."; sleep 1s
done
ant distclean pkg || true
ant jbigi

cd "$SCRIPT_DIR"

mkdir -p "$SCRIPT_DIR/src/I2P/config"
rm -rf "$SCRIPT_DIR/src/I2P/config/geoip" "$SCRIPT_DIR/src/I2P/config/webapps" "$SCRIPT_DIR/src/I2P/config/certificates" "$SCRIPT_DIR/src/I2P/config/eepsite"
cp -v "$RES_DIR/clients.config" "$SCRIPT_DIR/src/I2P/config/"
cp -v "$RES_DIR/wrapper.config" "$SCRIPT_DIR/src/I2P/config/"
#grep -v 'router.updateURL' $(RES_DIR)/router.config > "$SCRIPT_DIR"/src/I2P/config/router.config
cat router.config > "$SCRIPT_DIR/src/I2P/config/router.config"
cat i2ptunnel.config > "$SCRIPT_DIR/src/I2P/config/i2ptunnel.config"
cp -v "$RES_DIR/hosts.txt" "$SCRIPT_DIR/src/I2P/config/hosts.txt"
cp -R "$RES_DIR/certificates" "$SCRIPT_DIR/src/I2P/config/certificates"
cp -R "$RES_DIR/eepsite" "$SCRIPT_DIR/src/I2P/config/eepsite"
mkdir -p "$SCRIPT_DIR/src/I2P/config/geoip"
cp -v "$RES_DIR/GeoLite2-Country.mmdb.gz" "$SCRIPT_DIR/src/I2P/config/geoip/GeoLite2-Country.mmdb.gz"
cp -R "$I2P_PKG/webapps" "$SCRIPT_DIR/src/I2P/config/webapps"
cd "$SCRIPT_DIR/src/I2P/config/geoip" && gunzip GeoLite2-Country.mmdb.gz; cd ../../..

echo "compiling custom launcher"
mkdir -p "$SCRIPT_DIR/build"
cp "$I2P_JARS"/*.jar "$SCRIPT_DIR/build"
cp "$I2P_JBIGI_JAR" "$SCRIPT_DIR/build"

# Replace desktopgui system tray icons with our own
echo "replacing desktopgui icons"
ICON_SRC="$SCRIPT_DIR/src/icons/desktopgui/favicon_24.png"
if [ ! -f "$ICON_SRC" ]; then
  ICON_SRC="$SCRIPT_DIR/src/icons/windowsUIToopie2.png"
fi
if [ ! -f "$ICON_SRC" ]; then
  ICON_SRC="$SCRIPT_DIR/src/icons/desktopgui/itoopie_24.png"
fi
if [ -f "$ICON_SRC" ] && [ -f "$SCRIPT_DIR/build/desktopgui.jar" ]; then
  ICON_TMP="$SCRIPT_DIR/build/desktopgui_icons"
  mkdir -p "$ICON_TMP/desktopgui/resources/images"
  cp "$ICON_SRC" "$ICON_TMP/desktopgui/resources/images/itoopie_black_24.png"
  cp "$ICON_SRC" "$ICON_TMP/desktopgui/resources/images/itoopie_white_24.png"
  cp "$ICON_SRC" "$ICON_TMP/desktopgui/resources/images/logo.png"
  cd "$ICON_TMP"
  jar uf "$SCRIPT_DIR/build/desktopgui.jar" desktopgui/resources/images/itoopie_black_24.png desktopgui/resources/images/itoopie_white_24.png desktopgui/resources/images/logo.png
  cd "$SCRIPT_DIR"
  rm -rf "$ICON_TMP"
fi

# Jetty 12 eepsite template includes optional FastCGI context, but this
# bundle does not include jetty-fcgi jars. Remove it to avoid START_FAILED.
if [ -f "$SCRIPT_DIR/src/I2P/config/eepsite/contexts/cgi-context.xml" ]; then
  rm -f "$SCRIPT_DIR/src/I2P/config/eepsite/contexts/cgi-context.xml"
fi

if [ ! -f "$SCRIPT_DIR/build/jna.jar" ]; then
  echo "downloading jna"
  wget_download "https://repo1.maven.org/maven2/net/java/dev/jna/jna/$JNA_VERSION/jna-$JNA_VERSION.jar" -O "$SCRIPT_DIR/build/jna.jar"
fi

if [ ! -f "$SCRIPT_DIR/build/jna-platform.jar" ]; then
  echo "downloading jna-platform"
  wget_download "https://repo1.maven.org/maven2/net/java/dev/jna/jna-platform/$JNA_VERSION/jna-platform-$JNA_VERSION.jar" -O "$SCRIPT_DIR/build/jna-platform.jar"
fi

if [ ! -f "$SCRIPT_DIR/build/i2pfirefox.zip" ]; then
  echo "downloading i2pfirefox jars"
  wget_download "https://github.com/eyedeekay/i2p.plugins.firefox/releases/download/$I2PFIREFOX_VERSION/plugin.zip" -O "$SCRIPT_DIR/build/i2pfirefox.zip"
fi

if [ ! -d "$SCRIPT_DIR/src/I2P/config/plugins/i2pfirefox" ]; then
  mkdir -p "$SCRIPT_DIR/src/I2P/config/plugins/"
  unzip "$SCRIPT_DIR/build/i2pfirefox.zip" -d "$SCRIPT_DIR/src/I2P/config/plugins/"
  rm -rf "$SCRIPT_DIR/src/I2P/config/plugins/i2pfirefox"
  mv "$SCRIPT_DIR/src/I2P/config/plugins/plugin" "$SCRIPT_DIR/src/I2P/config/plugins/i2pfirefox"
fi

for dll in "$I2P_JBIGI/"*windows*.dll; do
  jar uf "$SCRIPT_DIR/build/jbigi.jar" "$dll"
done

cd "$SCRIPT_DIR"/java
"$JAVA_HOME"/bin/javac -Xlint:deprecation -d ../build -classpath "$SCRIPT_DIR/build/i2pfirefox.jar:$SCRIPT_DIR/build/jna.jar:$SCRIPT_DIR/build/jna-platform.jar":"$SCRIPT_DIR/build/i2p.jar:$SCRIPT_DIR/build/router.jar:$SCRIPT_DIR/build/routerconsole.jar:$SCRIPT_DIR/build/jbigi.jar" \
  net/i2p/router/I2PAppUtil.java \
  net/i2p/router/WindowsAppUtil.java \
  net/i2p/router/WindowsServiceUtil.java \
  net/i2p/router/WinLauncher.java \
  net/i2p/router/WinUpdatePostProcessor.java \
  net/i2p/router/WinUpdateProcess.java \
  net/i2p/router/ZipUpdateProcess.java

cd ..

#echo "building launcher.jar"
cd "$SCRIPT_DIR/build"
"$JAVA_HOME"/bin/jar -cf launcher.jar net
cd ..
