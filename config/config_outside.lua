-- コンフィグ設定
return { modemSide = "top",        -- エンダーモデムの接続面
	monitorName = "monitor_0", -- モニターの名前
	
	-- モード設定
	aggressiveTempScale = false, -- true で 10000℃ スケールを使用[aggressive] / false で 8000℃スケール [safemode]

	-- 温度スケール
	safeTempLimit = 8000,
	warnTempLimit = 7500,

	-- アラート設定
	alertInterval = 60 * 5,     -- アラート間隔（秒）

	-- グラフ設定
	maxHistory = 120,           -- 履歴保持数（秒）
	maxSecondsForGraph = 60 * 3600, -- グラフ最大時間（秒）

	-- 出力推定係数
	K = 300000,                 -- 出力調整係数

	-- 通信チャンネル
	channel = 1
}