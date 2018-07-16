--page Turn 422 lines by colbertd
--[[ this script takes the pages in the commissioning tool and provides a method of stepping forward and backward throught them.  You have to put the page names in manually ]]
 
 
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
 
 
 
-- GLOBAL VARRIABLES ___________________________________________________________________________________________________________________________________________________________
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
 
function TocPageJumpButtonsSetUpEventHandlers () -- setup the event handlers for the TOC page jump buttons
  for i = 1, 39 do 
    Controls.TocGoToPage[i].EventHandler = function ()
      PageCurrent = i -- go to the number of the button
      --print (PageCurrent)
      UCI["current.page"].String = PagesInOrder[PageCurrent] -- move the UCI to that page
      Controls.PageNameDisplay.String = PagesInOrder[PageCurrent] -- make the UI show the name of page you are on
      Controls.PagePlace.String = PageCurrent -- make the UI show the number of page you are on
      Controls.Progress.Value = ProgressMeterCalc () -- make the UI show progress
      Controls.ProgressWords.String = ("Step " ..PageCurrent .." of " ..PageCount)
    end
  end
end
 
function TocFillInNames () -- strip the Step # text off the commissiong page names and then put them in the page name display fields
  for k, v in ipairs (PagesInOrder) do
    for title in string.gmatch(v, " %- %a.*") do output = title end
    Controls.TocPageNames[k].String = (string.match (output ,".*", 4))
  end
end
 
--Previous / Next Navigation funcitons --------------------------------------------------------------------------------------------------------------------------------------------
function ResetSetSteps () -- reset the step counters at the beginning of the SetOrderSequence function 
  print ("resetting step finished flags")
  Step00 = 0
  Step0 = 0
  Step1 = 0
  Step2 = 0
  Step3 = 0
end
 
function ClearAllValues ()
  print ("Clearing all values " ..Step00)
  PageUseList = {nil}
  --print (PageUseList[1])
  PageNameList = {nil}
  --print (PageNameList[1])
  PagesInOrder = {nil}
  --print (PagesInOrder[1])
  for  i = 1, 39 do
    Controls.TocPageNames[i].String = ""
  end
  Step00 = 1
  print ("All values cleared " ..Step00)
end
 
function MakePageNameListFunction () -- fill the page name list with the page names gets these from the UCI object. This is the first step in SetOrderSequence
  print ("Starting makeing page name list " ..Step0)
  for k, v in ipairs(UCI["current.page"].Choices) do
    if string.match (v, "Step %d+") then -- only pages that begin "Step #" get used in the page name list
      --print (v)
      PageNameList[k] = v
        else
      print (v .. " -- this is not a step, not including it in the page name list") -- print the non matched names for error checking
    end
  end
  Step0 = 1 --mark this step as done
  print (Step0 .." page name list Set")
end
 
