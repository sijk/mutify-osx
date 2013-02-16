#!/bin/sh

ORGID=com.github.sijk
PROJECT=`xcodebuild -showBuildSettings | awk '/PROJECT =/ {print $3}'`

PACKROOT=build/package
EXECROOT=$PACKROOT/exec
SCRIPTDIR=$PACKROOT/scripts
DISTDIR=dist

mkdir -p $EXECROOT
mkdir -p $SCRIPTDIR
mkdir -p $DISTDIR

xcodebuild DSTROOT=$EXECROOT install

AGENT_PLIST=$ORGID.$PROJECT.plist
AGENT_CONTENT=`cat $PROJECT/$AGENT_PLIST`
AGENT_TARGET=\$HOME/Library/LaunchAgents/$AGENT_PLIST

# Create a postinstall script which generates and loads a LaunchAgent plist
cat > $SCRIPTDIR/postinstall <<EOF
#!/bin/sh

echo 'Creating launch agent'
su \$USER -c 'cat <<EOPLIST > $AGENT_TARGET
$AGENT_CONTENT
EOPLIST'

echo 'Launching agent'
su \$USER -c 'launchctl load $AGENT_TARGET'
EOF

chmod +x $SCRIPTDIR/postinstall

pkgbuild --identifier $ORGID.pkg.$PROJECT   \
         --root $EXECROOT                   \
         --install-location '/'             \
         --scripts $SCRIPTDIR               \
         $DISTDIR/$PROJECT.pkg
