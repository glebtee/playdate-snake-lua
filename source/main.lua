import "CoreLibs/graphics"

local pd <const> = playdate
local gfx <const> = pd.graphics
local snd <const> = pd.sound

local SCREEN_WIDTH <const> = 400
local SCREEN_HEIGHT <const> = 240

local CELL_SIZE <const> = 15
local FIELD_TOP <const> = 20
local FIELD_LEFT <const> = 0
local COLS <const> = SCREEN_WIDTH // CELL_SIZE
local ROWS <const> = (SCREEN_HEIGHT - FIELD_TOP) // CELL_SIZE

local DIR_UP <const> = 1
local DIR_RIGHT <const> = 2
local DIR_DOWN <const> = 3
local DIR_LEFT <const> = 4

local directionVectors = {
    [DIR_UP] = { x = 0, y = -1 },
    [DIR_RIGHT] = { x = 1, y = 0 },
    [DIR_DOWN] = { x = 0, y = 1 },
    [DIR_LEFT] = { x = -1, y = 0 }
}

local gameState = "title"
local snake = {}
local direction = DIR_RIGHT
local nextDirection = DIR_RIGHT
local food = { x = 1, y = 1 }
local score = 0
local frameCounter = 0

local speedOptions = {
    { label = "Slow", frames = 7, progressive = false },
    { label = "Normal", frames = 6, progressive = false },
    { label = "Fast", frames = 5, progressive = false },
    { label = "Challenge", frames = 6, progressive = true }
}
local selectedSpeedIndex = 2
local moveEveryFrames = speedOptions[selectedSpeedIndex].frames

local moveSynth = snd.synth.new(snd.kWaveSquare)
moveSynth:setADSR(0, 0, 0.15, 0)
moveSynth:setVolume(0.16)

local eatSynth = snd.synth.new(snd.kWaveSawtooth)
eatSynth:setADSR(0, 0.03, 0.25, 0.03)
eatSynth:setVolume(0.20)

local collisionSynth = snd.synth.new(snd.kWaveTriangle)
collisionSynth:setADSR(0, 0.04, 0.35, 0.06)
collisionSynth:setVolume(0.24)

local function isOpposite(a, b)
    return (a == DIR_UP and b == DIR_DOWN)
        or (a == DIR_DOWN and b == DIR_UP)
        or (a == DIR_LEFT and b == DIR_RIGHT)
        or (a == DIR_RIGHT and b == DIR_LEFT)
end

local function toPixelX(gridX)
    return FIELD_LEFT + (gridX - 1) * CELL_SIZE
end

local function toPixelY(gridY)
    return FIELD_TOP + (gridY - 1) * CELL_SIZE
end

local function spawnFood()
    if #snake >= COLS * ROWS then
        gameState = "won"
        return
    end

    while true do
        local candidateX = math.random(1, COLS)
        local candidateY = math.random(1, ROWS)
        local blocked = false

        for i = 1, #snake do
            if snake[i].x == candidateX and snake[i].y == candidateY then
                blocked = true
                break
            end
        end

        if not blocked then
            food.x = candidateX
            food.y = candidateY
            return
        end
    end
end

local function resetGame()
    local startX = COLS // 2
    local startY = ROWS // 2

    snake = {
        { x = startX, y = startY },
        { x = startX - 1, y = startY },
        { x = startX - 2, y = startY }
    }

    direction = DIR_RIGHT
    nextDirection = DIR_RIGHT
    score = 0
    frameCounter = 0
    moveEveryFrames = speedOptions[selectedSpeedIndex].frames
    gameState = "playing"
    spawnFood()
end

local function changeSelectedSpeed(delta)
    selectedSpeedIndex += delta
    if selectedSpeedIndex < 1 then
        selectedSpeedIndex = #speedOptions
    elseif selectedSpeedIndex > #speedOptions then
        selectedSpeedIndex = 1
    end
end

