# GiveMeABreak-plugin
A plugin to shift bot account turns, according to his config

giveMeABreak allows you to automatically switch your OpenKore config.txt for another config file at specific times (shifts/turnos), based on your schedule — for example, different bot behaviors overnight or during events.
It does this in-place, making a backup of your main config and replacing it with a file you specify, all without relying on File::Copy (so it works on Windows and Linux).

Add these variables to your main config.txt (the one loaded at OpenKore startup):
# Enable or disable the plugin
give_me_a_break 1

# Define shift(s). All files must be in the same folder as your current config.txt!
giveMeABreak_1_start 19:00
giveMeABreak_1_end   02:30
giveMeABreak_1_load  config_night.txt

giveMeABreak_2_start 02:31
giveMeABreak_2_end   18:00
giveMeABreak_2_load  config_day.txt

# Add more shifts as needed (just increment the number).
