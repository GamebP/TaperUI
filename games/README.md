# TaperUI Developer API Reference

This document provides a comprehensive API reference for TaperUI's elements module (`helper/elements.lua`) and details how to structure custom game scripts (`games/<game_id>.lua`) so they link with the TaperUI core loader.

---

## 🏗 Script Design & Structure

Game scripts in TaperUI are structured in one of two ways. You must format your game script according to whether it is loaded dynamically inside the Multi-Game Hub or runs as a completely independent client.

### 1. Hub Mode (Standard Dynamic Scripts)
If your game is loaded inside the default TaperUI Multi-Game Hub, your script **must return a function wrapper**. The loader (`UI.lua`) automatically executes this returned function and passes the runtime context as arguments:

```lua
return function(parent, config, Window, GameTab)
    -- 1. Import TaperUI's elements helper module
    local taperImport = getgenv().taperImport or function(path)
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/GamebP/TaperUI/main/" .. path .. ".lua"))()
    end
    local elements = taperImport("helper/elements")

    -- 2. Populate the parent scroll container with interactive elements
    elements:Label("🔥 Game Exploits", parent)
    
    elements:Toggle("Enable Auto Clicker", parent, false, function(state)
        print("Toggled clicker state to: ", state)
    end)
end
```

#### Callback Parameters Explained:
* **`parent`** (`Instance`): The scrolling content frame assigned to your game's tab. This is the `parent` container you must pass into all visual element functions.
* **`config`** (`table`): A JSON-decoded Lua table containing local configurations saved under `"TaperUI/Config.json"`.
* **`Window`** (`table`): The global framework Window object, allowing access to ScreenGuis, custom UI variables, or cleanup routines.
* **`GameTab`** (`table`): The dynamic Tab object created specifically for this game.

---

### 2. Standalone Mode (Independent Scripts)
If your game script is flagged as `"isStandalone": true` inside `data.json`, the core loader bypasses the Hub UI entirely and executes your script independently. In this mode, you do **not** use a function wrapper; instead, you bypass the loader and instantiate your own Window object:

```lua
-- 1. Bypass the automatic Multi-Game loader wrapper
getgenv().TaperDev = true

-- 2. Load the TaperUI core library
local TaperUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/GamebP/TaperUI/main/UI.lua"))()

-- 3. Create a dedicated Window and Tab hierarchy
local Window = TaperUI:CreateWindow({
    Name = "My Game",
    LoadingTitle = "My Cheat Client",
    LoadingSubtitle = "Standalone Script Edition",
    LoadingVersion = "v1.0"
})

local FarmTab = Window:CreateTab("Autofarm", TaperAssets.list)
Window:CreateSettingsTab()

-- 4. Standalone scripts have independent elements (they don't use 'helper/elements')
FarmTab:CreateLabel("🚜 Automation Settings")
FarmTab:CreateToggle("Enable Farm Loop", false, function(state)
    print("Farm Loop: ", state)
end)
```

---

## 🛠 Visual Elements API (`elements.lua`)

To create menus inside **Hub Mode** scripts, import the elements module at the top of your returning function wrapper:
```lua
local taperImport = getgenv().taperImport
local elements = taperImport("helper/elements")
```

### 1. `elements:Label(str, parent)`
Creates a non-interactive, flat dark header card used to divide and organize categories of cheat controls.
* **Parameters:**
  * `str` (`string`): The text to display on the label card.
  * `parent` (`Instance`): The container frame (typically `parent`).
* **Example:**
  ```lua
  elements:Label("👑 Player Modifications", parent)
  ```

---

### 2. `elements:Button(str, parent, cb)`
Creates a clean, clickable text button with left-aligned text, a faint element tag, hover animations, and press/hold color transitions.
* **Parameters:**
  * `str` (`string`): The text to display on the button face.
  * `parent` (`Instance`): The container frame.
  * `cb` (`function`): The callback executed when the button is clicked.
* **Example:**
  ```lua
  elements:Button("Teleport to Spawner", parent, function()
      print("Player teleported!")
  end)
  ```

---

### 3. `elements:Toggle(str, parent, def, cb)`
Creates a True/False state switch. Visually changes colors between green (enabled) and red (disabled) when clicked.
* **Parameters:**
  * `str` (`string`): The label text next to the toggle switch.
  * `parent` (`Instance`): The container frame.
  * `def` (`boolean`): The default state (`true` for enabled, `false` for disabled).
  * `cb` (`function`): Callback receiving the new boolean state `function(boolean)`.
* **Example:**
  ```lua
  elements:Toggle("Auto Clicker", parent, false, function(state)
      getgenv().AutoFarm = state
      if state then
          task.spawn(function()
              while getgenv().AutoFarm do
                  print("Clicking...")
                  task.wait(0.1)
              end
          end)
      end
  end)
  ```

---

### 4. `elements:Textbox(str, parent, def, cb)`
Creates a textbox. Excellent for handling custom values such as configuration settings, player walkspeeds, or jump heights.
* **Parameters:**
  * `str` (`string`): The label text next to the input box.
  * `parent` (`Instance`): The container frame.
  * `def` (`string`): The default placeholder/textbox value.
  * `cb` (`function`): Callback executed when focus is lost, receiving the string `function(text)`.
