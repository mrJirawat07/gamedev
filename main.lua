-- Solar System Explorer & Quiz App 🌌🚀
-- Developed for Solar2D (Corona SDK)
-- Fetching all assets dynamically from: https://raw.githubusercontent.com/mrJirawat07/gamedev/main/nasa/

math.randomseed(os.time())

-- ==========================================
-- 🪐 ฐานข้อมูลดวงดาวในระบบสุริยะ (13 ดวง)
-- ==========================================
local planetsData = {
    { id = 1, file = "Mercury.png", type = "Terrestrial Planet", distance = "0.39 AU", temp = "167°C", fact = "The smallest planet and closest to the Sun." },
    { id = 2, file = "Venus.png", type = "Terrestrial Planet", distance = "0.72 AU", temp = "464°C", fact = "The hottest planet in the Solar System." },
    { id = 3, file = "Earth.png", type = "Terrestrial Planet", distance = "1.00 AU", temp = "15°C", fact = "Our home, the only planet known to harbor life." },
    { id = 4, file = "Mars.png", type = "Terrestrial Planet", distance = "1.52 AU", temp = "-65°C", fact = "The Red Planet, home to Olympus Mons volcano." },
    { id = 5, file = "Jupiter.png", type = "Gas Giant", distance = "5.20 AU", temp = "-110°C", fact = "The largest planet, with a Great Red Spot storm." },
    { id = 6, file = "Saturn.png", type = "Gas Giant", distance = "9.58 AU", temp = "-140°C", fact = "Famous for its spectacular and complex ring system." },
    { id = 7, file = "Uranus.png", type = "Ice Giant", distance = "19.20 AU", temp = "-195°C", fact = "An ice giant that rotates on its side." },
    { id = 8, file = "Neptune.png", type = "Ice Giant", distance = "30.05 AU", temp = "-200°C", fact = "The most distant planet with supersonic winds." },
    { id = 9, file = "Pluto.png", type = "Dwarf Planet", distance = "39.48 AU", temp = "-225°C", fact = "Has a giant heart-shaped glacier named Tombaugh Regio." },
    { id = 10, file = "Ceres.png", type = "Dwarf Planet", distance = "2.77 AU", temp = "-105°C", fact = "The largest object in the asteroid belt." },
    { id = 11, file = "Eris.png", type = "Dwarf Planet", distance = "67.67 AU", temp = "-243°C", fact = "One of the most massive dwarf planets." },
    { id = 12, file = "Haumea.png", type = "Dwarf Planet", distance = "43.34 AU", temp = "-241°C", fact = "An extremely fast-spinning, football-shaped dwarf planet." },
    { id = 13, file = "Makemake.png", type = "Dwarf Planet", distance = "45.79 AU", temp = "-239°C", fact = "Covered in ultra-cold methane ice, discovered in 2005." },
}

-- Base URL สำหรับดึงข้อมูลออนไลน์ผ่าน GitHub Raw (โฟลเดอร์ nasa ตัวพิมพ์เล็กทั้งหมด)
local baseURL = "https://raw.githubusercontent.com/mrJirawat07/gamedev/main/nasa/"

-- ==========================================
-- 🎨 การจัดแจง Layer และ Display Groups
-- ==========================================
local backgroundGroup = display.newGroup()
local mainGroup = display.newGroup()
local menuGroup = display.newGroup()
local explorerGroup = display.newGroup()
local quizGroup = display.newGroup()

mainGroup:insert(menuGroup)
mainGroup:insert(explorerGroup)
mainGroup:insert(quizGroup)

-- ซ่อนกลุ่มที่จะไม่แสดงผลตอนเริ่ม
explorerGroup.isVisible = false
quizGroup.isVisible = false

-- ตัวแปรสถานะ
local currentImage = nil
local currentPlanetIndex = 1
local loadedNames = {} -- แคชชื่อดาวที่ดาวน์โหลดมาแล้ว

