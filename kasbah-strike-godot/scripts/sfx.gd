class_name Sfx

## Genere un son (bruit filtre + decroissance) sans fichier audio.
static func noise(dur: float, vol: float, lp: float, decay: float = 2.0, rate: int = 22050) -> AudioStreamWAV:
    var n := int(dur * rate)
    var d := PackedByteArray()
    d.resize(n * 2)
    var prev := 0.0
    for i in n:
        var env := pow(1.0 - float(i) / n, decay)
        prev += (randf() * 2.0 - 1.0 - prev) * lp
        d.encode_s16(i * 2, int(clampf(prev * env * vol, -1.0, 1.0) * 32767.0))
    var w := AudioStreamWAV.new()
    w.format = AudioStreamWAV.FORMAT_16_BITS
    w.mix_rate = rate
    w.stereo = false
    w.data = d
    return w
