
export type Keybind = {
    DisplayName: string;
    Key: Enum.KeyCode;
}

-- index is action name to be used in code
local DefaultKeybinds: {Enum.KeyCode} = {
    -- General
    -- Interact = {
    --     DisplayName = "Interact";
    --     Key = Enum.KeyCode.E;
    -- };
    -- Movement
    -- TODO: figure out how to override roblox controls
    -- Forward = {
    --     DisplayName = "Move Forward";
    --     Key = Enum.KeyCode.W;
    -- };
    -- Backward = {
    --     DisplayName = "Move Backward";
    --     Key = Enum.KeyCode.S;
    -- };
    -- Left = {
    --     DisplayName = "Move Left";
    --     Key = Enum.KeyCode.A;
    -- };
	-- Equipment
    Use = {
        DisplayName = "Use Equipment/Primary Fire";
        Key = Enum.UserInputType.MouseButton1;
    };
    AlternateUse = {
        DisplayName = "Alternate Use/Aim (Hold)";
        Key = Enum.UserInputType.MouseButton2;
    };
    Drop = {
        DisplayName = "Drop Item";
        Key = Enum.KeyCode.G;
    };
    Primary = {
        DisplayName = "Primary Slot";
        Key = Enum.KeyCode.One;
    };
    Secondary = {
        DisplayName = "Secondary Slot";
        Key = Enum.KeyCode.Two;
    };
    Tertiary = {
        DisplayName = "Tertiary Slot";
        Key = Enum.KeyCode.Three;
    };
}

return DefaultKeybinds
