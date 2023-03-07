class_name DroneManager

func simulate(drones : Array[Drone], protocol : Protocol):
	# Compute next drone state
	for d in drones:
		d.compute_next_state(protocol)
	# Update drone state
	for d in drones:
		d.update_state()
