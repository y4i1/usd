local Destruct = {functions = {}}

local Vector2New, Cam, Mouse, client, find, Draw, Inset, players, RunService =
    Vector2.new,
    workspace.CurrentCamera,
    game.Players.LocalPlayer:GetMouse(),
    game.Players.LocalPlayer,
    table.find,
    Drawing.new,
    game:GetService("GuiService"):GetGuiInset().Y,
    game.Players, 
    game.RunService


local mf, rnew = math.floor, Random.new

local Targetting
local lockedCamTo

local Circle = Draw("Circle")
Circle.Thickness = 1
Circle.Transparency = 0.7
Circle.Color = Color3.new(1,1,1)

Destruct.functions.update_FOVs = function ()
    if not (Circle) then
        return Circle
    end
    Circle.Radius =  getgenv().Destruct.SilentAim.FOVData.Radius * 3
    Circle.Visible = getgenv().Destruct.SilentAim.FOVData.Visibility
    Circle.Filled = getgenv().Destruct.SilentAim.FOVData.Filled
    Circle.Position = Vector2New(Mouse.X, Mouse.Y + (Inset))
    return Circle
end

Destruct.functions.onKeyPress = function(inputObject)
    if inputObject.KeyCode == Enum.KeyCode[getgenv().Destruct.SilentAim.Key:upper()] then
        getgenv().Destruct.SilentAim.Enabled = not getgenv().Destruct.SilentAim.Enabled
    end

    if inputObject.KeyCode == Enum.KeyCode[getgenv().Destruct.Tracing.Key:upper()] then
        if not lockedCamTo then
            lockedCamTo = true
            lockedCamTo = Destruct.functions.returnClosestPlayer()
        else
            lockedCamTo = false
            lockedCamTo = nil
        end
    end
end

game:GetService("UserInputService").InputBegan:Connect(Destruct.functions.onKeyPress)

Destruct.functions.wallCheck = function(direction, ignoreList)
    if not getgenv().Destruct.SilentAim.AimingData.CheckWalls then
        return true
    end

    local ray = Ray.new(Cam.CFrame.p, direction - Cam.CFrame.p)
    local part, _, _ = game:GetService("Workspace"):FindPartOnRayWithIgnoreList(ray, ignoreList)

    return not part
end

Destruct.functions.pointDistance = function(part)
    local OnScreen = Cam.WorldToScreenPoint(Cam, part.Position)
    if OnScreen then
        return (Vector2New(OnScreen.X, OnScreen.Y) - Vector2New(Mouse.X, Mouse.Y)).Magnitude
    end
end

Destruct.functions.returnClosestPart = function(Character)
    local data = {
        dist = math.huge,
        part = nil,
        classes = {"Part", "BasePart", "MeshPart"}
    }
    if not (Character and Character:IsA("Model")) then
        return data.part
    end
    local children = Character:GetChildren()
    for _, child in pairs(children) do
        if table.find(data.classes, child.ClassName) then
            local dist = Destruct.functions.pointDistance(child)
            if dist < data.dist then
                data.part = child
                data.dist = dist
            end
        end
    end
    return data.part
end



Destruct.functions.returnClosestPlayer = function (amount)
    local closestDistance = 1/0
    local closestPlayer = nil
    amount = amount or nil

    for _, player in pairs(players:GetPlayers()) do
        if (player.Character and player ~= client) then
            local charPosition = player.Character:GetBoundingBox().Position
            if charPosition then
                local viewPoint = Cam.WorldToViewportPoint(Cam, charPosition)
        
                if viewPoint then

                    local Magnitude = (Vector2New(Mouse.X, Mouse.Y) - Vector2New(viewPoint.X, viewPoint.Y)).Magnitude

                    if Circle.Radius > Magnitude and Magnitude < closestDistance and
                    Destruct.functions.wallCheck(player.Character.Head.Position,{client, player.Character}) 
                    then
                        closestDistance = Magnitude
                        closestPlayer = player
                    end
                end
            end
        end
    end

    local Calc = mf(rnew().NextNumber(rnew(), 0, 1) * 100) / 100
    local Use = getgenv().Destruct.SilentAim.ChanceData.UseChance
    if Use and Calc <= mf(amount) / 100 then
        return Calc and closestPlayer
    else
        return closestPlayer
    end
end

Destruct.functions.returnClosestPoint = function (player)

end

Destruct.functions.setAimingType = function (player, type)
    local previousSilentAimPart = getgenv().Destruct.SilentAim.AimPart
    local previousTracingPart = getgenv().Destruct.Tracing.AimPart
    if type == "Closest Part" then
        getgenv().Destruct.SilentAim.AimPart = tostring(Destruct.functions.returnClosestPart(player.Character))
        getgenv().Destruct.Tracing.AimPart = tostring(Destruct.functions.returnClosestPart(player.Character))
    elseif type == "Closest Point" then
        Destruct.functions.returnClosestPoint(player.Character)
    elseif type == "Default" then
        getgenv().Destruct.SilentAim.AimPart = previousSilentAimPart
        getgenv().Destruct.Tracing.AimPart = previousTracingPart
    else
        getgenv().Destruct.SilentAim.AimPart = previousSilentAimPart
        getgenv().Destruct.Tracing.AimPart = previousTracingPart
    end
end

Destruct.functions.aimingCheck = function (player)
    if getgenv().Destruct.SilentAim.AimingData.CheckKnocked == true and player and player.Character then
        if player.Character.BodyEffects["K.O"].Value then
            return true
        end
    end
    if getgenv().Destruct.SilentAim.AimingData.CheckGrabbed == true and player and player.Character then
        if player.Character:FindFirstChild("GRABBING_CONSTRAINT") then
            return true
        end
    end
    return false
end

local lastRender = 0
local interpolation = 0.01

RunService.RenderStepped:Connect(function(delta)
    lastRender = lastRender + delta
    while lastRender > interpolation do
        lastRender = lastRender - interpolation
    end
    if getgenv().Destruct.Tracing.Enabled and lockedCamTo then
        local Vel =  lockedCamTo.Character[getgenv().Destruct.Tracing.AimPart].Velocity / getgenv().Destruct.Tracing.Prediction
        local Main = CFrame.new(Cam.CFrame.p, lockedCamTo.Character[getgenv().Destruct.Tracing.AimPart].Position + (Vel))
        Cam.CFrame = Cam.CFrame:Lerp(Main ,getgenv().Destruct.Tracing.TracingOptions.Smoothness , Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
        Destruct.functions.setAimingType(lockedCamTo, getgenv().Destruct.Tracing.TracingOptions.AimingType) 
    end
end)

task.spawn(function ()
    while task.wait() do
        if Targetting then
            Destruct.functions.setAimingType(Targetting, getgenv().Destruct.SilentAim.AimingType)
        end
        Destruct.functions.update_FOVs()
    end
end)

local __index
__index = hookmetamethod(game,"__index", function(Obj, Property)
    if Obj:IsA("Mouse") and Property == "Hit" then
        Targetting = Destruct.functions.returnClosestPlayer(getgenv().Destruct.SilentAim.ChanceData.Chance)
        if Targetting and getgenv().Destruct.SilentAim.Enabled and not Destruct.functions.aimingCheck(Targetting) then
            local currentVelocity = Targetting.Character[getgenv().Destruct.SilentAim.AimPart].Velocity * getgenv().Destruct.SilentAim.Prediction
            local predictedPosition = Targetting.Character[getgenv().Destruct.SilentAim.AimPart].CFrame + (currentVelocity)
            return predictedPosition
        end
    end
    return __index(Obj, Property)
end)
