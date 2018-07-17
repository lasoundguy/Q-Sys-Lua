--page Turn 422 lines by colbertd
--[[ this script takes the pages in the commissioning tool and provides a method of stepping forward and backward throught them.  You have to put the page names in manually ]]
 
--[[ block quoting this out to test for character length 
-- LINKS TO OTHER BLOCKS ______________________________________________________________________________________________________________________________________________________
LecternIO = Component.New ("CommLecternIO")
Mains = Component.New("CommLoudspeakerDriveMains")
Subs = Component.New("CommLoudspeakerDriveSubs")
Ceiling1 = Component.New("CommLoudspeakerDriveCeiling1")
Ceiling2 = Component.New("CommLoudspeakerDriveCeiling2")
Ceiling3 = Component.New("CommLoudspeakerDriveCeiling3")
Ceiling4 = Component.New("CommLoudspeakerDriveCeiling4")
Ceiling5 = Component.New("CommLoudspeakerDriveCeiling5")
UCI = Component.New("CommUCI")
GAVCS = Component.New ("GAVCS Communication Script")
 
 
 
-- GLOBAL VARIABLES ___________________________________________________________________________________________________________________________________________________________
PageNameList = {} -- array that stores the page names (in the order you want them to be recalled in
PageUseList = {} -- array that stores true or false values for the pages you
PagesInOrder = {} -- array that stores the pages used in order
PageCount = 0 -- stores the total number of pages for the progress bar
PageCurrent = 1 -- varriable that stores the current page position 
 
Step00 = 0 -- step completion counter 0 for not done 1 for done -- used by a while wait
Step0 = 0 -- step completion counter 0 for not done 1 for done -- used by a while wait
Step1 = 0 -- step completion counter 0 for not done 1 for done -- used by a while wait
Step2 = 0 -- step completion counter 0 for not done 1 for done -- used by a while wait
Step3 = 0 -- step completion counter 0 for not done 1 for done -- used by a while wait
 
STARTINGPAGE = 4 --This is the page where you will calculate the page order currently this is the set IO hardware page which is the 4th page that starts with the mame "step"
 
LoginTimerCounter = 0 -- this holds the number of seconds that the username had been in use.  Gets reset to 0 every time there is a page change.
 
-- TIMERS ______________________________________________________________________________________________________________________________________________________________________
 
LogInTimer = Timer.New ()
 
 
-- DEFAULT VALUES _________________________________________________________________________________________________________________________________________________________________
 
Controls.UserError.String = "" --sets the user error string to nothing at the start
Controls.UserName.String = "" -- clear user name on startup
Controls.UserOrg.String = "" -- clear the user org on startup
 
-- FUNCTIONS ______________________________________________________________________________________________________________________________________________________________________
 
-- User Connection functions ------------------------------------------------------------------------------------------------------------------------------------------------------
 
function LogOnPageSelection () -- this function selects which page you go to when you logon.
  if GAVCS["CommissioningInProgress"].Boolean == true and LoginTimerCounter < 3600 then
    Log.Message ("Commissioning Tool: GAVCS Flag indicates that commissioning is in progress going to Table of Contents page")
    UCI["current.page"].String = "Table of Contents"
  elseif LoginTimerCounter > Controls.TimeOutUser.Value then
    Log.Message ("Commissioning Tool: commissioning User has not changed page in more then " ..math.floor(LoginTimerCounter / 60) .." min. going to landing page to verify user")
    Log.Message ("Commissioning Tool: Clearing User Name and Org fields")
    Controls.UserName.String = ""
    Controls.UserOrg.String = ""
    Controls.UserError.String = "" -- clear the error field on the landing page when user first gets there
  else
    Log.Message ("Commissioning Tool: GAVCS Flag indicates that commissioning is not in progress going to Landing page")
    UCI["current.page"].String = "Landing Page"
    Controls.UserError.String = "" -- clear the error field on the landing page when user first gets there
  end
end
 
-- Username set functions --------------------------------------------------------------------------------------------------------------------------------------------------------
 
function UserNameSetFunction () -- this function is ttriggered by the set suername button on the landing page
  if string.len (Controls.UserName.String) == 0 or string.len (Controls.UserOrg.String) == 0 then
    Controls.UserError.String = "Please enter a Name and Organization"
    print ("no entry in user or org")
  else
    Log.Message ("Commissioning Tool: " ..Controls.UserName.String .." from " ..Controls.UserOrg.String .." is commissioning the system")
    LoginTimerCounter = 0
    LogInTimer:Start (1)
    Uci.SetLayerVisibility("Commissioning", "Landing Page", "NextButton", true, "fade" )
  end
end
 
function LogInTimerFunction () -- this is the funciton called by the timer that counts up from the longon time
  LoginTimerCounter = LoginTimerCounter + 1 -- incriment the counter
  if LoginTimerCounter > Controls.TimeOutPage.Value then -- if the time is bigger than the timeout period
    Log.Message ("Commissioining Tool: The commissioning tool has been on the same page for over " ..(math.floor(LoginTimerCounter/60)) .." min. Logging off user")
    UCI["logoff"].Value = 1
    LogInTimer:Stop()
  end
  Controls.LogInTimerDisplay[1].String = math.floor(LoginTimerCounter / 60) -- show the minutes
  Controls.LogInTimerDisplay[2].String = math.fmod(LoginTimerCounter, 60)  -- show the seconds
end
 
-- Table of contents funcitons ---------------------------------------------------------------------------------------------------------------------------------------------------
 

 
LogInTimer.EventHandler = LogInTimerFunction
]]

Controls.result.String = "this is version 3--page turn"