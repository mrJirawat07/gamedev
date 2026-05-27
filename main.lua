--[[
Corona SDK - Random NASA Planet Image Viewer
Displays a random planet image every 3 seconds with planet name
GitHub: https://github.com/mrJirawat07/gamedev
]]

-- Initialize display
local centerX = display.contentCenterX
local centerY = display.contentCenterY
local screenWidth = display.actualContentWidth
local screenHeight = display.actualContentHeight

-- Create background
local background = display.newRect(centerX, centerY, screenWidth, screenHeight)
background:setFillColor(0.1, 0.1, 0.1)

-- GitHub configuration
local gitHubUser = "mrJirawat07"
local gitHubRepo = "gamedev"
local gitHubCommit = "a43cd2e"  -- Latest commit hash
local baseURL = "https://raw.githubusercontent.com/" .. gitHubUser .. "/" .. gitHubRepo .. "/" .. gitHubCommit .. "/NASA/"

-- Planet list (in order 1-13)
local planets = {
    "Mercury", "Venus", "Earth", "Mars", "Jupiter", "Saturn", "Uranus",
    "Neptune", "Pluto", "Ceres", "Haumea", "Makemake", "Eris"
}

-- Image extensions mapping (based on file formats available)
local imageExtensions = {
    "Mercury.webp", "Venus.webp", "Earth.webp", "Mars.webp", 
    "Jupiter.webp", "Saturn.webp", "Uranus.webp", "Neptune.webp", 
    "Pluto.webp", "Ceres.webp", "Haumea.webp", "Makemake.webp", "Eris.jpg"
}

-- Initialize random seed
math.randomseed(os.time())

-- UI Elements
local planetNameText
local imageDisplayGroup = display.newGroup()
local currentImage = nil

-- Function to get file extension for a planet
local function getImageFilename(index)
    if index >= 1 and index <= 13 then
        return imageExtensions[index]
    end
    return nil
end

-- Function to load and display random planet image
local function loadRandomImage()
    -- Clear previous image
    if currentImage then
        display.remove(currentImage)
        currentImage = nil
    end
    
    -- Select random planet
    local randomIndex = math.random(1, 13)
    local planetName = planets[randomIndex]
    local imageFilename = getImageFilename(randomIndex)
    
    if not imageFilename then
        print("Error: Invalid image filename")
        return
    end
    
    -- Construct image URL
    local imageURL = baseURL .. imageFilename
    
    print("Loading image: " .. imageURL)
    
    -- Load image from GitHub
    local function imageLoadListener(event)
        if event.phase == "began" then
            print("Loading image...")
        elseif event.phase == "ended" then
            if event.isError then
                print("Error loading image: " .. imageFilename)
                if planetNameText then
                    planetNameText.text = "Error loading: " .. planetName
                end
            else
                print("Successfully loaded: " .. planetName)
                currentImage = event.target
                
                -- Position and scale image
                currentImage.x = centerX
                currentImage.y = centerY - 80
                currentImage.width = screenWidth * 0.9
                currentImage.height = screenWidth * 0.9
                
                imageDisplayGroup:insert(currentImage)
            end
        end
    end
    
    -- Load image
    display.loadRemoteImage(imageURL, imageLoadListener)
    
    -- Load and display planet name
    if planetNameText then
        planetNameText:removeSelf()
        planetNameText = nil
    end
    
    planetNameText = display.newText(planetName, centerX, screenHeight - 100, native.systemFont, 48)
    planetNameText:setFillColor(1, 1, 1)
    
    -- Optional: Load planet name from text file (non-blocking)
    local function nameLoadListener(event)
        if event.phase == "ended" and not event.isError then
            if event.response.status == 200 then
                local nameFromFile = event.response.body
                print("Loaded name from file: " .. nameFromFile)
                if planetNameText then
                    planetNameText.text = nameFromFile
                end
            end
        end
    end
    
    local nameURL = baseURL .. randomIndex .. ".txt"
    network.request(nameURL, "GET", nameLoadListener)
end

-- Create initial UI
local titleText = display.newText("NASA Planet Viewer", centerX, 100, native.systemFont, 40)
titleText:setFillColor(0.2, 0.8, 1)

-- Button to manually load next image
local function onNextButtonPress(event)
    if event.phase == "ended" then
        loadRandomImage()
    end
end

local nextButton = display.newRect(centerX, screenHeight - 40, 200, 50)
nextButton:setFillColor(0.2, 0.6, 0.8)
nextButton:addEventListener("touch", onNextButtonPress)

local buttonText = display.newText("Next Planet", centerX, screenHeight - 40, native.systemFont, 20)
buttonText:setFillColor(1, 1, 1)

-- Load first image immediately
loadRandomImage()

-- Set up timer to load new image every 3 seconds
timer.performWithDelay(3000, loadRandomImage, 0)

print("Corona SDK NASA Planet Viewer Started")
print("GitHub: " .. baseURL)
print("Images loaded: " .. #planets)