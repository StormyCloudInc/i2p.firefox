#! /usr/bin/env bash

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

# Timestamp server for code signing longevity
TIMESTAMP_SERVER="${TIMESTAMP_SERVER:-http://timestamp.digicert.com}"

linuxsign() {
    ## LINUX SIGNING IS EXPERIMENTAL AND SHOULD NOT BE USED IN DEFAULT STATE.
    if [ ! -f jsign-4.1.jar ]; then
        wget -O jsign-4.1.jar https://github.com/ebourg/jsign/releases/download/4.1/jsign-4.1.jar
    fi
    if [ ! -f "$HOME/signingkeys/signing-key.jks" ]; then
        mkdir -p "$HOME/signingkeys/"
        keytool -genkey -alias server-alias -keyalg RSA -keypass changeit \
            -storepass changeit -keystore "$HOME/signingkeys/signing-key.jks"
    fi
    java -jar jsign-4.1.jar \
        --keystore "$HOME/signingkeys/signing-key.jks" \
        --storepass changeit \
        --keypass changeit \
        --tsaurl "$TIMESTAMP_SERVER" \
        --name "I2P-Easy-Install-Bundle" \
        --alg "SHA-512" \
        "$1"
}

windowssign() {
    # Sign a Windows executable with an EV code signing certificate.
    # EV certificates are typically on hardware tokens (SafeNet/YubiKey)
    # and are auto-detected by signtool via the /a flag.
    #
    # If you need to specify a particular certificate, set the
    # SIGNING_CERT_THUMBPRINT environment variable to the SHA1 thumbprint
    # of your certificate.
    #
    # Usage: windowssign <file_to_sign>
    local FILE_TO_SIGN="$1"

    if [ -z "$FILE_TO_SIGN" ]; then
        echo "ERROR: No file specified for signing."
        return 1
    fi

    if ! command -v signtool.exe &> /dev/null; then
        echo "ERROR: signtool.exe not found in PATH."
        echo "Install the Windows SDK or add it to your PATH."
        return 1
    fi

    if [ -n "$SIGNING_CERT_THUMBPRINT" ]; then
        # Sign with a specific certificate identified by thumbprint
        signtool.exe sign \
            /fd sha256 \
            /tr "$TIMESTAMP_SERVER" \
            /td sha256 \
            /sha1 "$SIGNING_CERT_THUMBPRINT" \
            "$FILE_TO_SIGN"
    else
        # Auto-detect the best signing certificate (/a flag)
        signtool.exe sign \
            /fd sha256 \
            /tr "$TIMESTAMP_SERVER" \
            /td sha256 \
            /a \
            "$FILE_TO_SIGN"
    fi

    if [ $? -ne 0 ]; then
        echo "ERROR: Signing failed for $FILE_TO_SIGN"
        return 1
    fi

    # Verify the signature
    signtool.exe verify /pa "$FILE_TO_SIGN"
    if [ $? -ne 0 ]; then
        echo "WARNING: Signature verification failed for $FILE_TO_SIGN"
        return 1
    fi

    echo "Successfully signed: $FILE_TO_SIGN"
}

INSTALLER="I2P-Easy-Install-Bundle-$I2P_VERSION.exe"

if [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    JAVA_HOME=`type -p java|xargs readlink -f|xargs dirname|xargs dirname`
    linuxsign "$INSTALLER"
    cp "$INSTALLER" "I2P-Easy-Install-Bundle-$I2P_VERSION-signed.exe"
else
    windowssign "$INSTALLER"
    if [ $? -eq 0 ]; then
        cp "$INSTALLER" "I2P-Easy-Install-Bundle-$I2P_VERSION-signed.exe"
    else
        echo "WARNING: Signing failed. Copying unsigned installer."
        cp "$INSTALLER" "I2P-Easy-Install-Bundle-$I2P_VERSION-signed.exe"
    fi
fi
