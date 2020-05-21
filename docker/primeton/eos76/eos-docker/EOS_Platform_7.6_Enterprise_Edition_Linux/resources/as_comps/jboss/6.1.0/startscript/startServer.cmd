@echo off
rem -------------------------------------------------------------------------
rem JBoss Bootstrap Script for Windows
rem -------------------------------------------------------------------------

rem $Id: run.bat 111395 2011-05-18 07:45:07Z beve $

@if not "%ECHO%" == ""  echo %ECHO%
@if "%OS%" == "Windows_NT" setlocal

if "%OS%" == "Windows_NT" (
  set "DIRNAME=%~dp0%"
) else (
  set DIRNAME=.\
)


set JBOSS_HOME=${RP_JBOSS_HOME}
set DIRNAME=${RP_JBOSS_HOME}\bin\
set JAVA_HOME=${RP_JAVA_HOME}
set EXTERNAL_CONFIG_DIR=${RP_APPS_CONFIG}

rem Read an optional configuration file.
if "x%RUN_CONF%" == "x" (   
   set "RUN_CONF=%DIRNAME%run.conf.bat"
)
if exist "%RUN_CONF%" (
   echo Calling %RUN_CONF%
   call "%RUN_CONF%" %*
) else (
   echo Config file not found %RUN_CONF%
)

pushd "%DIRNAME%.."
if "x%JBOSS_HOME%" == "x" (
  set "JBOSS_HOME=%CD%"
)
popd

rem set DIRNAME=

if "%OS%" == "Windows_NT" (
  set "PROGNAME=%~nx0%"
) else (
  set "PROGNAME=run.bat"
)

rem Setup JBoss specific properties
set JAVA_OPTS=%JAVA_OPTS% -Dprogram.name=%PROGNAME% -Dlogging.configuration=file:%DIRNAME%logging.properties

if "x%JAVA_HOME%" == "x" (
  set  JAVA=java
  echo JAVA_HOME is not set. Unexpected results may occur.
  echo Set JAVA_HOME to the directory of your local JDK to avoid this message.
) else (
  set "JAVA=%JAVA_HOME%\bin\java"
  if exist "%JAVA_HOME%\lib\tools.jar" (
    set "JAVAC_JAR=%JAVA_HOME%\lib\tools.jar"
  )
)

rem Add -server to the JVM options, if supported
"%JAVA%" -server -version 2>&1 | findstr /I hotspot > nul
if not errorlevel == 1 (
  set "JAVA_OPTS=%JAVA_OPTS% -server"
)

rem Add native to the PATH if present
set JBOSS_NATIVE_HOME=
set CHECK_NATIVE_HOME=
if exist "%JBOSS_HOME%\bin\libtcnative-1.dll" (
  set "CHECK_NATIVE_HOME=%JBOSS_HOME%\bin"
) else if exist "%JBOSS_HOME%\..\native\bin" (
  set "CHECK_NATIVE_HOME=%JBOSS_HOME%\..\native\bin"
) else if exist "%JBOSS_HOME%\bin\native\bin" (
  set "CHECK_NATIVE_HOME=%JBOSS_HOME%\bin\native\bin"
)
if "x%CHECK_NATIVE_HOME%" == "x" goto WITHOUT_JBOSS_NATIVE

rem Translate to the absolute path

pushd "%CHECK_NATIVE_HOME%"
set JBOSS_NATIVE_HOME=%CD%
popd
set CHECK_JBOSS_NATIVE_HOME=
set JAVA_OPTS=%JAVA_OPTS% "-Djava.library.path=%JBOSS_NATIVE_HOME%;%PATH%;%SYSTEMROOT%"
set PATH=%JBOSS_NATIVE_HOME%;%PATH%;%SYSTEMROOT%

:WITHOUT_JBOSS_NATIVE
rem Find run.jar, or we can't continue

if exist "%JBOSS_HOME%\bin\run.jar" (
  if "x%JAVAC_JAR%" == "x" (
    set "RUNJAR=%JBOSS_HOME%\bin\run.jar"
  ) else (
    set "RUNJAR=%JAVAC_JAR%;%JBOSS_HOME%\bin\run.jar"
  )
) else (
  echo Could not locate "%JBOSS_HOME%\bin\run.jar".
  echo Please check that you are in the bin directory when running this script.
  goto END
)

rem If JBOSS_CLASSPATH empty, don't include it, as this will
rem result in including the local directory in the classpath, which makes
rem error tracking harder.
if "x%JBOSS_CLASSPATH%" == "x" (
  set "RUN_CLASSPATH=%RUNJAR%"
) else (
  set "RUN_CLASSPATH=%JBOSS_CLASSPATH%;%RUNJAR%"
)

set JBOSS_CLASSPATH=%RUN_CLASSPATH%;%JBOSS_HOME%\server\default\lib\bcprov-jdk15-1.41.0.jar

rem Setup JBoss specific properties

rem Setup the java endorsed dirs
set JBOSS_ENDORSED_DIRS=%JBOSS_HOME%\lib\endorsed

if "%1"=="-debug" (
	set JAVA_OPTS=-Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=8787 %JAVA_OPTS%
	shift
)

set JAVA_OPTS=%JAVA_OPTS% -Djboss.bind.address=0.0.0.0 -Djavax.xml.soap.SAAJMetaFactory=com.sun.xml.messaging.saaj.soap.SAAJMetaFactoryImpl -DEXTERNAL_CONFIG_DIR=%EXTERNAL_CONFIG_DIR%  -Djava.net.preferIPv4Stack=true

echo ===============================================================================
echo.
echo   JBoss Bootstrap Environment
echo.
echo   JBOSS_HOME: %JBOSS_HOME%
echo.
echo   JAVA: %JAVA%
echo.
echo   JAVA_OPTS: %JAVA_OPTS%
echo.
echo   CLASSPATH: %JBOSS_CLASSPATH%
echo.
echo ===============================================================================
echo.

:RESTART
"%JAVA%" %JAVA_OPTS% ^
   -Djava.endorsed.dirs="%JBOSS_ENDORSED_DIRS%" ^
   -classpath "%JBOSS_CLASSPATH%" ^
   org.jboss.Main %*

if ERRORLEVEL 10 goto RESTART

:END
if "x%NOPAUSE%" == "x" pause

:END_NO_PAUSE
