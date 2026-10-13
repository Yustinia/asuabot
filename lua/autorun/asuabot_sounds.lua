ASUABOT_SOUND_FILES = ASUABOT_SOUND_FILES or {}

local function Add(name, files, level, pitch)
	ASUABOT_SOUND_FILES[name] = istable(files) and files[1] or files

	sound.Add({
		name = name,
		channel = CHAN_AUTO,
		volume = 1.0,
		level = level or 100,
		pitch = pitch or { 80, 120 },
		sound = files,
	})
end

Add("Asuabot.Screech", {
	"asuabot/Screech-1.wav",
	"asuabot/Screech-2.wav",
	"asuabot/Screech-3.wav",
}, 40)

Add("Asuabot.Roar", {
	"asuabot/Roar-1.wav",
	"asuabot/Roar-2.wav",
	"asuabot/Roar-3.wav",
	"asuabot/Roar-4.wav",
	"asuabot/Roar-5.wav",
	"asuabot/Roar-6.wav",
	"asuabot/Roar-7.wav",
	"asuabot/Roar-8.wav",
	"asuabot/Roar-9.wav",
	"asuabot/Roar-10.wav",
}, 80)

Add("Asuabot.Growl", {
	"asuabot/Growl-1.wav",
	"asuabot/Growl-2.wav",
	"asuabot/Growl-3.wav",
	"asuabot/Growl-4.wav",
	"asuabot/Growl-5.wav",
	"asuabot/Growl-6.wav",
	"asuabot/Growl-7.wav",
	"asuabot/Growl-8.wav",
}, 80)

Add("Asuabot.Jumpscare", {
	"asuabot/Jumpscare-1.wav",
	"asuabot/Jumpscare-2.wav",
	"asuabot/Jumpscare-3.wav",
	"asuabot/Jumpscare-4.wav",
	"asuabot/Jumpscare-5.wav",
	"asuabot/Jumpscare-6.wav",
}, 100)

Add("Asuabot.Approach", {
	"asuabot/Approach-1.wav",
	"asuabot/Approach-2.wav",
	"asuabot/Approach-3.wav",
}, 100)

Add("Asuabot.Ambiance", {
	"asuabot/Ambiance-1.wav",
	"asuabot/Ambiance-2.wav",
	"asuabot/Ambiance-3.wav",
	"asuabot/Ambiance-4.wav",
	"asuabot/Ambiance-5.wav",
	"asuabot/Ambiance-6.wav",
	"asuabot/Ambiance-7.wav",
}, 100, 100)

Add("Asuabot.Slam", {
	"asuabot/Slam-1.wav",
	"asuabot/Slam-2.wav",
	"asuabot/Slam-3.wav",
	"asuabot/Slam-4.wav",
}, 100)

Add("Asuabot.Foley", {
	"asuabot/Foley-1.wav",
	"asuabot/Foley-2.wav",
}, 100)
