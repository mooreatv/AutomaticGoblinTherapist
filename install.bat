for %%x in (_retail_ _classic_ _classic_era_) do (
echo Installing for %%x
xcopy /i /y AutomaticGoblinTherapist\*.* "C:\Program Files (x86)\World of Warcraft\%%x\Interface\Addons\AutomaticGoblinTherapist"
)
