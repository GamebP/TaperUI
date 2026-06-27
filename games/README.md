# TaperUI Developer API Reference

This document provides a comprehensive API reference for all visual creation functions available in TaperUI's elements module (`helper/elements.lua`) that are designed to populate your custom game scripts (`games/<game_id>.lua`).

---

## 🛠 Visual Elements API (`elements.lua`)

To use any of these elements inside a game script, ensure you have imported the elements helper at the top of your file first:
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