#!/bin/bash

# make errors fatal
set -e

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

stage="$(pwd)"
cd "$(dirname "$0")"
top="$(pwd)"
packages="$stage/packages"
install="$stage"

case "$AUTOBUILD_PLATFORM" in
    "windows")
        load_vsvars
        
        QTDIR=$(cygpath -m "$(pwd)/$QT_SOURCE_DIR")
        pushd "$QT_SOURCE_DIR"
            chmod +x "./configure.exe"
            echo "yes" | \
                ./configure.exe -opensource -platform win32-msvc2010 -fast -debug-and-release -no-qt3support -prefix "$QTDIR" -no-phonon -no-phonon-backend -qt-libjpeg -qt-libpng -openssl-linked -no-plugin-manifests -nomake demos -nomake examples -I "$(cygpath -m "$packages/include")" -L "$(cygpath -m "$packages/lib/release")"
            export PATH="$(cygpath -u "$QTDIR")/bin:$PATH"
            export QMAKESPEC="win32-msvc2010"
    
            nmake
        popd

        qtwebkit_libs_debug="QtCored4.dll QtCored4.lib QtGuid4.dll QtGuid4.lib \
            qtmaind.lib QtNetworkd4.dll QtNetworkd4.lib QtOpenGLd4.dll QtOpenGLd4.lib \
            QtWebKitd4.dll QtWebKitd4.lib QtXmlPatterns4.dll"

        mkdir -p "$install/lib/debug"
        for lib in $qtwebkit_libs_debug ; do
            cp "$QTDIR/lib/$lib" "$install/lib/debug"
        done

        qtwebkit_libs_release="QtCore4.dll QtCore4.lib QtGui4.dll QtGui4.lib \
            qtmain.lib QtNetwork4.dll QtNetwork4.lib QtOpenGL4.dll QtOpenGL4.lib \
            QtWebKit4.dll QtWebKit4.lib QtXmlPatterns4.dll"

        mkdir -p "$install/lib/release"
        for lib in $qtwebkit_libs_release ; do
            cp "$QTDIR/lib/$lib" "$install/lib/release"
        done

        qtwebkit_imageplugins_debug="qgifd4.dll qicod4.dll qjpegd4.dll \
            qmngd4.dll qsvgd4.dll qtiffd4.dll"

        mkdir -p "$install/lib/debug/imageformats"
        for plugin in $qtwebkit_imageplugins_debug ; do
            cp "$QTDIR/plugins/imageformats/$plugin" "$install/lib/debug/imageformats"
        done

        qtwebkit_imageplugins_release="qgif4.dll qico4.dll qjpeg4.dll \
            qmng4.dll qsvg4.dll qtiff4.dll"

        mkdir -p "$install/lib/release/imageformats"
        for plugin in $qtwebkit_imageplugins_release ; do
            cp "$QTDIR/plugins/imageformats/$plugin" "$install/lib/release/imageformats"
        done

        qtwebkit_codecs_debug="qjpcodecsd4.dll qcncodecsd4.dll qkrcodecsd4.dll qtwcodecsd4.dll"
        
        mkdir -p "$install/lib/debug/codecs"
        for codec in $qtwebkit_codecs_debug ; do
            cp "$QTDIR/plugins/codecs/$codec" "$install/lib/debug/codecs"
        done

        qtwebkit_codecs_release="qcncodecs4.dll qjpcodecs4.dll qkrcodecs4.dll qtwcodecs4.dll"
        
        mkdir -p "$install/lib/release/codecs"
        for codec in $qtwebkit_codecs_release ; do
            cp "$QTDIR/plugins/codecs/$codec" "$install/lib/release/codecs"
        done
        
        mkdir -p "$install/include"
        cp -r "$QTDIR/include" "$install"
        
        mkdir -p "$install/bin"
        qtwebkit_exes="moc.exe qmake.exe rcc.exe uic.exe"
        for exe in $qtwebkit_exes ; do
            cp "$QTDIR/bin/$exe" "$install/bin"
        done
        
        cp -r "$QTDIR/mkspecs" "$install"
    ;;
    "darwin")
        pushd "$QT_SOURCE_DIR"
            export QTDIR="$(pwd)"
            echo "yes" | \
                ./configure -opensource -platform macx-g++40 -no-framework -fast -no-qt3support -prefix "$install" \
                    -static -release -no-xmlpatterns -no-phonon -webkit -sdk /Developer/SDKs/MacOSX10.5.sdk/ -cocoa \
                    -nomake examples -nomake demos -nomake docs -nomake translations -nomake tools -nomake examples
            make -j4
            make -j4 -C "src/3rdparty/webkit/JavaScriptCore"
            export PATH="$PATH:$QTDIR/bin"
            make install
            
            cp "src/3rdparty/webkit/JavaScriptCore/release/libjscore.a" "$install/lib"
        popd
    ;;
    "linux")
        export MAKEFLAGS="-j12"
        export CXX="g++-4.1" CXXFLAGS="-DQT_NO_INOTIFY -m32 -fno-stack-protector"
        export CC='gcc-4.1' CFLAGS="-m32 -fno-stack-protector"
        export LD="g++-4.1" LDFLAGS="-m32"
        pushd "$QT_SOURCE_DIR"
            export QTDIR="$(pwd)"
            echo "DISTCC_HOSTS=$DISTCC_HOSTS"

            # fix for build on lenny (not sure why the qt build isn't obeying the environment var
			patch -p1 < "../000_qt_linux_mkspec_force_g++-4.1.patch"

            echo "yes" | \
            ./configure \
                -v -platform linux-g++-32  -fontconfig -fast -no-qt3support -static -release  -no-xmlpatterns -no-phonon \
                -openssl-linked -no-3dnow -no-sse -no-sse2 -no-sse3 -no-ssse3 -no-sse4.1 -no-sse4.2 -no-gtkstyle \
				-no-xinput -no-sm -buildkey LL$(date +%s) \
                -no-sql-sqlite -no-scripttools -no-cups -no-dbus -qt-libmng -no-glib -qt-libpng -opengl desktop  -no-xkb \
                -xrender -svg -no-pch -webkit -opensource -I"$packages/include" -L"$packages/lib" --prefix="$install" \
                -nomake examples -nomake demos -nomake docs -nomake translations -nomake tools
            make -j12
            export PATH="$PATH:$QTDIR/bin"
            make install
        popd
    ;;
esac
mkdir -p "$install/LICENSES"
cp "$QT_SOURCE_DIR/LICENSE.LGPL" "$install/LICENSES/qt.txt"

pass

