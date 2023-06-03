class_name DroneManager

func simulate(drones : Array[Drone], protocol : Protocol, base_pos : Vector3) -> ExecReturn:
	# Compute next drone state
	for d in drones:
		var exec := d.compute_next_state(protocol, base_pos)
		if exec.fail:
			return exec
	# Update drone state
	for d in drones:
		d.update_state()
		
	return ExecReturn.new(false, "", {})
