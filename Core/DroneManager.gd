class_name DroneManager

var protocol : Protocol

func simulate(drones : Array[Drone]):
	# Compute next drone state
	for d in drones:
		d.compute_next_state(protocol)
	# Update drone state
	for d in drones:
		d.update_state()
