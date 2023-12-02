allow system_server system_file file write

# context
create { system_lib_file vendor_file vendor_configs_file }
allow { system_file system_lib_file vendor_file vendor_configs_file } labeledfs filesystem associate
allow init { system_file system_lib_file vendor_file vendor_configs_file } { dir file } relabelfrom