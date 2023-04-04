class_name DroneManager

func simulate(drones : Array[Drone], protocol : Protocol, base_pos : Vector3):
	# Compute next drone state
	for d in drones:
		d.compute_next_state(protocol, base_pos)
	# Update drone state
	for d in drones:
		d.update_state()
