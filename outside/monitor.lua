-- コンフィグ設定
local config = require("config_outside")

-- エンダーモデムを取得 
local modem = peripheral.wrap(config.modemSide) 
if not modem then error("Ender Modem が見つかりません") end
modem.open(1)

-- モニターを取得
local mon = peripheral.wrap(config.monitorName) 
if not mon then error("Monitor が見つかりません") end

-- モニター関連の処理 
local old = term.redirect(mon)   -- ここで一度だけ monitor にリダイレクト 
local w, h = mon.getSize() 
local bottomY = h - 1

-- 背景色の設定。お好みで変更可
mon.setBackgroundColor(colors.black) 
mon.clear()

-- グラフエリアの調整 
local graphHeight = h - 4      -- 下4行は数値表示 
local barWidth    = math.floor(w * 0.25)  -- 左25%を棒グラフ 
local lineWidth   = w - barWidth          -- 残りを折れ線グラフ 
local lineOffset  = barWidth + 1

-- Safe/Aggressive ボタン位置（動的計算）
local function getSafeModeX()
    local label = config.aggressiveTempScale and "[AGGRESSIVE]" or "[SAFE MODE]"
    return w - #label - 2
end

-- 履歴データ準備 
local history = { 
	temperature = {},
	saturation = {},
	field = {},
	burn = {},
}

-- 折れ線グラフ描画用の準備 
local timeHistory = {}

-- 状態管理用フラグ 
local lastAlertTime = 0

-- タッチボタン
local safeModeX = 48   -- モニター幅に合わせて調整
local safeModeY = bottomY - 1

-- 棒グラフ描画 
local function drawBar(x, ratio, color) 
	if ratio < 0 then ratio = 0 end 
	if ratio > 1 then ratio = 1 end 
	
	local height = math.floor(ratio * graphHeight) 
	local x1 = x 
	local x2 = x + 2 
	local y1 = graphHeight - height 
	local y2 = graphHeight 

	paintutils.drawFilledBox(x1, y1, x2, y2, color)
end

-- 折れ線グラフ描画 
local graphTop = 3  -- タイトルと凡例の下から描画開始 
local graphBottom = graphHeight

local function scaledY(ratio) return 
	graphBottom - math.floor(ratio * (graphBottom - graphTop))
 end

