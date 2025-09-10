@echo off
echo Generating certificate from upload-keystore.jks...
cd mobile-app\android\app
"%JAVA_HOME%\bin\keytool" -export -rfc -alias upload -keystore upload-keystore.jks -storepass 123456 -file upload_certificate.pem
if exist upload_certificate.pem (
    echo Certificate generated: upload_certificate.pem
) else (
    echo Failed to generate certificate. Make sure JAVA_HOME is set.
)
pause
