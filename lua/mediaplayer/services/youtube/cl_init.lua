include "shared.lua"

local urllib = url

local htmlBaseUrl = MediaPlayer.GetConfigValue('html.base_url')

DEFINE_BASECLASS( "mp_service_browser" )

local ADBLOCK_JS = [[
const hiddenCSS=["#__ffYoutube1","#__ffYoutube2","#__ffYoutube3","#__ffYoutube4","#feed-pyv-container","#feedmodule-PRO","#homepage-chrome-side-promo","#merch-shelf","#offer-module",'#pla-shelf > ytd-pla-shelf-renderer[class="style-scope ytd-watch"]',"#pla-shelf","#premium-yva","#promo-info","#promo-list","#promotion-shelf","#related > ytd-watch-next-secondary-results-renderer > #items > ytd-compact-promoted-video-renderer.ytd-watch-next-secondary-results-renderer","#search-pva","#shelf-pyv-container","#video-masthead","#watch-branded-actions","#watch-buy-urls","#watch-channel-brand-div","#watch7-branded-banner","#YtKevlarVisibilityIdentifier","#YtSparklesVisibilityIdentifier",".carousel-offer-url-container",".companion-ad-container",".GoogleActiveViewElement",'.list-view[style="margin: 7px 0pt;"]',".promoted-sparkles-text-search-root-container",".promoted-videos",".searchView.list-view",".sparkles-light-cta",".watch-extra-info-column",".watch-extra-info-right",".ytd-carousel-ad-renderer",".ytd-compact-promoted-video-renderer",".ytd-companion-slot-renderer",".ytd-merch-shelf-renderer",".ytd-player-legacy-desktop-watch-ads-renderer",".ytd-promoted-sparkles-text-search-renderer",".ytd-promoted-video-renderer",".ytd-search-pyv-renderer",".ytd-video-masthead-ad-v3-renderer",".ytp-ad-action-interstitial-background-container",".ytp-ad-action-interstitial-slot",".ytp-ad-image-overlay",".ytp-ad-overlay-container",".ytp-ad-progress",".ytp-ad-progress-list",'[class*="ytd-display-ad-"]','[layout*="display-ad-"]','a[href^="https://www.youtube.com/cthru?"]','a[href^="https://www.youtube.com/cthru?"]',"ytd-action-companion-ad-renderer","ytd-banner-promo-renderer","ytd-compact-promoted-video-renderer","ytd-companion-slot-renderer","ytd-display-ad-renderer","ytd-promoted-sparkles-text-search-renderer","ytd-promoted-sparkles-web-renderer","ytd-search-pyv-renderer","ytd-single-option-survey-renderer","ytd-video-masthead-ad-advertiser-info-renderer","ytd-video-masthead-ad-v3-renderer","YTM-PROMOTED-VIDEO-RENDERER"],hideElements=()=>{if(!hiddenCSS)return;const e=hiddenCSS.join(", ")+" { display: none!important; }",r=document.createElement("style");r.textContent=e,document.head.appendChild(r)},observeDomChanges=e=>{new MutationObserver((r=>{e(r)})).observe(document.documentElement,{childList:!0,subtree:!0})},hideDynamicAds=()=>{const e=document.querySelectorAll("#contents > ytd-rich-item-renderer ytd-display-ad-renderer");0!==e.length&&e.forEach((e=>{if(e.parentNode&&e.parentNode.parentNode){const r=e.parentNode.parentNode;"ytd-rich-item-renderer"===r.localName&&(r.style.display="none")}}))},autoSkipAds=()=>{if(document.querySelector(".ad-showing")){const e=document.querySelector("video");e&&e.duration&&(e.currentTime=e.duration,setTimeout((()=>{const e=document.querySelector("button.ytp-ad-skip-button");e&&e.click()}),100))}},overrideObject=(e,r,t)=>{if(!e)return!1;let o=!1;for(const d in e)e.hasOwnProperty(d)&&d===r?(e[d]=t,o=!0):e.hasOwnProperty(d)&&"object"==typeof e[d]&&overrideObject(e[d],r,t)&&(o=!0);return o},jsonOverride=(e,r)=>{const t=JSON.parse;JSON.parse=(...o)=>{const d=t.apply(this,o);return overrideObject(d,e,r),d},Response.prototype.json=new Proxy(Response.prototype.json,{async apply(...t){const o=await Reflect.apply(...t);return overrideObject(o,e,r),o}})};jsonOverride("adPlacements",[]),jsonOverride("playerAds",[]),hideElements(),hideDynamicAds(),autoSkipAds(),observeDomChanges((()=>{hideDynamicAds(),autoSkipAds()}));
]]

-- https://developers.google.com/youtube/player_parameters
-- TODO: add closed caption option according to cvar
SERVICE.VideoUrlFormat = htmlBaseUrl .. "youtube.html"

local JS_SetVolume = "if(window.MediaPlayer) MediaPlayer.setVolume(%s);"
local JS_Seek = "if(window.MediaPlayer) MediaPlayer.seek(%s);"
local JS_Play = "if(window.MediaPlayer) MediaPlayer.play();"
local JS_Pause = "if(window.MediaPlayer) MediaPlayer.pause();"

local function YTSetVolume( self )
	-- if not self.playerId then return end
	local js = JS_SetVolume:format( MediaPlayer.Volume() * 100 )
	if self.Browser then
		self.Browser:RunJavascript(js)
	end
end

local function YTSeek( self, seekTime )
	-- if not self.playerId then return end
	local js = JS_Seek:format( seekTime )
	if self.Browser then
		self.Browser:RunJavascript(js)
	end
end

function SERVICE:SetVolume( volume )
	local js = JS_SetVolume:format( MediaPlayer.Volume() * 100 )
	self.Browser:RunJavascript(js)
end

function SERVICE:OnBrowserReady( browser )

	BaseClass.OnBrowserReady( self, browser )

	self.Browser:RunJavascript(ADBLOCK_JS)

	timer.Simple(0.1, function() 
		self.Browser:RunJavascript(ADBLOCK_JS)
	end)

	-- Resume paused player
	if self._YTPaused then
		self.Browser:RunJavascript( JS_Play )
		self._YTPaused = nil
		return
	end

	local videoId = self:GetYouTubeVideoId()
	local timedParam = self:IsTimed() and '1' or '0'
	local url = self.VideoUrlFormat .. '?v=' .. videoId ..
				'&timed=' .. timedParam

	local curTime = self:CurrentTime()

	-- Add start time to URL if the video didn't just begin
	if self:IsTimed() and curTime > 3 then
		url = url .. "&start=" .. math.Round(curTime)
	end


	self.Browser:RunJavascript(ADBLOCK_JS)

	browser:OpenURL(url)

	self.Browser:RunJavascript(ADBLOCK_JS)

end

function SERVICE:Pause()
	BaseClass.Pause( self )

	if ValidPanel(self.Browser) then
		self.Browser:RunJavascript(JS_Pause)
		self._YTPaused = true
	end
end

function SERVICE:Sync()
	local seekTime = self:CurrentTime()
	if self:IsPlaying() and self:IsTimed() and seekTime > 0 then
		YTSeek( self, seekTime )
	end
end

function SERVICE:IsMouseInputEnabled()
	return IsValid( self.Browser )
end
