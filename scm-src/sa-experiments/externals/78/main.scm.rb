declare do
  int @0 # sub-script id argument from start_new_streamed_script
end

log("starting script with ")
log_int(@0)
log("")

if @0 >= 0 && @0 < 400
  # normal scripts
  if @0 == EXT78_TEST
    [:IncludeRuby, "helper_v2", [:v2,true], [:external,true]]
  elsif @0 == EXT78_VEHICLE_MANAGER
    [:IncludeRuby, "detect-cars", [:external,true]]
  elsif @0 == EXT78_SPATIAL_MANAGER
    [:IncludeRuby, "spatial", [:external,true]]
  elsif @0 == EXT78_SMITE_DRIVER
    [:IncludeRuby, "smite", [:external,true]]
  end
elsif @0 >= 400 && @0 < 1000
  # vehicle scripts
  if @0 == 420
    [:IncludeRuby, "car-feature-420-taxi", [:external,true]]
  elsif @0 == 443
    [:IncludeRuby, "car-feature-443-packer", [:external,true]]
  end
elsif @0 >= 1000 && @0 < 2000
  @0 -= 1000
  # spatial scripts
  if @0 == 0
    [:IncludeRuby, "externals/78/spatial/000-test", [:v2,true], [:external,true]]
  # elsif @0 == 1
  #   [:IncludeRuby, "externals/78/spatial/000-test", [:v2,true], [:external,true]]
  end
end

script_name("xext78x")
loop do
  wait(0)
end

# if @0 == EXT78_DETECT_CARS
#   [:IncludeRuby,"detect-cars",[:external,true]]
# elsif @0 == EXT78_R1_MENU
#   [:IncludeRuby,"r1-menu",[:external,true]]
# elsif @0 == EXT78_SMITE
#   [:IncludeRuby,"smite",[:external,true]]
# elsif @0 == 420
#   [:IncludeRuby,"car-feature-420-taxi",[:external,true]]
# elsif @0 == 443
#   [:IncludeRuby,"car-feature-443-packer",[:external,true]]
# elsif @0 == 596
#   [:IncludeRuby,"car-feature-596-copcarla",[:external,true]]
# end
# 
# loop do
#   wait(0)
# end