-- ==========================================
-- ⭐ 1. สร้างพื้นหลังอวกาศแบบมีชีวิต (Twinkling Cosmos)
-- ==========================================
local bg = display.newRect(backgroundGroup, display.contentCenterX, display.contentCenterY, display.contentWidth + 100, display.contentHeight + 100)
-- กำหนดเฉดสีกราเดียนต์ของอวกาศสุดหรู (Deep Navy -> Cosmic Black)
local bgGradient = {
    type = "gradient",
    color1 = { 0.02, 0.05, 0.12, 1 },
    color2 = { 0, 0, 0, 1 },
    direction = "down"
}
bg:setFillColor(bgGradient)

-- สร้างเม็ดทรายดาวระยิบระยับแบบสุ่มจำนวน 45 ดวง
local stars = {}
for i = 1, 45 do
    local star = display.newCircle(backgroundGroup, math.random(0, display.contentWidth), math.random(0, display.contentHeight), math.random(1, 2) / 2)
    star:setFillColor(1, 1, 1, math.random(2, 8) / 10)
    stars[i] = star
end

-- อนิเมชันทำให้ดวงดาวกะพริบอย่างนุ่มนวล
local function twinkleStars()
    for i = 1, #stars do
        transition.to(stars[i], {
            alpha = math.random(1, 10) / 10,
            time = math.random(1000, 3000),
            onComplete = function()
                if stars[i] then twinkleStars() end
            end
        })
    end
end
twinkleStars()

-- ==========================================
-- 🛠️ ฟังก์ชันช่วยเหลือ (Helper Functions)
-- ==========================================

-- อนิเมชันลอยเบาๆ ของตัวแปรดาวเคราะห์ (Floating Planet Animation)
local floatTransition = nil
local function startPlanetFloating(target)
    if not target then return end
    
    local function floatUp()
        if not target.y then return end
        floatTransition = transition.to(target, {
            y = display.contentCenterY - 70,
            time = 1800,
            transition = easing.inOutSine,
            onComplete = function()
                if not target.y then return end
                floatTransition = transition.to(target, {
                    y = display.contentCenterY - 40,
                    time = 1800,
                    transition = easing.inOutSine,
                    onComplete = floatUp
                })
            end
        })
    end
    floatUp()
end

-- หน้าจอกะพริบเอฟเฟกต์ (Green/Red Flash Feedback)
local function playFlashFeedback(color)
    local flash = display.newRect(mainGroup, display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight)
    flash:setFillColor(unpack(color))
    flash.alpha = 0
    transition.to(flash, {
        alpha = 0.4,
        time = 150,
        yoyo = true,
        iterations = 2,
        onComplete = function()
            display.remove(flash)
        end
    })
end

-- อนิเมชันปุ่มสปริงตัวแบบ Elastic เมื่อทัช (Button Feedback)
local function applyButtonAnimation(target, onPressComplete)
    transition.to(target, {
        scaleX = 0.9,
        scaleY = 0.9,
        time = 80,
        transition = easing.outQuad,
        onComplete = function()
            transition.to(target, {
                scaleX = 1.0,
                scaleY = 1.0,
                time = 120,
                transition = easing.outElastic,
                onComplete = onPressComplete
            })
        end
    })
end

-- ==========================================
-- 🚀 2. โหมดสำรวจสุริยะ (Solar Explorer)
-- ==========================================

-- ส่วนประกอบ UI ใน Explorer Group
local explorerCard, explorerNameText, explorerTypeVal, explorerDistanceVal, explorerFactVal
local planetContainerGroup = display.newGroup()
explorerGroup:insert(planetContainerGroup)