function SetPageUseage () -- function that checks if the page is used and then marks it as true or false.  REMEMBER TO ADD PAGES HERE AS YOU ADD THEM TO THE COMMISSIOINING TOOL  This is the first step in SetOrderSequence
  print ("Starting determining page use " ..Step1)
  PageUseList[1] = true --"Step 1a - Commissioning Type"
  PageUseList[2] = true --"Step 1b - reset values"
  PageUseList[3] = true --"Step 2a - Select Standard Type"
  PageUseList[4] = true --"Step 2b-j - Select IO Hardware"
  PageUseList[5] = true --"Step 2k - Select Loudspeaker Type"
  PageUseList[6] = true --"Step 3a-s - Describe Room"
  if LecternIO["CommLecternIO 1"].Boolean == true then
    PageUseList[7] = true --"Step 4a(ii) - Configure AES67 Lectern Mics"
    PageUseList[8] = true --"Step 4a(iii) - Configure AES67 Lectern 3.5mm TRS input"
    PageUseList[9] = true --"Step 4a(iv) - Configure AES67 ALS Output"
  else
    PageUseList[7] = false --"Step 4a(ii) - Configure AES67 Lectern Mics"
    PageUseList[8] = false --"Step 4a(iii) - Configure AES67 Lectern 3.5mm TRS input"
    PageUseList[9] = false --"Step 4a(iv) - Configure AES67 ALS Output"
  end
  PageUseList[10] = true --"Step 4b - Configure Wireless Microphone Controls"
  PageUseList[11] = true --"Step 4b(v) - Configure Wireless Microphone AES67 Input"
  PageUseList[12] = true --"Step 4c - Configure Wireless Beltpack AES67 Output"
  PageUseList[13] = true --"Step 4d-e - Configure HDMI inputs"
  PageUseList[14] = true --"Step 5a - Output Gain Staging Warning"
  PageUseList[15] = true --"Step 5a - Are you sure?"
  PageUseList[16] = true --"Step 5d(i) - Level Set Main Left Loudspeaker"
  PageUseList[17] = true --"Step 5d(ii) - Level Set Main Right Loudspeaker"
  if Subs["CommLoudspeakerDriveSubs 1"].Boolean == true then
    PageUseList[18] = false --"Step 5d(iv) - Level Set Subwoofer"
  else
    PageUseList[18] = true --"Step 5d(iv) - Level Set Subwoofer"
  end
  if Ceiling1["CommLoudspeakerDriveCeiling1 1"].Boolean == true then
    PageUseList[19] = false --"Step 5e(i) - Level Set Ceiling Row 1"
  else
    PageUseList[19] = true --"Step 5e(i) - Level Set Ceiling Row 1"
  end
  if Ceiling2["CommLoudspeakerDriveCeiling2 1"].Boolean == true then
    PageUseList[20] = false --"Step 5e(ii) - Level Set Ceiling Row 2"
  else
    PageUseList[20] = true --"Step 5e(ii) - Level Set Ceiling Row 2"
  end
  if Ceiling3["CommLoudspeakerDriveCeiling3 1"].Boolean == true then
    PageUseList[21] = false --"Step 5e(iii) - Level Set Ceiling Row 3"
  else
    PageUseList[21] = true --"Step 5e(iii) - Level Set Ceiling Row 3"
  end
  if Ceiling4["CommLoudspeakerDriveCeiling4 1"].Boolean == true then
    PageUseList[22] = false --"Step 5e(iv) - Level Set Ceiling Row 4"
  else
    PageUseList[22] = true --"Step 5e(iv) - Level Set Ceiling Row 4"
  end
  if Ceiling5["CommLoudspeakerDriveCeiling5 1"].Boolean == true then
    PageUseList[23] = false --"Step 5e(v) - Level Set Ceiling Row 5"
  else
    PageUseList[23] = true --"Step 5e(v) - Level Set Ceiling Row 5"
  end
  PageUseList[24] = true --"Step 5f(i) - Verify Gain Taper and Delay Settings"
  PageUseList[25] = true --"Step 6a - Warning outputs muted"
  PageUseList[26] = true --"Step 6b - Test Lectern Microphone"
  PageUseList[27] = true --"Step 6c - Calibrate Lectern TRS MiniJack Input"
  PageUseList[28] = true --"Step 6d - Test GVC input"
  PageUseList[29] = true --"Step 6e - Test Wireless Microphone inputs"
  PageUseList[30] = true --"Step 6f - Test Audience Microphone Inputs"
  PageUseList[31] = true --"Step 7a - TestDigital IO"
  PageUseList[32] = true --"Step 7b(i)1 - Warning Making Noise Again"
  PageUseList[33] = true --"Step 7b - TestDigital IO Outputs"
  PageUseList[34] = true --"Step 8a - Warning Noise Once More Again"
  PageUseList[35] = true --"Step 8b - Lectern to left and right"
  PageUseList[36] = true --"Step 8c - Gain Stage Lectern Mics"
  PageUseList[37] = true --"Step 9a - Configure AEC Reference Level Warning"
  PageUseList[38] = true --"Step 9c - Configure AEC Reference Level"
  PageUseList[39] = true --"Step 10 - Done"
  Step1 = 1
  print (Step1 .." Page Use Set")
end
 
function PrintOutput () -- print function for debug
  print ("list start")
  print (PageNameList[1], PageNameList[2], PageNameList[3], PageNameList[4], PageNameList[5], PageNameList[6], PageNameList[7], PageNameList[8], PageNameList[9], PageNameList[10])
  print (PageNameList[11], PageNameList[12], PageNameList[13], PageNameList[14], PageNameList[15], PageNameList[16], PageNameList[17], PageNameList[18], PageNameList[19], PageNameList[20])
  print (PageNameList[21], PageNameList[22], PageNameList[23], PageNameList[24], PageNameList[25], PageNameList[26], PageNameList[27], PageNameList[28], PageNameList[29], PageNameList[30])
  print (PageNameList[31], PageNameList[32], PageNameList[33], PageNameList[34], PageNameList[35], PageNameList[36], PageNameList[37], PageNameList[38], PageNameList[39])
  --Log.Message (PageNameList[1], PageNameList[2], PageNameList[3], PageNameList[4], PageNameList[5], PageNameList[6], PageNameList[7], PageNameList[8], PageNameList[9], PageNameList[10])
  --Log.Message (PageNameList[11], PageNameList[12], PageNameList[13], PageNameList[14], PageNameList[15], PageNameList[16], PageNameList[17], PageNameList[18], PageNameList[19], PageNameList[20])
  --Log.Message (PageNameList[21], PageNameList[22], PageNameList[23], PageNameList[24], PageNameList[25], PageNameList[26], PageNameList[27], PageNameList[28], PageNameList[29], PageNameList[30])
  --Log.Message (PageNameList[31], PageNameList[32], PageNameList[33], PageNameList[34], PageNameList[35], PageNameList[36], PageNameList[37], PageNameList[38], PageNameList[39])
  for key, value in ipairs(PagesInOrder) do
    print(key, value)
    --Log.Message (key, value)
  end
  print ("list end")
