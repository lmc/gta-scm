declare do
  int @0 # sub-script id argument from start_new_streamed_script
end

if @0 >= 0 && @0 < 400
  # normal scripts
  if @0 == EXT78_TEST
    [:goto,[[:mission_label,:ext78_test]]]
  elsif @0 == EXT78_VEHICLE_MANAGER
    [:goto,[[:mission_label,:ext78_vehicle_manager]]]
  elsif @0 == EXT78_SPATIAL_MANAGER
    [:goto,[[:mission_label,:ext78_spatial_manager]]]
  elsif @0 == EXT78_SMITE_DRIVER
    [:goto,[[:mission_label,:ext78_vehicle_smite]]]
  end
elsif @0 >= 400 && @0 < 1000
  # vehicle scripts
  if @0 == 420
    [:goto,[[:mission_label,:ext78_vehicle_420_taxi]]]
  elsif @0 == 443
    [:goto,[[:mission_label,:ext78_vehicle_443_packer]]]
  end
elsif @0 >= 1000 && @0 < 2000
  # spatial scripts
  @0 -= 1000
  if @0 == 0
    [:goto,[[:mission_label,:ext78_spatial_000_test]]]
  # elsif @0 == 1
  #   [:goto,[[:mission_label,:ext78_spatial_001_test]]]
  end
end

# failsafe
script_name("xext78x")
loop { wait(0) }


[:labeldef,:ext78_test]
[:IncludeRuby, "helper_v2", [:v2,true], [:external,true]]

[:labeldef,:ext78_vehicle_manager]
[:IncludeRuby, "externals/78/vehicle-manager", [:external,true]]

[:labeldef,:ext78_spatial_manager]
[:IncludeRuby, "externals/78/spatial-manager", [:external,true]]

[:labeldef,:ext78_vehicle_smite]
[:IncludeRuby, "externals/78/vehicle-smite", [:external,true]]


[:labeldef,:ext78_vehicle_420_taxi]
[:IncludeRuby, "externals/78/vehicle/420-taxi", [:external,true]]

[:labeldef,:ext78_vehicle_443_packer]
[:IncludeRuby, "externals/78/vehicle/443-packer", [:external,true]]


[:IncludeRuby, "externals/78/spatial-functions", [:v2,true], [:keep_instance_scope,true], [:external,true]]

[:labeldef,:ext78_spatial_000_test]
[:IncludeRuby, "externals/78/spatial/000-test", [:v2,true], [:use_instance_scope,true], [:external,true]]

# [:labeldef,:ext78_spatial_001_test]
# [:IncludeRuby, "externals/78/spatial/001-test", [:v2,true], [:use_instance_scope,true], [:external,true]]