local function buildExplorerUI()
    -- การ์ดกระจกแก้วแสดงข้อมูล (Glassmorphism Info Card Container)
    explorerCard = display.newRoundedRect(explorerGroup, display.contentCenterX, display.contentHeight - 110, 280, 160, 12)
    explorerCard:setFillColor(0.05, 0.08, 0.18, 0.75)
    explorerCard.strokeWidth = 1.5
    explorerCard:setStrokeColor(0.3, 0.6, 1, 0.5)

    -- ชื่อดาวเคราะห์ (Glowing Blue)
    explorerNameText = display.newText(explorerGroup, "Loading...", display.contentCenterX, display.contentHeight - 165, native.systemFontBold, 24)
    explorerNameText:setFillColor(0.4, 0.8, 1)

    -- รายละเอียดดาวเคราะห์
    local typeLbl = display.newText(explorerGroup, "Type:", 40, display.contentHeight - 135, native.systemFontBold, 12)
    typeLbl.anchorX = 0
    typeLbl:setFillColor(0.7, 0.7, 0.8)

    explorerTypeVal = display.newText(explorerGroup, "", 80, display.contentHeight - 135, native.systemFont, 12)
    explorerTypeVal.anchorX = 0
    explorerTypeVal:setFillColor(1, 1, 1)

    local distLbl = display.newText(explorerGroup, "Distance:", 170, display.contentHeight - 135, native.systemFontBold, 12)
    distLbl.anchorX = 0
    distLbl:setFillColor(0.7, 0.7, 0.8)

    explorerDistanceVal = display.newText(explorerGroup, "", 235, display.contentHeight - 135, native.systemFont, 12)
    explorerDistanceVal.anchorX = 0
    explorerDistanceVal:setFillColor(1, 1, 1)

    -- คำอธิบาย Fun Fact ท้ายการ์ด
    explorerFactVal = display.newText({
        parent = explorerGroup,
        text = "",
        x = display.contentCenterX,
        y = display.contentHeight - 80,
        width = 250,
        height = 70,
        font = native.systemFont,
        fontSize = 11,
        align = "center"
    })
    explorerFactVal:setFillColor(0.9, 0.9, 0.9)

    -- ปุ่มลูกศรย้อนกลับ (Left Navigation)
    local leftArrowBg = display.newRoundedRect(explorerGroup, 30, display.contentCenterY - 50, 36, 36, 8)
    leftArrowBg:setFillColor(0.1, 0.15, 0.3, 0.6)
    leftArrowBg.strokeWidth = 1
    leftArrowBg:setStrokeColor(0.3, 0.6, 1, 0.3)
    local leftArrowText = display.newText(explorerGroup, "<", leftArrowBg.x, leftArrowBg.y - 2, native.systemFontBold, 18)
    leftArrowText:setFillColor(1, 1, 1)

    leftArrowBg:addEventListener("tap", function()
        applyButtonAnimation(leftArrowBg, function()
            currentPlanetIndex = currentPlanetIndex - 1
            if currentPlanetIndex < 1 then currentPlanetIndex = 13 end
            loadPlanetInExplorer(currentPlanetIndex)
        end)
    end)

    -- ปุ่มลูกศรไปข้างหน้า (Right Navigation)
    local rightArrowBg = display.newRoundedRect(explorerGroup, display.contentWidth - 30, display.contentCenterY - 50, 36, 36, 8)
    rightArrowBg:setFillColor(0.1, 0.15, 0.3, 0.6)
    rightArrowBg.strokeWidth = 1
    rightArrowBg:setStrokeColor(0.3, 0.6, 1, 0.3)
    local rightArrowText = display.newText(explorerGroup, ">", rightArrowBg.x, rightArrowBg.y - 2, native.systemFontBold, 18)
    rightArrowText:setFillColor(1, 1, 1)

    rightArrowBg:addEventListener("tap", function()
        applyButtonAnimation(rightArrowBg, function()
            currentPlanetIndex = currentPlanetIndex + 1
            if currentPlanetIndex > 13 then currentPlanetIndex = 1 end
            loadPlanetInExplorer(currentPlanetIndex)
        end)
    end)

    -- ปุ่มย้อนกลับเมนูหลัก (Back to Menu Button)
    local backBtn = display.newRoundedRect(explorerGroup, display.contentCenterX, 25, 110, 24, 6)
    backBtn:setFillColor(0.08, 0.12, 0.22, 0.8)
    backBtn.strokeWidth = 1
    backBtn:setStrokeColor(0.3, 0.6, 1, 0.4)
    local backBtnText = display.newText(explorerGroup, "⬅ Back to Menu", backBtn.x, backBtn.y, native.systemFont, 11)
    backBtnText:setFillColor(0.7, 0.8, 1)

    backBtn:addEventListener("tap", function()
        applyButtonAnimation(backBtn, function()
            -- ยกเลิกการเคลื่อนที่
            if floatTransition then transition.cancel(floatTransition) end
            -- เคลียร์รูป
            while planetContainerGroup.numChildren > 0 do
                local child = planetContainerGroup[1]
                child:removeSelf()
            end
            explorerGroup.isVisible = false
            menuGroup.isVisible = true
        end)
    end)
