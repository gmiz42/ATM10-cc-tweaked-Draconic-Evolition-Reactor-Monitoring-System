-- ステータス送信用プログラム（自動起動のためにファイル名を startup.lua に変更する）
-- config_inside.luaを読み込む
local config =  require("config_inside")

-- 周辺機器を取得(Ender Modem、Reactor Stabilizer,Flux Gate IN/OUT )
local modem = peripheral.wrap(config.modemSide)
if not modem then error("Ender Modem is not found. (" .. config.modemSide .. ")")  end -- エンダーモデムが見つからない

local logic = peripheral.find(config.reactorPeripheral) or peripheral.find("draconicReactor")
if not logic then error("Reactor Stabilizer is not found.") end  -- リアクターが見つからない

local inputGate = peripheral.wrap(config.inputGateName)
if not inputGate then error("Input Flux Gate is not found. (" .. config.inputGateName .. ")") end -- インジェクター側のフラックスゲートが見つからない

local outputGate = peripheral.wrap(config.outputGateName)
if not outputGate then error("Output Flux Gate is not found. (" .. config.outputGateName .. ")") end -- スタビライザー側のフラックスゲートが見つからない


--チャンネル確立
modem.open(config.channel)

-- JSON送信関数
local function sendStatus()
    local info = logic.getReactorInfo()
    if not info then
        print("Cannot obtain ReactorInfo. The Reactor may be stopped.") -- ReactorInfo が見つかりません。 Reactorが停止中の可能性があります。
        return
    end

    local data = {
        info = info,
        input = inputGate.getFlow(),
        output = outputGate.getFlow(),
    }

	-- JSON形式に変換して管理用PCへ送信
    local json = textutils.serializeJSON(data)
    modem.transmit(config.channel, config.channel, json)

    -- デバッグ表示
    term.clear()
    term.setCursorPos(1, 1)
    print("SEND:", json)
end

-- メインループ開始
while true do
	sendStatus()
	sleep(config.interval)
end
