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

Add("Asuabot.Jumpscare", {
	"asuabot/Jumpscare-1.wav",
	"asuabot/Jumpscare-2.wav",
}, 100)

Add("Asuabot.Approach", "asuabot/Approach-1.wav")

Add("Asuabot.Ambiance1", "asuabot/Ambiance-1.wav", 100, 100)
Add("Asuabot.Ambiance2", "asuabot/Ambiance-2.wav", 100, 100)
Add("Asuabot.Ambiance3", "asuabot/Ambiance-3.wav", 100, 100)
Add("Asuabot.Ambiance3", "asuabot/Ambiance-4.wav", 100, 100)

Add("Asuabot.Slam", {
	"asuabot/Slam-1.wav",
	"asuabot/Slam-2.wav",
}, 100)
