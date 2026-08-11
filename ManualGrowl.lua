function getClientInfo()
	return {
		name = "2 - Manual Growl",
		category = "Utilities",
		author = "Turbo49",
		versionNumber = 1,
		minEditorVersion = 131330,
		type = "SidePanelSection"
	}
end

-- initialize vars
parameters = {
	growlType = SV:create("WidgetValue"),
	growlCoverage = SV:create("WidgetValue"),
	growlAmplitudeMod = SV:create("WidgetValue"),
	applyButton = SV:create("WidgetValue"),
	resetButton = SV:create("WidgetValue"),
}

-- set defaults
parameters.growlType:setValue(0)
parameters.growlCoverage:setValue(50)
parameters.growlAmplitudeMod:setValue(0)

-- functions that do the thing
function clearAutomation(group,notes)
	local startPosition = notes[1]:getOnset()
	local endPosition = notes[#notes]:getEnd()

	local pitch = group:getParameter("pitchDelta")
	local breath = group:getParameter("breathiness")
	local voice = group:getParameter("voicing")
	-- reset pitch to 0
	pitch:remove(startPosition,endPosition)
	pitch:add(startPosition,0)
	pitch:add(endPosition,0)
	-- remove points in others, keep default value
	breath:remove(startPosition,endPosition)
	voice:remove(startPosition,endPosition)
end

function createAutomation(group,notes)
	local pitch = group:getParameter("pitchDelta")
	local breath = group:getParameter("breathiness")
	local voice = group:getParameter("voicing")

	-- initialize position vars
	local startPosition = 0
	local endPosition = 0
	local noteLength = 0

	for _,note in ipairs(notes) do
		startPosition = note:getOnset()
		endPosition = note:getEnd()
		noteLength = endPosition - startPosition

		if parameters.growlType:getValue() == 4 then
			local pointAmplitude = 1000 + parameters.growlAmplitudeMod:getValue()
			pitch:add(startPosition + 1, -pointAmplitude)
			pitch:add(startPosition + noteLength * parameters.growlCoverage:getValue() / 320, -pointAmplitude * .8)
			pitch:add(startPosition + noteLength * parameters.growlCoverage:getValue() / 300, 0)

		elseif parameters.growlType:getValue() == 5 then
			local pointAmplitude = 1000 + parameters.growlAmplitudeMod:getValue()
			pitch:add(endPosition - 1, -pointAmplitude)
			pitch:add(endPosition - noteLength * parameters.growlCoverage:getValue() / 320, -pointAmplitude * .8)
			pitch:add(endPosition - noteLength * parameters.growlCoverage:getValue() / 300, 0)

		elseif parameters.growlType:getValue() == 0 then
			local pointBoundaries = math.floor(50 + (parameters.growlAmplitudeMod:getValue() / 2))
			local pointSpacing = .02 * SV.QUARTER
			local pointAmount = math.floor(noteLength * parameters.growlCoverage:getValue() / 100 / pointSpacing)
			-- use a boolean to make sure the average pitch doesn't offset too much from 0
			local isUp = true
			for i = 1,pointAmount do
				if isUp then
					pitch:add(startPosition + i * pointSpacing, math.random(0, pointBoundaries))
				else
					pitch:add(startPosition + i * pointSpacing, math.random(-pointBoundaries, 0))
				end
				isUp = not isUp
			end
			-- add a final point at 0 to stop the pitch from being modified outside of bounds
			pitch:add(startPosition + noteLength * parameters.growlCoverage:getValue() / 100, 0)

		elseif parameters.growlType:getValue() == 1 then
			local pointBoundaries = math.floor(50 + (parameters.growlAmplitudeMod:getValue() / 2))
			local pointSpacing = .02 * SV.QUARTER
			local pointAmount = math.floor(noteLength * parameters.growlCoverage:getValue() / 100 / pointSpacing)
			-- use a boolean to make sure the average pitch doesn't offset too much from 0
			local isUp = true
			for i = 1,pointAmount do
				if isUp then
					pitch:add(endPosition - i * pointSpacing, math.random(0, pointBoundaries))
				else
					pitch:add(endPosition - i * pointSpacing, math.random(-pointBoundaries, 0))
				end
				isUp = not isUp
			end
			-- add a final point at 0 to stop the pitch from being modified outside of bounds
			pitch:add(endPosition - noteLength * parameters.growlCoverage:getValue() / 100, 0)

		elseif parameters.growlType:getValue() == 2 then
			local pointBoundaries = 0
			local pointAmplitude = 0
			local pointSpacing = .01 * SV.QUARTER
			local pointAmount = noteLength * parameters.growlCoverage:getValue() / 100 / pointSpacing
			for i = 1,pointAmount do
				pointAmplitude = 75 + parameters.growlAmplitudeMod:getValue() / 2
				pointBoundaries = math.floor(pointAmplitude - (i / pointAmount) * pointAmplitude)
				pitch:add(startPosition + i * pointSpacing, math.random(-pointBoundaries,pointBoundaries))
			end

		elseif parameters.growlType:getValue() == 3 then
			local pointBoundaries = 0
			local pointAmplitude = 0
			local pointSpacing = .01 * SV.QUARTER
			local pointAmount = noteLength * parameters.growlCoverage:getValue() / 100 / pointSpacing
			for i = 1,pointAmount do
				pointAmplitude = 75 + parameters.growlAmplitudeMod:getValue() / 2
				pointBoundaries = math.floor(pointAmplitude - (i / pointAmount) * pointAmplitude)
				pitch:add(endPosition - i * pointSpacing, math.random(-pointBoundaries,pointBoundaries))
			end

		elseif parameters.growlType:getValue() == 6 then
			-- add points at note boundaries at current values
			breath:add(startPosition, breath:get(startPosition))
			breath:add(endPosition, breath:get(endPosition))
			voice:add(startPosition, voice:get(startPosition))
			voice:add(endPosition, voice:get(endPosition))
			-- add the points offset from note boundaries to keep others untouched
			breath:add(startPosition + 1, 1)
			breath:add(endPosition - 1, 1)
			voice:add(startPosition + 1, 0)
			voice:add(endPosition - 1, 0)

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
		clearAutomation(selectedGroup,selectedNotes)
		createAutomation(selectedGroup,selectedNotes)
	end
end)

parameters.resetButton:setValueChangeCallback(function()
	if selectedNotes == nil then
		SV:showMessageBox("Error","No notes were selected")
	else
		clearAutomation(selectedGroup,selectedNotes)
	end
end)

function getSidePanelSectionState()
	return {
		title = "Manual Growl",
		rows = {
			--options
			{
				type = "Container",
				columns = {
					{
						type = "ComboBox",
						choices = {"Growl (Start)", "Growl (End)", "Fading Growl (Start)", "Fading Growl (End)", "Vocal Fry (Start)", "Vocal Fry (End)", "Guttural"},
						value = parameters.growlType
					}
				}
			},
			{
				type = "Container",
				columns = {
					{
						type = "Slider",
						text = "Amplitude Modifier",
						format = "%+3.0f cents",
						minValue = -100,
						maxValue = 100,
						interval = 1,
						value = parameters.growlAmplitudeMod
					}
				}
			},
			{
				type = "Container",
				columns = {
					{
						type = "Slider",
						text = "Coverage",
						format = "%3.0f %%",
						minValue = 0,
						maxValue = 100,
						interval = 5,
						value = parameters.growlCoverage
					}
				}
			},
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
			}
		}
	}
end