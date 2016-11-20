local VALUE = 0
local COMBO = 1

local edit = false
local page = 1
local current = 1
local pageOffset = 0
local pages = {}
local fields = {}


-- {[1] x_desc, [2] "Desc text", [3] x_val, [4] TYPE, [5] default, [6]{ values}}

local page1Fields = {
  {10, "Sample text:", 300, COMBO, 1, { "Choice1", "Choice2", "Choice3" } },
  {10, "Sample value:", 300, VALUE, 0, -10, 10, "%" },
}

local page2Fields = {
  {30, "Sample text to number:", 350,  COMBO, 1, { "Disable", "Enable" } },
}


local function drawScreenTitle(title,page, pages)
	lcd.drawFilledRectangle(0, 0, LCD_W, 30, TITLE_BGCOLOR)
	lcd.drawText(1, 5, title, MENU_TITLE_COLOR)
	lcd.drawText(LCD_W-40, 5, page.."/"..pages, MENU_TITLE_COLOR)
end

-- Change display attribute to current field
local function addField(step)
  local field = fields[current]
  local min, max
  if field[4] == VALUE then
    min = field[6]
    max = field[7]
  elseif field[4] == COMBO then
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
  pageOffset = 0
end

-- Select the next or previous editable field
local function selectField(step)
  current = 1 + ((current + step - 1 + #fields) % #fields)
  if current > 7 + pageOffset then
    pageOffset = current - 7
  elseif current <= pageOffset then
    pageOffset = current - 1
  end
end


-- Redraw the current page
local function redrawFieldsPage(event)
  lcd.clear()
  lcd.drawFilledRectangle(0, 0, LCD_W, LCD_H, TEXT_BGCOLOR)
  drawScreenTitle("Wizard", page, #pages)

  for index = 1, 10, 1 do
    local field = fields[pageOffset+index]
    if field == nil then
      break
    end

    local attr = current == (pageOffset+index) and ((edit == true and BLINK or 0) + INVERS) or 0
	attr = attr + TEXT_COLOR

    lcd.drawText( field[1], 30+20*index, field[2], TEXT_COLOR)

    if field[4] == nil then
      lcd.drawText(field[3], 30+20*index, "---", attr)
    else
      if field[4] == VALUE then
        lcd.drawNumber(field[3], 30+20*index, field[5], LEFT + attr)
      elseif field[4] == COMBO then
        if field[5] >= 0 and field[5] < #(field[6]) then
          lcd.drawText(field[3], 30+20*index, field[6][1+field[5]], attr)
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

local function runPage1(event)
  fields = page1Fields
  return runFieldsPage(event)
end

local function runPage2(event)
  fields = page2Fields
  local result = runFieldsPage(event)
  if fields[1][4] ~= nil then
    lcd.drawText(50, 100, "Choice selected is :" ..fields[1][5], TEXT_COLOR)
  end
  return result
end

-- Init
local function init()
  current, edit = 1, false
  pages = {
    runPage1,
    runPage2,
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
