
export type Keybind = {
    DisplayName: string;
    Key: Enum.KeyCode;
}

-- index is action name to be used in code
local DefaultKeybinds: {[string]: Keybind} = {
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
    Run = {
        DisplayName = "Run (Hold)";
        Key = Enum.KeyCode.LeftShift;
    };
	-- Equipment
    Use = {
        DisplayName = "Use Equipment/Primary Fire";
        Key = Enum.UserInputType.MouseButton1;
    };
    AltUse = {
        DisplayName = "Alternate Use/Aim (Hold)";
        Key = Enum.KeyCode.Q;
    };
    Reload = {
        DisplayName = "Reload";
        Key = Enum.KeyCode.R;
    };
    -- Drop = {
    --     DisplayName = "Drop Item";
    --     Key = Enum.KeyCode.G;
    -- };
    -- Primary = {
    --     DisplayName = "Primary Slot";
    --     Key = Enum.KeyCode.One;
    -- };
    -- Secondary = {
    --     DisplayName = "Secondary Slot";
    --     Key = Enum.KeyCode.Two;
    -- };
    -- Tertiary = {
    --     DisplayName = "Tertiary Slot";
    --     Key = Enum.KeyCode.Three;
    -- };
    ChangeCameraMode = {
        DisplayName = "Change Camera Mode";
        Key = Enum.KeyCode.V;
    }
}

return DefaultKeybinds
