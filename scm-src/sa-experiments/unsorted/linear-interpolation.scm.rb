routines do

  $lerp_coords1 = Vector3.new
  $lerp_coords2 = Vector3.new
  $lerp_coords3 = Vector3.new
  $lerp_value = 0.0

  linear_interpolation = function(
    args: [$lerp_coords1,$lerp_coords2,$lerp_value],
    returns: [$lerp_coords3]
  ) do
    
    if $lerp_coords2.x > $lerp_coords1.x
      $lerp_coords3.x  = $lerp_coords2.x
      $lerp_coords3.x -= $lerp_coords1.x
      $lerp_coords3.x *= $lerp_value
      $lerp_coords3.x += $lerp_coords1.x
    else
      $lerp_coords3.x  = $lerp_coords1.x
      $lerp_coords3.x -= $lerp_coords2.x
      $lerp_coords3.x *= $lerp_value
      $lerp_coords3.x += $lerp_coords2.x
    end

    if $lerp_coords2.y > $lerp_coords1.y
      $lerp_coords3.y  = $lerp_coords2.y
      $lerp_coords3.y -= $lerp_coords1.y
      $lerp_coords3.y *= $lerp_value
      $lerp_coords3.y += $lerp_coords1.y
    else
      $lerp_coords3.y  = $lerp_coords1.y
      $lerp_coords3.y -= $lerp_coords2.y
      $lerp_coords3.y *= $lerp_value
      $lerp_coords3.y += $lerp_coords2.y
    end

    if $lerp_coords2.z > $lerp_coords1.z
      $lerp_coords3.z  = $lerp_coords2.z
      $lerp_coords3.z -= $lerp_coords1.z
      $lerp_coords3.z *= $lerp_value
      $lerp_coords3.z += $lerp_coords1.z
    else
      $lerp_coords3.z  = $lerp_coords1.z
      $lerp_coords3.z -= $lerp_coords2.z
      $lerp_coords3.z *= $lerp_value
      $lerp_coords3.z += $lerp_coords2.z
    end

  end

end