function getClientInfo()
	return {
		name = "1 - Manual Pitch",
		category = "Utilities",
		author = "Turbo49",
		versionNumber = 1,
		minEditorVersion = 131330,
		type = "SidePanelSection"
	}
end

-- initialize vars
parameters = {
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
	--options
	useFlattening = SV:create("WidgetValue"),
	--buttons
	applyButton = SV:create("WidgetValue"),
	resetButton = SV:create("WidgetValue"),
	loadButton = SV:create("WidgetValue"),
}

-- set defaults
parameters.useStartTransition:setValue(false)
parameters.startTransitionWidth:setValue(0.05)
parameters.startTransitionHeight:setValue(0)

parameters.useEndTransition:setValue(false)
parameters.endTransitionWidth:setValue(0.05)
parameters.endTransitionHeight:setValue(0)

parameters.useVibrato:setValue(true)
parameters.vibratoMinNoteLength:setValue(1.5)
parameters.vibratoCoverage:setValue(80)
parameters.vibratoFrequency:setValue(6)
parameters.vibratoAmplitude:setValue(0.8)

parameters.useFlattening:setValue(true)

--main functions for functionality
function clearPitch(group,notes)
	if group:getNumPitchControls() ~= 0 then
		local minPosition = notes[1]:getOnset()
		local maxPosition = notes[#notes]:getEnd()
		local currentControl = 1

		while group:getPitchControl(currentControl):getPosition() < minPosition do
			currentControl = currentControl + 1
		end

		while group:getNumPitchControls() > 0 and group:getPitchControl(currentControl):getPosition() < maxPosition do
			group:removePitchControl(currentControl)
		end
	end
end

function createPitch(group,notes)
	--note loop
	for _,note in ipairs(notes) do
		--get note timing and pitch info
		local noteStart = note:getOnset()
		local noteDuration = note:getDuration()
		local noteEnd = noteStart + noteDuration
		local notePitch = note:getPitch()

		--add parameters
		local pointStart = noteStart + (parameters.startTransitionWidth:getValue() * SV.QUARTER)
		local pointEnd = noteEnd - (parameters.endTransitionWidth:getValue() * SV.QUARTER)
		-- initialize vibrato position at the end in case it goes unused
		local vibratoStart = pointEnd - (parameters.startTransitionWidth:getValue() * SV.QUARTER) + SV:getProject():getTimeAxis():getBlickFromSeconds(0.25/parameters.vibratoFrequency:getValue())

		--start transition
		if parameters.useStartTransition:getValue() then
			local startTransition = SV:create("PitchControlPoint")
			startTransition:setPosition(math.min(noteEnd,pointStart))
			startTransition:setPitch(notePitch + parameters.startTransitionHeight:getValue())
			group:addPitchControl(startTransition)
		end

		--end transition
		if parameters.useEndTransition:getValue() then
			local endTransition = SV:create("PitchControlPoint")
			endTransition:setPosition(math.max(pointStart,pointEnd))
			endTransition:setPitch(notePitch + parameters.endTransitionHeight:getValue())
			group:addPitchControl(endTransition)
		end

		--vibrato
		if (parameters.useVibrato:getValue()) and (noteDuration > parameters.vibratoMinNoteLength:getValue() * SV.QUARTER) then
			--add parameters in loop
			vibratoStart = noteStart + noteDuration * (100 - parameters.vibratoCoverage:getValue()) / 100
			local currentVibratoPosition = vibratoStart
			local isTop = true

			while currentVibratoPosition < pointEnd do
				local vibratoPoint = SV:create("PitchControlPoint")
				vibratoPoint:setPosition(currentVibratoPosition)
				--find pitch
				if isTop then
					vibratoPoint:setPitch(notePitch + parameters.vibratoAmplitude:getValue() / 2)
				else
					vibratoPoint:setPitch(notePitch - parameters.vibratoAmplitude:getValue() / 2)
				end
				group:addPitchControl(vibratoPoint)
				--increase position
				currentVibratoPosition = currentVibratoPosition + SV:getProject():getTimeAxis():getBlickFromSeconds(1/parameters.vibratoFrequency:getValue()) / 2
				isTop = not isTop
			end
		end

		--flattening
		if (parameters.useFlattening:getValue()) then
			if (vibratoStart - noteStart > (parameters.startTransitionWidth:getValue() * SV.QUARTER * 2) + (SV:getProject():getTimeAxis():getBlickFromSeconds(0.25/parameters.vibratoFrequency:getValue()))) then
				local controlCurve = SV:create("PitchControlCurve")
				controlCurve:setPitch(notePitch)
				controlCurve:setPosition(noteStart)
				controlCurve:setPoints({{(parameters.startTransitionWidth:getValue() * SV.QUARTER * 2),0},{vibratoStart - noteStart - SV:getProject():getTimeAxis():getBlickFromSeconds(0.25/parameters.vibratoFrequency:getValue()),0}})
				group:addPitchControl(controlCurve)
			--if the margins are too large, add a single point in the middle
			else
				local minlengthPoint = SV:create("PitchControlPoint")
				minlengthPoint:setPosition((noteStart + noteEnd)/2)
				minlengthPoint:setPitch(notePitch)
				group:addPitchControl(minlengthPoint)
			end
		end

	end
end

--store values in the notes to be pulled later
function storeParameters(notes)
	for _,note in ipairs(notes) do
		for key,value in pairs(parameters) do
			note:setScriptData(key, value:getValue())
		end
	end
end

function loadParameters(note)
	for key,value in pairs(parameters) do
		if note:getScriptData(key) ~= nil then
			value:setValue(note:getScriptData(key))
		end
	end
end

--update selection on change
selectedGroup = nil
selectedNotes = nil

SV:getMainEditor():getSelection():registerSelectionCallback(function()
	selectedGroup = SV:getMainEditor():getCurrentGroup():getTarget()
	selectedNotes = SV:getMainEditor():getSelection():getSelectedNotes()
end)

SV:getMainEditor():getSelection():registerClearCallback(function()
	selectedGroup = nil
	selectedNotes = nil
end)

--on button press
parameters.applyButton:setValueChangeCallback(function()
	if selectedNotes == nil then
		SV:showMessageBox("Error","No notes were selected")
	else
		clearPitch(selectedGroup,selectedNotes)
		createPitch(selectedGroup,selectedNotes)
		storeParameters(selectedNotes)
	end
end)

parameters.resetButton:setValueChangeCallback(function()
	if selectedNotes == nil then
		SV:showMessageBox("Error","No notes were selected")
	else
		clearPitch(selectedGroup,selectedNotes)
	end
end)

parameters.loadButton:setValueChangeCallback(function()
	if selectedNotes == nil then
		SV:showMessageBox("Error","No notes were selected")
	else
		loadParameters(selectedNotes[#selectedNotes])
	end
end)

--side panel
function getSidePanelSectionState()
	return {
		title = "Manual Pitch",
		rows = {
			--options
			{
				type = "Container",
				columns = {
					{
						type = "CheckBox",
						text = "Flatten Pitch",
						value = parameters.useFlattening
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
						value = parameters.useStartTransition
					}
				}
			},
			{
				type = "Container",
				columns = {
					{
						type = "Slider",
						text = "Transition Width",
						format = "%.2f beats",
						minValue = 0,
						maxValue = 1,
						interval = 0.01,
						value = parameters.startTransitionWidth
					}
				}
			},
			{
				type = "Container",
				columns = {
					{
						type = "Slider",
						text = "Transition Height",
						format = "%.1f smt.",
						minValue = -5,
						maxValue = 5,
						interval = 0.1,
						value = parameters.startTransitionHeight
					}
				}
			},
			{
				type = "Container",
				columns = {
					{
						type = "CheckBox",
						text = "End Transition Point",
						value = parameters.useEndTransition
					}
				}
			},
			{
				type = "Container",
				columns = {
					{
						type = "Slider",
						text = "Transition Width",
						format = "%.2f beats",
						minValue = 0,
						maxValue = 1,
						interval = 0.01,
						value = parameters.endTransitionWidth
					}
				}
			},
			{
				type = "Container",
				columns = {
					{
						type = "Slider",
						text = "Transition Height",
						format = "%.1f smt.",
						minValue = -5,
						maxValue = 5,
						interval = 0.1,
						value = parameters.endTransitionHeight
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
						value = parameters.useVibrato
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
						maxValue = 3,
						interval = 0.1,
						value = parameters.vibratoMinNoteLength
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
						value = parameters.vibratoCoverage
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
						value = parameters.vibratoFrequency
					}
				}
			},
			{
				type = "Container",
				columns = {
					{
						type = "Slider",
						text = "Amplitude",
						format = "%.1f smt.",
						minValue = 0,
						maxValue = 5,
						interval = 0.1,
						value = parameters.vibratoAmplitude
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
						value = parameters.vibratoFadeIn
					},
					{
						type = "Slider",
						text = "Fade Out",
						format = "%.1f beats",
						width = 0.5,
						minValue = 0,
						maxValue = 4,
						interval = 0.1,
						value = parameters.vibratoFadeOut
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
						value = parameters.applyButton
					}
				}
			},
			{
				type = "Container",
				columns = {
					{
						type = "Button",
						text = "Reset Selected",
						value = parameters.resetButton
					}
				}
			},
			{
				type = "Container",
				columns = {
					{
						type = "Button",
						text = "Load Values from Selected",
						value = parameters.loadButton
					}
				}
			}
		}
	}
end

