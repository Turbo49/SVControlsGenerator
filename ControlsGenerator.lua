function getClientInfo()
	return {
		name = "Controls Generator",
		category = "Utilities",
		author = "Turbo49",
		versionNumber = 1,
		minEditorVersion = 131330,
		type = "SidePanelSection"
	}
end

--Initialize vars--
local controls = {
	useStartTransition = {
		value = SV:create("WidgetValue"),
		defaultValue = true
	},
	startTransitionWidth = {
		value = SV:create("WidgetValue"),
		defaultValue = 10
	},
	startTransitionHeight = {
		value = SV:create("WidgetValue"),
		defaultValue = 0
	},
	useEndTransition = {
		value = SV:create("WidgetValue"),
		defaultValue = true
	},
	endTransitionWidth = {
		value = SV:create("WidgetValue"),
		defaultValue = 10
	},
	endTransitionHeight = {
		value = SV:create("WidgetValue"),
		defaultValue = 0
	},
}

function getSidePanelSectionState()
	return {
		title = "Controls Generator",
		rows = {
			--Transitions--
			{
				type = "Container",
				columns = {
					{
						type = "CheckBox",
						text = "Start Transition Point",
						value = controls.useStartTransition
					}
				}
			},
			{
				type = "Container",
				columns = {
					{
						type = "Slider",
						text = "Transition Width",
						format = "%.0f beats",
						value = controls.startTransitionWidth
					}
				}
			},
			{
				type = "Container",
				columns = {
					{
						type = "Slider",
						text = "Transition Height",
						format = "%.0f cents",
						value = controls.startTransitionHeight
					}
				}
			},
			{
				type = "Container",
				columns = {
					{
						type = "CheckBox",
						text = "End Transition Point",
						value = controls.useEndTransition
					}
				}
			},
			{
				type = "Container",
				columns = {
					{
						type = "Slider",
						text = "Transition Width",
						format = "%.0f beats",
						value = controls.endTransitionWidth
					}
				}
			},
			{
				type = "Container",
				columns = {
					{
						type = "Slider",
						text = "Transition Height",
						format = "%.0f cents",
						value = controls.endTransitionHeight
					}
				}
			},
			--Vibrato--
			{
				type = "Container",
				columns = {
					{
						type = "CheckBox",
						text = "Vibrato",
						value = controls.useVibrato
					}
				}
			},
			{
				type = "Container",
				columns = {
					{
						type = "Slider",
						text = "Minimum Time from Start",
						format = "%.0f beats",
						value = controls.vibratoStartStart
					}
				}
			},
			{
				type = "Container",
				columns = {
					{
						type = "Slider",
						text = "Maximum Time from End",
						format = "%.0f beats",
						value = controls.vibratoStartEnd
					}
				}
			},
			{
				type = "Container",
				columns = {
					{
						type = "Slider",
						text = "Frequency",
						format = "%.0f Hz",
						value = controls.vibratoFrequency
					}
				}
			},
			{
				type = "Container",
				columns = {
					{
						type = "Slider",
						text = "Amplitude",
						format = "%.0f cents",
						value = controls.vibratoAmplitude
					}
				}
			},
			{
				type = "Container",
				columns = {
					{
						type = "Slider",
						text = "Fade In",
						format = "%.0f beats",
						width = 0.5,
						value = controls.vibratoFadeIn
					},
					{
						type = "Slider",
						text = "Fade Out",
						format = "%.0f beats",
						width = 0.5,
						value = controls.vibratoFadeOut
					}
				}
			},
			--Buttons--
			{
				type = "Container",
				columns = {
					{
						type = "Button",
						text = "Apply",
						value = controls.applyControls
					}
				}
			},
			{
				type = "Container",
				columns = {
					{
						type = "Button",
						text = "Reset",
						value = controls.resetControls
					}
				}
			}
		}
	}
end

