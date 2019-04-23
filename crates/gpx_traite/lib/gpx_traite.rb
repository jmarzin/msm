require "helix_runtime"

begin
  require "gpx_traite/native"
rescue LoadError
  warn "Unable to load gpx_traite/native. Please run `rake build`"
end
