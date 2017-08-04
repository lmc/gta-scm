
@event_id = -1
MAX_EVENTS = 2

@event_x = 0.0
@event_y = 0.0
@event_z = 0.0
@event_radius = 0.0

def get_event(event_id)
  if event_id == 0
    @event_x,@event_y,@event_z = 2457.371, -1662.359, 13.146
    @event_radius = 20.0
  elsif event_id == 1
    @event_x,@event_y,@event_z = 2457.371, -1662.359, 13.146
    @event_radius = 20.0
  end
end

# EVENTS = VariableSetterHash.new(@event_x,@event_y,@event_z,@event_radius)
# EVENTS[0] = [2457.371, -1662.359, 13.146, 20.0]
# EVENTS[1] = routine do
#   custom_code_for_setter()
# end
# # Invoked with:
# # EVENTS.each { |index| ... } # no block args?
# # EVENTS.get(0)

for i in 0..MAX_EVENTS
  get_event(i)
  $player_x,$player_y,$player_z = get_char_coordinates($player_char)
  distance = get_distance_between_coords_3d($player_x,$player_y,$player_z,@event_x,@event_y,@event_z)
  if distance > @event_distance
    create_event(i)
  end
end
