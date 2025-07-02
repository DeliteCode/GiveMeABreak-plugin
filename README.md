# GiveMeABreak-plugin
A plugin to shift bot account turns, according to his config

giveMeABreak allows you to automatically switch your OpenKore config.txt for another config file at specific times (shifts/turnos), based on your schedule — for example, different bot behaviors overnight or during events.
It does this in-place, making a backup of your main config and replacing it with a file you specify, all without relying on File::Copy (so it works on Windows and Linux).