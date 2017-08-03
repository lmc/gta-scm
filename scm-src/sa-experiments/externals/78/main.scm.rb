declare do
  int @0 # sub-script id argument from start_new_streamed_script
end

if @0 == 1
  [:IncludeRuby,"detect-cars",[:external,true]]
elsif @0 == 8
  [:IncludeRuby,"r1-menu",[:external,true]]
elsif @0 == 9
  [:IncludeRuby,"smite",[:external,true]]
elsif @0 == 420
  [:IncludeRuby,"car-feature-420-taxi",[:external,true]]
elsif @0 == 443
  [:IncludeRuby,"car-feature-443-packer",[:external,true]]
elsif @0 == 596
  [:IncludeRuby,"car-feature-596-copcarla",[:external,true]]
end

loop do
  wait(0)
end