local function drawLineGraph(values, color, xOffset) 
	if #values < 2 then	return end 
	
	-- 最新値を右端に固定
	local startIndex = math.max(1, #values - lineWidth + 1) 
		for i = startIndex + 1, #values do 
			local x1 = xOffset + (i - startIndex - 1) 
			local x2 = xOffset + (i - startIndex) 
			local y1 = scaledY(values[i - 1]) 
			local y2 = scaledY(values[i]) 
			paintutils.drawLine(x1, y1, x2, y2, color) 
		end 
	end

-- fuelBurnRateの準備 
local fuelBurnRate = 0

-- 危険判定関数 
local function evaluateDanger(info) 
local danger = { temp=0, sat=0, field=0 } 
local tempLimit = config.aggressiveTempScale and 10000 or config.safeTempLimit

-- 温度判定 
if info.temperature >= tempLimit then
	danger.temp = 2
elseif info.temperature >= config.warnTempLimit then
	danger.temp = 1
end

-- 飽和度判定 
local sat = info.energySaturation / info.maxEnergySaturation 
	if sat <= 0.20 then
		danger.sat = 2 
	elseif sat <= 0.25 then
		danger.sat = 1 
end

-- シールド判定 
local fld = info.fieldStrength / info.maxFieldStrength 
	if fld <= 0.20 then
		danger.field = 2 
	elseif fld <= 0.30 then
	 danger.field = 1
	end
	return danger
end

-- 危険度に応じた色分け関数 
local function dangerColor(level) 
	if level == 2 then
		return colors.red
	elseif level == 1 then
		return colors.orange
	else
		return colors.green
	end
end

-- メインループ（通信＋描画） 
while true do
	--os.pullEventの判定 #1 JSON受信
	local event, p1, p2, p3, p4 = os.pullEvent()
	if event == "modem_message" then 
		local side, ch, rch, msg = p1, p2, p3, p4 
		local data = textutils.unserializeJSON(msg) 
		if data then 
			mon.setBackgroundColor(colors.black) 
			mon.clear()

			-- 折れ線グラフタイトル 
			mon.setTextColor(colors.white) 
			mon.setBackgroundColor(colors.black) 
			mon.setCursorPos(lineOffset, 1) 
			mon.write("Reactor Status (Scaled Line Graph)")

			-- 凡例 
			local legendY = 2 -- タイトルのすぐ下
			mon.setCursorPos(lineOffset, legendY) 
			mon.setTextColor(colors.red) 
			mon.write("Temp ") 
			mon.setTextColor(colors.green) 
			mon.write("Sat ") 
			mon.setTextColor(colors.blue) 
			mon.write("Field") 
			mon.setTextColor(colors.yellow) 
			mon.write("Time") 
			mon.setTextColor(colors.purple) 
			mon.write("Burn")

			-- 折れ線グラフ用のスケーリング 
			local tempLimit = config.aggressiveTempScale and 10000 or config.safeTempLimit 
			local tempLineRatio  = math.min(data.info.temperature / tempLimit, 1) 
			local satLineRatio   = data.info.energySaturation / data.info.maxEnergySaturation 
			local fieldLineRatio = data.info.fieldStrength / data.info.maxFieldStrength

			-- 履歴更新 
			table.insert(history.temperature, tempLineRatio) 
			table.insert(history.saturation,  satLineRatio) 
			table.insert(history.field,       fieldLineRatio)

			if #history.temperature > lineWidth then
				table.remove(history.temperature, 1)
				table.remove(history.saturation, 1)
				table.remove(history.field, 1)
			end

			-- 危険度スケール 
			local tempRatio   = tempLineRatio 
			local fieldRatio = math.min(math.max(fieldLineRatio, 0), 1) 
			local satRatio = math.min(data.info.energySaturation / data.info.maxEnergySaturation, 1) 
			local inputRatio  = math.min((data.input or 0) / 10000000, 1) 
			local outputRatio = math.min((data.output or 0) / 10000000, 1)

			-- 棒グラフ描画 
			drawBar(2,  tempRatio,   dangerColor(evaluateDanger(data.info).temp)) 
			drawBar(6,  fieldRatio,  dangerColor(evaluateDanger(data.info).field)) 
			drawBar(10, satRatio,    dangerColor(evaluateDanger(data.info).sat))

			local function safeY(ratio) 
				local y = graphHeight - math.floor(ratio * graphHeight) - 1 
				if y < 1 then y = 1 end 
				return y 
			end

			-- 棒グラフの上にパーセンテージ表示 
			mon.setTextColor(colors.white) 
			mon.setBackgroundColor(colors.black) 
			mon.setCursorPos(2,  safeY(tempRatio)) 
			mon.write(string.format("%d%%", math.floor(tempRatio * 100))) 
			mon.setCursorPos(6,  safeY(fieldRatio)) 
			mon.write(string.format("%d%%", math.floor(fieldRatio * 100))) 
			mon.setCursorPos(10, safeY(satRatio)) 
			mon.write(string.format("%d%%", math.floor(satRatio * 100)))

			-- 棒グラフラベル 
			mon.setTextColor(colors.white) 
			mon.setBackgroundColor(colors.black) 
			mon.setCursorPos(2, graphHeight + 1) 
			mon.write("Temp") 
			mon.setCursorPos(6, graphHeight + 1) 
			mon.write("Fld") 
			mon.setCursorPos(10, graphHeight + 1) 
			mon.write("Sat")

			-- 燃料情報 
			local fuelUsed_mB      = data.info.fuelConversion 
			local fuelMax_mB       = data.info.maxFuelConversion 
			local fuelRemaining_mB = fuelMax_mB - fuelUsed_mB 
			local fuelPercent   = (fuelRemaining_mB / fuelMax_mB) * 100

			-- 燃焼率 
			local rateNbPerTick = data.info.fuelConversionRate 
			local rateNbPerSec  = rateNbPerTick * 20 / 1000000 -- mB/s

			-- 残り時間計算（ｎB/sの移動平均） 
			fuelBurnRate = (fuelBurnRate * 0.9) + ((rateNbPerSec) * 0.1) 

			local secondsRemain = fuelRemaining_mB / math.max(fuelBurnRate, 0.0000001)

			-- グラフ用正規化 
			local timeRatio = secondsRemain / config.maxSecondsForGraph 
			if timeRatio > 1 then timeRatio = 1 end 
			if timeRatio < 0 then timeRatio = 0	end

			table.insert(timeHistory, timeRatio) 
			if #timeHistory > config.maxHistory then
				table.remove(timeHistory, 1)
			end

			-- 燃焼率比率 
			local burnRatio = math.min(fuelBurnRate / 0.2, 1) 
			table.insert(history.burn, burnRatio) 

			if #history.burn > lineWidth then
				table.remove(history.burn, 1)
			end

			-- 折れ線グラフ描画 
			drawLineGraph(history.temperature, colors.red,   lineOffset) 
			drawLineGraph(history.saturation,  colors.green, lineOffset) 
			drawLineGraph(history.field, colors.blue, lineOffset) 
			drawLineGraph(timeHistory, colors.yellow, lineOffset) 
			drawLineGraph(history.burn, colors.purple, lineOffset)

			-- 下部詳細情報表示 
			mon.setTextColor(colors.white) 
			mon.setBackgroundColor(colors.black)

			-- アラート判定（残り時間1時間未満） 
			if secondsRemain < 3600 then 
				local now = os.epoch("utc") / 1000 
				if now - lastAlertTime > config.alertInterval then
					commands.say(string.format(
						"⚠ Reactor fuel low: %dm remaining",
						math.floor(secondsRemain / 60)
					))
					lastAlertTime = now
				end
			end

			local function formatTime(sec) 
			if sec < 60 then
				return string.format("%.1fs", sec) 
				elseif sec < 3600 then 
					return string.format("%dm %ds", math.floor(sec / 60), sec % 60)
				else
					return string.format("%dh %dm", math.floor(sec / 3600), 
					math.floor((sec % 3600) / 60)) 
				end
			end

			-- 適正出力要求の推定 
			local satNow  = satLineRatio 
			local satPrev = history.saturation[#history.saturation - 1] or satNow 
			local tempNow  = history.temperature[#history.temperature] or 0 
			local tempPrev = history.temperature[#history.temperature - 1] or tempNow 
			local tempSlope = (tempNow - tempPrev) local satSlope = (satNow - satPrev) 
			local optimalOutput = (data.output or 0) - (satSlope * config.K)

			-- マイナスにならないよう補正
			if optimalOutput < 0 then optimalOutput = 0 end

			-- 飽和度の上下余裕	
			local satRatio = data.info.energySaturation / data.info.maxEnergySaturation 
			local satUpperMargin = 1.0 - satRatio 
			local satLowerMargin = satRatio - 0.0 
			local satCriticalMargin = math.min(satUpperMargin, satLowerMargin)

			-- 温度の余裕
			local tempMargin = (tempLimit - data.info.temperature) / tempLimit 
			if tempMargin < 0 then tempMargin = 0 end

			-- 総合した要求出力の余裕
			local safetyMargin = math.min(tempMargin, satCriticalMargin) 
			if safetyMargin < 0 then safetyMargin = 0 end

			-- 傾きの評価（危険方向に傾いているか）
			local slopePenalty = 0 

			-- 温度上昇中はペナルティ
			if tempSlope > 0 then
				slopePenalty = slopePenalty + tempSlope * 2
			end

			-- 飽和度下降中はペナルティ
			if satSlope < 0 then
				slopePenalty = slopePenalty + (-satSlope) * 2
			end

			-- ★　温度の上昇・飽和度の下降は、変更した出力要求に耐えられたら上昇を始めるので別の角度からも判断する
			-- 温度危険域評価
			local tempDanger = 0 
			if data.info.temperature > tempLimit * 0.9 then  -- 90%
				tempDanger = (data.info.temperature - tempLimit * 0.9 ) / tempLimit  -- 0-0.1程度
			end

			local satDanger = 0 
			if satRatio < 0.20 then  -- 20%以下は危険域
				satDanger = (0.20 - satRatio) / 0.20  -- 0-1.0
			end

			-- 総合ペナルティ評価
			local totalPenalty = slopePenalty + tempDanger + satDanger

			-- マージンの危険域評価
			local dangerZoneFactor = 1.0 

			-- 温度危険ゾーン 温度80%以上なら 4割にする
			if data.info.temperature >= tempLimit * 0.8 then
				dangerZoneFactor = dangerZoneFactor * 0.4
			end

			-- 飽和度危険ゾーン 25%以下なら 3割にする
			if satRatio <= 0.25 then
				dangerZoneFactor = dangerZoneFactor * 0.3
			end

			-- 最終的な安全マージンに適用
			safetyMargin = safetyMargin * dangerZoneFactor

			-- 安全マージンにペナルティ評価を反映
			safetyMargin = safetyMargin - totalPenalty 
			if safetyMargin < 0 then safetyMargin = 0 end

			-- MAX推定要求出力
			local currentOutput = data.output or 0
			local maxSafeOutput = currentOutput * (1 + safetyMargin)
			local headroom = maxSafeOutput - currentOutput
			if headroom < 0 then headroom = 0 end

			-- ★ モード補正（Safe / Aggressive）
			local modeFactor = config.aggressiveTempScale and 1.2 or 0.5
			local adjustedHeadroom = headroom * modeFactor

			-- ★ 推奨出力
			local recommended = math.floor(currentOutput + adjustedHeadroom)

			-- Safe Mode 表示用の文字列
			local safeModeLabel = config.aggressiveTempScale and "[AGGRESSIVE]" or "[SAFE MODE]"
			local safeColor = config.aggressiveTempScale and colors.red or colors.green

			-- 下段の情報を表示
			-- 推奨出力、headroom、モードボタン
			mon.setCursorPos(1, bottomY - 1)
			mon.setTextColor(colors.yellow)
			mon.setBackgroundColor(colors.black)
			mon.write(string.format("Recommend: %d op/t | Headroom: +%d op/t | Mode(touch): ",
			recommended,
			math.floor(headroom)
			))

			local label = safeModeLabel
			local safeModeX = w - #label - 1
			mon.setCursorPos(safeModeX, bottomY - 1)
			mon.setTextColor(safeColor)	
			mon.setBackgroundColor(colors.gray)
			mon.write(label)

			mon.setTextColor(colors.white)
			mon.setBackgroundColor(colors.black)
			mon.setCursorPos(1, bottomY) 
			mon.write(string.format( 
				"Status: %s   Output: %s op/t   Fuel: %.2f/%.2f mB (Remain: %.1f%%)",
				data.info.status or "Unknown",
				data.output or 0,
				fuelUsed_mB, fuelMax_mB, fuelPercent
			))

			mon.setCursorPos(1, bottomY + 1) 
			mon.write(string.format( 
				"Temp: %d C   Burn: %d nB/t   Time Left: %s", 
				data.info.temperature, rateNbPerTick, formatTime(secondsRemain) 
			))
		end
	-- os.pullEventの判定 #2 タッチパネルイベントedi
	elseif event == "monitor_touch" then
		local side, x, y = p1, p2, p3
		local safeModeX = getSafeModeX()
		-- Safe Mode ボタンの範囲判定
		if y == safeModeY and x >= safeModeX and x <= safeModeX + 12 then
        config.aggressiveTempScale = not config.aggressiveTempScale
        end
	end
end

term.redirect(old)
