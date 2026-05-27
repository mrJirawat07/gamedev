-- Solar System Explorer (Simplified Version) 🌌🚀
-- Developed for Solar2D (Corona SDK)
-- Fetching all assets dynamically from the user's GitHub Raw:
-- https://raw.githubusercontent.com/mrJirawat07/gamedev/main/nasa/

math.randomseed(os.time())

-- รายชื่อไฟล์รูปภาพดาวเคราะห์ทั้ง 13 ดวงเรียงตามลำดับสุริยะ
local planetFiles = {
    "Mercury.png", "Venus.png", "Earth.png", "Mars.png", "Jupiter.png",
    "Saturn.png", "Uranus.png", "Neptune.png", "Pluto.png", "Ceres.png",
    "Eris.png", "Haumea.png", "Makemake.png"
}

local baseURL = "https://raw.githubusercontent.com/mrJirawat07/gamedev/main/nasa/"

local currentImage = nil
local currentIndex = 1
local floatTransition = nil

-- ==========================================
-- 🎨 1. พื้นหลังอวกาศ Nebula และดาววิบวับ
-- ==========================================
local bgGroup = display.newGroup()
local mainGroup = display.newGroup()

local bg = display.newRect(bgGroup, display.contentCenterX, display.contentCenterY, display.contentWidth + 100, display.contentHeight + 100)
local bgGradient = {
    type = "gradient",
    color1 = { 0.02, 0.05, 0.12, 1 },
    color2 = { 0, 0, 0, 1 },
    direction = "down"
}
bg:setFillColor(bgGradient)

-- สร้างดาวระยิบระยับกะพริบเบาๆ
local stars = {}
for i = 1, 35 do
    local star = display.newCircle(bgGroup, math.random(0, display.contentWidth), math.random(0, display.contentHeight), math.random(1, 2) / 2)
    star:setFillColor(1, 1, 1, math.random(2, 8) / 10)
    stars[i] = star
end

local function twinkleStar(star)
    if not star or not star.x then return end
    transition.to(star, {
        alpha = math.random(1, 10) / 10,
        time = math.random(1000, 3000),
        onComplete = function()
            twinkleStar(star)
        end
    })
end

for i = 1, #stars do
    twinkleStar(stars[i])
end

-- ==========================================
-- 🪐 2. ส่วนแสดงผลข้อความและภาพดาวเคราะห์
-- ==========================================

-- ออบเจกต์ข้อความชื่อดาวเคราะห์ด้านบน
local nameText = display.newText(mainGroup, "Loading...", display.contentCenterX, 60, native.systemFontBold, 30)
nameText:setFillColor(0.4, 0.8, 1) -- สีฟ้านีออนเรืองแสง

-- อนิเมชันลอยเบาๆ (Floating Planet)
local function startPlanetFloating(target)
    if not target then return end
    
    local function floatUp()
        if not target.y then return end
        floatTransition = transition.to(target, {
            y = display.contentCenterY - 60,
            time = 1800,
            transition = easing.inOutSine,
            onComplete = function()
                if not target.y then return end
                floatTransition = transition.to(target, {
                    y = display.contentCenterY - 30,
                    time = 1800,
                    transition = easing.inOutSine,
                    onComplete = floatUp
                })
            end
        })
    end
    floatUp()
end

-- ฟังก์ชันดึงชื่อดวงดาว (.txt) จาก GitHub Raw
local function loadPlanetName(index)
    nameText.text = "Fetching..."
    
    local url = baseURL .. index .. ".txt"
    network.request(url, "GET", function(event)
        if event.isError then
            nameText.text = "Connection Error"
        else
            -- ขจัดช่องว่าง หรืออักษรขึ้นบรรทัดใหม่
            local cleanName = event.response:gsub("[\r\n]", "")
            nameText.text = cleanName:upper()
        end
    end)
end

-- ฟังก์ชันดึงรูปภาพ (.png) และอัปเดตข้อมูล
local function loadPlanet(index)
    -- ล้างรูปเก่าและอนิเมชันเดิมเพื่อป้องกันเมมโมรี่เต็ม
    if floatTransition then transition.cancel(floatTransition) end
    if currentImage then
        currentImage:removeSelf()
        currentImage = nil
    end

    -- 1. โหลดชื่อดาวเคราะห์จากไฟล์ .txt
    loadPlanetName(index)

    -- 2. โหลดรูปภาพจากไฟล์ .png
    local fileName = planetFiles[index]
    local imageURL = baseURL .. fileName

    display.loadRemoteImage(
        imageURL,
        "GET",
        function(event)
            if event.isError then
                print("Image load error")
            else
                if mainGroup.y ~= nil then
                    currentImage = event.target
                    mainGroup:insert(currentImage)
                    
                    -- จัดตำแหน่งและขนาดรูปภาพตรงกลางจอ
                    currentImage.x = display.contentCenterX
                    currentImage.y = display.contentCenterY - 30
                    currentImage.width = 160
                    currentImage.height = 160
                    
                    -- เอฟเฟกต์เฟดภาพและเริ่มลอยเบาๆ
                    currentImage.alpha = 0
                    transition.to(currentImage, { alpha = 1, time = 400 })
                    startPlanetFloating(currentImage)
                end
            end
        end,
        fileName,
        system.TemporaryDirectory
    )
end

-- ==========================================
-- 🚀 3. ปุ่มกดถัดไป (Next Planet Button)
-- ==========================================
local nextBtn = display.newRoundedRect(mainGroup, display.contentCenterX, display.contentHeight - 65, 200, 44, 10)
nextBtn:setFillColor(0.05, 0.08, 0.2, 0.8)
nextBtn.strokeWidth = 1.5
nextBtn:setStrokeColor(0.3, 0.6, 1, 0.5)

local nextBtnText = display.newText(mainGroup, "NEXT PLANET 🚀", nextBtn.x, nextBtn.y, native.systemFontBold, 13)
nextBtnText:setFillColor(0.8, 0.9, 1)

-- ฟังก์ชันการกดปุ่มแล้วสปริงตัวแบบยืดหยุ่น (Elastic Feedback)
nextBtn:addEventListener("tap", function()
    transition.to(nextBtn, {
        scaleX = 0.9,
        scaleY = 0.9,
        time = 80,
        transition = easing.outQuad,
        onComplete = function()
            transition.to(nextBtn, {
                scaleX = 1.0,
                scaleY = 1.0,
                time = 120,
                transition = easing.outElastic,
                onComplete = function()
                    -- เลื่อนไปดาวเคราะห์ลำดับถัดไป (1 ถึง 13 วนลูป)
                    currentIndex = currentIndex + 1
                    if currentIndex > 13 then
                        currentIndex = 1
                    end
                    loadPlanet(currentIndex)
                end
            })
        end
    })
end)

-- โหลดดวงดาวแรกเมื่อเปิดแอปสำเร็จ
loadPlanet(currentIndex)