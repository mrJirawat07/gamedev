math.randomseed(os.time())

local baseURL =
"https://raw.githubusercontent.com/zorkia/flag/ed07aeff6f282df8a25ac9902da361311ba13bb9/"

local currentImage
local countryText = display.newText("", display.contentCenterX, display.contentHeight - 60,
    native.systemFont, 28)

local function loadCountryName(num)
    local fileName = num .. ".txt"
    local url = baseURL .. fileName

    network.request(url, "GET", function(event)
        if event.isError then
            countryText.text = "Name error"
        else
            countryText.text = event.response
        end
    end)
end

local function loadRandomImage()

    local num = math.random(1, 230)

    local imageFileName = num .. ".png"
    local imageURL = baseURL .. imageFileName

    print(imageURL)

    display.loadRemoteImage(
        imageURL,
        "GET",

        function(event)

            if event.isError then
                print("Load error")
                countryText.text = ""
            else
                print("OK")

                if currentImage then
                    currentImage:removeSelf()
                    currentImage = nil
                end

                currentImage = event.target
                currentImage.x = display.contentCenterX
                currentImage.y = display.contentCenterY - 40

                loadCountryName(num)
            end
        end,

        imageFileName,
        system.TemporaryDirectory
    )
end

loadRandomImage()

timer.performWithDelay(3000, loadRandomImage, 0)