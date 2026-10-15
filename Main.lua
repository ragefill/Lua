
-- RAGEFILL // FLIGHT CONTROL
-- For your own Roblox Studio experience
-- Place in StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local OLD = playerGui:FindFirstChild("RagefillFlight")
if OLD then OLD:Destroy() end

local C = {
    bg = Color3.fromRGB(12, 12, 16),
    panel = Color3.fromRGB(22, 22, 29),
    button = Color3.fromRGB(37, 37, 46),
    red = Color3.fromRGB(235, 42, 60),
    redDark = Color3.fromRGB(110, 23, 34),
    white = Color3.fromRGB(245, 245, 250),
    muted = Color3.fromRGB(145, 145, 160),
    green = Color3.fromRGB(42, 180, 105),
}

local MIN_SPEED, MAX_SPEED = 10, 150
local speed = 50
local mode = "NORMAL"
local acceleration = 5
local currentVelocity = Vector3.zero
local flying = false
local ascending, descending = false, false
local panelOpen = true
local minimized = false
local alive = true

local char, hum, root
local attachment, linearVelocity, align
local flightConn, charConn

local gui = Instance.new("ScreenGui")
gui.Name = "RagefillFlight"
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.Parent = playerGui

local function make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do obj[k] = v end
    obj.Parent = parent
    return obj
end

local function round(obj, radius)
    make("UICorner", {
        CornerRadius = UDim.new(0, radius)
    }, obj)
end

local function stroke(obj, color, transparency)
    make("UIStroke", {
        Color = color,
        Thickness = 1,
        Transparency = transparency or 0,
    }, obj)
end

local function label(parent, text, pos, size, textSize, color)
    return make("TextLabel", {
        Position = pos,
        Size = size,
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = color or C.white,
        Font = Enum.Font.GothamBold,
        TextSize = textSize or 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, parent)
end

local function button(parent, text, pos, size, color)
    local b = make("TextButton", {
        Position = pos,
        Size = size,
        BackgroundColor3 = color or C.button,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = C.white,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        AutoButtonColor = true,
    }, parent)
    round(b, 8)
    return b
end

-- Floating circular open/close button
local orb = make("TextButton", {
    Name = "FloatingButton",
    Size = UDim2.fromOffset(58, 58),
    Position = UDim2.new(0, 20, 0.55, -29),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
    Text = "RF",
    TextColor3 = C.white,
    Font = Enum.Font.GothamBlack,
    TextSize = 19,
    Active = true,
    ZIndex = 10,
}, gui)
round(orb, 100)
stroke(orb, C.red, 0)

local orbAccent = make("Frame", {
    Size = UDim2.new(0.45, 0, 0, 3),
    Position = UDim2.new(0.275, 0, 1, -7),
    BackgroundColor3 = C.red,
    BorderSizePixel = 0,
    ZIndex = 11,
}, orb)
round(orbAccent, 4)

-- Main panel
local panel = make("Frame", {
    Name = "MainPanel",
    Size = UDim2.fromOffset(310, 390),
    Position = UDim2.new(0, 92, 0.5, -195),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
    Visible = true,
    Active = true,
}, gui)
round(panel, 12)
stroke(panel, C.red, 0.25)

local header = make("Frame", {
    Size = UDim2.new(1, 0, 0, 58),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
    Active = true,
}, panel)
round(header, 12)

label(header, "RAGEFILL", UDim2.fromOffset(15, 7),
    UDim2.new(1, -100, 0, 24), 17, C.white)

label(header, "FLIGHT CONTROL  /  V2",
    UDim2.fromOffset(16, 32),
    UDim2.new(1, -100, 0, 15), 9, C.muted)

local minimize = button(header, "−",
    UDim2.new(1, -66, 0, 13),
    UDim2.fromOffset(25, 30), C.button)

local close = button(header, "×",
    UDim2.new(1, -35, 0, 13),
    UDim2.fromOffset(25, 30), C.red)

local body = make("Frame", {
    Position = UDim2.fromOffset(14, 68),
    Size = UDim2.new(1, -28, 1, -80),
    BackgroundTransparency = 1,
}, panel)

local status = label(body, "●  FLIGHT DISABLED",
    UDim2.fromOffset(0, 0),
    UDim2.new(1, 0, 0, 20), 11, C.muted)

local toggle = button(body, "ENABLE FLIGHT",
    UDim2.fromOffset(0, 28),
    UDim2.new(1, 0, 0, 42), C.redDark)

label(body, "MOVEMENT SPEED",
    UDim2.fromOffset(0, 83),
    UDim2.new(1, 0, 0, 17), 10, C.muted)

local minus = button(body, "−",
    UDim2.fromOffset(0, 105),
    UDim2.fromOffset(42, 34))

local speedBox = make("TextBox", {
    Position = UDim2.fromOffset(49, 105),
    Size = UDim2.new(1, -98, 0, 34),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
    Text = tostring(speed),
    TextColor3 = C.white,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    ClearTextOnFocus = false,
}, body)
round(speedBox, 8)

local plus = button(body, "+",
    UDim2.new(1, -42, 0, 105),
    UDim2.fromOffset(42, 34))

-- Speed slider
local sliderTrack = make("Frame", {
    Position = UDim2.fromOffset(0, 151),
    Size = UDim2.new(1, 0, 0, 8),
    BackgroundColor3 = C.button,
    BorderSizePixel = 0,
    Active = true,
}, body)
round(sliderTrack, 6)

local sliderFill = make("Frame", {
    Size = UDim2.new((speed - MIN_SPEED) / (MAX_SPEED - MIN_SPEED), 0, 1, 0),
    BackgroundColor3 = C.red,
    BorderSizePixel = 0,
}, sliderTrack)
round(sliderFill, 6)

local sliderKnob = make("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new((speed - MIN_SPEED) / (MAX_SPEED - MIN_SPEED), 0, 0.5, 0),
    Size = UDim2.fromOffset(14, 14),
    BackgroundColor3 = C.white,
    BorderSizePixel = 0,
}, sliderTrack)
round(sliderKnob, 100)

