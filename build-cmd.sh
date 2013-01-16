#!/bin/bash

cd "`dirname "$0"`"
top="`pwd`"
stage="$top/stage"

packages="$stage/packages"
install="$stage"

# make errors fatal
set -e

# So we can turn off building qt.
BUILD_QT=1
while getopts "x" OPTION
do
    case $OPTION in
    x)
        echo 'not building qt'
        BUILD_QT=0 
    ;;
    esac
done

QT_SOURCE_DIR="qt-everywhere-opensource-src-4.7.1"

if [ -z "$AUTOBUILD" ] ; then 
    fail
fi

if [ "$OSTYPE" = "cygwin" ] ; then
    export AUTOBUILD="$(cygpath -u $AUTOBUILD)"
fi

# load autbuild provided shell functions and variables
eval "$("$AUTOBUILD" source_environment)"

# turn on verbose debugging output for logging.
set -x

case "$AUTOBUILD_PLATFORM" in
    "windows")        
        load_vsvars
        
        # build qt
        if [ $BUILD_QT -ne 0 ]
        then
            pushd "$stage"            
                QTDIR="$(pwd)/../$QT_SOURCE_DIR"
                export PATH="$QTDIR"/bin:"$PATH" 
                export QMAKESPEC="win32-msvc2010"
        
                chmod +x "$QTDIR/configure.exe"
                common_configure_options="-opensource -confirm-license -platform win32-msvc2010 -fast \
                    -no-qt3support -no-phonon -no-phonon-backend \
                    -qt-libjpeg -qt-libpng -openssl-linked -no-plugin-manifests -nomake demos -nomake examples -I \
                    "$(cygpath -m "$packages/include")""
        
				 "$QTDIR/configure.exe" $common_configure_options -debug  -L "$(cygpath -m "$packages/lib/debug")"
			 	nmake
			 	
                "$QTDIR/configure.exe" $common_configure_options -release  -L "$(cygpath -m "$packages/lib/release")"
                nmake
            popd
    
            # Move around libraries to match autobuild layout.
            qtwebkit_libs_debug="QtCored4.dll QtCored4.lib QtGuid4.dll QtGuid4.lib \
                qtmaind.lib QtNetworkd4.dll QtNetworkd4.lib QtOpenGLd4.dll QtOpenGLd4.lib \
                QtWebKitd4.dll QtWebKitd4.lib QtXmlPatternsd4.dll"
            mkdir -p "$install/lib/debug"
            for lib in $qtwebkit_libs_debug ; do
                cp "$stage/lib/$lib" "$install/lib/debug"
            done
            
            qtwebkit_libs_release="QtCore4.dll QtCore4.lib QtGui4.dll QtGui4.lib \
                qtmain.lib QtNetwork4.dll QtNetwork4.lib QtOpenGL4.dll QtOpenGL4.lib \
                QtWebKit4.dll QtWebKit4.lib QtXmlPatterns4.dll"
            mkdir -p "$install/lib/release"
            for lib in $qtwebkit_libs_release ; do
                cp "$stage/lib/$lib" "$install/lib/release"
            done
            
            qtwebkit_imageplugins_debug="qgifd4.dll qicod4.dll qjpegd4.dll \
                qmngd4.dll qsvgd4.dll qtiffd4.dll"
            mkdir -p "$install/lib/debug/imageformats"
            for plugin in $qtwebkit_imageplugins_debug ; do
                cp "$stage/plugins/imageformats/$plugin" "$install/lib/debug/imageformats"
            done            

            qtwebkit_imageplugins_release="qgif4.dll qico4.dll qjpeg4.dll \
                qmng4.dll qsvg4.dll qtiff4.dll"
            mkdir -p "$install/lib/release/imageformats"
            for plugin in $qtwebkit_imageplugins_release ; do
                cp "$stage/plugins/imageformats/$plugin" "$install/lib/release/imageformats"
            done

            qtwebkit_codecs_debug="qjpcodecsd4.dll qcncodecsd4.dll qkrcodecsd4.dll qtwcodecsd4.dll"
            mkdir -p "$install/lib/debug/codecs"
            for codec in $qtwebkit_codecs_debug ; do
                cp "$stage/plugins/codecs/$codec" "$install/lib/debug/codecs"
            done
            
            qtwebkit_codecs_release="qcncodecs4.dll qjpcodecs4.dll qkrcodecs4.dll qtwcodecs4.dll"
            mkdir -p "$install/lib/release/codecs"
            for codec in $qtwebkit_codecs_release ; do
                cp "$stage/plugins/codecs/$codec" "$install/lib/release/codecs"
            done
        fi
                
        # Now build llqtwebkit...
        export PATH=$PATH:"$install/bin/"
        
        qmake CONFIG-=debug
        nmake clean
        nmake
        
        qmake CONFIG+=debug
        nmake clean
        nmake

        mkdir -p "$install/lib/debug"
		cp "debug/llqtwebkitd.lib"  "$install/lib/debug"        

        mkdir -p "$install/lib/release"
        cp "release/llqtwebkit.lib" "$install/lib/release"
		
        mkdir -p "$install/include"
        cp "llqtwebkit.h" "$install/include"
        
        cp win32/3p-qt-vars.bat $stage/bin
    ;;
    "darwin")
        # Build qt...
        if [ $BUILD_QT -ne 0 ]
        then
            pushd "$QT_SOURCE_DIR"
                export QTDIR="$(pwd)"
                echo "yes" | \
                    ./configure -opensource -openssl-linked -release -platform macx-g++40 -no-framework -fast -no-qt3support -prefix "$install" \
                        -static -no-xmlpatterns -no-phonon -webkit -sdk /Developer/SDKs/MacOSX10.5.sdk/ -cocoa \
                        -nomake examples -nomake demos -nomake docs -nomake translations -nomake tools -I"$packages/include" -L"$packages/lib"
                make -j4
                make -j4 -C "src/3rdparty/webkit/JavaScriptCore"
                export PATH="$PATH:$QTDIR/bin"
                make install
                
                cp "src/3rdparty/webkit/JavaScriptCore/release/libjscore.a" "$install/lib"
            popd
        fi

        # Now build llqtwebkit
        if [ ! -e QTDIR ]
        then
            ln -s "$install" QTDIR
        fi
        xcodebuild -project llqtwebkit.xcodeproj -target llqtwebkit -configuration Release

        mkdir -p "$install/lib/release"
        cp "build/Release/libllqtwebkit.dylib" "$install/lib/release"

        mkdir -p "$install/include"
        cp "llqtwebkit.h" "$install/include"
    ;;
    "linux")
        LIB_DIR="$install/libraries/i686-linux/lib/release"
        export MAKEFLAGS="-j8"
        export CXX="g++" CXXFLAGS="-DQT_NO_INOTIFY -m32 -fno-stack-protector"
        export CC="gcc" CFLAGS="-m32 -fno-stack-protector"
        export LD="g++" LDFLAGS="-m32"

        #Build qt...
        if [ $BUILD_QT -ne 0 ]
        then
            mkdir -p "$stage/qt-builddir"
            pushd "$stage/qt-builddir"
                export QTDIR="$(pwd)"
 
                echo "yes" | \
                OPENSSL_LIBS="-L$packages/libraries/i686-linux/lib/release -lssl -lcrypto" \
                "$top/$QT_SOURCE_DIR"/configure \
                    -v -platform linux-g++-32 -static -fontconfig -fast -no-qt3support -release -no-xmlpatterns -no-phonon \
                    -openssl-linked -no-3dnow -no-sse -no-sse3 -no-ssse3 -no-sse4.1 -no-sse4.2 -no-gtkstyle \
                    -no-xinput -no-sm -buildkey LL$(date +%s) -qt-libtiff -qt-gif -qt-libjpeg \
                    -no-sql-sqlite -no-sql-psql -no-sql-mysql -no-scripttools -no-cups -no-dbus -qt-libmng -no-glib -qt-libpng -opengl desktop -no-xkb \
                    -xrender -svg -no-pch -webkit -opensource -no-declarative -no-rpath -no-accessibility \
		    -I"$packages/libraries/i686-linux/include" -L"$packages/libraries/i686-linux/lib/release" \
		    -prefix "$install" -libdir "$LIB_DIR" -plugindir "$LIB_DIR" -prefix-install \
                    -nomake examples -nomake demos -nomake docs -nomake translations -nomake tools
                make
                export PATH="$QTDIR/bin:$PATH"
                make install
        
                # libjscore.a doesn't get installed but some libs depend on it.
                cp "./src/3rdparty/webkit/JavaScriptCore/release/libjscore.a" "$LIB_DIR"
            popd
        fi

        # Now build llqtwebkit...
        export PATH="$install/bin/:$PATH"
        qmake -platform linux-g++-32 CONFIG-=debug
        make

        cp "libllqtwebkit.a" "$LIB_DIR"

        mkdir -p "$install/libraries/i686-linux/include"
        cp "llqtwebkit.h" "$install/libraries/i686-linux/include"
    ;;
    "linux64")
        LIB_DIR="$install/libraries/x86_64-linux/lib/release"
        export MAKEFLAGS="-j8"
        export CXX="g++" CXXFLAGS="-DQT_NO_INOTIFY -m64 -fno-stack-protector"
        export CC="gcc" CFLAGS="-m64 -fno-stack-protector"
        export LD="g++" LDFLAGS="-m64"

        #Build qt...
        if [ $BUILD_QT -ne 0 ]
        then
            mkdir -p "$stage/qt-builddir"
            pushd "$stage/qt-builddir"
                export QTDIR="$(pwd)"
 
                echo "yes" | \
                OPENSSL_LIBS="-L$packages/libraries/x86_64-linux/lib/release -lssl -lcrypto" \
                "$top/$QT_SOURCE_DIR"/configure \
                    -v -platform linux-g++-64 -static -fontconfig -fast -no-qt3support -release -no-xmlpatterns -no-phonon \
                    -openssl-linked -no-3dnow -no-sse -no-sse3 -no-ssse3 -no-sse4.1 -no-sse4.2 -no-gtkstyle \
                    -no-xinput -no-sm -buildkey LL$(date +%s) -qt-libtiff -qt-gif -qt-libjpeg \
                    -no-sql-sqlite -no-sql-psql -no-sql-mysql -no-scripttools -no-cups -no-dbus -qt-libmng -no-glib -qt-libpng -opengl desktop -no-xkb \
                    -xrender -svg -no-pch -webkit -opensource -no-declarative -no-rpath -no-accessibility \
		    -I"$packages/libraries/x86_64-linux/include" -L"$packages/libraries/x86_64-linux/lib/release" \
		    -prefix "$install" -libdir "$LIB_DIR" -plugindir "$LIB_DIR" -prefix-install \
                    -nomake examples -nomake demos -nomake docs -nomake translations -nomake tools
                make
                export PATH="$QTDIR/bin:$PATH"
                make install
        
                # libjscore.a doesn't get installed but some libs depend on it.
                cp "./src/3rdparty/webkit/JavaScriptCore/release/libjscore.a" "$LIB_DIR"
            popd
        fi

        # Now build llqtwebkit...
        export PATH="$install/bin/:$PATH"
        qmake -platform linux-g++-64 CONFIG-=debug
        make

        cp "libllqtwebkit.a" "$LIB_DIR"

        mkdir -p "$install/libraries/x86_64-linux/include"
        cp "llqtwebkit.h" "$install/libraries/x86_64-linux/include"
    ;;
esac
mkdir -p "$install/LICENSES"
cp "LLQTWEBKIT_LICENSE.txt" "$install/LICENSES/llqtwebkit.txt"

pass