end

-- ดาวน์โหลดชื่อจากไฟล์ 1.txt - 13.txt ทางออนไลน์
local function downloadPlanetName(index, onComplete)
    if loadedNames[index] then
        onComplete(loadedNames[index])
        return
    end

    local url = baseURL .. index .. ".txt"
    network.request(url, "GET", function(event)
        if event.isError then
            onComplete("Unknown Planet")
        else
            -- ขจัดช่องว่าง หรืออักษรขึ้นบรรทัดใหม่
            local cleanName = event.response:gsub("[\r\n]", "")
            loadedNames[index] = cleanName
            onComplete(cleanName)
        end
    end)
end

-- โหลดดาวเคราะห์และเปลี่ยนแผงข้อมูล
function loadPlanetInExplorer(index)
    local data = planetsData[index]
    explorerNameText.text = "Fetching..."
    
    -- เคลียร์และหยุดอนิเมชันรูปภาพเดิม
    if floatTransition then transition.cancel(floatTransition) end
    while planetContainerGroup.numChildren > 0 do
        local child = planetContainerGroup[1]
        child:removeSelf()
    end

    -- ดาวน์โหลดชื่อจาก GitHub Raw
    downloadPlanetName(index, function(planetName)
        explorerNameText.text = planetName:upper()
    end)

    -- อัปเดตข้อมูล Text ในการ์ด
    explorerTypeVal.text = data.type
    explorerDistanceVal.text = data.distance
    explorerFactVal.text = data.fact

    -- ดาวน์โหลดและแสดงผลรูปภาพผ่าน GitHub Raw
    local imageURL = baseURL .. data.file
    display.loadRemoteImage(
        imageURL,
        "GET",
        function(event)
            if not event.isError and planetContainerGroup.y ~= nil then
                local img = event.target
                planetContainerGroup:insert(img)
                img.x = display.contentCenterX
                img.y = display.contentCenterY - 45
                img.width = 125
                img.height = 125
                img.alpha = 0
                transition.to(img, { alpha = 1, time = 400 })
                startPlanetFloating(img)
            end
        end,
        data.file,
        system.TemporaryDirectory
    )
end

buildExplorerUI()

-- ==========================================
-- 🧠 3. โหมดเกมตอบคำถาม (Space Quiz Quest)
-- ==========================================

-- ส่วนประกอบ UI ใน Quiz Group
local quizImageContainer = display.newGroup()
quizGroup:insert(quizImageContainer)

local quizScoreText, quizStreakText, timerBar, quizQuestionTitle
local choiceButtons = {}
local choiceTexts = {}

-- สถานะคะแนนของเกมนิ้วไว
local quizScore = 0
local quizStreak = 1
local correctIndex = 1
local currentQuizPlanetId = 1
local quizTimerRef = nil
local quizVisualTimerTrans = nil
local questionCount = 0

