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
	vibratoMinNoteLength = SV:create("WidgetValue"),
	vibratoCoverage = SV:create("WidgetValue"),
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
controls.useStartTransition:setValue(false)
controls.startTransitionWidth:setValue(0.2)
controls.startTransitionHeight:setValue(0)

controls.useEndTransition:setValue(false)
controls.endTransitionWidth:setValue(0.2)
controls.endTransitionHeight:setValue(0)

controls.useVibrato:setValue(true)
controls.vibratoMinNoteLength:setValue(6)
controls.vibratoCoverage:setValue(80)
controls.vibratoFrequency:setValue(6)
controls.vibratoAmplitude:setValue(0.8)
controls.vibratoFadeIn:setValue(1)
controls.vibratoFadeOut:setValue(1)

controls.useFlattening:setValue(true)

-- functions that do the thing
function clearNoteParameters(group,notes)
	local numControls = group:getNumPitchControls()
	
	for controlIndex = 1,numControls do
		group:removePitchControl(1)
	end
end

function createNoteParameters(group,notes)
	--note loop
	local numNotes = group:getNumNotes()

	for noteIndex = 1,numNotes do
		local note = group:getNote(noteIndex)

		--get note timing and pitch info
		local noteOnset = note:getOnset()
		local noteDuration = note:getDuration()
		local noteEnd = noteOnset + noteDuration
		local notePitch = note:getPitch()

		--set expression to rigid and vibrato to 1
		note:setAttributes({dF0VbrMod = 1, expValueX = -1, expValueY = -1})

		--add controls
		local startPosition = noteOnset + (controls.startTransitionWidth:getValue() * SV.QUARTER / 4)
		local endPosition = noteEnd - (controls.endTransitionWidth:getValue() * SV.QUARTER / 4)
		-- initialize vibrato position at the end in case it goes unused
		local vibratoStartPosition = endPosition - (controls.startTransitionWidth:getValue() * SV.QUARTER / 4) + SV:getProject():getTimeAxis():getBlickFromSeconds(0.25/controls.vibratoFrequency:getValue())

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
		if (controls.useVibrato:getValue()) and (noteDuration > controls.vibratoMinNoteLength:getValue() * SV.QUARTER / 4) then
			--add controls in loop
			vibratoStartPosition = noteOnset + noteDuration * (100 - controls.vibratoCoverage:getValue()) / 100
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
		if (controls.useFlattening:getValue()) and (vibratoStartPosition - noteOnset > (controls.startTransitionWidth:getValue() * SV.QUARTER / 2) + (SV:getProject():getTimeAxis():getBlickFromSeconds(0.25/controls.vibratoFrequency:getValue()))) then
			local controlCurve = SV:create("PitchControlCurve")
			controlCurve:setPitch(notePitch)
			controlCurve:setPosition(noteOnset)
			controlCurve:setPoints({{(controls.startTransitionWidth:getValue() * SV.QUARTER / 2),0},{vibratoStartPosition - noteOnset - SV:getProject():getTimeAxis():getBlickFromSeconds(0.25/controls.vibratoFrequency:getValue()),0}})
			group:addPitchControl(controlCurve)
		end
		
	end
end

--update selection on change
selectedGroup = SV:getMainEditor():getCurrentGroup():getTarget()
selectedNotes = SV:getMainEditor():getSelection():getSelectedNotes()

SV:getMainEditor():getSelection():registerSelectionCallback(function()
	selectedGroup = SV:getMainEditor():getCurrentGroup():getTarget()
	selectedNotes = SV:getMainEditor():getSelection():getSelectedNotes()
end)

--on button press
controls.applyControls:setValueChangeCallback(function() 
	clearNoteParameters(selectedGroup,selectedNotes)
	createNoteParameters(selectedGroup,selectedNotes) end)

controls.resetControls:setValueChangeCallback(function()
	clearNoteParameters(selectedGroup,selectedNotes) end)


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
						text = "Minimum Note Length",
						format = "%.1f beats",
						minValue = 0,
						maxValue = 12,
						interval = 0.1,
						value = controls.vibratoMinNoteLength
					}
				}
			},
			{
				type = "Container",
				columns = {
					{
						type = "Slider",
						text = "Note Coverage",
						format = "%3.0f %%",
						minValue = 0,
						maxValue = 100,
						interval = 1,
						value = controls.vibratoCoverage
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
						text = "Apply to Selected",
						value = controls.applyControls
					}
				}
			},
			{
				type = "Container",
				columns = {
					{
						type = "Button",
						text = "Reset Selected",
						value = controls.resetControls
					}
				}
			}
		}
	}
end

