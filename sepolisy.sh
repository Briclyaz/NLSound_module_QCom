# debug
magiskpolicy --live "dontaudit system_server system_file file write"
magiskpolicy --live "allow     system_server system_file file write"

# context
magiskpolicy --live "type vendor_file"
magiskpolicy --live "type vendor_configs_file"
magiskpolicy --live "dontaudit { vendor_file vendor_configs_file } labeledfs filesystem associate"
magiskpolicy --live "allow     { vendor_file vendor_configs_file } labeledfs filesystem associate"
magiskpolicy --live "dontaudit init { vendor_file vendor_configs_file } dir relabelfrom"
magiskpolicy --live "allow     init { vendor_file vendor_configs_file } dir relabelfrom"
magiskpolicy --live "dontaudit init { vendor_file vendor_configs_file } file relabelfrom"
magiskpolicy --live "allow     init { vendor_file vendor_configs_file } file relabelfrom"


