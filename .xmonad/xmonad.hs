{- xmonad.hs
 - Author: Jelle van der Waa ( jelly1 )
 -}

-- Import stuff
import XMonad
import qualified XMonad.StackSet as W 
import qualified XMonad.StackSet as Z 
import qualified Data.Map as M
import XMonad.Util.EZConfig(additionalKeys)
import System.Exit
import Graphics.X11.Xlib
import System.IO


-- actions
import XMonad.Actions.CycleWS
import XMonad.Actions.WindowGo
import qualified XMonad.Actions.Submap as SM
import XMonad.Actions.GridSelect
import XMonad.Actions.FloatKeys
import XMonad.Actions.Submap

-- utils

import XMonad.Util.Run
import qualified XMonad.Prompt 		as P
import XMonad.Prompt.Shell
import XMonad.Prompt
import XMonad.Prompt.AppendFile (appendFilePrompt)
import XMonad.Prompt.RunOrRaise
import XMonad.Util.NamedWindows (getName)

-- hooks
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.UrgencyHook
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.SetWMName

-- layouts
import XMonad.Layout.NoBorders
import XMonad.Layout.ResizableTile
import XMonad.Layout.Reflect
import XMonad.Layout.IM
import XMonad.Layout.Tabbed
import XMonad.Layout.PerWorkspace (onWorkspace)
import XMonad.Layout.Grid
import XMonad.Layout.ComboP
import XMonad.Layout.Column
import XMonad.Layout.Named
import XMonad.Layout.TwoPane

-- Data.Ratio for IM layout
import Data.Ratio ((%))
import Data.List (isInfixOf)

import XMonad.Hooks.EwmhDesktops


-- Main --
main = do
    xmproc <- spawnPipe "xmobar"
    spawn "sh /home/jelle/.xmonad/autostart.sh"
    xmonad $ withUrgencyHook NoUrgencyHook $ defaultConfig  {  manageHook = myManageHook  <+> manageDocks
        	, layoutHook = myLayoutHook   
		, borderWidth = myBorderWidth
		, normalBorderColor = myNormalBorderColor
		, focusedBorderColor = myFocusedBorderColor
		, keys = myKeys
        	, modMask = myModMask  
        	, terminal = myTerminal
		, workspaces = myWorkspaces
                , focusFollowsMouse = False
                , logHook = dynamicLogWithPP $ xmobarPP { ppOutput = hPutStrLn xmproc , ppTitle = xmobarColor "green" "" . shorten 50}
		}


-- hooks
-- automaticly switching app to workspace 
myManageHook :: ManageHook
myManageHook =  (composeAll . concat $
                [[isFullscreen                  --> doFullFloat
		, className =?  "Xmessage" 	--> doCenterFloat 
		--, className =?  "Steam" 	--> doFloat 
		, className =? "Xfce4-notifyd" --> doIgnore
                , className =? "Gimp"           --> doShift "9:gimp"
                , className =? "Evolution"           --> doShift "2:web"
                , className =? "Pidgin"           --> doShift "1:chat"
                , className =? "Skype"           --> doShift "1:chat"
                , className =? "Mail"           --> doShift "2:mail"
                , className =? "Thunderbird"           --> doShift "2:mail"
		, className =? "MPlayer"	--> doShift "8:vid"
		, className =? "mplayer2"	--> doShift "8:vid"
		, className =? "rdesktop"	--> doShift "6:vm"
		, className =? "NXAgent"	--> doShift "6:vm"
		, fmap ("NX" `isInfixOf`) title --> doShift "6:vm"
		, className =? "Wine"	--> doShift "7:games"
		, className =? "pyrogenesis"	--> doShift "7:games"
		, className =? "Springlobby"	--> doShift "7:games"
		, className =? "Steam"	--> doShift "7:games"
		, className =? "mono"	--> doShift "7:games"
		, className =? "SeamlessRDP"	--> doShift "5:doc"
		, className =? "Calibre-gui"	--> doShift "5:doc"
		, className =? "Spotify"	--> doShift "10:spotify"
                , fmap ("libreoffice"  `isInfixOf`) className --> doShift "5:doc"
		, className =? "MPlayer"	--> (ask >>= doF . W.sink) 
                ]]) 