* **Example:**
  ```lua
  elements:Textbox("Walkspeed Multiplier", parent, "16", function(text)
      local numValue = tonumber(text)
      if numValue then
          game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = numValue
      end
  end)
  ```

---

### 5. `elements:Keybind(str, parent, def, cb)`
Creates an interactive hotkey selector. Users can click on it and type any keyboard key to change binds dynamically.
* **Parameters:**
  * `str` (`string`): The text next to the keybind card.
  * `parent` (`Instance`): The container frame.
  * `def` (`string`): The default starting keybind (e.g., `"H"` or `"F"`).
  * `cb` (`function`): Callback executed when changed, receiving the key name `function(keyName)`.
* **Example:**
  ```lua
  elements:Keybind("Teleport Hotkey", parent, "H", function(keyName)
      print("Hotkey changed to: " .. tostring(keyName))
  end)
  ```

---

### 6. `elements:Dropdown(str, parent, options, def, cb)`
Creates a dynamic dropdown selection menu. When clicked, it expands its frame vertically, allows selecting an option, updates the display labels, and collapses cleanly.
* **Parameters:**
  * `str` (`string`): The text next to the dropdown card.
  * `parent` (`Instance`): The container frame.
  * `options` (`table`): An array of strings representing the selectable choices (e.g., `{"Hold", "Toggle"}`).
  * `def` (`string`): The default option selected on start (e.g., `"Hold"`).
  * `cb` (`function`): Callback executed when changed, receiving the selected string `function(selectedOption)`.
* **Example:**
  ```lua
  elements:Dropdown("Trigger Mode", parent, {"Hold", "Toggle"}, "Hold", function(selectedOption)
      print("Selected trigger mode: " .. tostring(selectedOption))
  end)
  ```

---

### 7. `elements:Slider(str, parent, min, max, def, decimals, cb)`
Creates an interactive horizontal dragging slider element.
* **Parameters:**
  * `str` (`string`): The text display on the left side of the slider card.
  * `parent` (`Instance`): The container frame (typically `parent`).
  * `min` (`number`): The minimum allowed value.
  * `max` (`number`): The maximum allowed value.
  * `def` (`number`): The default starting value.
  * `decimals` (`number`): Number of decimal places to process (e.g., `0` for whole integer values, `1` or `2` for floating-point values).
  * `cb` (`function`): Callback executed when modified, returning the current calculated slider number `function(value)`.
* **Example:**
  ```lua
  elements:Slider("Gravity", parent, 0, 196.2, 196.2, 1, function(val)
      workspace.Gravity = val
  end)
  ```

---

### 8. `elements:Paragraph(title, desc, parent)`
Creates an informational card containing a bold, clean title and a wrapping, multi-line paragraph block. The element automatically adjusts its height dynamically to fit any string length without clipping.
* **Parameters:**
  * `title` (`string`): The header text for the information card.
  * `desc` (`string`): The detailed, wrapping description body text.
  * `parent` (`Instance`): The container frame.
* **Example:**
  ```lua
  elements:Paragraph("💡 Dynamic Autofarm Info", "Please select your target zone inside the selector below.", parent)
  ```

---

### 9. `elements:DualButton(str1, cb1, str2, cb2, parent)`
Creates two equal half-width interactive buttons arranged horizontally on a single row. This element reuses the standard button logic, ensuring that full hover effects, sound cues, and press animations are preserved while optimizing visual workspace.
* **Parameters:**
  * `str1` (`string`): Display label of the left button.
  * `cb1` (`function`): Callback trigger for the left button click.
  * `str2` (`string`): Display label of the right button.
  * `cb2` (`function`): Callback trigger for the right button click.
  * `parent` (`Instance`): The container frame.
* **Example:**
  ```lua
  elements:DualButton("Claim Cash", function()
      print("Cash claimed!")
  end, "Claim Weapon", function()
      print("Weapon added!")
  end, parent)
  ```

---

### 10. `elements:Selector(str, parent, options, def, cb)`
Creates a horizontal segmented tab control panel containing multiple select choices styled side-by-side. It features snappy transition animations and dynamically manages uniform item sizes relative to the options list size. Excellent alternative to dropdowns for simple option lists of 2–4 choices.
* **Parameters:**
  * `str` (`string`): The label text on the left side of the row.
  * `parent` (`Instance`): The container frame.
  * `options` (`table`): An array of strings representing the select choices (e.g. `{"1x", "3x", "8x"}`).
  * `def` (`string`): The default starting select choice.
  * `cb` (`function`): Callback executed when modified, receiving the select choice string `function(selectedOption)`.
* **Example:**
  ```lua
  elements:Selector("Hatch Quantity", parent, {"1x", "3x", "8x"}, "1x", function(choice)
      print("Hatch mode updated to: " .. choice)
  end)
  ```

---

### 11. `elements:Spacer(height, parent)`
Creates a non-interactive, transparent padding layout block to adjust spacing margins and clean up vertical UI layouts dynamically.
* **Parameters:**
  * `height` (`number`): The vertical size of the padding space in pixels.
  * `parent` (`Instance`): The container frame.
* **Example:**
  ```lua
  elements:Spacer(15, parent)
  ```