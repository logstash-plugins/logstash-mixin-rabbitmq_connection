## 4.2.0
 - breaking,config: Remove obsolete config `debug` and `verify_ssl`
 - breaking,config : Remove deprecated config `tls_certificate_path` and `tls_certificate_password`. Please use `ssl_` prefixed config

## 4.1.1
 - Remove internal Logstash deps that were not necessary

## 4.1.0
 - Fix SSL option to be boolean once again
 - Add separate ssl_version parameter
 - Mark verify_ssl parameter as obsolete since it never worked
 - Better checks for SSL argument consistency

## 2.4.0
 - Add SSL/TLS Support
 - Add support for "x-consistent-hash" and "x-modulus-hash" exchanges

## 2.3.1
 - use logstash-core-plugin-api as dependency instead of logstash-core directly

## 2.3.0
 - Bump march_mare version to 2.15.0 to fix perms issue internal to march hare gem (.jar not installed with o+r perms)

## 2.2.0
 - Rollback the changes in 2.1.0 . prefetch_count only belongs in the input plugin

## 2.1.0
 - Add prefetch_count config option

## 2.0.3
 - Add heartbeat setting
 - Add connect_timeout setting

## 2.0.0
 - Make LS2 compatible

## 1.0.1
 - Initial Release
 