--logHook
myLogHook :: Handle -> X ()
myLogHook h = dynamicLogWithPP $ customPP { ppOutput = hPutStrLn h }
         


---- Looks --
---- bar
customPP :: PP
customPP = defaultPP { 
     			    ppHidden = xmobarColor "#00FF00" ""
			  , ppCurrent = xmobarColor "#FF0000" "" . wrap "[" "]"
			  , ppUrgent = xmobarColor "#FF0000" "" . wrap "*" "*"
                          , ppLayout = xmobarColor "#FF0000" ""
                          , ppTitle = xmobarColor "#00FF00" "" . shorten 80
                          , ppSep = "<fc=#0033FF> | </fc>"
                     }

-- some nice colors for the prompt windows to match the dzen status bar.
myXPConfig = defaultXPConfig                                    
    { 
	font  = "-*-terminus-*-*-*-*-12-*-*-*-*-*-*-u" 
	,fgColor = "#0096d1"
	, bgColor = "#000000"
	, bgHLight    = "#000000"
	, fgHLight    = "#FF0000"
	, position = Top
        , historySize = 512
        , showCompletionOnTab = True
        , historyFilter = deleteConsecutive
    }



--LayoutHook
myLayoutHook  =  onWorkspace "1:chat" imLayout $  onWorkspace "2:mail" webL $ onWorkspace "6:VM" fullL $ onWorkspace "8:vid" fullL  $ standardLayouts 
   where
	standardLayouts =   avoidStruts  $ (tiled |||  reflectTiled ||| Mirror tiled ||| Grid ||| Full) 

        --Layouts
	tiled     = smartBorders (ResizableTall 1 (2/100) (1/2) [])
        reflectTiled = (reflectHoriz tiled)
	full 	  = noBorders Full

        --Im Layout
	--Show pidgin tiled left and skype right
        imLayout = avoidStruts $ smartBorders $ withIM ratio pidginRoster $ reflectHoriz $ withIM skypeRatio skypeRoster (tiled ||| reflectTiled ||| Grid) where
                chatLayout      = Grid
	        ratio = (1%9)
                skypeRatio = (1%8)
                pidginRoster    = And (ClassName "Pidgin") (Role "buddy_list")
                skypeRoster  = (ClassName "Skype")     `And`
                               (Not (Title "Options")) `And`
                                              (Not (Role "Chats"))    `And`
                                                             (Not (Role "CallWindowForm"))
	--Weblayout
	webL      = avoidStruts $  full ||| tiled ||| reflectHoriz tiled  

        --VirtualLayout
        fullL = avoidStruts $ full



-------------------------------------------------------------------------------
---- Terminal --
myTerminal :: String
myTerminal = "termite"


-------------------------------------------------------------------------------
-- Keys/Button bindings --
-- modmask
myModMask :: KeyMask
myModMask = mod4Mask


-- borders
myBorderWidth :: Dimension
myBorderWidth = 1
myNormalBorderColor, myFocusedBorderColor :: String
myNormalBorderColor = "#333333"
myFocusedBorderColor = "#306EFF"

--Workspaces
myWorkspaces :: [WorkspaceId]
myWorkspaces = ["1:chat", "2:mail", "3:code", "4:pdf", "5:doc", "6:vm" ,"7:games", "8:vid", "9:gimp","10:spotify"] 


