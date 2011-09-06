@echo.
@echo This batch file quickly rebuilds LLQtWebKit and the test apps.
@echo You should only use this after a full autobuild of Qt
@echo.
@echo This probably won't work unless you run it from a Qt 4.7.x command
@echo prompt since it needs a path to the Qt 4.7.x build directory.
@echo.
@echo About to delete intermediate files - edit this file if that makes you sad.
@echo.
@pause

@rem Uncomment the next line if you DO NOT want to erase intermediate files first
@rem goto NO_ERASE

@rem Delete LLQtWebKit files
@rmdir .moc\ /s /q
@rmdir .obj\ /s /q
@rmdir .ui\ /s /q
@del Makefile
@del Makefile.Release
@rmdir release\ /s /q
@del Makefile.Debug
@rmdir debug\ /s /q

@rem Delete build directory
@rmdir tests\build\ /s /q

@rem Delete QtTestApp files
@rmdir tests\qttestapp\Release\ /s /q
@rmdir tests\qttestapp\Debug\ /s /q
@del tests\qttestapp\Makefile
@del tests\qttestapp\Makefile.Release
@del tests\qttestapp\Makefile.Debug
@del tests\qttestapp\ui_window.h

@rem Delete testGL files
@rmdir tests\testgl\Release\ /s /q
@rmdir tests\testgl\Debug\ /s /q
@del tests\testgl\Makefile
@del tests\testgl\Makefile.Release
@del tests\testgl\Makefile.Debug

@rem Delete ssltest files
@rmdir tests\ssltest\Release\ /s /q
@rmdir tests\ssltest\Debug\ /s /q
@del tests\ssltest\Makefile
@del tests\ssltest\Makefile.Release
@del tests\ssltest\Makefile.Debug

@echo.
@echo Deleted intermediate files.
@echo.
@pause

:NO_ERASE
@rem Copy runtime files to the build dir where test apps end up
mkdir tests\build
copy .\stage\packages\lib\release\libeay32.dll tests\build /Y
copy .\stage\packages\lib\release\ssleay32.dll tests\build /Y
copy .\stage\packages\lib\release\freeglut_static.lib tests\build /Y

@rem clean and make a release version of LLQtWebKit
@rem No longer patching Qt as of v4.7.0 so switch off code that referenced changes
qmake CONFIG-=debug DEFINES+=VANILLA_QT
nmake clean
nmake

@rem clean and make a release version of testGL test app
pushd .
cd tests\testgl
qmake CONFIG-=debug
nmake clean
nmake
popd

@rem clean and make a release version of QtTestApp test app
pushd .
cd tests\qttestapp
qmake CONFIG-=debug
nmake clean
nmake
popd

@rem clean and make a release version of SSL test app
pushd .
cd tests\ssltest
qmake CONFIG-=debug
nmake clean
nmake
popd

@rem Hard to see if builds fail so look for what we need afterwards
@if not exist release\llqtwebkit.lib echo ****** ERROR: Failed to build LLQtWebKit (release) library
@if not exist tests\build\qttestapp.exe echo ****** ERROR: Failed to build QtTestApp test app
@if not exist tests\build\testgl.exe echo ****** ERROR: Failed to build testGL test app
@if not exist tests\build\ssltest.exe echo ****** ERROR: Failed to build SSL test app

@echo -- End of batch file --
