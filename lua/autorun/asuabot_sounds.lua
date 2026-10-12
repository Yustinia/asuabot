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
	"asuabot/Screech-4.wav",
	"asuabot/Screech-5.wav",
	"asuabot/Screech-6.wav",
	"asuabot/Screech-7.wav",
	"asuabot/Screech-8.wav",
	"asuabot/Screech-9.wav",
	"asuabot/Screech-10.wav",
	"asuabot/Screech-11.wav",
	"asuabot/Screech-12.wav",
	"asuabot/Screech-13.wav",
	"asuabot/LowScreech-1.wav",
	"asuabot/LowScreech-2.wav",
	"asuabot/LowScreech-3.wav",
	"asuabot/LowScreech-4.wav",
	"asuabot/LowScreech-5.wav",
	"asuabot/LowScreech-6.wav",
	"asuabot/LowScreech-7.wav",
	"asuabot/LowScreech-8.wav",
}, 40)

Add("Asuabot.Jumpscare", {
	"asuabot/Jumpscare-1.wav",
	"asuabot/Jumpscare-2.wav",
	"asuabot/Jumpscare-3.wav",
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
}, 100, 100)

Add("Asuabot.Slam", {
	"asuabot/Slam-1.wav",
	"asuabot/Slam-2.wav",
	"asuabot/Slam-3.wav",
}, 100)

Add("Asuabot.Foley", {
	"asuabot/Foley-1.wav",
}, 100)