-- keys
myKeys :: XConfig Layout -> M.Map (KeyMask, KeySym) (X ())
myKeys conf@(XConfig {XMonad.modMask = modMask}) = M.fromList $
    -- killing programs
    [ ((modMask, xK_Return), spawn $ XMonad.terminal conf)
    , ((modMask .|. shiftMask, xK_c ), kill)

    -- opening program launcher / search engine
    ,((modMask , xK_p), shellPrompt myXPConfig)
    
    -- GridSelect
    , ((modMask, xK_g), goToSelected defaultGSConfig)

    -- layouts
    , ((modMask, xK_space ), sendMessage NextLayout)
    , ((modMask .|. shiftMask, xK_space ), setLayout $ XMonad.layoutHook conf)
    , ((modMask, xK_b ), sendMessage ToggleStruts)
 
    -- floating layer stuff
    , ((modMask, xK_t ), withFocused $ windows . W.sink)
 
    -- refresh'
    , ((modMask, xK_n ), refresh)
 
    -- focus
    , ((modMask, xK_Tab ), windows W.focusDown)
    , ((modMask, xK_j ), windows W.focusDown)
    , ((modMask, xK_k ), windows W.focusUp)
    , ((modMask, xK_m ), windows W.focusMaster)

 
    -- swapping
    , ((modMask .|. shiftMask, xK_Return), windows W.swapMaster)
    , ((modMask .|. shiftMask, xK_j ), windows W.swapDown )
    , ((modMask .|. shiftMask, xK_k ), windows W.swapUp )
 
    -- increase or decrease number of windows in the master area
    , ((modMask , xK_comma ), sendMessage (IncMasterN 1))
    , ((modMask , xK_period), sendMessage (IncMasterN (-1)))
 
    -- resizing
    , ((modMask, xK_h ), sendMessage Shrink)
    , ((modMask, xK_l ), sendMessage Expand)
    , ((modMask .|. shiftMask, xK_h ), sendMessage MirrorShrink)
    , ((modMask .|. shiftMask, xK_l ), sendMessage MirrorExpand)

    -- xscreensaver
    , ((modMask .|.  mod1Mask, xK_l ), spawn "xscreensaver-command --lock")
    --Spotify
    , ((modMask, xK_a), spawn "dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous")
    , ((modMask, xK_s), spawn "dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause")
    , ((modMask, xK_d), spawn "dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next")
    , ((0 			, 0x1008ff16 ), spawn "dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous")
    , ((0 			, 0x1008ff14 ), spawn "dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause")
    , ((0 			, 0x1008ff17 ), spawn "dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next")

    --Launching programs
    , ((0 			, 0x1008ff19 ), runOrRaise "thunderbird" (className =? "Lanikai"))
    , ((0 			, 0x1008ff18 ), runOrRaise "aurora" (className =? "Aurora"))
    , ((0 			, 0x1008ff1b ), runOrRaise "pidgin" (className =? "Pidgin"))

    -- volume control
    , ((0 			, 0x1008ff13 ), spawn "ponymix increase 1")
    , ((0 			, 0x1008ff11 ), spawn "ponymix decrease 1")
    , ((0 			, 0x1008ff12 ), spawn "ponymix toggle")

    -- brightness control
    --, ((0 			, 0x1008ff03 ), spawn "xcalib -co 50 -a")
    --, ((0 			, 0x1008ff02 ), spawn "xcalib -c -a")

    -- toggle trackpad
    , ((modMask .|. shiftMask, xK_t ), spawn "synclient TouchpadOff=$(synclient -l | grep -c 'TouchpadOff.*=.*0')")

    -- toggle flash video script
    , ((modMask .|. shiftMask, xK_f ), spawn "/home/jelle/bin/flashvideo")

    -- quit, or restart
    , ((modMask .|. shiftMask, xK_q ), io (exitWith ExitSuccess))
    , ((modMask , xK_q ), restart "xmonad" True)
    ]
    ++
    -- mod-[1..9] %! Switch to workspace N
    -- mod-shift-[1..9] %! Move client to workspace N
    [((m .|. modMask, k), windows $ f i)
        | (i, k) <- zip (XMonad.workspaces conf) ([xK_1 .. xK_9] ++ [xK_0])
        , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]
    ++
    -- mod-[w,e] %! switch to twinview screen 1/2
    -- mod-shift-[w,e] %! move window to screen 1/2
    [((m .|. modMask, key), screenWorkspace sc >>= flip whenJust (windows . f))
        | (key, sc) <- zip [xK_e, xK_w, xK_r] [0..]
        , (f, m) <- [(W.view, 0), (W.shift, shiftMask)]]

