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

-- initialize vars
controls = {
	--start
	useStartTransition = SV:create("WidgetValue"),
	startTransitionWidth = SV:create("WidgetValue"),
	startTransitionHeight = SV:create("WidgetValue"),
	--end
	useEndTransition = SV:create("WidgetValue"),
	endTransitionWidth = SV:create("WidgetValue"),
	endTransitionHeight = SV:create("WidgetValue"),
	--vibrato
	useVibrato = SV:create("WidgetValue"),
	vibratoStartFromStart = SV:create("WidgetValue"),
	vibratoStartFromEnd = SV:create("WidgetValue"),
	vibratoFrequency = SV:create("WidgetValue"),
	vibratoAmplitude = SV:create("WidgetValue"),
	vibratoFadeIn = SV:create("WidgetValue"),
	vibratoFadeOut = SV:create("WidgetValue"),
	--options
	useFlattening = SV:create("WidgetValue"),
	--buttons
	applyControls = SV:create("WidgetValue"),
	resetControls = SV:create("WidgetValue"),
}

-- set defaults
controls.useStartTransition:setValue(true)
controls.startTransitionWidth:setValue(1)
controls.startTransitionHeight:setValue(0)

controls.useEndTransition:setValue(true)
controls.endTransitionWidth:setValue(1)
controls.endTransitionHeight:setValue(0)

controls.useVibrato:setValue(true)
controls.vibratoStartFromStart:setValue(4)
controls.vibratoStartFromEnd:setValue(8)
controls.vibratoFrequency:setValue(8)
controls.vibratoAmplitude:setValue(1)
controls.vibratoFadeIn:setValue(1)
controls.vibratoFadeOut:setValue(1)

controls.useFlattening:setValue(true)

-- functions that do the thing
function clearNoteParameters(group)
	local numControls = group:getNumPitchControls()

	for controlIndex = 1,numControls do
		group:removePitchControl(1)
	end
end

function createNoteParameters(group)
	--note loop
	local numNotes = group:getNumNotes()

	for noteIndex = 1,numNotes do
		local note = group:getNote(noteIndex)

		--get note timing and pitch info
		local noteOnset = note:getOnset()
		local noteDuration = note:getDuration()
		local noteEnd = noteOnset + noteDuration
		local notePitch = note:getPitch()

		--set expression to rigid and vibrato to 0
		note:setAttributes({dF0VbrMod = 0, expValueX = -1, expValueY = -1})

		--add controls
		local startPosition = noteOnset + (controls.startTransitionWidth:getValue() * SV.QUARTER / 4)
		local endPosition = noteEnd - (controls.endTransitionWidth:getValue() * SV.QUARTER / 4)
		local vibratoStartPosition = math.max(noteOnset + (controls.vibratoStartFromStart:getValue() * SV.QUARTER / 4), noteEnd - (controls.vibratoStartFromEnd:getValue() * SV.QUARTER / 4))
		local vibratoDistance = (vibratoStartPosition - startPosition)

		--start transition
		if controls.useStartTransition:getValue() then
			local startTransition = SV:create("PitchControlPoint")
			startTransition:setPosition(math.min(noteEnd,startPosition))
			startTransition:setPitch(notePitch + controls.startTransitionHeight:getValue())
			group:addPitchControl(startTransition)
		end

		--end transition
		if controls.useEndTransition:getValue() then
			local endTransition = SV:create("PitchControlPoint")
			endTransition:setPosition(math.max(startPosition,endPosition))
			endTransition:setPitch(notePitch + controls.endTransitionHeight:getValue())
			group:addPitchControl(endTransition)
		end

		--vibrato
		if controls.useVibrato:getValue() then
			--add controls in loop
			local currentVibratoPosition = vibratoStartPosition
			local isTop = true

			while currentVibratoPosition < endPosition do
				local vibratoPoint = SV:create("PitchControlPoint")
				vibratoPoint:setPosition(currentVibratoPosition)
				--find pitch
				if isTop then
					vibratoPoint:setPitch(notePitch + controls.vibratoAmplitude:getValue() / 2)
				else
					vibratoPoint:setPitch(notePitch - controls.vibratoAmplitude:getValue() / 2)
				end
				group:addPitchControl(vibratoPoint)
				--increase position
				currentVibratoPosition = currentVibratoPosition + SV:getProject():getTimeAxis():getBlickFromSeconds(1/controls.vibratoFrequency:getValue()) / 2
				isTop = not isTop
			end
		end

		--flattening
		if controls.useFlattening:getValue() and vibratoDistance > (controls.startTransitionWidth:getValue() * SV.QUARTER / 4) then
			local controlCurve = SV:create("PitchControlCurve")
			controlCurve:setPitch(notePitch)
			controlCurve:setPosition(noteOnset)
			controlCurve:setPoints({{(controls.startTransitionWidth:getValue() * SV.QUARTER / 2),0},{vibratoStartPosition - noteOnset - (controls.startTransitionWidth:getValue() * SV.QUARTER / 4),0}})
			group:addPitchControl(controlCurve)
		end
		
	end
end

-- main loop
function main(group)
	clearNoteParameters(group)
	createNoteParameters(group)
end

local selectedGroup = SV:getMainEditor():getCurrentGroup():getTarget()
local selectedNotes = SV:getMainEditor():getSelection():getSelectedNotes()
--on button press
controls.applyControls:setValueChangeCallback(function() main(selectedGroup) end)
controls.resetControls:setValueChangeCallback(function() clearNoteParameters(selectedGroup) end)


-- debug code
--[[
--local message=""
--for value in SV:getMainEditor():getSelection():getSelectedGroups() do
--	message = message..tostring(value).."\n"
--end
--local form = {message=message}
local message = tostring(#SV:getMainEditor():getSelection():getSelectedGroups())
SV:showCustomDialog(message)
]]

function getSidePanelSectionState()
	return {
		title = "Controls Generator",
		rows = {
			--options
			{
				type = "Container",
				columns = {
					{
						type = "CheckBox",
						text = "Flatten Pitch",
						value = controls.useFlattening
					}
				}
			},
			--transitions
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
						format = "%.1f beats",
						minValue = 0,
						maxValue = 4,
						interval = 0.1,
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
						format = "%.1f cents",
						minValue = -5,
						maxValue = 5,
						interval = 0.1,
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
						format = "%.1f beats",
						minValue = 0,
						maxValue = 4,
						interval = 0.1,
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
						format = "%.1f cents",
						minValue = -5,
						maxValue = 5,
						interval = 0.1,
						value = controls.endTransitionHeight
					}
				}
			},
			--vibrato
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
						format = "%.1f beats",
						minValue = 0,
						maxValue = 12,
						interval = 0.1,
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
						format = "%.1f beats",
						minValue = 0,
						maxValue = 24,
						interval = 0.1,
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
						format = "%.1f Hz",
						minValue = 1,
						maxValue = 60,
						interval = 0.1,
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
						format = "%.1f cents",
						minValue = 0,
						maxValue = 5,
						interval = 0.1,
						value = controls.vibratoAmplitude
					}
				}
			},
			--[[ TODO: add fade
			{
				type = "Container",
				columns = {
					{
						type = "Slider",
						text = "Fade In",
						format = "%.1f beats",
						width = 0.5,
						minValue = 0,
						maxValue = 4,
						interval = 0.1,
						value = controls.vibratoFadeIn
					},
					{
						type = "Slider",
						text = "Fade Out",
						format = "%.1f beats",
						width = 0.5,
						minValue = 0,
						maxValue = 4,
						interval = 0.1,
						value = controls.vibratoFadeOut
					}
				}
			},
			]]
			--buttons
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