local function drawOptionsScreen()
    local panelW = 260
    local panelH = 140
    local panelX = (SCREEN_WIDTH - panelW) // 2
    local panelY = 50

    gfx.drawRoundRect(panelX, panelY, panelW, panelH, 8)
    gfx.drawTextAligned("OPTIONS", SCREEN_WIDTH // 2, panelY + 14, kTextAlignment.center)
    gfx.drawTextAligned("Select Speed", SCREEN_WIDTH // 2, panelY + 36, kTextAlignment.center)

    for i = 1, #speedOptions do
        local optionY = panelY + 52 + (i - 1) * 18
        local prefix = (i == selectedSpeedIndex) and "> " or "  "
        gfx.drawTextAligned(prefix .. speedOptions[i].label, SCREEN_WIDTH // 2, optionY, kTextAlignment.center)
    end

    gfx.drawTextAligned("A: Confirm  B: Back", SCREEN_WIDTH // 2, panelY + 118, kTextAlignment.center)
end

local function handleDirectionInput()
    if pd.buttonJustPressed(pd.kButtonUp) then
        nextDirection = DIR_UP
    elseif pd.buttonJustPressed(pd.kButtonRight) then
        nextDirection = DIR_RIGHT
    elseif pd.buttonJustPressed(pd.kButtonDown) then
        nextDirection = DIR_DOWN
    elseif pd.buttonJustPressed(pd.kButtonLeft) then
        nextDirection = DIR_LEFT
    end

    if isOpposite(direction, nextDirection) then
        nextDirection = direction
    end
end

local function moveSnake()
    direction = nextDirection

    local head = snake[1]
    local step = directionVectors[direction]
    local newHead = { x = head.x + step.x, y = head.y + step.y }

    if newHead.x < 1 or newHead.x > COLS or newHead.y < 1 or newHead.y > ROWS then
        collisionSynth:playNote(42, 0.1, 0.22)
        gameState = "gameover"
        return
    end

    local willGrow = (newHead.x == food.x and newHead.y == food.y)
    local collisionLength = willGrow and #snake or (#snake - 1)

    for i = 1, collisionLength do
        if snake[i].x == newHead.x and snake[i].y == newHead.y then
            collisionSynth:playNote(42, 0.1, 0.22)
            gameState = "gameover"
            return
        end
    end

    table.insert(snake, 1, newHead)
    moveSynth:playNote(72, 0.06, 0.08)

    if willGrow then
        score += 1
        eatSynth:playNote(86, 0.05, 0.14)
        if speedOptions[selectedSpeedIndex].progressive and score % 4 == 0 then
            moveEveryFrames = math.max(2, moveEveryFrames - 1)
        end
        spawnFood()
    else
        table.remove(snake)
    end
end

local function drawHeader()
    gfx.drawText("SNAKE LUA", 6, 2)
    gfx.drawTextAligned("Score: " .. score, SCREEN_WIDTH - 6, 2, kTextAlignment.right)
end

local function drawField()
    gfx.drawRect(FIELD_LEFT, FIELD_TOP, COLS * CELL_SIZE, ROWS * CELL_SIZE)

    for i = 1, #snake do
        local segment = snake[i]
        local px = toPixelX(segment.x)
        local py = toPixelY(segment.y)
        gfx.fillRect(px + 1, py + 1, CELL_SIZE - 2, CELL_SIZE - 2)
    end

    local foodX = toPixelX(food.x)
    local foodY = toPixelY(food.y)
    gfx.fillRect(foodX + 2, foodY + 2, CELL_SIZE - 4, CELL_SIZE - 4)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawPixel(foodX + (CELL_SIZE // 2), foodY + (CELL_SIZE // 2))
    gfx.setColor(gfx.kColorBlack)
end

local function drawCenterText(text)
    gfx.drawTextAligned(text, SCREEN_WIDTH // 2, 90, kTextAlignment.center)
end

local function drawBoldText(text, x, y)
    gfx.drawText(text, x - 1, y)
    gfx.drawText(text, x + 1, y)
    gfx.drawText(text, x, y - 1)
    gfx.drawText(text, x, y + 1)
    gfx.drawText(text, x, y)
end

pd.display.setRefreshRate(30)

function pd.update()
    gfx.clear(gfx.kColorWhite)

    if gameState == "title" then
        drawCenterText("SNAKE LUA")
        gfx.drawTextAligned("D-Pad: Move", SCREEN_WIDTH // 2, 116, kTextAlignment.center)
        gfx.drawTextAligned("A: Start", SCREEN_WIDTH // 2, 134, kTextAlignment.center)
        gfx.drawTextAligned("B: Options", SCREEN_WIDTH // 2, 152, kTextAlignment.center)
        gfx.drawTextAligned("Speed: " .. speedOptions[selectedSpeedIndex].label, SCREEN_WIDTH // 2, 170, kTextAlignment.center)
        if pd.buttonJustPressed(pd.kButtonA) then
            resetGame()
        elseif pd.buttonJustPressed(pd.kButtonB) then
            gameState = "options"
        end
        return
    end

    if gameState == "options" then
        if pd.buttonJustPressed(pd.kButtonUp) then
            changeSelectedSpeed(-1)
        elseif pd.buttonJustPressed(pd.kButtonDown) then
            changeSelectedSpeed(1)
        elseif pd.buttonJustPressed(pd.kButtonA) or pd.buttonJustPressed(pd.kButtonB) then
            gameState = "title"
        end

        drawOptionsScreen()
        return
    end

    if gameState == "playing" then
        handleDirectionInput()
        frameCounter += 1
        if frameCounter >= moveEveryFrames then
            frameCounter = 0
            moveSnake()
        end
    end

    drawHeader()
    drawField()

    if gameState == "gameover" then
        local panelW = 220
        local panelH = 70
        local panelX = (SCREEN_WIDTH - panelW) // 2
        local panelY = 76
        local gameOverText = "GAME OVER"
        local restartText = "A: Restart  B: Menu"
        local gameOverTextW = gfx.getTextSize(gameOverText)
        local restartTextW = gfx.getTextSize(restartText)
        local gameOverTextX = (SCREEN_WIDTH - gameOverTextW) // 2
        local restartTextX = (SCREEN_WIDTH - restartTextW) // 2
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRoundRect(panelX, panelY, panelW, panelH, 8)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        drawBoldText(gameOverText, gameOverTextX, panelY + 18)
        gfx.drawText(restartText, restartTextX, panelY + 42)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    elseif gameState == "won" then
        drawCenterText("YOU WIN")
        gfx.drawTextAligned("A: Restart", SCREEN_WIDTH // 2, 112, kTextAlignment.center)
    end

    if (gameState == "gameover" or gameState == "won") and pd.buttonJustPressed(pd.kButtonA) then
        resetGame()
    end

    if gameState == "gameover" and pd.buttonJustPressed(pd.kButtonB) then
        gameState = "title"
    end
end