label(body, "FLIGHT MODE",
    UDim2.fromOffset(0, 172),
    UDim2.new(1, 0, 0, 18), 10, C.muted)

local normal = button(body, "NORMAL",
    UDim2.fromOffset(0, 194),
    UDim2.new(0.5, -5, 0, 32), C.redDark)

local fast = button(body, "FAST",
    UDim2.new(0.5, 5, 0, 194),
    UDim2.new(0.5, -5, 0, 32), C.button)

local up = button(body, "▲  ASCEND",
    UDim2.fromOffset(0, 237),
    UDim2.new(0.5, -5, 0, 40))

local down = button(body, "▼  DESCEND",
    UDim2.new(0.5, 5, 0, 237),
    UDim2.new(0.5, -5, 0, 40))

label(body, "PC: F = TOGGLE  |  SPACE = UP  |  SHIFT = DOWN",
    UDim2.fromOffset(0, 287),
    UDim2.new(1, 0, 0, 18), 8, C.muted)

local function setSpeed(n)
    n = tonumber(n)
    if n and n == n then
        speed = math.clamp(math.floor(n), MIN_SPEED, MAX_SPEED)
    end
    speedBox.Text = tostring(speed)
    local fraction = (speed - MIN_SPEED) / (MAX_SPEED - MIN_SPEED)
    sliderFill.Size = UDim2.new(fraction, 0, 1, 0)
    sliderKnob.Position = UDim2.new(fraction, 0, 0.5, 0)
end

local function updateMode(newMode)
    mode = newMode
    normal.BackgroundColor3 = mode == "NORMAL" and C.redDark or C.button
    fast.BackgroundColor3 = mode == "FAST" and C.redDark or C.button
end

local function stopFlight()
    flying = false
    ascending = false
    descending = false
    currentVelocity = Vector3.zero

    if flightConn then
        flightConn:Disconnect()
        flightConn = nil
    end

    if align then align:Destroy(); align = nil end
    if linearVelocity then linearVelocity:Destroy(); linearVelocity = nil end
    if attachment then attachment:Destroy(); attachment = nil end

    if hum and hum.Parent then
        hum.PlatformStand = false
        hum.AutoRotate = true
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end

    toggle.Text = "ENABLE FLIGHT"
    toggle.BackgroundColor3 = C.redDark
    status.Text = "●  FLIGHT DISABLED"
    status.TextColor3 = C.muted
end

