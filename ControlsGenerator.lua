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
	---start
	useStartTransition = SV:create("WidgetValue"),
	startTransitionWidth = SV:create("WidgetValue"),
	startTransitionHeight = SV:create("WidgetValue"),
	---end
	useEndTransition = SV:create("WidgetValue"),
	endTransitionWidth = SV:create("WidgetValue"),
	endTransitionHeight = SV:create("WidgetValue"),
	---vibrato
	useVibrato = SV:create("WidgetValue"),
	vibratoStartFromStart = SV:create("WidgetValue"),
	vibratoStartFromEnd = SV:create("WidgetValue"),
	vibratoFrequency = SV:create("WidgetValue"),
	vibratoAmplitude = SV:create("WidgetValue"),
	vibratoFadeIn = SV:create("WidgetValue"),
	vibratoFadeOut = SV:create("WidgetValue"),
	---buttons
	applyControls = SV:create("WidgetValue"),
	resetControls = SV:create("WidgetValue"),
}

controls.useStartTransition:setValue(true)
controls.startTransitionWidth:setValue(10)
controls.startTransitionHeight:setValue(0)

controls.useEndTransition:setValue(true)
controls.endTransitionWidth:setValue(10)
controls.endTransitionHeight:setValue(0)

controls.useVibrato:setValue(true)
controls.vibratoStartFromStart:setValue(10)
controls.vibratoStartFromEnd:setValue(10)
controls.vibratoFrequency:setValue(5)
controls.vibratoAmplitude:setValue(10)
controls.vibratoFadeIn:setValue(2)
controls.vibratoFadeOut:setValue(2)

--[[
local message=""
for key,value in pairs(controls.useStartTransition.value) do
	message = message..tostring(key).."\n"
end
local form = {message=message}
SV:showCustomDialog(form)
]]

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
						minValue = 0,
						maxValue = 20,
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
						minValue = -100,
						maxValue = 100,
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
						minValue = 0,
						maxValue = 20,
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
						minValue = -100,
						maxValue = 100,
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
						minValue = 0,
						maxValue = 50,
						value = controls.vibratoStartFromStart
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
						minValue = 0,
						maxValue = 50,
						value = controls.vibratoStartFromEnd
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
						minValue = 1,
						maxValue = 100,
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
						minValue = 0,
						maxValue = 100,
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
						minValue = 0,
						maxValue = 20,
						value = controls.vibratoFadeIn
					},
					{
						type = "Slider",
						text = "Fade Out",
						format = "%.0f beats",
						width = 0.5,
						minValue = 0,
						maxValue = 20,
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