end
 
function CountPages () -- count the number of pages bases on the number of entries in PageUseList This is the second step in SetOrderSequence
  print ("Starting page count " ..Step2)
  PageCount = 0 --reset count
  for i, v in ipairs (PageUseList) do
    if v == true then
      PageCount = PageCount + 1
    end
  end
  Step2 = 1
  print (Step2 .." Page Count = " ..PageCount)
end
 
function MakePageListInOrder ()  -- go throught the PageNameList and if PageUseList shows the value as true include the page in the PagesInOrder array This is the third step in SetOrderSequence
  print ("Starting building page list in order " ..Step3)
  for i, v in ipairs (PageNameList) do
    --print (i)
    if PageUseList[i] == true then
      table.insert(PagesInOrder, v)
    end
  end
  Step3 = 1
  print (Step3 .." Page list in order done")
end
 
function SetOrderSequence () -- function that performs all the set up functions
  Log.Message ("Commissioning Tool: Creating Page Order")
  ResetSetSteps ()
  ClearAllValues ()
  while (Step00 == 0) do
    print ("waiting for function ClearAllValues to finish")
  end
  MakePageNameListFunction ()
  while (Step0 == 0) do
    print ("waiting for function MakePageNameListFunction to finish")
  end
  SetPageUseage ()
  while (Step1 == 0) do
    print ("waiting for function SetPageUseage to finish")
  end
  CountPages ()
  while (Step2 == 0) do
    print ("waiting for function CountPages to finish")
  end
  MakePageListInOrder ()
  while (Step3 == 0) do
    print ("waiting for function MakePageListInOrder to finish")
  end
  --PrintOutput ()
  TocPageJumpButtonsSetUpEventHandlers () -- set up the event handlers for the buttons on the TOC page
  TocFillInNames () -- fill in the names on the TOC page
  PageCurrent = STARTINGPAGE -- set the page current to the starting page 
  Controls.PagePlace.String = STARTINGPAGE -- make the UI display match the varriable
  Controls.Progress.Value = ProgressMeterCalc () -- make the UI show progress
  Controls.ProgressWords.String = ("Step " ..PageCurrent .." of " ..PageCount)
end
 
function ProgressMeterCalc () -- this is a bit of math that does some scaling so that the meter object used as a progress bar works right. 
  return ((PageCurrent * (80 / PageCount)) - 61) -- there are 80 dB that show on the meter so we devide that by the PageCount to make the increment of indication.  Then we multiply that by the current page to get the amount of progress.  Finally we subtract 61 because the lowest value we see is -60 on the meter.
end
 
function PreviousPageFunction () -- this is the previous page function
  if PageCurrent <= 1 then -- don't go below page 1
    print ("Error: Can't go below page 1")
  else
    PageCurrent = PageCurrent - 1 -- go down one number form where you are
    --print (PageCurrent)
    UCI["current.page"].String = PagesInOrder[PageCurrent] -- move the UCI to that page
    Controls.PageNameDisplay.String = PagesInOrder[PageCurrent] -- make the UI show the name of page you are on
    Controls.PagePlace.String = PageCurrent -- make the UI show the number of page you are on
    Controls.Progress.Value = ProgressMeterCalc () -- make the UI show progress
    Controls.ProgressWords.String = ("Step " ..PageCurrent .." of " ..PageCount)
  end
end
 