-- สุ่มตัวเลือกคำตอบ 4 ตัวเลือกแบบไม่ซ้ำ
local function generateQuizChoices(correctId)
    local choices = { correctId }
    local pool = {}
    
    for i = 1, 13 do
        if i ~= correctId then table.insert(pool, i) end
    end
    
    -- สุ่มเลือกคำตอบผิด 3 ข้อ
    for i = 1, 3 do
        local randIndex = math.random(1, #pool)
        table.insert(choices, pool[randIndex])
        table.remove(pool, randIndex)
    end
    
    -- ทำการสลับปุ่ม (Shuffle) เพื่อสุ่มปุ่มที่ถูกต้อง
    local shuffled = {}
    while #choices > 0 do
        local randIndex = math.random(1, #choices)
        table.insert(shuffled, choices[randIndex])
        table.remove(choices, randIndex)
    end
    
    return shuffled
end

local function showGameOverScreen()
    -- ยกเลิกกระบวนการของคำถามเดิม
    if quizTimerRef then timer.cancel(quizTimerRef); quizTimerRef = nil end
    if quizVisualTimerTrans then transition.cancel(quizVisualTimerTrans); quizVisualTimerTrans = nil end
    
    -- เคลียร์รูปหน้าตาทั้งหมด
    while quizImageContainer.numChildren > 0 do
        quizImageContainer[1]:removeSelf()
    end

    -- ซ่อนส่วนอื่นๆ ของโจทย์
    timerBar.isVisible = false
    quizQuestionTitle.isVisible = false
    for i=1, 4 do choiceButtons[i].isVisible = false end

    -- แผงสรุปแก้วใบใหญ่ (Game Over Panel)
    local gameOverCard = display.newRoundedRect(quizGroup, display.contentCenterX, display.contentCenterY, 260, 280, 15)
    gameOverCard:setFillColor(0.08, 0.05, 0.18, 0.85)
    gameOverCard.strokeWidth = 2
    gameOverCard:setStrokeColor(1, 0.4, 0.4, 0.6)

    local overText = display.newText(quizGroup, "MISSION OVER", display.contentCenterX, display.contentCenterY - 100, native.systemFontBold, 22)
    overText:setFillColor(1, 0.3, 0.3)

    -- การประเมินยศอิงตามผลคะแนน (Cosmic Ranks)
    local rankStr = "Space Cadet 🚀"
    local rankColor = { 0.7, 0.8, 1 }
    if quizScore >= 1000 then
        rankStr = "Cosmos Master 🌌"
        rankColor = { 1, 0.85, 0 }
    elseif quizScore >= 500 then
        rankStr = "Astro Commander 🛸"
        rankColor = { 0.3, 0.8, 1 }
    end

    local finalScoreVal = display.newText(quizGroup, "Final Score: " .. quizScore, display.contentCenterX, display.contentCenterY - 50, native.systemFontBold, 18)
    finalScoreVal:setFillColor(1, 1, 1)

    local rankTitle = display.newText(quizGroup, "Your Rank:", display.contentCenterX, display.contentCenterY - 15, native.systemFont, 11)
    rankTitle:setFillColor(0.6, 0.6, 0.7)
    
    local rankVal = display.newText(quizGroup, rankStr, display.contentCenterX, display.contentCenterY + 5, native.systemFontBold, 15)
    rankVal:setFillColor(unpack(rankColor))

    -- ปุ่มลุยอีกรอบ (Retry)
    local retryBtn = display.newRoundedRect(quizGroup, display.contentCenterX, display.contentCenterY + 60, 160, 36, 8)
    retryBtn:setFillColor(0.08, 0.4, 0.25, 0.8)
    retryBtn.strokeWidth = 1
    retryBtn:setStrokeColor(0.2, 0.8, 0.5, 0.6)
    local retryBtnText = display.newText(quizGroup, "TRY AGAIN", retryBtn.x, retryBtn.y, native.systemFontBold, 13)
    retryBtnText:setFillColor(1, 1, 1)

    -- ปุ่มกลับบ้าน (Exit)
    local exitBtn = display.newRoundedRect(quizGroup, display.contentCenterX, display.contentCenterY + 110, 160, 36, 8)
    exitBtn:setFillColor(0.2, 0.2, 0.25, 0.7)
    exitBtn.strokeWidth = 1
    exitBtn:setStrokeColor(1, 1, 1, 0.2)
    local exitBtnText = display.newText(quizGroup, "MAIN MENU", exitBtn.x, exitBtn.y, native.systemFontBold, 13)
    exitBtnText:setFillColor(0.9, 0.9, 0.9)

    -- สลัดออบเจกต์หน้าจอนี้ออกเพื่อสลายความยุ่งเหยิงเมื่อเล่นใหม่
    local function cleanupGameOver()
        display.remove(gameOverCard)
        display.remove(overText)
        display.remove(finalScoreVal)
        display.remove(rankTitle)
        display.remove(rankVal)
        display.remove(retryBtn)
        display.remove(retryBtnText)
        display.remove(exitBtn)
        display.remove(exitBtnText)
    end

    retryBtn:addEventListener("tap", function()
        applyButtonAnimation(retryBtn, function()
            cleanupGameOver()
            startNewQuizGame()
        end)
    end)

    exitBtn:addEventListener("tap", function()
        applyButtonAnimation(exitBtn, function()
            cleanupGameOver()
            quizGroup.isVisible = false
            menuGroup.isVisible = true
        end)
    end)
end

-- สร้างหน้าจอคำถามถัดไป
local function nextQuizQuestion()
    questionCount = questionCount + 1
    if questionCount > 10 then
        showGameOverScreen()
        return
    end

    -- ยกเลิกงานตัวจับเวลาเดิม
    if quizTimerRef then timer.cancel(quizTimerRef); quizTimerRef = nil end
    if quizVisualTimerTrans then transition.cancel(quizVisualTimerTrans); quizVisualTimerTrans = nil end

    -- ล้างรูปดาวเคราะห์รูปเก่า
    while quizImageContainer.numChildren > 0 do
        quizImageContainer[1]:removeSelf()
    end

    -- สุ่มดวงดาว
    currentQuizPlanetId = math.random(1, 13)
    local currentPlanetData = planetsData[currentQuizPlanetId]

    quizQuestionTitle.text = "Target Identified? [ " .. questionCount .. " / 10 ]"

    -- แสดงสถานะกำลังโหลด
    for i=1, 4 do
        choiceTexts[i].text = "Connecting..."
        choiceButtons[i].isVisible = false
    end

    -- ดึงตัวเลือกตอบ 4 ช้อยส์
    local buttonAssignments = generateQuizChoices(currentQuizPlanetId)

    -- ดึงชื่อมาแสดงตามลำดับปุ่ม
    local loadedChoiceCount = 0
    for i = 1, 4 do
        local choicePlanetId = buttonAssignments[i]
        downloadPlanetName(choicePlanetId, function(planetName)
            if quizGroup.isVisible then
                choiceTexts[i].text = planetName:upper()
                choiceButtons[i].isVisible = true
                
                -- ตรวจจับว่าเป็นปุ่มถูกหรือผิด
                choiceButtons[i].isCorrectAnswer = (choicePlanetId == currentQuizPlanetId)

                loadedChoiceCount = loadedChoiceCount + 1
                -- เมื่อช้อยส์พร้อม และรูปพร้อม เริ่มนับเวลา!
                if loadedChoiceCount == 4 then
                    -- สั่งเริ่มแท่งเวลานับถอยหลัง
                    timerBar.width = display.contentWidth - 40
                    timerBar.isVisible = true
                    
                    quizVisualTimerTrans = transition.to(timerBar, {
                        width = 0,
                        time = 12000
                    })

                    -- ทำงานเมื่องดตอบภายใน 12 วินาที
                    quizTimerRef = timer.performWithDelay(12000, function()
                        playFlashFeedback({ 0.8, 0.1, 0.1 }) -- แฟลชแดง
                        quizStreak = 1
                        quizStreakText.text = "Streak: 1x"
                        nextQuizQuestion()
                    end)
                end
            end
        end)
    end

    -- โหลดภาพดาวเคราะห์
    local imageURL = baseURL .. currentPlanetData.file
    display.loadRemoteImage(
        imageURL,
        "GET",
        function(event)
            if not event.isError and quizImageContainer.y ~= nil then
                local img = event.target
                quizImageContainer:insert(img)
                img.x = display.contentCenterX
                img.y = display.contentCenterY - 45
                img.width = 115
                img.height = 115
                img.alpha = 0
                transition.to(img, { alpha = 1, time = 300 })
                startPlanetFloating(img)
            end
        end,
        currentPlanetData.file,
        system.TemporaryDirectory
    )
end

function startNewQuizGame()
    quizScore = 0
    quizStreak = 1
    questionCount = 0

    quizScoreText.text = "SCORE: 0"
    quizStreakText.text = "Streak: 1x"

    timerBar.isVisible = true
    quizQuestionTitle.isVisible = true

    nextQuizQuestion()
end

-- สร้างอินเตอร์เฟส Quiz หน้าหลัก
local function buildQuizUI()
    -- คะแนน (Score Card)
    quizScoreText = display.newText(quizGroup, "SCORE: 0", 25, 25, native.systemFontBold, 14)
    quizScoreText.anchorX = 0
    quizScoreText:setFillColor(1, 1, 1)

    -- สถิติการคอมโบ (Streak Combo)
    quizStreakText = display.newText(quizGroup, "Streak: 1x", display.contentWidth - 25, 25, native.systemFontBold, 12)
    quizStreakText.anchorX = 1
    quizStreakText:setFillColor(0.3, 0.9, 0.5)

    -- โจทย์คำถาม
    quizQuestionTitle = display.newText(quizGroup, "Target Identified?", display.contentCenterX, 60, native.systemFontBold, 16)
    quizQuestionTitle:setFillColor(0.4, 0.8, 1)

    -- แถบเวลานีออนวิ่งถอยหลัง (Timer Bar)
    timerBar = display.newRect(quizGroup, display.contentCenterX, 85, display.contentWidth - 40, 6)
    timerBar:setFillColor(0.1, 0.6, 1) -- สีฟ้านีออนสว่าง

    -- ลิสต์ปุ่มช้อยส์คำตอบ 4 ช้อยส์ด้านล่าง
    local buttonStartY = display.contentHeight - 165
    local buttonSpacing = 38

    for i = 1, 4 do
        local btn = display.newRoundedRect(quizGroup, display.contentCenterX, buttonStartY + (i - 1) * buttonSpacing, 250, 32, 8)
        btn:setFillColor(0.08, 0.12, 0.22, 0.75)
        btn.strokeWidth = 1.5
        btn:setStrokeColor(0.3, 0.6, 1, 0.4)

        local txt = display.newText(quizGroup, "Loading...", btn.x, btn.y, native.systemFontBold, 12)
        txt:setFillColor(1, 1, 1)

        choiceButtons[i] = btn
        choiceTexts[i] = txt

        -- อีเวนต์จับการกดคำตอบ
        btn:addEventListener("tap", function()
            applyButtonAnimation(btn, function()
                if btn.isCorrectAnswer then
                    -- ตอบถูก! ได้คะแนนเพิ่มทวีคูณตามคอมโบ
                    quizScore = quizScore + (100 * quizStreak)
                    quizScoreText.text = "SCORE: " .. quizScore
                    
                    playFlashFeedback({ 0.1, 0.7, 0.3 }) -- กะพริบเขียว
                    
                    quizStreak = quizStreak + 1
                    quizStreakText.text = "Streak: " .. quizStreak .. "x"
                else
                    -- ตอบผิด! ทำการสั่นสะเทือนตัวภาพ และล้างคอมโบ
                    playFlashFeedback({ 0.8, 0.1, 0.1 }) -- กะพริบแดง
                    
                    if quizImageContainer.numChildren > 0 then
                        local img = quizImageContainer[1]
                        transition.to(img, { x = img.x - 10, time = 50, yoyo = true, iterations = 4 })
                    end

                    quizStreak = 1
                    quizStreakText.text = "Streak: 1x"
                end
                
                -- เปลี่ยนคำถามถัดไป
                nextQuizQuestion()
            end)
        end)
    end
end

buildQuizUI()

-- ==========================================
-- 🌌 4. หน้าเมนูหลัก (Main Menu Screen)
-- ==========================================
local function buildMainMenuUI()
    -- ชื่องานออกแบบสุดล้ำ (Glowing Futuristic Title)
    local titleGlow = display.newText(menuGroup, "COSMOS QUEST", display.contentCenterX, 92, native.systemFontBold, 34)
    titleGlow:setFillColor(0.1, 0.5, 1, 0.3) -- ตัวเรืองแสงสีฟ้าด้านหลัง
    
    local titleText = display.newText(menuGroup, "COSMOS QUEST", display.contentCenterX, 90, native.systemFontBold, 32)
    titleText:setFillColor(1, 1, 1)

    local subtitle = display.newText(menuGroup, "SOLAR SYSTEM QUEST", display.contentCenterX, 122, native.systemFont, 11)
    subtitle:setFillColor(0.4, 0.7, 1)

    -- การ์ดดวงอาทิตย์ลอยอยู่กึ่งกลางเป็นหน้าตาตัวแอป
    local menuOrbit = display.newCircle(menuGroup, display.contentCenterX, display.contentCenterY - 40, 50)
    local orbitPaint = {
        type = "gradient",
        color1 = { 1, 0.5, 0.1, 0.9 },
        color2 = { 1, 0.8, 0, 0.2 },
        direction = "down"
    }
    menuOrbit:setFillColor(orbitPaint)

    -- วงโคจรรอบดวงอาทิตย์
    local menuOrbitLine = display.newCircle(menuGroup, display.contentCenterX, display.contentCenterY - 40, 70)
    menuOrbitLine:setFillColor(0,0,0,0)
    menuOrbitLine.strokeWidth = 1
    menuOrbitLine:setStrokeColor(1,1,1,0.15)

    -- อนิเมชันทำให้วงกลมดวงอาทิตย์ขยายหดนุ่มนวลเหมือนหัวใจเต้น
    local function pulseSun()
        transition.to(menuOrbit, {
            pathRadius = 55,
            time = 1500,
            transition = easing.inOutQuad,
            onComplete = function()
                transition.to(menuOrbit, {
                    pathRadius = 48,
                    time = 1500,
                    transition = easing.inOutQuad,
                    onComplete = pulseSun
                })
            end
        })
    end
    pulseSun()

    -- 🚀 ปุ่มโหมดสำรวจ (Solar Explorer Mode Button)
    local explorerBtn = display.newRoundedRect(menuGroup, display.contentCenterX, display.contentHeight - 120, 220, 42, 10)
    explorerBtn:setFillColor(0.05, 0.08, 0.2, 0.8)
    explorerBtn.strokeWidth = 1.5
    explorerBtn:setStrokeColor(0.3, 0.6, 1, 0.5)

    local explorerBtnText = display.newText(menuGroup, "🚀 SOLAR EXPLORER", explorerBtn.x, explorerBtn.y, native.systemFontBold, 13)
    explorerBtnText:setFillColor(0.8, 0.9, 1)

    explorerBtn:addEventListener("tap", function()
        applyButtonAnimation(explorerBtn, function()
            menuGroup.isVisible = false
            explorerGroup.isVisible = true
            currentPlanetIndex = 1
            loadPlanetInExplorer(currentPlanetIndex)
        end)
    end)

    -- 🧠 ปุ่มโหมดเกมนิ้วไว (Space Quiz Mode Button)
    local quizBtn = display.newRoundedRect(menuGroup, display.contentCenterX, display.contentHeight - 65, 220, 42, 10)
    quizBtn:setFillColor(0.05, 0.2, 0.12, 0.8)
    quizBtn.strokeWidth = 1.5
    quizBtn:setStrokeColor(0.2, 0.8, 0.5, 0.5)

    local quizBtnText = display.newText(menuGroup, "🧠 ASTRO QUIZ QUEST", quizBtn.x, quizBtn.y, native.systemFontBold, 13)
    quizBtnText:setFillColor(0.8, 1, 0.9)

    quizBtn:addEventListener("tap", function()
        applyButtonAnimation(quizBtn, function()
            menuGroup.isVisible = false
            quizGroup.isVisible = true
            startNewQuizGame()
        end)
    end)

    -- เครดิตลิขสิทธิ์ NASA
    local credits = display.newText(menuGroup, "Imagery provided by NASA Science", display.contentCenterX, display.contentHeight - 12, native.systemFont, 9)
    credits:setFillColor(0.5, 0.5, 0.6)
end

buildMainMenuUI()