local DefaultIdlescreen = [[
<!doctype html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<title>MediaPlayer Idlescreen</title>
	<style type="text/css">
	html, body {
		margin: 0;
		padding: 0;
		width: 100%%;
		height: 100%%;
	}
	html {
		background: #fff;
	}
	body {
		overflow: hidden;
		display: -webkit-box;
		display: -moz-box;
		display: box;
		-webkit-box-orient: horizontal;
		-moz-box-orient: horizontal;
		-box-orient: horizontal;
		-webkit-box-pack: center;
		-webkit-box-align: center;
		background: -webkit-radial-gradient(center, ellipse cover,
			transparent 0%%, rgba(0, 0, 0, 0.7) 100%%);
	}
	h1 {
		margin: 0;
		padding: 0;
	}
	.background {
		position: absolute;
		display: block;
		width: 100%%;
		z-index: -1;
		-webkit-filter: blur(8px);
		-webkit-transform: scale(1.2);
		opacity: 0.66;
	}
	.content {
		color: rgba(255, 255, 255, 0.66);
		font-family: sans-serif;
		font-size: 1.5em;
		text-align: center;
		-webkit-box-flex: 1;
		-moz-box-flex: 1;
		box-flex: 1;
	}

	.metastream {
		display: block;
		max-width: 80%%;
		font-size: 18pt;
		font-weight: bold;
		margin: 20px auto 0 auto;
		padding: 16px 24px;
		text-align: center;
		text-decoration: none;
		color: white;
		line-height: 28pt;
		letter-spacing: 0.5px;
		text-shadow: 1px 1px 1px rgba(0,0,0,0.2);
		border-radius: 4px;
		background: -webkit-linear-gradient(
			-20deg,
			#20202f 0%%,
			#273550 40%%,
			#416081 100%%
		);
	}
	.metastream-link {
		color: #f98673;
		text-decoration: underline;
	}
	</style>
</head>
<body>
	<img src="asset://mapimage/gm_construct" class="background">
	<div class="content">
		<h1>No media playing</h1>
		<p>Hold Q while looking at the media player to reveal the queue menu.</p>
	</div>
</body>
</html>
]]

local ErrorIdlescreen = [[
<!doctype html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<title>MediaPlayer Idlescreen</title>
	<style type="text/css">
	html, body {
		margin: 0;
		padding: 0;
		width: 100%%;
		height: 100%%;
	}
	html {
		background: #fff;
	}
	body {
		overflow: hidden;
		display: -webkit-box;
		display: -moz-box;
		display: box;
		-webkit-box-orient: horizontal;
		-moz-box-orient: horizontal;
		-box-orient: horizontal;
		-webkit-box-pack: center;
		-webkit-box-align: center;
		background: -webkit-radial-gradient(center, ellipse cover,
			transparent 0%%, rgba(0, 0, 0, 0.7) 100%%);
	}
	h1 {
		margin: 0;
		padding: 0;
	}
	.background {
		position: absolute;
		display: block;
		width: 100%%;
		z-index: -1;
		-webkit-filter: blur(8px);
		-webkit-transform: scale(1.2);
		opacity: 0.66;
	}
	.content {
		color: rgba(255, 255, 255, 0.66);
		font-family: sans-serif;
		font-size: 1.5em;
		text-align: center;
		-webkit-box-flex: 1;
		-moz-box-flex: 1;
		box-flex: 1;
	}

	.metastream {
		display: block;
		max-width: 80%%;
		font-size: 18pt;
		font-weight: bold;
		margin: 20px auto 0 auto;
		padding: 16px 24px;
		text-align: center;
		text-decoration: none;
		color: white;
		line-height: 28pt;
		letter-spacing: 0.5px;
		text-shadow: 1px 1px 1px rgba(0,0,0,0.2);
		border-radius: 4px;
		background: -webkit-linear-gradient(
			-20deg,
			#20202f 0%%,
			#273550 40%%,
			#416081 100%%
		);
	}
	.metastream-link {
		color: #f98673;
		text-decoration: underline;
	}
	</style>
</head>
<body>
	<img src="asset://mapimage/gm_construct" class="background">
	<div class="content">
		<h1>Oops! You are missing something...</h1>
		<p>Your games version does not support video players.</p>

		<div class="metastream">
			Press F4 to open the instructions video, or head to:
			<span class="metastream-link">www.solsticegamestudios.com/fixmedia</span>
		</div>
	</div>
</body>
</html>
]]

local HasBetaBranch, HasCodecFix
local function GetIdlescreenHTML()
	local contextMenuBind = "Q"
	contextMenuBind = contextMenuBind:upper()

	if (!HasBetaBranch || (!HasBetaBranch && HasCodecFix)) then
		return ErrorIdlescreen:format( contextMenuBind )
	else
		return DefaultIdlescreen:format( contextMenuBind )
	end
end

function MediaPlayer.GetIdlescreen()

	if not MediaPlayer._idlescreen then
		local browser = vgui.Create( "DMediaPlayerHTML" )
		browser:SetPaintedManually(true)
		browser:SetKeyBoardInputEnabled(false)
		browser:SetMouseInputEnabled(false)
		browser:SetPos(0,0)

		local resolution = MediaPlayer.Resolution()
		browser:SetSize( resolution * 16/9, resolution )

		-- TODO: set proper browser size

		MediaPlayer._idlescreen = browser

		local setup = hook.Run( "MediaPlayerSetupIdlescreen", browser )
		if not setup then
			MediaPlayer._idlescreen:SetHTML( GetIdlescreenHTML() )
		end
	end

	return MediaPlayer._idlescreen

end

local InstructionSite = "https://www.solsticegamestudios.com/fixmedia/"

local HTML_Code = [[
<html><body>
<script>
	var support = "SUPPORT:";
	video = document.createElement('video');
	support += video.canPlayType('video/mp4; codecs="avc1.42E01E"') === "probably"?1:0,
	console.log(support);
</script>
</body></html>
]]

local function CheckServiceDependency()
	local panel = vgui.Create("HTML")
	panel:SetSize(100, 100)
	panel:SetAlpha(0)
	panel:SetMouseInputEnabled(false)

	function panel:ConsoleMessage(msg)
		if msg:StartWith("SUPPORT:") then
			HasBetaBranch = BRANCH and BRANCH == "x86-64" or false
			HasCodecFix = msg[9] == "1"
			
			self:Remove()
			if (!HasBetaBranch || (!HasBetaBranch && HasCodecFix)) then
				hook.Add("Move", "MoveMediaPlayerDependency", function(ply, mv)
					if (input.WasKeyPressed(KEY_F4) && LocalPlayer():GetNW2Bool("inTheatre", false)) then
						gui.OpenURL(InstructionSite)
					end
				end)
			end
		end
	end

	panel:SetHTML(HTML_Code)
end
hook.Add("InitPostEntity", "CheckServiceDependency", CheckServiceDependency)
hook.Add("OnReloaded", "CheckServiceDependency", CheckServiceDependency)