function NextPageFunction () -- this is the next page funciton
  if PageCurrent >= PageCount then -- don't go above the number of page we have 
    print ("Error: Can't go above page " ..PageCount)
  else
    PageCurrent = PageCurrent + 1  -- go up one number form where you are
    print (PagesInOrder[PageCurrent])
    UCI["current.page"].String = PagesInOrder[PageCurrent] -- move the UCI to that page
    Controls.PageNameDisplay.String = PagesInOrder[PageCurrent] -- make the UI show the name of page you are on
    Controls.PagePlace.String = PageCurrent -- make the UI show the number of page you are on
    Controls.Progress.Value = ProgressMeterCalc () -- make the UI show progress
    Controls.ProgressWords.String = ("Step " ..PageCurrent .." of " ..PageCount)
  end
end
 
function ClearStepStartandStepCompleteOnPageChange () --Clear Step Start and Step Complete On PageChange -- function called on every page change to uncheck these boxes
  Controls.StepStart.Boolean = false
  Controls.StepComplete.Boolean = false
end
 
-- EVENT HANDLERS ______________________________________________________________________________________________________________________________________________________________________________________
 
UCI["current.page"].EventHandler = function (page) -- every time the page changes set the page action start stop buttons to false so that the user has to enable the actions
  ClearStepStartandStepCompleteOnPageChange ()
  Log.Message ("Commissioning Tool: Page Changed to: " ..UCI["current.page"].String .." User was on the previous page for " ..LoginTimerCounter .." seconds.")
  LoginTimerCounter = 0 -- reset the timer counter you can spen an hour on each page till this thing timesout
end
 
UCI["status"].EventHandler = function (ctl) -- watch the status of the commissioning UCI and run the logon page choice function when the user connects (indicated by position going to 0.0)
  if ctl.Position == 0.0 then
    Log.Message ("Commissioning Tool: UCI Log On Detected")
    Log.Message ("Commissioning Tool: User page timeout is: " ..Controls.TimeOutPage.Value .." User name timeout is: " ..Controls.TimeOutUser.Value .." (times in seconds)")
    print ("Commissioning Tool: UCI Log On Detected")
    print (Controls.TimeOutPage.Value)
    print (Controls.TimeOutUser.Value)
    LogOnPageSelection ()
  else
  LogInTimer:Stop() -- stop the log in timer
  end
end
 
Controls.PageButtonsLandingPage.EventHandler = function () -- The event handler for the next button on the landing page.
  -- button 1 = next
  if GAVCS["CommissioinedStatus"].Boolean == true then
    UCI["current.page"].String = "Already Commissioned Warning" -- if the system has been commissioned go to the table of contents page
  elseif GAVCS["CommissioningInProgress"].Boolean == false then
    UCI["current.page"].String = "Step 1a - Commissioning Type" -- if the system hasn't been commissioned and the the commissioning has not started go the select commissioning type page 
  else
    UCI["current.page"].String = "Table of Contents" -- if the system hasn't been commissioined and the process has started go to the table of contents
  end
end
 
Controls.PageButtonsAlreadyCommWarn[1].EventHandler = function ()
  -- button 1 = exit
  Log.Message ("Commissioning Tool: User initiated Log Off")
  UCI["logoff"].Value = 1
  -- button 2 = recommission system
  -- button 3 = adjust settings
  -- button 4 = table of contents
end
 
Controls.PageButtonsAlreadyCommWarn[2].EventHandler = function ()
  -- button 1 = exit
  -- button 2 = recommission system
  UCI["current.page"].String = "Step 1a - Commissioning Type"
  -- button 3 = adjust settings
  -- button 4 = table of contents
end
 
Controls.PageButtonsAlreadyCommWarn[3].EventHandler = function ()
  -- button 1 = exit
  -- button 2 = recommission system
  -- button 3 = adjust settings
  UCI["current.page"].String = "Adjust Settings 1 - Index Page"
  -- button 4 = table of contents
end
 
Controls.PageButtonsAlreadyCommWarn[4].EventHandler = function ()
  -- button 1 = exit
  -- button 2 = recommission system
  -- button 3 = adjust settings
  -- button 4 = table of contents
  UCI["current.page"].String = "Table of Contents"
end
 
Controls.SetUserName.EventHandler = function ()
  UserNameSetFunction ()
end
 
Controls.SetOrder.EventHandler = function ()
  SetOrderSequence ()
end
 
Controls.Previous.EventHandler = function ()
  PreviousPageFunction ()
end
 
Controls.Next.EventHandler = function ()
  NextPageFunction ()
end
 
-- TIMER EVENT HANDLERS ___________________________________________________________________________________________________________________________________________________________________________________
 
LogInTimer.EventHandler = LogInTimerFunction
Remember, everything here is CONFIDENTIAL unless specifically stated otherwise.

© 2014 Google Inc. All Rights Reserved.