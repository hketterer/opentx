local VALUE = 0
local COMBO = 1

local edit = false
local page = 1
local current = 1
local pages = {}
local fields = {}



local function drawScreenTitle(title,page, pages)
	lcd.drawFilledRectangle(0, 0, LCD_W, 30, TITLE_BGCOLOR)
	lcd.drawText(1, 5, title, MENU_TITLE_COLOR)
	lcd.drawText(LCD_W-40, 5, page.."/"..pages, MENU_TITLE_COLOR)
end

-- Change display attribute to current field
local function addField(step)
  local field = fields[current]
  local min, max
  if field[3] == VALUE then
    min = field[6]
    max = field[7]
  elseif field[3] == COMBO then
    min = 0
    max = #(field[6]) - 1
  end
  if (step < 0 and field[5] > min) or (step > 0 and field[5] < max) then
    field[5] = field[5] + step
  end
end

-- Select the next or previous page
local function selectPage(step)
  page = 1 + ((page + step - 1 + #pages) % #pages)
end

-- Select the next or previous editable field
local function selectField(step)
  repeat
    current = 1 + ((current + step - 1 + #fields) % #fields)
  until fields[current][4]==1
end


-- Redraw the current page
local function redrawFieldsPage(event)
  --drawScreenTitle("Wizard", page, #pages)

  for index = 1, 10, 1 do
    local field = fields[index]
    if field == nil then
      break
    end

    local attr = current == (index) and ((edit == true and BLINK or 0) + INVERS) or 0
	   attr = attr + TEXT_COLOR

     if field[4] == 1 then
      if field[3] == VALUE then
        lcd.drawNumber(field[1], field[2], field[5], LEFT + attr)
      elseif field[3] == COMBO then
        if field[5] >= 0 and field[5] < #(field[6]) then
          lcd.drawText(field[1],field[2], field[6][1+field[5]], attr)
        end
      end
    end
  end
end

local function updateField(field)
  local value = field[5]
end

-- Main
local function runFieldsPage(event)
  if event == EVT_EXIT_BREAK  then             -- exit script
    return 2
  elseif event == EVT_ENTER_BREAK or event == EVT_ROT_BREAK then        -- toggle editing/selecting current field
    if fields[current][5] ~= nil then
      edit = not edit
      if edit == false then
        updateField(fields[current])
      end
    end
  elseif edit then
    if event == EVT_PLUS_FIRST or event == EVT_ROT_RIGHT or event == EVT_PLUS_REPT then
      addField(1)
    elseif event == EVT_MINUS_FIRST or event == EVT_ROT_LEFT or event == EVT_MINUS_REPT then
      addField(-1)
    end
  else
    if event == EVT_MINUS_FIRST or event == EVT_ROT_RIGHT then
      selectField(1)
    elseif event == EVT_PLUS_FIRST or event == EVT_ROT_LEFT then
      selectField(-1)
    end
  end
  redrawFieldsPage(event)
  return 0
end

local MotorConfigBackground = Bitmap.open("img/bg_engine.png")
local MotorFields = {
  {40 , 105, COMBO, 1, 1, { "No", "Yes"} },
  {40, 185,  COMBO, 3, 1, { "CH1", "CH2", "CH3", "CH4", "CH5", "CH6", "CH7", "CH8"  } },
}

local function runMotorConfig(event)
  lcd.clear()
  fields = MotorFields
  lcd.drawBitmap(MotorConfigBackground, 0, 0)
  lcd.drawText(40, 80, "Does your model have a motor ?", TEXT_COLOR)
  local result = runFieldsPage(event)
  fields[2][4]=0
  if fields[1][5] == 1 then
    lcd.drawText(40, 160, "What channel is it on ?", TEXT_COLOR)
    fields[2][4]=1
  end
  return result
end

-- fields format : {[1]x, [2]y, [3]COMBO, [4]visible, [5]default, [6]{ values}}
-- fields format : {[1]x, [2]y, [3]VALUE, [4]visible, [5]default, [6]min, [7]max}
local AilFields = {
{30, 105, COMBO, 1, 1, { "None", "One, or two with Y cable", "Two"} },
{170, 140,  VALUE, 1, 1, 1, 16 },  -- Ail1 chan
{170, 160,  VALUE, 5, 1, 1, 16 }, -- Ail2 chan
}

local function runAilConfig(event)
  lcd.clear()
  fields = AilFields
  lcd.drawBitmap(MotorConfigBackground, 0, 0)
  lcd.drawText(30, 80, "Number of ailerons on your model ?", TEXT_COLOR)
  local result = runFieldsPage(event)
  fields[2][4], fields[3][4]=0
  if fields[1][5] >= 1 then
    lcd.drawText(30, 140, "Channel for Ail1 :", TEXT_COLOR)
    fields[2][4]=1
  end
  if fields[1][5] == 2 then
    lcd.drawText(30, 160, "Channel for Ail2 :", TEXT_COLOR)
    fields[3][4]=1
  end
  return result
end

local FlapsFields = {
{30, 105, COMBO, 1, 1, { "No", "Yes, on one channel", "Yes, on two channels"} },
{30, 160,  COMBO, 1, 1, { "CH1", "CH2", "CH3", "CH4", "CH5", "CH6", "CH7", "CH8"  } },
{30, 220,  COMBO, 1, 1, { "CH1", "CH2", "CH3", "CH4", "CH5", "CH6", "CH7", "CH8"  } },
}

local function runFlapsConfig(event)
  lcd.clear()
  fields = FlapsFields
  lcd.drawBitmap(MotorConfigBackground, 0, 0)
  lcd.drawText(30, 80, "Does your model have flaps ?", TEXT_COLOR)
  local result = runFieldsPage(event)
  fields[2][4], fields[3][4]=0
  if fields[1][5] == 1 then
    lcd.drawText(30, 140, "Channel to use for flaps :", TEXT_COLOR)
    fields[2][4]=1
  end
  if fields[1][5] == 2 then
    lcd.drawText(30, 140, "Channel for right flaps :", TEXT_COLOR)
		lcd.drawText(30, 200, "Channel for left flaps :", TEXT_COLOR)
    fields[2][4] = 1
		fields[3][4] = 1
  end
  return result
end

local TailFields = {
{30, 105, COMBO, 1, 2, { "1 channel for Elevator, no Rudder", "One chan for Elevator, one for Rudder", "Two chans for Elevator, one for Rudder", "V Tail"} },
{30, 160,  COMBO, 1, 2, { "CH1", "CH2", "CH3", "CH4", "CH5", "CH6", "CH7", "CH8"  } }, --ele
{30, 200,  COMBO, 1, 4, { "CH1", "CH2", "CH3", "CH4", "CH5", "CH6", "CH7", "CH8"  } }, --rud
{30, 240,  COMBO, 0, 6, { "CH1", "CH2", "CH3", "CH4", "CH5", "CH6", "CH7", "CH8"  } }, --ele2
}

local function runTailConfig(event)
  lcd.clear()
  fields = TailFields
  lcd.drawBitmap(MotorConfigBackground, 0, 0)
  lcd.drawText(30, 80, "Pick the tail config of your model", TEXT_COLOR)
  local result = runFieldsPage(event)
	fields[2][4]=0
	fields[3][4]=0
	fields[3][5]=0
  if fields[1][5] == 0 then
    lcd.drawText(30, 140, "Channel for Elevator :", TEXT_COLOR)
    fields[2][4]=1
		fields[3][4]=0
		fields[4][4]=0
  end
	if fields[1][5] == 1 then
		lcd.drawText(30, 140, "Channel for Elevator :", TEXT_COLOR)
		lcd.drawText(30, 180, "Channel for Rudder :", TEXT_COLOR)
		fields[2][4]=1
		fields[3][4]=1
		fields[4][4]=0
	end
	if fields[1][5] == 2 then
		lcd.drawText(30, 140, "Channel for Elevator :", TEXT_COLOR)
		lcd.drawText(30, 180, "Channel for Rudder :", TEXT_COLOR)
		lcd.drawText(30, 220, "Channel for Elevator 2 :", TEXT_COLOR)
		fields[2][4]=1
		fields[3][4]=1
		fields[4][4]=1
	end
	if fields[1][5] == 3 then
		lcd.drawText(30, 140, "Channel for V right :", TEXT_COLOR)
		lcd.drawText(30, 180, "Channel for V left :", TEXT_COLOR)
		fields[2][4]=1
		fields[3][4]=1
		fields[4][4]=0
	end
  return result
end

-- Init
local function init()
  current, edit = 1, false
  pages = {
    runMotorConfig,
    runAilConfig,
		runFlapsConfig,
		runTailConfig,
  }
end

-- Main
local function run(event)
  if event == nil then
    error("Cannot be run as a model script!")
    return 2
  elseif event == EVT_PAGE_BREAK or event == EVT_PAGEDN_FIRST  then
    selectPage(1)
  elseif event == EVT_PAGE_LONG or event == EVT_PAGEUP_FIRST then
    killEvents(event);
    selectPage(-1)
  end

  local result = pages[page](event)
  return result
end

return { init=init, run=run }
