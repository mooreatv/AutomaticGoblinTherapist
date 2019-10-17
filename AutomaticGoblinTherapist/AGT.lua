--[[
-------------------------------------------------------------------------------------------------------------
AGT - Automatic Goblin Therapist
by Duugu (EU - Die silberne Hand - Horde)
-------------------------------------------------------------------------------------------------------------

1.5.0
- Code import to https://github.com/mooreatv/AutomaticGoblinTherapist
- Auto packaging for retail and classic

1.4.5
- Code cleanup

1.4.4
- PlaySoundFile bug fixed. Ty MooreaTv

1.4.3
- Updated to 80200
- SetScale bug fixed

1.4.2
- Addon updated to 80100
- Some xml bugs fixed

1.4.1
- Updated the addon to 60000.
- Fixed a bug with the new whisper/ignore sound options.

1.4.0
- Updated the addon to 54000.

1.3.2
- Slightly changed the phrase recognition mechanics
- toc updated to 30000

1.3.1
- Bugfix: Minimap Button Frame not longer breaks the addon

1.3
- 3.0 changes
- Bug: Malformed pattern bug fixed

1.2.3
- removed some overlooked debug code :D

1.2.2
- Fixed a bug with the "guild pass trough" option
- added a "quote" option.
  AGT replies to whispers without recognized keywords with neutral phrases like "I see" or "I'm not sure I understand\nyou fully".
  The quote option is to add more variety to these kind of replies. The option forces AGT to reply to x percent of the incoming
  whispers without a keyword with a "best fit" quote out of a list approx. 850 predefinied quotes.
  If you set the option to 100% AGT answeres every whisper without a listed keywords with a quote.
  If you set the option to 0% AGT don't replies with quotes.
  A good value for this option could be "20%", where AGT replies with a quote to 20% of all whispers without a keyword.

1.2.1
- Added a "Pass Through Guild" option. AGT will not reply to characters from your guild.

1.2
- Added "Greet" option
- Added "Edit Library" option
- AGT will not longer answers if there are multiple responses available
- AGT will only reply to the keywords "what, who, where, when, or why" with a question if the whisper was a question (ends with ?)
- Fixed a bug with malformed patterns and unfinished captures.
- Added a "Pass Through Friends" option. AGT will not reply to characters from your friends list.

1.1
- Added options (accessible via the blizzard interface menu)

1.0
- Inital version
-------------------------------------------------------------------------------------------------------------

Ever had an annoying conversation with one of these morons who couldn't shut up?
A brainsick lvl 1 orc asks you every few minutes for some gold?
Whispers with "r u healer?" over and over again?

From now on your personal Automatic Goblin Therapist will do the job for you.
He will do the full conversation for you - guarding your back AND doing all the treatment.

Every character who whispers you is added to the Waiting Room.
A left click on a character in the Waiting Room moves it to Surgery where the last whisper
and all further whispers are automatically answered by your diligent Goblin Therapist.
A second left click will move the character back to the Waiting Room.
A right click kicks the character out of Surgery or Waiting Room and opens a seat for new patients.

- Surgery or not ... the Goblin Therapist will not automatically respond to any whispers if you are afk or dnd.
- Furthermore the Goblin Therapist will inform you if the patient ignores you.
- Characters will be automatically removed from the Surgery and the Waiting Room after 5 minutes without any new whispers.
- The Goblin Therapist is able to handle up to five patients simultaneously.


Credits
- ELIZA is a computer program by Joseph Weizenbaum, designed in 1966, which parodied a Rogerian therapist,
largely by rephrasing many of the patient's statements as questions and posing them to the patient.
http://en.wikipedia.org/wiki/ELIZA
- I took lot of the source code from Michal Wallace's and George Dunlop's JavaScript implementation
of ELIZA (http://www.manifestation.com/neurotoys/eliza.php3) and ported it to lua.

-------------------------------------------------------------------------------------------------------------
--]] -- probably should move all those globals into AGT. instead
AGTtocVersion = select(4, GetBuildInfo()) -- TODO replace by is classic vs not, or remove entirely

local AGTelapsedUpdate = 0
local AGTNotFoundKey = 1
local AGTRepeatKey = 2
local AGTmaxConj = 18
local AGTmax2ndConj = 6
local AGTPatients = {}
local AGTSendQueue = {}
AGTkeyword = {
  [1] = {
    key = "**NO KEY FOUND** DO NOT TOUCH THIS KEY",
    Responses = {106, 107, 108, 109, 110, 111, 112, 129, 130, 131, 132},
    Selected = false,
    Q = false
  },
  [2] = {
    key = "**REPEAT WHISPER** DO NOT TOUCH THIS KEY",
    Responses = {113, 114, 115, 116, 117},
    Selected = false,
    Q = false
  },
  [3] = {key = "YOU'RE", Responses = {6, 7, 8, 9}, Selected = false, Q = false},
  [4] = {key = "I DON'T", Responses = {10, 11, 12, 13}, Selected = false, Q = false},
  [5] = {key = "I FEEL", Responses = {14, 15, 16}, Selected = false, Q = false},
  [6] = {key = "WHY DON'T YOU", Responses = {17, 18, 19}, Selected = false, Q = false},
  [7] = {key = "WHY CAN'T I", Responses = {20, 21}, Selected = false, Q = false},
  [8] = {key = "ARE YOU", Responses = {22, 23, 24}, Selected = false, Q = false},
  [9] = {key = "I CAN'T", Responses = {25, 26, 27}, Selected = false, Q = false},
  [10] = {key = "I AM", Responses = {28, 29, 30, 31}, Selected = false, Q = false},
  [11] = {key = "I'M", Responses = {28, 29, 30, 31}, Selected = false, Q = false},
  [12] = {key = "YOU", Responses = {32, 33, 34}, Selected = false, Q = false},
  [13] = {key = "I WANT", Responses = {35, 36, 37, 38, 39}, Selected = false, Q = false},
  [14] = {key = "WHAT", Responses = {40, 41, 42, 43, 44, 45, 46, 47, 48}, Selected = false, Q = true},
  [15] = {key = "HOW", Responses = {40, 41, 42, 43, 44, 45, 46, 47, 48}, Selected = false, Q = true},
  [16] = {key = "WHO", Responses = {40, 41, 42, 43, 44, 45, 46, 47, 48}, Selected = false, Q = true},
  [17] = {key = "WHERE", Responses = {40, 41, 42, 43, 44, 45, 46, 47, 48}, Selected = false, Q = true},
  [18] = {key = "WHEN", Responses = {40, 41, 42, 43, 44, 45, 46, 47, 48}, Selected = false, Q = true},
  [19] = {key = "WHY", Responses = {40, 41, 42, 43, 44, 45, 46, 47, 48}, Selected = false, Q = true},
  [20] = {key = "NAME", Responses = {49, 50}, Selected = false, Q = false},
  [21] = {key = "CAUSE", Responses = {51, 52, 53, 54}, Selected = false, Q = false},
  [22] = {key = "SORRY", Responses = {55, 56, 57, 58}, Selected = false, Q = false},
  [23] = {key = "DREAM", Responses = {59, 60, 61, 62}, Selected = false, Q = false},
  [24] = {key = "HELLO", Responses = {63}, Selected = false, Q = false},
  [25] = {key = "HI", Responses = {63}, Selected = false, Q = false},
  [26] = {key = "MAYBE", Responses = {64, 65, 66, 67, 68}, Selected = false, Q = false},
  [27] = {key = "NO", Responses = {69, 70, 71, 72, 73}, Selected = false, Q = false},
  [28] = {key = "YOUR", Responses = {74, 75}, Selected = false, Q = false},
  [29] = {key = "ALWAYS", Responses = {76, 77, 78, 79}, Selected = false, Q = false},
  [30] = {key = "THINK", Responses = {80, 81, 82}, Selected = false, Q = false},
  [31] = {key = "ALIKE", Responses = {83, 84, 85, 86, 87, 88, 89}, Selected = false, Q = false},
  [32] = {key = "YES", Responses = {90, 91, 92}, Selected = false, Q = false},
  [33] = {key = "FRIEND", Responses = {93, 94, 95, 96, 97, 98}, Selected = false, Q = false},
  [34] = {key = "NOOB", Responses = {99, 100, 101, 102, 103, 104, 105}, Selected = false, Q = false},
  [35] = {key = "CAN I", Responses = {4, 5}, Selected = false, Q = false},
  [36] = {key = "CAN YOU", Responses = {1, 2, 3}, Selected = false, Q = false},
  [37] = {key = "YOU ARE", Responses = {6, 7, 8, 9}, Selected = false, Q = false},
  [38] = {key = "HEALER", Responses = {118, 119}, Selected = false, Q = false},
  [39] = {key = "HOLY", Responses = {118, 119}, Selected = false, Q = false},
  [40] = {key = "RESTORATION", Responses = {118, 119}, Selected = false, Q = false},
  [41] = {key = "HEAL", Responses = {118, 119}, Selected = false, Q = false},
  [42] = {key = "PORT", Responses = {40, 41, 42, 43, 44, 45, 46, 47, 48}, Selected = false, Q = false},
  [43] = {key = "PORTAL", Responses = {40, 41, 42, 43, 44, 45, 46, 47, 48}, Selected = false, Q = false},
  [44] = {key = "WATER", Responses = {40, 41, 42, 43, 44, 45, 46, 47, 48}, Selected = false, Q = false},
  [45] = {key = "FOOD", Responses = {40, 41, 42, 43, 44, 45, 46, 47, 48}, Selected = false, Q = false},
  [46] = {key = "MONEY", Responses = {40, 41, 42, 43, 44, 45, 46, 47, 48}, Selected = false, Q = false},
  [47] = {key = "GOLD", Responses = {40, 41, 42, 43, 44, 45, 46, 47, 48}, Selected = false, Q = false},
  [48] = {key = "PVP", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [49] = {key = "ARATHI", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [50] = {key = "RAGEFIRE", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [51] = {key = "ORGRIMMAR", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [52] = {key = "WAILING", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [53] = {key = "CAVERNS", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [54] = {key = "DEADMINES", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [55] = {key = "EYE", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [56] = {key = "SHADOWFANG", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [57] = {key = "CAVERNS", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [58] = {key = "STOCKADE", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [59] = {key = "RAZORFEN", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [60] = {key = "GNOMEREGAN", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [61] = {key = "MONASTERY", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [62] = {key = "ULDAMAN", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [63] = {key = "MARAUDON", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [64] = {key = "ZUL'FARRAK", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [65] = {key = "TEMPLE", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [66] = {key = "BLACKROCK", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [67] = {key = "BRD", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [68] = {key = "ALTERAC", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [69] = {key = "DIRE", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [70] = {key = "STRATHOLME", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [71] = {key = "RUINS", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [72] = {key = "AHN'QIRAJ", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [73] = {key = "SCHOLOMANCE", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [74] = {key = "SCHOLO", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [75] = {key = "HELLFIRE", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [76] = {key = "RAMPARTS", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [77] = {key = "ZUL'GURUB", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [78] = {key = "ZUL", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [79] = {key = "ZA", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [80] = {key = "ONYXIA", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [81] = {key = "BWL", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [82] = {key = "MOLTEN", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [83] = {key = "CORE", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [84] = {key = "MC", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [85] = {key = "NAXXRAMAS", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [86] = {key = "NAXX", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [87] = {key = "BLOOD FURNACE", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [88] = {key = "BLOOD", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [89] = {key = "UNDERBOG", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [90] = {key = "SLAVE", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [91] = {key = "PENS", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [92] = {key = "TOMBS", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [93] = {key = "HILLSBRAD", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [94] = {key = "AUCHENAI", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [95] = {key = "CRYPTS", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [96] = {key = "MORASS", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [97] = {key = "SHATTERED", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [98] = {key = "SETHEKK", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [99] = {key = "ARCATRAZ", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [100] = {key = "SHADOW", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [101] = {key = "SHADOW", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [102] = {key = "LABYRINTH", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [103] = {key = "BOTANICA", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [104] = {key = "MECHANAR", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [105] = {key = "TERRACE", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [106] = {key = "KARAZHAN", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [107] = {key = "KARA", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [108] = {key = "MH", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [109] = {key = "HYJAL", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [110] = {key = "STEAMVAULT", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [111] = {key = "ZUL'AMAN", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [112] = {key = "TEMPEST", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [113] = {key = "BLACK TEMPLE", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [114] = {key = "BT", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [115] = {key = "SUNWELL", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [116] = {key = "SERPENTSHRINE", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [117] = {key = "GRUUL", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [118] = {key = "WARSONG", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [119] = {key = "ARENA", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [120] = {key = "MAGTHERIDON", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [122] = {key = "LORDAERON", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [121] = {key = "MAG", Responses = {120, 121, 122, 123, 124, 125}, Selected = false, Q = false},
  [123] = {key = "GUILD", Responses = {126, 127, 128}, Selected = false, Q = false}
}
AGTresponse = {
  [1] = {Text = "Don't you believe that I can<*", Selected = false},
  [2] = {Text = "Perhaps you would like to be able to<*", Selected = false},
  [3] = {Text = "You want me to be able to<*", Selected = false},
  [4] = {Text = "Perhaps you don't want to<*", Selected = false},
  [5] = {Text = "Do you want to be able to<*", Selected = false},
  [6] = {Text = "What makes you think I am<*", Selected = false},
  [7] = {Text = "Does it please you to believe I am<*", Selected = false},
  [8] = {Text = "Perhaps you would like to be<*", Selected = false},
  [9] = {Text = "Do you sometimes wish you were<*", Selected = false},
  [10] = {Text = "Don't you really<*", Selected = false},
  [11] = {Text = "Why don't you<*", Selected = false},
  [12] = {Text = "Do you wish to be able to<*", Selected = false},
  [13] = {Text = "Does that trouble you?", Selected = false},
  [14] = {Text = "Tell me more about such feelings.", Selected = false},
  [15] = {Text = "Do you often feel<*", Selected = false},
  [16] = {Text = "Do you enjoy feeling<*", Selected = false},
  [17] = {Text = "Do you really believe I don't<*", Selected = false},
  [18] = {Text = "Perhaps in good time I will<@", Selected = false},
  [19] = {Text = "Do you want me to<*", Selected = false},
  [20] = {Text = "Do you think you should be able to<*", Selected = false},
  [21] = {Text = "Why can't you<*", Selected = false},
  [22] = {Text = "Why are you interested in whether or not I am<*", Selected = false},
  [23] = {Text = "Would you prefer if I were not<*", Selected = false},
  [24] = {Text = "Perhaps in your fantasies I am<*", Selected = false},
  [25] = {Text = "How do you know you can't<*", Selected = false},
  [26] = {Text = "Have you tried?", Selected = false},
  [27] = {Text = "Perhaps you can now<*", Selected = false},
  [28] = {Text = "Did you come to me because you are<*", Selected = false},
  [29] = {Text = "How long have you been<*", Selected = false},
  [30] = {Text = "Do you believe it is normal to be<*", Selected = false},
  [31] = {Text = "Do you enjoy being<*", Selected = false},
  [32] = {Text = "We were discussing you, not me.", Selected = false},
  [33] = {Text = "Oh... <*", Selected = false},
  [34] = {Text = "You're not really talking about me, are you?", Selected = false},
  [35] = {Text = "What would it mean to you if you got<*", Selected = false},
  [36] = {Text = "Why do you want<*", Selected = false},
  [37] = {Text = "Suppose you got<*", Selected = false},
  [38] = {Text = "What if you never got<*", Selected = false},
  [39] = {Text = "I sometimes also want<@", Selected = false},
  [40] = {Text = "Why do you ask?", Selected = false},
  [41] = {Text = "Does that question interest you?", Selected = false},
  [42] = {Text = "What answer would please you the most?", Selected = false},
  [43] = {Text = "What do you think?", Selected = false},
  [44] = {Text = "Are such questions on your mind often?", Selected = false},
  [45] = {Text = "What is it that you really want to know?", Selected = false},
  [46] = {Text = "Have you asked anyone else?", Selected = false},
  [47] = {Text = "Have you asked such questions before?", Selected = false},
  [48] = {Text = "What else comes to mind when you ask that?", Selected = false},
  [49] = {Text = "Names don't interest me.", Selected = false},
  [50] = {Text = "I don't care about names, please go on.", Selected = false},
  [51] = {Text = "Is that the real reason?", Selected = false},
  [52] = {Text = "Don't any other reasons come to mind?", Selected = false},
  [53] = {Text = "Does that reason explain anything else?", Selected = false},
  [54] = {Text = "What other reasons might there be?", Selected = false},
  [55] = {Text = "Please don't apologise!", Selected = false},
  [56] = {Text = "Apologies are not necessary.", Selected = false},
  [57] = {Text = "What feelings do you have when you apologise?", Selected = false},
  [58] = {Text = "Don't be so defensive!", Selected = false},
  [59] = {Text = "What does that dream suggest to you?", Selected = false},
  [60] = {Text = "Do you dream often?", Selected = false},
  [61] = {Text = "What persons appear in your dreams?", Selected = false},
  [62] = {Text = "Are you disturbed by your dreams?", Selected = false},
  [63] = {Text = "How are you today.. What would you like to discuss?", Selected = false},
  [64] = {Text = "You don't seem quite certain.", Selected = false},
  [65] = {Text = "Why the uncertain tone?", Selected = false},
  [66] = {Text = "Can't you be more positive?", Selected = false},
  [67] = {Text = "You aren't sure?", Selected = false},
  [68] = {Text = "Don't you know?", Selected = false},
  [69] = {Text = "Are you saying no just to be negative?", Selected = false},
  [70] = {Text = "You are being a bit negative.", Selected = false},
  [71] = {Text = "Why not?", Selected = false},
  [72] = {Text = "Are you sure?", Selected = false},
  [73] = {Text = "Why no?", Selected = false},
  [74] = {Text = "Why are you concerned about my<*", Selected = false},
  [75] = {Text = "What about your own<*", Selected = false},
  [76] = {Text = "Can you think of a specific example?", Selected = false},
  [77] = {Text = "When?", Selected = false},
  [78] = {Text = "What are you thinking of?", Selected = false},
  [79] = {Text = "Really, Selected = false,}, always?", Selected = false},
  [80] = {Text = "Do you really think so?", Selected = false},
  [81] = {Text = "But you are not sure you<*", Selected = false},
  [82] = {Text = "Do you doubt you<*", Selected = false},
  [83] = {Text = "In what way?", Selected = false},
  [84] = {Text = "What resemblence do you see?", Selected = false},
  [85] = {Text = "What does the similarity suggest to you?", Selected = false},
  [86] = {Text = "What other connections do you see?", Selected = false},
  [87] = {Text = "Could there really be some connection?", Selected = false},
  [88] = {Text = "How?", Selected = false},
  [89] = {Text = "You seem quite positive.", Selected = false},
  [90] = {Text = "Are you Sure?", Selected = false},
  [91] = {Text = "I see.", Selected = false},
  [92] = {Text = "I understand.", Selected = false},
  [93] = {Text = "Why do you bring up the topic of friends?", Selected = false},
  [94] = {Text = "Do your friends worry you?", Selected = false},
  [95] = {Text = "Do your friends pick on you?", Selected = false},
  [96] = {Text = "Are you sure you have any friends?", Selected = false},
  [97] = {Text = "Do you impose on your friends?", Selected = false},
  [98] = {Text = "Perhaps your love for friends worries you.", Selected = false},
  [99] = {Text = "Do noobs worry you?", Selected = false},
  [100] = {Text = "Are you talking about me in particular?", Selected = false},
  [101] = {Text = "Are you frightened by noobs?", Selected = false},
  [102] = {Text = "Why do you mention noobs?", Selected = false},
  [103] = {Text = "What do you think noobs have to do with your problems?", Selected = false},
  [104] = {Text = "Don't you think noobs can help people?", Selected = false},
  [105] = {Text = "What is it about noobs that worries you?", Selected = false},
  [106] = {Text = "Say, do you have any psychological problems?", Selected = false},
  [107] = {Text = "What does that suggest to you?", Selected = false},
  [108] = {Text = "I see.", Selected = false},
  [109] = {Text = "I'm not sure I understand you fully.", Selected = false},
  [110] = {Text = "Come, come, elucidate your thoughts.", Selected = false},
  [111] = {Text = "Can you elaborate on that?", Selected = false},
  [112] = {Text = "That is quite interesting.", Selected = false},
  [113] = {Text = "Why did you repeat yourself?", Selected = false},
  [114] = {Text = "Do you expect a different answer by repeating yourself?", Selected = false},
  [115] = {Text = "Come, come, elucidate your thoughts.", Selected = false},
  [116] = {Text = "Moooooooo", Selected = false},
  [117] = {Text = "Please don't repeat yourself!", Selected = false},
  [118] = {Text = "Are you hurt?", Selected = false},
  [119] = {Text = "Do you ever reflected on bandages?", Selected = false},
  [120] = {Text = "Why do you bring up this topic?", Selected = false},
  [121] = {Text = "You seem quite positive.", Selected = false},
  [122] = {Text = "What do you think?", Selected = false},
  [123] = {Text = "What is it that you really want to know?", Selected = false},
  [124] = {Text = "What is your level?", Selected = false},
  [125] = {Text = "Is this your first character?", Selected = false},
  [126] = {Text = "Do your think guilds are helpful?", Selected = false},
  [127] = {Text = "What is a guild?", Selected = false},
  [128] = {Text = "What is the name?", Selected = false},
  [129] = {Text = "Tell me more ...", Selected = false},
  [130] = {Text = "Ah", Selected = false},
  [131] = {Text = "Uh?", Selected = false},
  [132] = {Text = "hmmm ...", Selected = false}
}
AGTToShortResponse = {[1] = {Text = "OK... \"%s\". Tell me more.", Selected = false}}

local conj1 = {
  [1] = "are",
  [2] = "am",
  [3] = "were",
  [4] = "was",
  [5] = "I",
  [6] = "me",
  [7] = "you",
  [8] = "my",
  [9] = "your",
  [10] = "mine",
  [11] = "your's",
  [12] = "I'm",
  [13] = "you're",
  [14] = "I've",
  [15] = "you've",
  [16] = "I'll",
  [17] = "you'll",
  [18] = "myself",
  [19] = "yourself"
}
local conj2 = {
  [1] = "am",
  [2] = "are",
  [3] = "was",
  [4] = "were",
  [5] = "you",
  [6] = "you",
  [7] = "me",
  [8] = "your",
  [9] = "my",
  [10] = "your's",
  [11] = "mine",
  [12] = "you're",
  [13] = "I'm",
  [14] = "you've",
  [15] = "I've",
  [16] = "you'll",
  [17] = "I'll",
  [18] = "yourself",
  [19] = "myself"
}
local conj3 = {
  [1] = "me am",
  [2] = "am me",
  [3] = "mecan",
  [4] = "can me",
  [5] = "me have",
  [6] = "me will",
  [7] = "will me"
}
local conj4 = {[1] = "I am", [2] = "am I", [3] = "I can", [4] = "can I", [5] = "I have", [6] = "I will", [7] = "will I"}
local tmpPunct = {
  [1] = {pattern = "%.", value = "."},
  [2] = {pattern = ",", value = ","},
  [3] = {pattern = "!", value = "!"},
  [4] = {pattern = "%?", value = "?"},
  [5] = {pattern = ":", value = ":"},
  [6] = {pattern = ";", value = ";"},
  [7] = {pattern = "&", value = "&"},
  [8] = {pattern = "\"", value = "\""},
  [9] = {pattern = "@", value = "@"},
  [10] = {pattern = "#", value = "#"},
  [11] = {pattern = "%(", value = "("},
  [12] = {pattern = "%)", value = ")"}
}

AGTSoundFiles = {
  [1] = {name = "None", path = "Sound\\Creature\\GoblinMaleGruffNPC\\", id = 0},
  [2] = {name = "GoblinMaleGruffNPCFarewell02", path = "Sound\\Creature\\GoblinMaleGruffNPC\\", id = 550788},
  [3] = {name = "GoblinMaleGruffNPCFarewell03", path = "Sound\\Creature\\GoblinMaleGruffNPC\\", id = 550787},
  [4] = {name = "GoblinMaleGruffNPCFarewell04", path = "Sound\\Creature\\GoblinMaleGruffNPC\\", id = 550783},
  [5] = {name = "GoblinMaleGruffNPCGreeting01", path = "Sound\\Creature\\GoblinMaleGruffNPC\\", id = 550785},
  [6] = {name = "GoblinMaleGruffNPCGreeting02", path = "Sound\\Creature\\GoblinMaleGruffNPC\\", id = 550781},
  [7] = {name = "GoblinMaleGruffNPCGreeting03", path = "Sound\\Creature\\GoblinMaleGruffNPC\\", id = 550784},
  [8] = {name = "GoblinMaleGruffNPCGreeting04", path = "Sound\\Creature\\GoblinMaleGruffNPC\\", id = 550778},
  [9] = {name = "GoblinMaleGruffNPCGreeting05", path = "Sound\\Creature\\GoblinMaleGruffNPC\\", id = 550786},
  [10] = {name = "GoblinMaleGruffNPCGreeting06", path = "Sound\\Creature\\GoblinMaleGruffNPC\\", id = 550773},
  [11] = {name = "GoblinMaleGruffNPCPissed01", path = "Sound\\Creature\\GoblinMaleGruffNPC\\", id = 550775},
  [12] = {name = "GoblinMaleGruffNPCPissed02", path = "Sound\\Creature\\GoblinMaleGruffNPC\\", id = 550780},
  [13] = {name = "GoblinMaleGruffNPCPissed03", path = "Sound\\Creature\\GoblinMaleGruffNPC\\", id = 550779},
  [14] = {name = "GoblinMaleGruffNPCPissed04", path = "Sound\\Creature\\GoblinMaleGruffNPC\\", id = 550777},
  [15] = {name = "GoblinMaleGruffNPCPissed05", path = "Sound\\Creature\\GoblinMaleGruffNPC\\", id = 550774},
  [16] = {name = "GoblinMaleGruffNPCFarewell01", path = "Sound\\Creature\\GoblinMaleGruffNPC\\", id = 550776}
}
local AGTFonts = {
  [1] = "GameFontNormal",
  [2] = "GameFontNormal",
  [3] = "GameFontNormalSmall",
  [4] = "GameFontNormalLarge",
  [5] = "GameFontHighlight",
  [6] = "GameFontHighlightSmall",
  [7] = "GameFontHighlightSmallOutline",
  [8] = "GameFontHighlightLarge",
  [9] = "GameFontDisable",
  [10] = "GameFontDisableSmall",
  [11] = "GameFontDisableLarge",
  [12] = "GameFontGreen",
  [13] = "GameFontGreenSmall",
  [14] = "GameFontGreenLarge",
  [15] = "GameFontRed",
  [16] = "GameFontRedSmall",
  [17] = "GameFontRedLarge",
  [18] = "GameFontWhite",
  [19] = "GameFontDarkGraySmall",
  [20] = "NumberFontNormalYellow",
  [21] = "NumberFontNormalSmallGray",
  [22] = "QuestFontNormalSmall",
  [23] = "DialogButtonHighlightText",
  [24] = "ErrorFont",
  [25] = "TextStatusBarText",
  [26] = "CombatLogFont"
}
------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
function AGAGTen(msg, patient)
  local sInput = AGTstrTrim(msg)
  if sInput ~= "" and sInput ~= " " and sInput ~= "  " and sInput ~= "." and sInput ~= "," then
    local wInput = AGTpadString(string.upper(sInput))
    local foundkey = AGTfindkey(wInput)
    if AGTkeyword[foundkey].Q == true then
      if string.sub(msg, -1, -1) ~= "?" then
        foundkey = AGTNotFoundKey
      end
    end
    if msg == AGTPatients[patient].PrevAnswMsg then
      foundkey = AGTRepeatKey
    end
    if foundkey == AGTNotFoundKey then
      if AGTPatients[patient].Greet == false and AGTOptionsSettings["Global"].Hello.Value == AGTOptionsCONSTChecked then
        AGTPatients[patient].Greet = true
        AGTPatients[patient].PrevAnswMsg = msg
        return "Don't you ever say Hello?"
      else
        AGTPatients[patient].Greet = true
        AGTPatients[patient].PrevAnswMsg = msg
        if string.len(sInput) < 5 and AGTPatients[patient].PrevAnswMsg ~= "" then
          local idrange = #AGTToShortResponse
          local choice = 0
          if idrange > 1 then
            local stop = false
            while stop == false do
              choice = math.floor(math.random(1, idrange))
              if string.format(AGTToShortResponse[choice].Text, sInput) ~= AGTPatients[patient].LastResponseNr then
                stop = true
              end
            end
          else
            choice = 1
          end
          if AGTOptionsSettings["Global"].Quotes.Value > 0 then
            if AGTOptionsSettings["Global"].Quotes.Value >= math.random(100) then
              return AGTGetQuote(sInput)
            else
              return string.format(AGTToShortResponse[choice].Text, sInput)
            end
          else
            return string.format(AGTToShortResponse[choice].Text, sInput)
          end
        else
          if AGTOptionsSettings["Global"].Quotes.Value > 0 then
            if AGTOptionsSettings["Global"].Quotes.Value >= math.random(100) then
              return AGTGetQuote(sInput)
            else
              return AGTphrase(sInput, AGTNotFoundKey, patient)
            end
          else
            return AGTphrase(sInput, AGTNotFoundKey, patient)
          end
        end
      end
    else
      AGTPatients[patient].Greet = true
      AGTPatients[patient].PrevAnswMsg = msg
      return AGTphrase(sInput, foundkey, patient)
    end
  else
    return "I can't help, if you will not chat with me!"
  end
end
------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
function AGTGetQuote(sInput)
  local tWords = {}
  for k, _ in string.gmatch(sInput, "([%w']+)") do
    table.insert(tWords, k)
  end
  local tBestQuotes = {}
  local mxWords = 0
  for x = 1, #AGTQuotes, 1 do
    local count = 0
    for y = 1, #tWords, 1 do
      if string.find(AGTQuotes[x].Quote, tWords[y]) then
        count = count + 1
      end
    end
    if count > mxWords then
      tBestQuotes = {}
      mxWords = count
      table.insert(tBestQuotes, x)
    elseif count == mxWords then
      table.insert(tBestQuotes, x)
    end
  end
  local tResponse
  if #tBestQuotes > 0 then
    tResponse = tBestQuotes[math.random(#tBestQuotes)]
  else
    tResponse = math.random(#AGTQuotes)
  end
  return "\"" .. AGTQuotes[tResponse].Quote .. "\" - " .. AGTQuotes[tResponse].Source
end
------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
function AGTDialog(msg, patient)
  _G["AGTMain"]:Show()
  AGTPatients[patient].ChatLog = AGTPatients[patient].ChatLog .. msg .. "\n"
  if AGTPatients[patient].InTreatment == true then
    local GoblinsResponse = AGAGTen(msg, patient)
    AGTPatients[patient].ChatLog = AGTPatients[patient].ChatLog .. GoblinsResponse .. "\n"
    AGTSendResponse(GoblinsResponse, patient)
  end
end
------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
function AGTstrTrim(orgString)
  local tmpChars = ".,!?:;&\"@#()^$+-%= "

  local x = 1
  local found = true
  while found == true do
    local tchar = string.sub(orgString, -(x), -(x))
    if tchar == "(" or tchar == ")" or tchar == "." or tchar == "%" or tchar == "+" or tchar == "-" or tchar == "*" or
      tchar == "?" or tchar == "[" or tchar == "]" or tchar == "^" or tchar == "$" then
      tchar = "%" .. tchar
    end
    found = string.find(tmpChars, tchar) and (string.len(orgString) - x) > 0
    x = x + 1
  end
  x = x - 1
  if (string.len(orgString) - x) > 0 then
    orgString = string.sub(orgString, 1, string.len(orgString) - x + 1)
  end

  x = 1
  -- ~ 	while string.find(tmpChars, string.sub(orgString, x, x), 1, true) and (string.len(orgString) - x) > 0 do
  while string.find(tmpChars, string.sub(orgString, x, x)) and (string.len(orgString) - x) > 0 do
    x = x + 1
  end
  if (string.len(orgString) - x) > 0 then
    orgString = string.sub(orgString, x)
  end
  return orgString
end
------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
function AGTpadString(strng)
  local aString = " " .. strng .. " "
  for i = 1, 12, 1 do
    aString = string.gsub(aString, tmpPunct[i].pattern, " " .. tmpPunct[i].value .. " ")
  end

  return " " .. aString .. " "
end
------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
function AGTfindkey(wString)
  for k, _ in string.gmatch(wString, "([%w']+ [%w']+ [%w']+ [%w']+ [%w']+)") do
    for x = 1, #AGTkeyword, 1 do
      if AGTkeyword[x].key == k then
        return x
      end
    end
  end
  for k, _ in string.gmatch(wString, "([%w']+ [%w']+ [%w']+ [%w']+)") do
    for x = 1, #AGTkeyword, 1 do
      if AGTkeyword[x].key == k then
        return x
      end
    end
  end
  for k, _ in string.gmatch(wString, "([%w']+ [%w']+ [%w']+)") do
    for x = 1, #AGTkeyword, 1 do
      if AGTkeyword[x].key == k then
        return x
      end
    end
  end
  for k, _ in string.gmatch(wString, "([%w']+ [%w']+)") do
    for x = 1, #AGTkeyword, 1 do
      if AGTkeyword[x].key == k then
        return x
      end
    end
  end
  for k, _ in string.gmatch(wString, "([%w]-) ") do
    for x = 1, #AGTkeyword, 1 do
      if AGTkeyword[x].key == k then
        return x
      end
    end
  end

  return AGTNotFoundKey
end
------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
function AGTphrase(sString, keyidx, patient)
  local thisstr
  local idrange = #AGTkeyword[keyidx].Responses
  local choice = 0
  if idrange > 1 then
    local stop = false
    while stop == false do
      choice = math.floor(math.random(1, idrange))
      if AGTkeyword[keyidx].Responses[choice] ~= AGTPatients[patient].LastResponseNr then
        stop = true
      end
    end
  else
    choice = 1
  end

  AGTPatients[patient].LastResponseNr = AGTkeyword[keyidx].Responses[choice]
  local rTemp = AGTresponse[AGTkeyword[keyidx].Responses[choice]].Text
  local tempt = string.sub(rTemp, -1, -1)
  local sTemp
  if tempt == "*" or tempt == "@" then
    sTemp = AGTpadString(sString)
    local wTemp = string.upper(sTemp)

    local strpstr = string.find(wTemp, " " .. AGTkeyword[keyidx].key .. " ")
    if not strpstr then
      strpstr = string.find(wTemp, " " .. AGTkeyword[keyidx].key)
    end
    if not strpstr then
      strpstr = string.find(wTemp, AGTkeyword[keyidx].key .. " ")
    end
    -- ~ 		if not strpstr then
    -- ~ 			strpstr = string.find(wTemp, AGTkeyword[keyidx].key)
    -- ~ 		end
    -- ~ 		strpstr = string.find(wTemp, " "..AGTkeyword[keyidx].key.." ")
    strpstr = strpstr + string.len(AGTkeyword[keyidx].key) + 1
    thisstr = AGTconjugate(string.sub(sTemp, strpstr))
    thisstr = AGTstrTrim(AGTunpadString(thisstr))

    if tempt == "*" then
      sTemp = string.gsub(rTemp, "<%*", " " .. thisstr .. "?")
    else
      sTemp = string.gsub(rTemp, "<@", " " .. thisstr .. ".")
    end
  else
    sTemp = rTemp
  end

  return sTemp
end
------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
function AGTunpadString(strng)
  local aString = strng
  aString = string.gsub(aString, "  ", " ")
  if string.sub(aString, 1, 1) == " " then
    aString = string.sub(aString, 2)
  end

  if string.sub(aString, -1, -1) == " " then
    aString = string.sub(aString, 1, string.len(aString) - 1)
  end

  for i = 1, 12, 1 do
    aString = string.gsub(aString, " " .. tmpPunct[i].pattern, tmpPunct[i].value)
  end

  return aString
end
------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
function AGTconjugate(sStrg)
  local sString = sStrg
  for i = 1, AGTmaxConj, 1 do
    sString = string.gsub(sString, conj1[i], "#@&" .. i)
  end
  for i = 1, AGTmaxConj, 1 do
    sString = string.gsub(sString, "#@&" .. i, conj2[i])
  end
  for i = 1, AGTmax2ndConj, 1 do
    sString = string.gsub(sString, conj3[i], "#@&" .. i)
  end
  for i = 1, AGTmax2ndConj, 1 do
    sString = string.gsub(sString, "#@&" .. i, conj4[i])
  end

  return sString
end
------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
function AGTOnUpdate(_self, elapsed)
  if AGTOptionsSettings["Global"].Enabled.Value == AGTOptionsCONSTChecked then
    AGTelapsedUpdate = AGTelapsedUpdate + elapsed
    if AGTelapsedUpdate > 4 then
      AGTelapsedUpdate = 0

      if table.maxn(AGTSendQueue) > 0 then
        local ttime = GetTime()
        for x = 1, table.maxn(AGTSendQueue), 1 do
          if AGTSendQueue[x] then
            if AGTSendQueue[x].sendat < ttime then
              SendChatMessage(AGTSendQueue[x].msg, "WHISPER", nil, AGTSendQueue[x].to)
              table.remove(AGTSendQueue, x)
            end
          end
        end
      end

      if GetTime() > AGTOptionsSettings["Global"].RemoveInaktiveAfter.Value then
        for x = 1, 5, 1 do
          if _G["AGTMainTherapy" .. x .. "FS"]:GetText() ~= "Empty Seat" then
            if AGTPatients[_G["AGTMainTherapy" .. x .. "FS"]:GetText()].LastContact <
              (GetTime() - AGTOptionsSettings["Global"].RemoveInaktiveAfter.Value) then
              AGTPatients[_G["AGTMainTherapy" .. x .. "FS"]:GetText()] =
                {
                  Channel = "",
                  PrevMsg = "",
                  ChatLog = "",
                  Frame = 0,
                  Greet = false,
                  PrevAnswMsg = "",
                  LastResponseNr = 0,
                  InTreatment = false,
                  LastContact = 0
                }
              AGTRemoveSeat(_G["AGTMainTherapy" .. x .. "FS"]:GetText())
            end
          end
        end
      end
    end
  end
end
------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
function AGTOnLoad(self)
  DEFAULT_CHAT_FRAME:AddMessage("Your Goblin Therapist Hangs Out His Shingle")
  self:RegisterEvent("CHAT_MSG_WHISPER")
  self:RegisterEvent("CHAT_MSG_IGNORED")
end
------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
function AGTOnEvent(_self, event, ...)
  if AGTOptionsSettings["Global"].Enabled.Value == AGTOptionsCONSTChecked then

    local arg1, arg2, _arg3, _arg4, _arg5, _arg6, _arg7, _arg8, _arg9 = ...
    if event == "CHAT_MSG_IGNORED" then
      if AGTPatients[arg2] then
        if AGTPatients[arg2].InTreatment == true then
          AGTPatients[arg2] = {
            Channel = "",
            PrevMsg = "",
            ChatLog = "",
            Frame = 0,
            Greet = false,
            PrevAnswMsg = "",
            LastResponseNr = 0,
            InTreatment = false,
            LastContact = 0
          }
          AGTRemoveSeat(arg2)
          DEFAULT_CHAT_FRAME:AddMessage("Therapist: You finaly made it! " .. arg2 .. " ignores you!")
        end
      end
      if AGTOptionsSettings["Sounds"].Ignore.Value > 1 then
        --	PlaySoundFile(AGTSoundFiles[math.floor(AGTOptionsSettings["Sounds"].Ignore.Value)]
        --   .path..AGTSoundFiles[math.floor(AGTOptionsSettings["Sounds"].Ignore.Value)].name..".ogg")
        PlaySoundFile(AGTSoundFiles[math.floor(AGTOptionsSettings["Sounds"].Ignore.Value)].id)
      end
    end
    if event == "CHAT_MSG_WHISPER" then
      if not UnitIsAFK("player") and not UnitIsDND("player") then
        local friend = nil
        for x = 1, C_FriendList.GetNumFriends(), 1 do
          local tname = C_FriendList.GetFriendInfo(x)
          if arg2 == tname then
            if AGTOptionsSettings["Global"].Friends.Value == AGTOptionsCONSTChecked then
              friend = true
            end
          end
        end

        if GetGuildInfo("player") then
          GuildRoster()
          for x = 1, GetNumGuildMembers(), 1 do
            local tname = GetGuildRosterInfo(x)
            if arg2 == tname then
              if AGTOptionsSettings["Global"].Guild.Value == AGTOptionsCONSTChecked then
                friend = true
              end
            end
          end
        end

        if not friend then
          if (not AGTPatients[arg2]) then
            AGTPatients[arg2] = {
              Channel = "",
              PrevMsg = arg1,
              ChatLog = "",
              Frame = 0,
              Greet = false,
              PrevAnswMsg = "",
              LastResponseNr = 0,
              InTreatment = false,
              LastContact = 0
            }
            AGTUpdateSeats(arg2)
          end
          if AGTPatients[arg2].PrevMsg == "" then
            AGTPatients[arg2].PrevMsg = arg1
            AGTUpdateSeats(arg2)
          end
          AGTPatients[arg2].LastContact = GetTime()
          if AGTOptionsSettings["Global"]["OnlyLast"].Value == AGTOptionsCONSTChecked then
            for x = 1, table.maxn(AGTSendQueue), 1 do
              if AGTSendQueue[x] then
                if AGTSendQueue[x].to == arg2 then
                  table.remove(AGTSendQueue, x)
                end
              end
            end
          end
          AGTDialog(arg1, arg2)
          if AGTPatients[arg2].InTreatment == true then
            if AGTOptionsSettings["Sounds"].WhisperInSurgery.Value > 1 then
              PlaySoundFile(AGTSoundFiles[math.floor(AGTOptionsSettings["Sounds"].WhisperInSurgery.Value)].id)
            end
          end
        end
      end
    end
  end
end
------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
function AGTSendResponse(GoblinsResponse, patient)
  if AGTOptionsSettings["Global"].AddTherapistPrefix.Value == AGTOptionsCONSTChecked then
    GoblinsResponse = "[Therapist]: " .. GoblinsResponse
  end
  table.insert(AGTSendQueue, {
    ["sendat"] = (math.floor(GetTime()) +
      ((string.len(GoblinsResponse) / AGTOptionsSettings["Global"].CharsPerMinute.Value) * 60)),
    ["msg"] = GoblinsResponse,
    ["to"] = patient
  })

end
------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
function AGTRemoveSeat(Patient)
  for x = 1, 5, 1 do
    if _G["AGTMainTherapy" .. x .. "FS"]:GetText() == Patient and _G["AGTMainTherapy" .. x .. "FS"]:GetText() ~=
      "Empty Seat" then
      _G["AGTMainTherapy" .. x .. "FS"]:SetText("Empty Seat")
      DEFAULT_CHAT_FRAME:AddMessage("Therapist: Patient " .. Patient .. " quit the waiting room.")
      _G["AGTMainTherapy" .. x]:SetPoint("TOPLEFT", "AGTMain", "TOPLEFT", 0, ((-16) - (x * 21)))
    end
  end

  if AGTOptionsSettings["Global"].HideIfEmpty.Value == AGTOptionsCONSTChecked then
    local empty = true
    for x = 1, 5, 1 do
      if _G["AGTMainTherapy" .. x .. "FS"]:GetText() ~= "Empty Seat" then
        empty = false
      end
    end
    if empty == true then
      _G["AGTMain"]:Hide()
    else
      _G["AGTMain"]:Show()
    end
  else
    _G["AGTMain"]:Show()
  end
end
------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
function AGTUpdateSeats(newPatient)
  local done = false
  for x = 1, 5, 1 do
    if _G["AGTMainTherapy" .. x .. "FS"]:GetText() == "Empty Seat" and done == false then
      _G["AGTMainTherapy" .. x .. "FS"]:SetText(newPatient)
      if AGTOptionsSettings["Global"].AutoSurgery.Value == AGTOptionsCONSTChecked then

        _G["AGTMainTherapy" .. x]:SetPoint("TOPLEFT", "AGTMain", "TOPLEFT", 128, ((-16) - (x * 21)))
        _G["AGTMainTherapy" .. x].InTreatment = true
        AGTPatients[newPatient].InTreatment = true

      end
      done = true
    end
  end
  if done == true then
    DEFAULT_CHAT_FRAME:AddMessage("Therapist: New patient " .. newPatient .. " entered the waiting room.")
  else
    DEFAULT_CHAT_FRAME:AddMessage("Therapist: Oh noes! Waiting room full. New patient " .. newPatient .. " rejected.")
  end
end
------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
function AGTTherapyOnClick(self, button, _down)
  local x = string.sub(self:GetName(), 15)

  if button == "LeftButton" then
    if _G["AGTMainTherapy" .. x .. "FS"]:GetText() ~= "Empty Seat" then
      if self.InTreatment == false then
        self:SetPoint("TOPLEFT", "AGTMain", "TOPLEFT", 128, ((-16) - (x * 21)))
        self.InTreatment = true
        AGTPatients[_G["AGTMainTherapy" .. x .. "FS"]:GetText()].InTreatment = true
        AGTDialog(AGTPatients[_G["AGTMainTherapy" .. x .. "FS"]:GetText()].PrevMsg,
                  _G["AGTMainTherapy" .. x .. "FS"]:GetText())
      else
        self:SetPoint("TOPLEFT", "AGTMain", "TOPLEFT", 0, ((-16) - (x * 21)))
        self.InTreatment = false
        AGTPatients[_G["AGTMainTherapy" .. x .. "FS"]:GetText()].InTreatment = false
      end
    end
  elseif button == "RightButton" then
    AGTPatients[_G["AGTMainTherapy" .. x .. "FS"]:GetText()] =
      {
        Channel = "",
        PrevMsg = "",
        ChatLog = "",
        Frame = 0,
        Greet = false,
        PrevAnswMsg = "",
        LastResponseNr = 0,
        InTreatment = false,
        LastContact = 0
      }
    AGTRemoveSeat(_G["AGTMainTherapy" .. x .. "FS"]:GetText())
  end
end
------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
local f = CreateFrame("Frame", "AGTMain", UIParent)
f:SetFrameStrata("MEDIUM")
f:SetWidth(260)
f:SetHeight(145)
f:SetScript("OnDragStart", function()
  _G["AGTMain"]:StartMoving()
end)
f:SetScript("OnDragStop", function()
  _G["AGTMain"]:StopMovingOrSizing()
end)
f:SetPoint("CENTER", 0, 0)
f:SetBackdrop({
  bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
  edgeFile = "",
  tile = false,
  tileSize = 0,
  edgeSize = 32,
  insets = {left = 0, right = 0, top = 0, bottom = 0}
})
f:SetMovable(true)
f:EnableMouse(true)
f:SetClampedToScreen(true)
f:RegisterForDrag("LeftButton")
f:Show()
local fs = f:CreateFontString("AGTMainFS")
fs:SetWidth(260)
fs:SetHeight(50)
fs:SetFontObject(GameFontNormal)
fs:SetTextColor(0.5, 0.5, 1, 1)
fs:SetJustifyH("CENTER")
fs:SetJustifyV("TOP")
fs:SetPoint("TOPLEFT", "AGTMain", "TOPLEFT")
fs:SetText("Automatic Goblin Therapist")
fs = f:CreateFontString("AGTMainFSLeft")
fs:SetWidth(180)
fs:SetHeight(50)
fs:SetFontObject(GameFontNormal)
fs:SetTextColor(1, 0, 0, 1)
fs:SetJustifyH("LEFT")
fs:SetJustifyV("TOP")
fs:SetPoint("TOPLEFT", "AGTMain", "TOPLEFT", 0, -15)
fs:SetText("Waiting Room")
fs = f:CreateFontString("AGTMainFSRight")
fs:SetWidth(180)
fs:SetHeight(50)
fs:SetFontObject(GameFontNormal)
fs:SetTextColor(1, 0, 0, 1)
fs:SetJustifyH("RIGHT")
fs:SetJustifyV("TOP")
fs:SetPoint("TOPRIGHT", "AGTMain", "TOPRIGHT", 0, -15)
fs:SetText("Surgery ")

-- Therapy buttons
for x = 1, 5, 1 do
  local tf = CreateFrame("Button", "AGTMainTherapy" .. x, f)
  tf:SetWidth(125)
  tf:SetHeight(20)
  tf:SetPoint("TOPLEFT", "AGTMain", "TOPLEFT", 0, ((-16) - (x * 21)))
  tf:RegisterForClicks("AnyUp")
  tf:SetScript("OnClick", function(self, button, down)
    AGTTherapyOnClick(self, button, down)
  end)
  tf:SetBackdrop({
    bgFile = "",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false,
    tileSize = 0,
    edgeSize = 16,
    insets = {left = 0, right = 0, top = 0, bottom = 0}
  })
  tf.InTreatment = false
  fs = tf:CreateFontString("AGTMainTherapy" .. x .. "FS")
  fs:SetWidth(125)
  fs:SetHeight(20)
  fs:SetFontObject(GameFontNormalSmall)
  fs:SetTextColor(1, 1, 1, 1)
  fs:SetJustifyH("MIDDLE")
  fs:SetJustifyV("MIDDLE")
  fs:SetPoint("TOP", "AGTMainTherapy" .. x, "TOP")
  fs:SetText("Empty Seat")
end
------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
function AGTUpdateVisuals()
  local f = _G["AGTMain"]
  if AGTOptionsSettings["Global"].Enabled.Value == AGTOptionsCONSTChecked then
    f:SetHeight(45 + (AGTOptionsSettings["Visuals"].NumberSeats.Value * 20))
    for x = 1, 5, 1 do
      if x <= AGTOptionsSettings["Visuals"].NumberSeats.Value then
        _G["AGTMainTherapy" .. x]:Show()
      else
        if _G["AGTMainTherapy" .. x .. "FS"]:GetText() ~= "Empty Seat" then
          AGTPatients[_G["AGTMainTherapy" .. x .. "FS"]:GetText()] =
            {
              Channel = "",
              PrevMsg = "",
              ChatLog = "",
              Frame = 0,
              Greet = false,
              PrevAnswMsg = "",
              LastResponseNr = 0,
              InTreatment = false,
              LastContact = 0
            }
          AGTRemoveSeat(_G["AGTMainTherapy" .. x .. "FS"]:GetText())
        end
        _G["AGTMainTherapy" .. x]:Hide()
      end
      _G["AGTMainTherapy" .. x .. "FS"]:SetFontObject(AGTFonts[AGTOptionsSettings["Visuals"].FontType.Value])
    end
    _G["AGTMainFS"]:SetFontObject(AGTFonts[AGTOptionsSettings["Visuals"].FontType.Value])
    _G["AGTMainFSLeft"]:SetFontObject(AGTFonts[AGTOptionsSettings["Visuals"].FontType.Value])
    _G["AGTMainFSRight"]:SetFontObject(AGTFonts[AGTOptionsSettings["Visuals"].FontType.Value])

    if AGTOptionsSettings["Global"].HideIfEmpty.Value == AGTOptionsCONSTChecked then
      local empty = true
      for x = 1, 5, 1 do
        if _G["AGTMainTherapy" .. x .. "FS"]:GetText() ~= "Empty Seat" then
          empty = false
        end
      end
      if empty == true then
        _G["AGTMain"]:Hide()
      else
        _G["AGTMain"]:Show()
      end
    else
      _G["AGTMain"]:Show()
    end
    f:SetScale(AGTOptionsSettings["Visuals"].Scale.Value)
  else
    _G["AGTMain"]:Hide()
  end
end
------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
function AGTOptionsShowOptionsHelp(framename, inout)
  if AGTOptionsSettings["Global"].AGTShowHelpTooltips.Value == AGTOptionsCONSTChecked then
    local tLocale
    if AGTOptionsLocales[GetLocale()] then
      tLocale = GetLocale() .. "Help"
    else
      tLocale = "enENHelp"
    end
    if AGTOptionsSettingsTemplate[AGTOptionsActualOptionsTemplate][string.sub(framename,
                                                                              string.find(framename, "Settings") + 8)][tLocale] ~=
      "" then
      if inout == true then
        AGTOptionsTooltip:ClearLines()
        AGTOptionsTooltip:SetOwner(_G[framename], "ANCHOR_TOPLEFT")
        AGTOptionsTooltip:AddLine(AGTOptionsSettingsTemplate[AGTOptionsActualOptionsTemplate][string.sub(framename,
                                                                                                         string.find(
                                                                                                           framename,
                                                                                                           "Settings") +
                                                                                                           8)][tLocale],
                                  1, 1, 1, 1)
        AGTOptionsTooltip:Show()
      else
        AGTOptionsTooltip:ClearLines()
        AGTOptionsTooltip:Hide()
      end
    end
  else
    AGTOptionsTooltip:ClearLines()
    AGTOptionsTooltip:Hide()
  end
end
------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
function AGTOptionsHighlightButtons()
  for x = 1, AGTOptionsNoOptionsFrameTemplates, 1 do
    _G["AGTOptionsTabs" .. AGTOptionsOptionsTemplate[x]]:UnlockHighlight()
  end
  _G["AGTOptionsTabs" .. AGTOptionsActualOptionsTemplate]:LockHighlight()
end
------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
function AGTOptionsLoadSettings()
  local tLocale
  if AGTOptionsLocales[GetLocale()] then
    tLocale = GetLocale()
  else
    tLocale = "enEN"
  end

  local kids = {_G["AGTOptionsTabsSettings"]:GetChildren()}
  for _, child in ipairs(kids) do
    child:Hide()
  end
  local tpos = -15

  local tempSorttable = {}
  for index in pairs(AGTOptionsSettingsTemplate[AGTOptionsActualOptionsTemplate]) do
    table.insert(tempSorttable, index)
  end
  table.sort(tempSorttable, function(a, b)
    if AGTOptionsSettingsTemplate[AGTOptionsActualOptionsTemplate][a]["Sort"] <
      AGTOptionsSettingsTemplate[AGTOptionsActualOptionsTemplate][b]["Sort"] then
      return true
    else
      return false
    end
  end)

  table.foreach(tempSorttable, function(_key, value)
    local tvalue = ""
    local ttype = ""
    local tdescription = ""
    local tmin = ""
    local tmax = ""
    local tstep = ""
    local ttemplate = ""
    local tOnValueChanged = nil
    local tOnClick = nil
    local tOnShow = nil
    local tOnHide = nil
    table.foreach(AGTOptionsSettingsTemplate[AGTOptionsActualOptionsTemplate][value], function(nkey, nvalue)
      if nkey == "Value" then
        tvalue = AGTOptionsSettings[AGTOptionsActualOptionsTemplate][value]["Value"]
      end
      if nkey == "Type" then
        ttype = nvalue
      end
      if nkey == "Template" then
        ttemplate = nvalue
      end
      if nkey == tLocale .. "Description" then
        tdescription = nvalue
      end
      if nkey == "Min" then
        tmin = nvalue
      end
      if nkey == "Max" then
        tmax = nvalue
      end
      if nkey == "Step" then
        tstep = nvalue
      end
      if nkey == "Template" then
        ttemplate = nvalue
      end
      if nkey == "OnValueChanged" then
        tOnValueChanged = nvalue
      end
      if nkey == "OnClick" then
        tOnClick = nvalue
      end
      if nkey == "OnShow" then
        tOnShow = nvalue
      end
      if nkey == "OnHide" then
        tOnHide = nvalue
      end
    end)

    if value then
      local tframe
      if _G["AGTOptionsTabsSettings" .. value] == nil then
        tframe = CreateFrame(ttype, "AGTOptionsTabsSettings" .. value, _G["AGTOptionsTabsSettings"], ttemplate)
      else
        tframe = _G["AGTOptionsTabsSettings" .. value]
      end
      if _G["AGTOptionsTabsSettings" .. value .. "FS"] then
        _G["AGTOptionsTabsSettings" .. value .. "FS"]:SetText(tdescription)
      end

      if ttemplate == "AGTOptionsCheckTemplate" or ttemplate == "AGTOptionsColorPickerTemplate" or ttemplate ==
        "AGTOptionsClickButtonTemplate" then
        tframe:SetScript("OnClick", tOnClick)
      end
      if ttemplate == "AGTOptionsSliderTemplate" then
        tframe:SetScript("OnValueChanged", tOnValueChanged)
      end
      tframe:SetScript("OnShow", tOnShow)
      tframe:SetScript("OnHide", tOnHide)

      if ttype == "Button" then
        -- colorpicker
        if ttemplate == "AGTOptionsColorPickerTemplate" then
          tframe:SetBackdropColor(tvalue.r, tvalue.g, tvalue.b)
        end
        -- simple button
        if ttemplate == "AGTOptionsClickButtonTemplate" then
          if tvalue ~= 0 then
            tframe:SetText(tvalue)
          end
        end
      end

      if ttype == "EditBox" then
        tframe:SetPoint("TOPLEFT", _G["AGTOptionsTabsSettings"], "TOPLEFT", 14, tpos)
      else
        tframe:SetPoint("TOPLEFT", _G["AGTOptionsTabsSettings"], "TOPLEFT", 5, tpos)
      end

      if ttype == "Slider" then
        tframe:SetMinMaxValues(tmin, tmax)
        tframe:SetValueStep(tstep)
        tframe:SetValue(tvalue)
        _G[tframe:GetName() .. "High"]:SetText(tmax)
        _G[tframe:GetName() .. "Low"]:SetText(tmin)
      end

      if ttype == "EditBox" then
        tframe:SetMaxLetters(tmax)
        tframe:SetText(tvalue)
      end
      if ttype == "Frame" then
        _G["AGTOptionsTabsSettings" .. value .. "FS"]:SetText(tdescription .. ": " .. tvalue)
      end
      --
      if ttype == "CheckButton" then
        if tvalue == AGTOptionsCONSTChecked then
          tframe:SetChecked(true)
        elseif tvalue == AGTOptionsCONSTUnChecked then
          tframe:SetChecked(false)
        end
      end

      tframe:Show()
      tpos = tpos - 24
    end
  end)
end
------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
function AGTOptionsSaveSettings()
  local kids = {_G["AGTOptionsTabsSettings"]:GetChildren()} -- get all options
  for _, child in ipairs(kids) do
    if child:IsVisible() then
      if AGTOptionsSettingsTemplate[AGTOptionsActualOptionsTemplate][string.sub(child:GetName(), string.find(
                                                                                  child:GetName(), "Settings") + 8)]
        .Type == "Button" and AGTOptionsSettingsTemplate[AGTOptionsActualOptionsTemplate][string.sub(child:GetName(),
                                                                                                     string.find(
                                                                                                       child:GetName(),
                                                                                                       "Settings") + 8)]
        .Template == "AGTOptionsColorPickerTemplate" then
        local r, g, b = child:GetBackdropColor()
        AGTOptionsSettings[AGTOptionsActualOptionsTemplate][string.sub(child:GetName(),
                                                                       string.find(child:GetName(), "Settings") + 8)]
        .Value.r = r
        AGTOptionsSettings[AGTOptionsActualOptionsTemplate][string.sub(child:GetName(),
                                                                       string.find(child:GetName(), "Settings") + 8)]
        .Value.g = g
        AGTOptionsSettings[AGTOptionsActualOptionsTemplate][string.sub(child:GetName(),
                                                                       string.find(child:GetName(), "Settings") + 8)]
        .Value.b = b
      end
      if AGTOptionsSettingsTemplate[AGTOptionsActualOptionsTemplate][string.sub(child:GetName(), string.find(
                                                                                  child:GetName(), "Settings") + 8)]
        .Type == "Slider" then
        if AGTOptionsSettingsTemplate[AGTOptionsActualOptionsTemplate][string.sub(child:GetName(), string.find(
                                                                                    child:GetName(), "Settings") + 8)]
          .Decimal then
          AGTOptionsSettings[AGTOptionsActualOptionsTemplate][string.sub(child:GetName(),
                                                                         string.find(child:GetName(), "Settings") + 8)]
          .Value = child:GetValue()
        else
          AGTOptionsSettings[AGTOptionsActualOptionsTemplate][string.sub(child:GetName(),
                                                                         string.find(child:GetName(), "Settings") + 8)]
          .Value = math.floor(child:GetValue())
        end
      end
      if AGTOptionsSettingsTemplate[AGTOptionsActualOptionsTemplate][string.sub(child:GetName(), string.find(
                                                                                  child:GetName(), "Settings") + 8)]
        .Type == "CheckButton" then
        if child:GetChecked() == true then
          AGTOptionsSettings[AGTOptionsActualOptionsTemplate][string.sub(child:GetName(),
                                                                         string.find(child:GetName(), "Settings") + 8)]
          .Value = AGTOptionsCONSTChecked
        end
        if child:GetChecked() == false then
          AGTOptionsSettings[AGTOptionsActualOptionsTemplate][string.sub(child:GetName(),
                                                                         string.find(child:GetName(), "Settings") + 8)]
          .Value = AGTOptionsCONSTUnChecked
        end
      end
      if AGTOptionsSettingsTemplate[AGTOptionsActualOptionsTemplate][string.sub(child:GetName(), string.find(
                                                                                  child:GetName(), "Settings") + 8)]
        .Type == "EditBox" then
        AGTOptionsSettings[AGTOptionsActualOptionsTemplate][string.sub(child:GetName(),
                                                                       string.find(child:GetName(), "Settings") + 8)]
        .Value = child:GetText()
      end
    end
  end
  AGTUpdateVisuals()
end
------------------------------------------------------------------------------------------------------------------------------------
-- called with framname for this the colorpicker is opened
------------------------------------------------------------------------------------------------------------------------------------
function AGTOptionsColorPickerPrepare(target)
  AGTOptionsOptionsColorPickerActualFrame = target
  local r, g, b, _a = _G[target]:GetBackdropColor()
  ColorPickerFrame.previousValues = {r, g, b}
  ColorPickerFrame.func = AGTOptionsColorPickerChangeColor
  ColorPickerFrame.cancelFunc = AGTOptionsColorPickerCancel
  ColorPickerFrame.hasOpacity = false
  -- ColorSwatch:SetTexture(_G[target]:GetBackdropColor())
  ColorPickerFrame:SetColorRGB(_G[target]:GetBackdropColor())
  ColorPickerFrame:Show()
end
--------------------------------------------------------------------------------------------------------------------------------
-- color selected - set it
--------------------------------------------------------------------------------------------------------------------------------
function AGTOptionsColorPickerChangeColor()
  _G[AGTOptionsOptionsColorPickerActualFrame]:SetBackdropColor(ColorPickerFrame:GetColorRGB())
  AGTOptionsSaveSettings()
end
--------------------------------------------------------------------------------------------------------------------------------
-- cancel - set the old color
--------------------------------------------------------------------------------------------------------------------------------
function AGTOptionsColorPickerCancel(prevvals)
  _G[AGTOptionsOptionsColorPickerActualFrame]:SetBackdropColor(unpack(prevvals))
  ColorPickerFrame:Hide()
  AGTOptionsSaveSettings()
  AGTOptionsOptionsColorPickerActualFrame = ""
end
------------------------------------------------------------------------------------
--
------------------------------------------------------------------------------------
function AGTOptionsOpenOnLoad(self)
  self:RegisterEvent("VARIABLES_LOADED")
end
------------------------------------------------------------------------------------
--
------------------------------------------------------------------------------------
function AGTOptionsOpenOnEvent(_self)
  local panel = _G["AGTOptions"]
  panel.name = "AGT"
  panel:ClearAllPoints()
  InterfaceOptions_AddCategory(panel)
  AGTOptionsInitAll()
end
--------------------------------------------------------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------------------------------------------------------
function AGTOptionsInitAll()
  local tframe
  local y = -5
  local xs = 0
  for x = 1, AGTOptionsNoOptionsFrameTemplates, 1 do
    if not AGTOptionsSettings[AGTOptionsOptionsTemplate[x]] then
      AGTOptionsSettings[AGTOptionsOptionsTemplate[x]] = {}
    end

    table.foreach(AGTOptionsSettingsTemplate[AGTOptionsOptionsTemplate[x]], function(key, value)
      if not AGTOptionsSettings[AGTOptionsOptionsTemplate[x]][key] then
        AGTOptionsSettings[AGTOptionsOptionsTemplate[x]][key] = {}
      end
      table.foreach(value, function(tkey, tvalue)
        if tkey == "Value" then
          if not AGTOptionsSettings[AGTOptionsOptionsTemplate[x]][key][tkey] then
            AGTOptionsSettings[AGTOptionsOptionsTemplate[x]][key][tkey] = tvalue
          end
        end
      end)
    end)

    for xx = 1, AGTOptionsNoOptionsFrameTemplates, 1 do
      if AGTOptionsSettings[AGTOptionsOptionsTemplate[xx]] then
        table.foreach(AGTOptionsSettings[AGTOptionsOptionsTemplate[xx]], function(key, _value)
          if AGTOptionsSettingsTemplate[AGTOptionsOptionsTemplate[xx]][key] == nil then
            DEFAULT_CHAT_FRAME:AddMessage("Old setting " .. key .. " in " .. AGTOptionsOptionsTemplate[xx] ..
                                            " not longer in use - Removed.")
            AGTOptionsSettings[AGTOptionsOptionsTemplate[xx]][key] = nil
          end
        end)
      end
    end

    if _G["AGTOptionsTabs" .. AGTOptionsOptionsTemplate[x]] then
      tframe = _G["AGTOptionsTabs" .. AGTOptionsOptionsTemplate[x]]
    else
      tframe = CreateFrame("Button", "AGTOptionsTabs" .. AGTOptionsOptionsTemplate[x], _G["AGTOptionsTabs"],
                           "UIPanelButtonTemplate")
    end
    if x == 7 then
      y = y - 22
      xs = (((x - 1) * 75))
    end
    tframe:SetPoint("TOPLEFT", "AGTOptionsTabs", "TOPLEFT", (((x - 1) * 75) + 5) - xs, y)
    tframe:SetWidth(70)
    tframe:SetHeight(20)
    tframe:SetText(AGTOptionsOptionsTemplate[x])
    tframe:SetScript("OnClick", function(self)
      AGTOptionsSaveSettings()
      AGTOptionsActualOptionsTemplate = self:GetText()
      AGTOptionsHighlightButtons()
      AGTOptionsLoadSettings()
    end)
  end

  AGTOptionsHighlightButtons()
  AGTOptionsLoadSettings()
  AGTUpdateVisuals()
end
--------------------------------------------------------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------------------------------------------------------
function AGTOptionsReset()
  AGTOptionsSettings = {}
  AGTOptionsActualOptionsTemplate = AGTOptionsOptionsTemplate[1]
  AGTOptionsOptionsColorPickerActualFrame = ""
  for x = 1, AGTOptionsNoOptionsFrameTemplates, 1 do
    AGTOptionsSettings[AGTOptionsOptionsTemplate[x]] = {}
    table.foreach(AGTOptionsSettingsTemplate[AGTOptionsOptionsTemplate[x]], function(key, value)
      if not AGTOptionsSettings[AGTOptionsOptionsTemplate[x]][key] then
        AGTOptionsSettings[AGTOptionsOptionsTemplate[x]][key] = {}
      end
      table.foreach(value, function(tkey, tvalue)
        if tkey == "Value" then
          if not AGTOptionsSettings[AGTOptionsOptionsTemplate[x]][key][tkey] then
            AGTOptionsSettings[AGTOptionsOptionsTemplate[x]][key][tkey] = tvalue
          end
        end
      end)
    end)
  end
  AGTOptionsHighlightButtons()
  AGTOptionsLoadSettings()
  AGTUpdateVisuals()
end
------------------------------------------------------------------------------------------------------------------------------------
--
------------------------------------------------------------------------------------------------------------------------------------
AGTOptionsOptionsTemplate = {"Global", "Visuals", "Sounds"}
AGTOptionsCONSTChecked = 1
AGTOptionsCONSTUnChecked = -1
AGTOptionsCONSTSaveValue = false
AGTOptionsNoOptionsFrameTemplates = #AGTOptionsOptionsTemplate
AGTOptionsActualOptionsTemplate = AGTOptionsOptionsTemplate[1]
AGTOptionsOptionsColorPickerActualFrame = ""
AGTOptionsLocales = {enEN = true}
AGTOptionsSettings = {}
AGTOptionsSettingsTemplate = {}

AGTOptionsSettingsTemplate["Global"] = {
  Enabled = {
    Sort = 1,
    Type = "CheckButton",
    Value = AGTOptionsCONSTChecked,
    Template = "AGTOptionsCheckTemplate",
    OnClick = function()
      AGTOptionsSaveSettings()
    end,
    enENHelp = "Activate/deactivate addon",
    enENDescription = "Enable"
  },
  HideIfEmpty = {
    Sort = 1.5,
    Type = "CheckButton",
    Value = AGTOptionsCONSTUnChecked,
    Template = "AGTOptionsCheckTemplate",
    OnClick = function()
      AGTOptionsSaveSettings()
    end,
    enENHelp = "Hide the ATG frame while\nall seats are empty.",
    enENDescription = "Hide If Empty"
  },
  AutoSurgery = {
    Sort = 1.6,
    Type = "CheckButton",
    Value = AGTOptionsCONSTUnChecked,
    Template = "AGTOptionsCheckTemplate",
    OnClick = function()
      AGTOptionsSaveSettings()
    end,
    enENHelp = "Every new patient is automatically moved to the surgery.",
    enENDescription = "Auto move to surgery"
  },
  RemoveInaktiveAfter = {
    Sort = 2,
    Type = "Slider",
    Value = 300,
    Min = 10,
    Max = 600,
    Step = 10,
    Template = "AGTOptionsSliderTemplate",
    OnValueChanged = function(self)
      if AGTOptionsCONSTSaveValue == true then
        AGTOptionsSaveSettings()
      end
      _G[self:GetName() .. "FSVal"]:SetText(math.floor(self:GetValue()))
    end,
    enENHelp = "Number of seconds ATG waits before removing a inactive character from a seat " ..
      "(inactive are all characters who don't send new whispers).",
    enENDescription = "Remove After"
  },
  CharsPerMinute = {
    Sort = 3,
    Type = "Slider",
    Value = 400,
    Min = 100,
    Max = 600,
    Step = 10,
    Template = "AGTOptionsSliderTemplate",
    OnValueChanged = function(self)
      if AGTOptionsCONSTSaveValue == true then
        AGTOptionsSaveSettings()
      end
      _G[self:GetName() .. "FSVal"]:SetText(math.floor(self:GetValue()))
    end,
    enENHelp = "To don't confuse the conversation partner the Therapist answers in a natural manner typing x characters per minute",
    enENDescription = "Chars Per Minute"
  },
  OnlyLast = {
    Sort = 3.5,
    Type = "CheckButton",
    Value = AGTOptionsCONSTChecked,
    Template = "AGTOptionsCheckTemplate",
    OnClick = function()
      AGTOptionsSaveSettings()
    end,
    enENHelp = "If a conversation partner sends multiple whispers in a row or if he/she sends the next whisper" ..
      " before the previous was answered the Therapist will reply to the most recent whisper only.",
    enENDescription = "Most Recent Only"
  },
  Quotes = {
    Sort = 3.6,
    Type = "Slider",
    Value = 0,
    Min = 0,
    Max = 100,
    Step = 10,
    Template = "AGTOptionsSliderTemplate",
    OnValueChanged = function(self)
      if AGTOptionsCONSTSaveValue == true then
        AGTOptionsSaveSettings()
      end
      _G[self:GetName() .. "FSVal"]:SetText(math.floor(self:GetValue()))
    end,
    enENHelp = "AGT replies to whispers without recognized keywords with\nneutral phrases like \"I see\" " ..
      "or \"I'm not sure I understand\nyou fully\". This option is to add more variety to these\nkind of replies." ..
      " The option forces AGT to reply to x percent\nof the incoming whispers with a quote out of a list approx.\n" ..
      "700 predefinied quotes. If you set the option to 100% AGT\n" ..
      "answers every whisper without keywords with a quote. If\n" ..
      "you set the option to 0% AGT don't replies with quotes.\nA good value for this option is 20%.",
    enENDescription = "% Quote-Replies"
  },
  AddTherapistPrefix = {
    Sort = 4,
    Type = "CheckButton",
    Value = AGTOptionsCONSTUnChecked,
    Template = "AGTOptionsCheckTemplate",
    OnClick = function()
      AGTOptionsSaveSettings()
    end,
    enENHelp = "Add the prefix \"[Therapist]: \" to every outgoing whisper",
    enENDescription = "Add Prefix"
  },

  Friends = {
    Sort = 4.5,
    Type = "CheckButton",
    Value = AGTOptionsCONSTChecked,
    Template = "AGTOptionsCheckTemplate",
    OnClick = function()
      AGTOptionsSaveSettings()
    end,
    enENHelp = "Don't reply to whispers from characters on you friend list.",
    enENDescription = "Pass Through Friends"
  },
  Guild = {
    Sort = 4.6,
    Type = "CheckButton",
    Value = AGTOptionsCONSTChecked,
    Template = "AGTOptionsCheckTemplate",
    OnClick = function()
      AGTOptionsSaveSettings()
    end,
    enENHelp = "Don't reply to whispers from guild members.",
    enENDescription = "Pass Through Guild Members"
  },
  Hello = {
    Sort = 5,
    Type = "CheckButton",
    Value = AGTOptionsCONSTUnChecked,
    Template = "AGTOptionsCheckTemplate",
    OnClick = function()
      AGTOptionsSaveSettings()
    end,
    enENHelp = "Reply with \"Don't you ever say Hello?\" if the first whisper isn't a greeting.",
    enENDescription = "Force Greet"
  },
  AGTShowHelpTooltips = {
    Sort = 7,
    Type = "CheckButton",
    Value = AGTOptionsCONSTChecked,
    Template = "AGTOptionsCheckTemplate",
    OnClick = function()
      AGTOptionsSaveSettings()
    end,
    enENHelp = "Show a tooltip for every AGT setting",
    enENDescription = "Help Tooltips"
  },
  EditLib = {
    Sort = 7.5,
    Type = "Button",
    Value = "Edit Library",
    Min = 0,
    Max = 0,
    Template = "AGTOptionsClickButtonTemplate",
    OnClick = function()
      AGTOpenLib()
    end,
    enENHelp = "Edit the keywords and responses of the current library.",
    enENDescription = "Edit Library"
  },
  Reset = {
    Sort = 8,
    Type = "Button",
    Value = "Reset Settings",
    Min = 0,
    Max = 0,
    Template = "AGTOptionsClickButtonTemplate",
    OnClick = function()
      AGTOptionsReset()
    end,
    enENHelp = "All settings will be set to default (exept the library!)",
    enENDescription = "Default Settings"
  }
}
AGTOptionsSettingsTemplate["Visuals"] = {
  Scale = {
    Sort = 1,
    Type = "Slider",
    Value = 1,
    Min = 0.3,
    Max = 1.5,
    Step = 0.1,
    Template = "AGTOptionsSliderTemplate",
    Decimal = true,
    OnValueChanged = function(self)
      if AGTOptionsCONSTSaveValue == true then
        AGTOptionsSaveSettings()
      end
      _G[self:GetName() .. "FSVal"]:SetText(math.floor(self:GetValue()))
    end,
    enENHelp = "Scale of the AGT frame",
    enENDescription = "Scale"
  },
  NumberSeats = {
    Sort = 2,
    Type = "Slider",
    Value = 3,
    Min = 1,
    Max = 5,
    Step = 1,
    Template = "AGTOptionsSliderTemplate",
    OnValueChanged = function(self)
      if AGTOptionsCONSTSaveValue == true then
        AGTOptionsSaveSettings()
      end
      _G[self:GetName() .. "FSVal"]:SetText(math.floor(self:GetValue()))
    end,
    enENHelp = "Number of seats the Therapist is handling",
    enENDescription = "NumberSeats"
  },
  FontType = {
    Sort = 4,
    Type = "Slider",
    Value = 3,
    Min = 1,
    Max = 26,
    Step = 1,
    Template = "AGTOptionsSliderTemplate",
    OnValueChanged = function(self)
      if AGTOptionsCONSTSaveValue == true then
        AGTOptionsSaveSettings()
      end
      _G[self:GetName() .. "FSVal"]:SetText(AGTFonts[math.floor(self:GetValue())])
    end,
    enENHelp = "Guess what",
    enENDescription = "Font Type"
  }
}
AGTOptionsSettingsTemplate["Sounds"] = {
  WhisperInSurgery = {
    Sort = 1,
    Type = "Slider",
    Value = 1,
    Min = 1,
    Max = 16,
    Step = 1,
    Template = "AGTOptionsSliderTemplate",
    OnValueChanged = function(self)
      if AGTOptionsCONSTSaveValue == true then
        AGTOptionsSaveSettings()
      end
      _G[self:GetName() .. "FSVal"]:SetText(AGTSoundFiles[math.floor(self:GetValue())].name)
    end,
    enENHelp = "This sound is played if a patient who's in the surgery whispers you",
    enENDescription = "Whisper In Surgery"
  },
  Ignore = {
    Sort = 3,
    Type = "Slider",
    Value = 11,
    Min = 1,
    Max = 16,
    Step = 1,
    Template = "AGTOptionsSliderTemplate",
    OnValueChanged = function(self)
      if AGTOptionsCONSTSaveValue == true then
        AGTOptionsSaveSettings()
      end
      _G[self:GetName() .. "FSVal"]:SetText(AGTSoundFiles[math.floor(self:GetValue())].name)
    end,
    enENHelp = "This sound is played if a patient ignores you",
    enENDescription = "Patient Ignores You"
  }
}

function AGTOpenLib()
  AGTEdit:Show()
  AGTEditEditbox3List = 0
  AGTEditEditbox3Entry = 0
  AGTEditEditboxText3:SetText("")
  AGTEditScrollBars_Update()
  AGTEditSave:Disable()
  AGTEditSaveKey:Disable()
  AGTEditSaveResponse:Disable()
  AGTEditEditboxText3:ClearFocus()
  AGTParent = 0
  for x = 1, #AGTresponse, 1 do
    AGTresponse[x].Selected = false
  end
  for x = 1, #AGTkeyword, 1 do
    AGTkeyword[x].Selected = false
  end
  AGTEditScrollBars_Update()
  -- ~ 	InterfaceOptionsFrame_Show()
end

function AGTEdit_OnLoad()
  AGTEditScrollBar1:Show()
  AGTEditScrollBar2:Show()
  AGTEditScrollBars_Update()
  AGTEditSave:Disable()
  AGTEditSaveKey:Disable()
  AGTEditSaveResponse:Disable()
  -- ~ DAHITBlau = "|cffffff00";
  -- ~ DAHIHBlau = "|caaaaaa00";
  -- ~ DAHIDBlau = "|cffffffaa";
  AGTEditTitelShortHelpFS:SetText(
    "|cffffff00QUICK HELP|caaaaaa00\nResponse endings:\n      <*   Insert whisper text as question\n      <@  Insert whisper text as statement\n\nLeft click: select parent\nRight click: add/remove child to parent\nShift left click: edit entry\nEnter: save edit text\nEsc: cancel edit")
  AGTEditHelpFrameTextFS:SetText(
    "|cffffff00HOW AGT WORKS|caaaaaa00\nAGT utilizes as list of keywords (left) and a list of responses (right). Each keyword has one or more responses assigned. AGT is searching for the keywords in all new whisper messages. If a keyword is found then one of the assigned responses is send back to your patient.\n\n|cffffff00HOW TO SHOW KEYWORDS AND ASSIGNED RESPONSES|caaaaaa00\nExample: Close the help and do a left click on keyword number 3 (YOU'RE). You will realize that the keyword will be highlighted in green. Additionally in the right list (responses) the assigned responses are highlighted. This means if AGT finds the phrase \"YOU'RE\" in a chat message it will respond with one of these phrases. Do another left click on the keyword number 3 and it's not longer highlighted.\nYou could also show all keywords a response is assigned to (there are few responses that are assigned to multiple keywords). \nExample: Just do a left click on response number 28 (scroll down the right list). You will see, that the response is highlighted. Now scroll down the left list to keyword number 11. You will see that keyword number 10 and 11 are green. This means the selected response 28 is assigned to keyword number 10 and number 11. Left click again on response number 28 to deselect it.\nDo some more left clicks on keywords and responses. Mind the indicator text in the top of the windows. It says \"Child(s)<<<Parent\" or \"Parent>>>Child(s)\". The indicator shows the current selection. The parent list is the list where you selected an entry (one is green). The child list is the list that shows the assigned values (one or more are green).\n\n|cffffff00HOW TO ASSIGN RESPONSES/KEYWORDS|caaaaaa00\nSelect a keyword or response (left click). Right click on a white entry in the child list to additionally assign this entry to the selected keyword. Right click on a green entry to remove the assignment.\nExample: Select a keyword as parent (left click on a keyword). Then add or remove child assignments (right click on responses). Then de-select the keyword. Select a response (left click) as parent. Add the response to some additional keywords (right click). De-select the response.\n\n|cffffff00HOW TO EDIT RESPONSES/KEYWORDS|caaaaaa00\nJust hold the shift key and do a left click on a keyword or response. Type the new text into the edit box. Click on \"Save\" or press the enter key to save the keyword/response. Press the escape key to cancel the edit process.\n\n|cffffff00HOW TO ADD NEW RESPONSES/KEYWORDS|caaaaaa00\nJust type the new text into the edit box. Click on \"Save as new keyword\" or \"Save as new response\". Press the escape key to cancel.\n\n|cffffff00HOW TO RESET THE OLD RESPONSES/KEYWORDS IF YOU'RE TOTALLY FUCKED UP|caaaaaa00\nClick on the \"Load library\" combo box. Select \"Original\".")
end

AGTParent = 0
AGTEditEditbox3List = 0
AGTEditEditbox3Entry = 0

function AGTEditScrollBar_OnClick(...)
  local self, arg1, _down = ...

  if arg1 == "LeftButton" then
    if IsShiftKeyDown() then
      -- edit
      if string.find(self:GetName(), "AGTEdit1") then
        AGTEditEditbox3List = 1
        AGTEditEditbox3Entry = FauxScrollFrame_GetOffset(AGTEditScrollBar1) + self:GetID()
      elseif string.find(self:GetName(), "AGTEdit2") then
        AGTEditEditbox3List = 2
        AGTEditEditbox3Entry = FauxScrollFrame_GetOffset(AGTEditScrollBar2) + self:GetID()
      end
      AGTLoadEditbox()
      AGTEditSave:Disable()
      AGTEditSaveKey:Disable()
      AGTEditSaveResponse:Disable()
    else
      AGTClearEditbox()
      if string.find(self:GetName(), "AGTEdit1") then
        if AGTkeyword[FauxScrollFrame_GetOffset(AGTEditScrollBar1) + self:GetID()].Selected == true and AGTParent == 1 then
          AGTParent = 0
          for x = 1, #AGTkeyword, 1 do
            AGTkeyword[x].Selected = false
          end
          for x = 1, #AGTresponse, 1 do
            AGTresponse[x].Selected = false
          end
        else
          AGTParent = 1
          for x = 1, #AGTkeyword, 1 do
            AGTkeyword[x].Selected = false
          end
          AGTkeyword[FauxScrollFrame_GetOffset(AGTEditScrollBar1) + self:GetID()].Selected = true

          for x = 1, #AGTresponse, 1 do
            AGTresponse[x].Selected = false
          end
          for x = 1, #AGTkeyword[FauxScrollFrame_GetOffset(AGTEditScrollBar1) + self:GetID()].Responses, 1 do
            AGTresponse[AGTkeyword[FauxScrollFrame_GetOffset(AGTEditScrollBar1) + self:GetID()].Responses[x]].Selected =
              true
          end
        end
      elseif string.find(self:GetName(), "AGTEdit2") then
        if AGTresponse[FauxScrollFrame_GetOffset(AGTEditScrollBar2) + self:GetID()].Selected == true and AGTParent == 2 then
          AGTParent = 0
          for x = 1, #AGTkeyword, 1 do
            AGTkeyword[x].Selected = false
          end
          for x = 1, #AGTresponse, 1 do
            AGTresponse[x].Selected = false
          end
        else
          AGTParent = 2
          for x = 1, #AGTkeyword, 1 do
            AGTkeyword[x].Selected = false
          end
          for x = 1, #AGTresponse, 1 do
            AGTresponse[x].Selected = false
          end
          AGTresponse[FauxScrollFrame_GetOffset(AGTEditScrollBar2) + self:GetID()].Selected = true

          for x = 1, #AGTkeyword, 1 do
            for y = 1, #AGTkeyword[x].Responses, 1 do
              if AGTkeyword[x].Responses[y] == FauxScrollFrame_GetOffset(AGTEditScrollBar2) + self:GetID() then
                AGTkeyword[x].Selected = true
              end
            end
          end
        end
      end
    end
  elseif arg1 == "RightButton" then
    AGTClearEditbox()
    if IsShiftKeyDown() then
      -- delete
      if string.find(self:GetName(), "AGTEdit1") and AGTParent == 2 then
        -- ?
        print("AGT right button and shift edit1") -- fix/refactor/ use debug print...
      elseif string.find(self:GetName(), "AGTEdit2") and AGTParent == 1 then
        -- ?
        print("AGT right button and shift edit2")
      end
    else
      if string.find(self:GetName(), "AGTEdit1") and AGTParent == 2 then
        local selresp = 0
        for x = 1, #AGTresponse, 1 do
          if AGTresponse[x].Selected == true then
            selresp = x
          end
        end

        if AGTkeyword[FauxScrollFrame_GetOffset(AGTEditScrollBar1) + self:GetID()].Selected == true then
          local found = 0
          for x = 1, #AGTkeyword[FauxScrollFrame_GetOffset(AGTEditScrollBar1) + self:GetID()].Responses, 1 do
            if AGTkeyword[FauxScrollFrame_GetOffset(AGTEditScrollBar1) + self:GetID()].Responses[x] == selresp then
              found = x
            end
          end
          if found > 0 then
            table.remove(AGTkeyword[FauxScrollFrame_GetOffset(AGTEditScrollBar1) + self:GetID()].Responses, found)
          end
        else
          table.insert(AGTkeyword[FauxScrollFrame_GetOffset(AGTEditScrollBar1) + self:GetID()].Responses, selresp)
        end

        for x = 1, #AGTkeyword, 1 do
          AGTkeyword[x].Selected = false
        end
        for q = 1, #AGTresponse, 1 do
          if AGTresponse[q].Selected == true then
            for x = 1, #AGTkeyword, 1 do
              for y = 1, #AGTkeyword[x].Responses, 1 do
                if AGTkeyword[x].Responses[y] == q then
                  AGTkeyword[x].Selected = true
                end
              end
            end
          end
        end
      elseif string.find(self:GetName(), "AGTEdit2") and AGTParent == 1 then
        local selkey = 0
        for x = 1, #AGTkeyword, 1 do
          if AGTkeyword[x].Selected == true then
            selkey = x
          end
        end
        if AGTresponse[FauxScrollFrame_GetOffset(AGTEditScrollBar2) + self:GetID()].Selected == true then
          local found = 0
          for x = 1, #AGTkeyword[selkey].Responses, 1 do
            if AGTkeyword[selkey].Responses[x] == FauxScrollFrame_GetOffset(AGTEditScrollBar2) + self:GetID() then
              found = x
            end
          end
          if found > 0 then
            table.remove(AGTkeyword[selkey].Responses, found)
          end
        else
          table.insert(AGTkeyword[selkey].Responses, FauxScrollFrame_GetOffset(AGTEditScrollBar2) + self:GetID())
        end

        for x = 1, #AGTresponse, 1 do
          AGTresponse[x].Selected = false
        end
        for x = 1, #AGTkeyword[selkey].Responses, 1 do
          AGTresponse[AGTkeyword[selkey].Responses[x]].Selected = true
        end
      end
    end
  end
  AGTEditScrollBars_Update()
end
function AGTEditScrollBars_Update()
  local lineplusoffset
  FauxScrollFrame_Update(AGTEditScrollBar1, #AGTkeyword, 10, 20)
  for line = 1, 10, 1 do
    lineplusoffset = line + FauxScrollFrame_GetOffset(AGTEditScrollBar1)
    if lineplusoffset <= #AGTkeyword then
      _G["AGTEdit1Entry" .. line .. "NoFS"]:SetText(lineplusoffset)
      _G["AGTEdit1Entry" .. line .. "TextFS"]:SetText(AGTkeyword[lineplusoffset].key)
      if AGTkeyword[lineplusoffset].Selected == true then
        _G["AGTEdit1Entry" .. line .. "NoFS"]:SetTextColor(0, 1, 0, 1)
        _G["AGTEdit1Entry" .. line .. "TextFS"]:SetTextColor(0, 1, 0, 1)
      else
        _G["AGTEdit1Entry" .. line .. "NoFS"]:SetTextColor(1, 1, 1, 1)
        _G["AGTEdit1Entry" .. line .. "TextFS"]:SetTextColor(1, 1, 1, 1)
      end
      if AGTEditEditbox3List == 1 and AGTEditEditbox3Entry == lineplusoffset then
        _G["AGTEdit1Entry" .. line .. "NoFS"]:SetTextColor(1, 0, 0, 1)
        _G["AGTEdit1Entry" .. line .. "TextFS"]:SetTextColor(1, 0, 0, 1)
      end
      _G["AGTEdit1Entry" .. line]:Show()
    else
      _G["AGTEdit1Entry" .. line]:Hide()
    end
  end

  FauxScrollFrame_Update(AGTEditScrollBar2, #AGTresponse, 10, 20)
  for line = 1, 10, 1 do
    lineplusoffset = line + FauxScrollFrame_GetOffset(AGTEditScrollBar2)
    if lineplusoffset <= #AGTresponse then
      _G["AGTEdit2Entry" .. line .. "NoFS"]:SetText(lineplusoffset)
      _G["AGTEdit2Entry" .. line .. "TextFS"]:SetText(AGTresponse[lineplusoffset].Text)
      if AGTresponse[lineplusoffset].Selected == true then
        _G["AGTEdit2Entry" .. line .. "NoFS"]:SetTextColor(0, 1, 0, 1)
        _G["AGTEdit2Entry" .. line .. "TextFS"]:SetTextColor(0, 1, 0, 1)
      else
        _G["AGTEdit2Entry" .. line .. "NoFS"]:SetTextColor(1, 1, 1, 1)
        _G["AGTEdit2Entry" .. line .. "TextFS"]:SetTextColor(1, 1, 1, 1)
      end
      if AGTEditEditbox3List == 2 and AGTEditEditbox3Entry == lineplusoffset then
        _G["AGTEdit2Entry" .. line .. "NoFS"]:SetTextColor(1, 0, 0, 1)
        _G["AGTEdit2Entry" .. line .. "TextFS"]:SetTextColor(1, 0, 0, 1)
      end
      _G["AGTEdit2Entry" .. line]:Show()
    else
      _G["AGTEdit2Entry" .. line]:Hide()
    end
  end

  if AGTParent == 0 then
    AGTEditTitelParentFS:SetText("")
  elseif AGTParent == 1 then
    AGTEditTitelParentFS:SetText("Parent >>> Child(s)")
  elseif AGTParent == 2 then
    AGTEditTitelParentFS:SetText("Child(s) <<< Parent")
  end
end

function AGTLoadEditbox()
  if AGTEditEditbox3List == 1 then
    AGTEditEditboxText3:SetText(AGTkeyword[AGTEditEditbox3Entry].key)
  elseif AGTEditEditbox3List == 2 then
    AGTEditEditboxText3:SetText(AGTresponse[AGTEditEditbox3Entry].Text)
  end
  AGTEditEditboxText3:SetFocus()
  AGTEditScrollBars_Update()
end
function AGTSaveEditbox()
  if AGTEditEditboxText3:GetText() ~= "" then
    AGTEditEditboxText3:SetText(string.upper(AGTEditEditboxText3:GetText()))
    if AGTEditEditbox3List == 1 then
      AGTkeyword[AGTEditEditbox3Entry].key = AGTEditEditboxText3:GetText()
    elseif AGTEditEditbox3List == 2 then
      AGTresponse[AGTEditEditbox3Entry].Text = AGTEditEditboxText3:GetText()
    end
    AGTEditEditboxText3:SetText("")
  else
    AGTClearEditbox()
  end
  AGTEditEditbox3List = 0
  AGTEditEditbox3Entry = 0

  AGTEditSave:Disable()
  AGTEditSaveKey:Disable()
  AGTEditSaveResponse:Disable()
  AGTEditScrollBars_Update()
  AGTEditEditboxText3:ClearFocus()
end
function AGTClearEditbox()
  AGTEditEditbox3List = 0
  AGTEditEditbox3Entry = 0

  AGTEditEditboxText3:SetText("")
  AGTEditScrollBars_Update()
  AGTEditSave:Disable()
  AGTEditSaveKey:Disable()
  AGTEditSaveResponse:Disable()
  AGTEditScrollBars_Update()
  AGTEditEditboxText3:ClearFocus()
end

function AGTSaveButton()
  AGTSaveEditbox()
end
function AGTNewKeyButton()
  if AGTEditEditboxText3:GetText() ~= "" then
    local notnew = 0
    for x = 1, #AGTkeyword, 1 do
      if AGTkeyword[x].key == string.upper(AGTEditEditboxText3:GetText()) then
        notnew = x
      end
    end
    if notnew > 0 then
      FauxScrollFrame_SetOffset(AGTEditScrollBar1, notnew - 1)
      _G["AGTEditScrollBar1ScrollBar"]:SetValue((notnew - 1) * 20)
      AGTEditScrollBars_Update()
      AGTClearEditbox()
      return
    else
      table.insert(AGTkeyword,
                   {key = string.upper(AGTEditEditboxText3:GetText()), Responses = {}, Selected = false, Q = false})
      AGTEditScrollBars_Update()
      FauxScrollFrame_SetOffset(AGTEditScrollBar1, (#AGTkeyword + 1))
      _G["AGTEditScrollBar1ScrollBar"]:SetValue((#AGTkeyword + 1) * 20)
      AGTEditScrollBars_Update()
      AGTClearEditbox()
    end

    -- ~ 		-- wenn resp selecte dann resp gleich dazu
    -- ~ 		if AGTParent == 2 then
    -- ~ 		end
  end
end
function AGTNewResponseButton()
  if AGTEditEditboxText3:GetText() ~= "" then
    local notnew = 0
    for x = 1, #AGTresponse, 1 do
      if AGTresponse[x].Text == AGTEditEditboxText3:GetText() then
        notnew = x
      end
    end
    if notnew > 0 then
      FauxScrollFrame_SetOffset(AGTEditScrollBar2, notnew - 1)
      _G["AGTEditScrollBar2ScrollBar"]:SetValue((notnew - 1) * 20)
      AGTEditScrollBars_Update()
      AGTClearEditbox()
      return
    else
      table.insert(AGTresponse, {Text = AGTEditEditboxText3:GetText(), Selected = false})
      AGTEditScrollBars_Update()
      FauxScrollFrame_SetOffset(AGTEditScrollBar2, (#AGTresponse + 1))
      _G["AGTEditScrollBar2ScrollBar"]:SetValue((#AGTresponse + 1) * 20)
      AGTEditScrollBars_Update()
      AGTClearEditbox()
    end
  end
end

function AGTOptionsOutputDropDown_OnLoad(frame, source, value)
  local tname = frame:GetName()
  -- tint?
  UIDropDownMenu_Initialize(frame, function()
    local entry = {
      func = function(self)
        AGTOptionsOutputDropDown_OnClick(self, tname)
      end
    }
    for i = 1, #source, 1 do
      entry.text = source[i]
      entry.value = value
      UIDropDownMenu_AddButton(entry)
    end
  end)
end
function AGTOptionsOutputDropDown_OnClick(self, _tname)
  AGTNotFoundKey = AGTLibs[AGTLibsNames[self:GetID()]].AGTNotFoundKey
  AGTRepeatKey = AGTLibs[AGTLibsNames[self:GetID()]].AGTRepeatKey
  AGTkeyword = AGTLibs[AGTLibsNames[self:GetID()]].AGTkeyword
  AGTresponse = AGTLibs[AGTLibsNames[self:GetID()]].AGTresponse

  AGTEditEditbox3List = 0
  AGTEditEditbox3Entry = 0
  AGTEditEditboxText3:SetText("")
  AGTEditScrollBars_Update()
  AGTEditSave:Disable()
  AGTEditSaveKey:Disable()
  AGTEditSaveResponse:Disable()
  AGTEditEditboxText3:ClearFocus()
  AGTParent = 0
  for x = 1, #AGTresponse, 1 do
    AGTresponse[x].Selected = false
  end
  for x = 1, #AGTkeyword, 1 do
    AGTkeyword[x].Selected = false
  end
  AGTEditScrollBars_Update()
end