local function startFlight()
    char = player.Character
    hum = char and char:FindFirstChildOfClass("Humanoid")
    root = char and char:FindFirstChild("HumanoidRootPart")

    if not hum or not root or hum.Health <= 0 then
        status.Text = "●  CHARACTER NOT READY"
        return
    end

    stopFlight()

    attachment = Instance.new("Attachment")
    attachment.Name = "RagefillFlightAttachment"
    attachment.Parent = root

    linearVelocity = Instance.new("LinearVelocity")
    linearVelocity.Attachment0 = attachment
    linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
    linearVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    linearVelocity.MaxForce = 100000
    linearVelocity.VectorVelocity = Vector3.zero
    linearVelocity.Parent = root

    align = Instance.new("AlignOrientation")
    align.Mode = Enum.OrientationAlignmentMode.OneAttachment
    align.Attachment0 = attachment
    align.MaxTorque = 100000
    align.Responsiveness = 18
    align.Parent = root

    hum.PlatformStand = true
    hum.AutoRotate = false
    flying = true

    toggle.Text = "DISABLE FLIGHT"
    toggle.BackgroundColor3 = C.green
    status.Text = "●  FLIGHT ACTIVE"
    status.TextColor3 = C.green

    flightConn = RunService.Heartbeat:Connect(function(dt)
        if not flying or not root or not root.Parent or not hum or hum.Health <= 0 then
            stopFlight()
            return
        end

        local camera = workspace.CurrentCamera
        if not camera then return end

        local look = camera.CFrame.LookVector
        local right = camera.CFrame.RightVector

        local forward = Vector3.new(look.X, 0, look.Z)
        local sideways = Vector3.new(right.X, 0, right.Z)

        if forward.Magnitude > 0.001 then forward = forward.Unit end
        if sideways.Magnitude > 0.001 then sideways = sideways.Unit end

        local move = hum.MoveDirection
        local direction = forward * (-move.Z) + sideways * move.X

        local vertical = 0
        if ascending or UIS:IsKeyDown(Enum.KeyCode.Space) then
            vertical += 1
        end
        if descending or UIS:IsKeyDown(Enum.KeyCode.LeftShift)
            or UIS:IsKeyDown(Enum.KeyCode.Q) then
            vertical -= 1
        end

        direction += Vector3.new(0, vertical, 0)
        if direction.Magnitude > 1 then direction = direction.Unit end

        local targetSpeed = speed * (mode == "FAST" and 1.75 or 1)
        local targetVelocity = direction * targetSpeed
        local alpha = 1 - math.exp(-acceleration * dt)

        currentVelocity = currentVelocity:Lerp(targetVelocity, alpha)
        linearVelocity.VectorVelocity = currentVelocity

        local facing = Vector3.new(look.X, 0, look.Z)
        if facing.Magnitude > 0.001 then
            align.CFrame = CFrame.lookAt(
                root.Position,
                root.Position + facing.Unit
            )
        end
    end)
end

local function toggleFlight()
    if flying then stopFlight() else startFlight() end
end

toggle.Activated:Connect(toggleFlight)
minus.Activated:Connect(function() setSpeed(speed - 10) end)
plus.Activated:Connect(function() setSpeed(speed + 10) end)
speedBox.FocusLost:Connect(function() setSpeed(speedBox.Text) end)

-- Drag slider with mouse or touch.
local sliderDragging = false

local function updateSlider(input)
    local fraction = math.clamp(
        (input.Position.X - sliderTrack.AbsolutePosition.X) /
        sliderTrack.AbsoluteSize.X, 0, 1
    )
    setSpeed(MIN_SPEED + fraction * (MAX_SPEED - MIN_SPEED))
end

sliderTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = true
        updateSlider(input)
    end
end)

UIS.InputChanged:Connect(function(input)
    if sliderDragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        updateSlider(input)
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = false
    end
end)

normal.Activated:Connect(function() updateMode("NORMAL") end)
fast.Activated:Connect(function() updateMode("FAST") end)

local function hold(buttonObj, setter)
    buttonObj.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
            setter(true)
        end
    end)

    buttonObj.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
            setter(false)
        end
    end)
end

hold(up, function(v) ascending = v end)
hold(down, function(v) descending = v end)

-- Drag the floating button.
local function makeDraggable(object)
    local dragging, start, initial
    object.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            start = input.Position
            initial = object.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseMovement
        ) then
            local delta = input.Position - start
            object.Position = UDim2.new(
                initial.X.Scale, initial.X.Offset + delta.X,
                initial.Y.Scale, initial.Y.Offset + delta.Y
            )
        end
    end)
end

makeDraggable(orb)
makeDraggable(header)

orb.Activated:Connect(function()
    panelOpen = not panelOpen
    panel.Visible = panelOpen
end)

close.Activated:Connect(function()
    panelOpen = false
    panel.Visible = false
end)

minimize.Activated:Connect(function()
    minimized = not minimized
    body.Visible = not minimized
    panel.Size = minimized
        and UDim2.fromOffset(310, 58)
        or UDim2.fromOffset(310, 390)
    minimize.Text = minimized and "+" or "−"
end)

UIS.InputBegan:Connect(function(input, processed)
    if processed or not alive then return end
    if input.KeyCode == Enum.KeyCode.F then
        toggleFlight()
    end
end)

charConn = player.CharacterAdded:Connect(function(newChar)
    stopFlight()
    task.spawn(function()
        char = newChar
        hum = newChar:WaitForChild("Humanoid")
        root = newChar:WaitForChild("HumanoidRootPart")
    end)
end)

gui.Destroying:Connect(function()
    alive = false
    stopFlight()
    if charConn then charConn:Disconnect() end
end)

setSpeed(speed)
updateMode("NORMAL")
