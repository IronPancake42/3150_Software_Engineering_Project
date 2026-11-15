class_name PsxTexturePrep
extends RefCounted
## Pure, deterministic texture preparation on top of Godot's Image class.
##
## All functions are static and return new images; inputs are never modified.
##  - fit_pow2():    make both sides a power of two.
##  - to_rgb555():   quantise each RGB channel to 5 bits (optional Bayer dither).
##  - to_palette():  reduce to an N-colour palette (median cut, optional dither).

## Round each side to the nearest power of two (ties round up). Content is resized (nearest).
const MODE_NEAREST_POW2 := 0
## Largest power of two that fits in each side. Content is cropped, centred.
const MODE_CROP := 1
## Smallest power of two that covers each side. Content is centred, not scaled; new pixels are transparent.
const MODE_PAD := 2

## Classic 4x4 Bayer matrix, row-major, indexed as [(y & 3) * 4 + (x & 3)].
const BAYER4 := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]


# ---------------------------------------------------------------- helpers

static func _rgba_copy(img: Image) -> Image:
	if img == null or img.is_empty():
		return Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
	var out: Image = img.duplicate()
	if out.is_compressed():
		out.decompress()
	if out.get_format() != Image.FORMAT_RGBA8:
		out.convert(Image.FORMAT_RGBA8)
	return out


static func _floor_pow2(n: int) -> int:
	var p := 1
	while p * 2 <= n:
		p *= 2
	return p


static func _ceil_pow2(n: int) -> int:
	var p := 1
	while p < n:
		p *= 2
	return p


static func _target_side(n: int, mode: int, cap: int) -> int:
	var lo := _floor_pow2(n)
	var t := lo
	match mode:
		MODE_NEAREST_POW2:
			var hi := lo if lo == n else lo * 2
			t = lo if (n - lo) < (hi - n) else hi
		MODE_PAD:
			t = _ceil_pow2(n)
		_:
			t = lo
	return mini(t, cap)


# -------------------------------------------------------------- fit_pow2

## Returns a copy of `img` whose sides are powers of two, none above `max_side`
## (if `max_side` is not a power of two, the largest power of two <= max_side is used).
## Output format is RGBA8.
static func fit_pow2(img: Image, mode: int, max_side: int = 1024) -> Image:
	var src := _rgba_copy(img)
	var cap := _floor_pow2(maxi(1, max_side))
	var w := src.get_width()
	var h := src.get_height()
	var tw := _target_side(w, mode, cap)
	var th := _target_side(h, mode, cap)
	if mode == MODE_NEAREST_POW2:
		if tw != w or th != h:
			src.resize(tw, th, Image.INTERPOLATE_NEAREST)
		return src
	# CROP / PAD: centred copy onto a transparent canvas of the target size.
	var out := Image.create_empty(tw, th, false, Image.FORMAT_RGBA8)
	var ox := (tw - w) >> 1
	var oy := (th - h) >> 1
	var sx := 0
	var sy := 0
	var cw := w
	var ch := h
	if ox < 0:
		sx = -ox
		cw = tw
		ox = 0
	if oy < 0:
		sy = -oy
		ch = th
		oy = 0
	out.blit_rect(src, Rect2i(sx, sy, cw, ch), Vector2i(ox, oy))
	return out


# ------------------------------------------------------------- to_rgb555

## Quantises R, G and B to 5 bits each. With `dither`, a 4x4 Bayer offset of
## (bayer / 16 - 0.5) * 8 is added to each channel first. Levels are expanded back
## with bit replication: out = (level << 3) | (level >> 2).
## Alpha becomes binary: alpha >= alpha_threshold * 255 -> 255, otherwise 0.
static func to_rgb555(img: Image, dither: bool, alpha_threshold: float = 0.5) -> Image:
	var out := _rgba_copy(img)
	var w := out.get_width()
	var h := out.get_height()
	var d := out.get_data()
	var athr := alpha_threshold * 255.0
	for y in h:
		for x in w:
			var i := (y * w + x) * 4
			var off := 0.0
			if dither:
				off = (float(BAYER4[((y & 3) << 2) | (x & 3)]) / 16.0 - 0.5) * 8.0
			for c in 3:
				var v: int = d[i + c]
				if dither:
					v = int(clampf(float(v) + off, 0.0, 255.0))
				var level := v >> 3
				d[i + c] = (level << 3) | (level >> 2)
			d[i + 3] = 255 if float(d[i + 3]) >= athr else 0
	out.set_data(w, h, false, Image.FORMAT_RGBA8, d)
	return out


# ------------------------------------------------------------ to_palette

## Reduces `img` to at most `colors` colours (clamped to 2..256) using median cut.
## Opaque pixels only take part in building the palette. With `dither`, the Bayer
## offset (bayer / 16 - 0.5) * spread is added to each channel before the nearest
## palette entry is chosen, where spread = 128 / cbrt(colors).
## Transparent pixels (alpha below threshold) get alpha 0 and the RGB of palette[0].
## Returns { "image": Image (RGBA8), "palette": PackedColorArray }.
static func to_palette(img: Image, colors: int = 16, dither: bool = true, alpha_threshold: float = 0.5) -> Dictionary:
	colors = clampi(colors, 2, 256)
	var out := _rgba_copy(img)
	var w := out.get_width()
	var h := out.get_height()
	var d := out.get_data()
	var athr := alpha_threshold * 255.0

	var counts := {}
	for p in w * h:
		var i := p * 4
		if float(d[i + 3]) >= athr:
			var key: int = (d[i] << 16) | (d[i + 1] << 8) | d[i + 2]
			counts[key] = int(counts.get(key, 0)) + 1

	var pal_keys := _median_cut(counts, colors)
	if pal_keys.is_empty():
		pal_keys.append(0)
	var pr := PackedInt32Array()
	var pg := PackedInt32Array()
	var pb := PackedInt32Array()
	var palette := PackedColorArray()
	for k in pal_keys:
		pr.append((k >> 16) & 255)
		pg.append((k >> 8) & 255)
		pb.append(k & 255)
		palette.append(Color8((k >> 16) & 255, (k >> 8) & 255, k & 255))

	var spread := 128.0 / pow(float(colors), 1.0 / 3.0)
	var cache := {}
	for y in h:
		for x in w:
			var i := (y * w + x) * 4
			if float(d[i + 3]) < athr:
				d[i] = pr[0]
				d[i + 1] = pg[0]
				d[i + 2] = pb[0]
				d[i + 3] = 0
				continue
			var r: int = d[i]
			var g: int = d[i + 1]
			var b: int = d[i + 2]
			if dither:
				var off := (float(BAYER4[((y & 3) << 2) | (x & 3)]) / 16.0 - 0.5) * spread
				r = int(clampf(float(r) + off, 0.0, 255.0))
				g = int(clampf(float(g) + off, 0.0, 255.0))
				b = int(clampf(float(b) + off, 0.0, 255.0))
			var ck := (r << 16) | (g << 8) | b
			var idx: int
			if cache.has(ck):
				idx = cache[ck]
			else:
				idx = _nearest(r, g, b, pr, pg, pb)
				cache[ck] = idx
			d[i] = pr[idx]
			d[i + 1] = pg[idx]
			d[i + 2] = pb[idx]
			d[i + 3] = 255
	out.set_data(w, h, false, Image.FORMAT_RGBA8, d)
	return {"image": out, "palette": palette}


static func _nearest(r: int, g: int, b: int, pr: PackedInt32Array, pg: PackedInt32Array, pb: PackedInt32Array) -> int:
	var best := 0
	var best_d := 1 << 30
	for j in pr.size():
		var dr := r - pr[j]
		var dg := g - pg[j]
		var db := b - pb[j]
		var dist := dr * dr + dg * dg + db * db
		if dist < best_d:  # strict: ties keep the lowest index
			best_d = dist
			best = j
	return best


# Channel-permuted key so that a plain integer sort orders by `ch` first, then the
# remaining channels in R, G, B order. Keys are unique, so the order is total.
static func _pk(key: int, ch: int) -> int:
	var r := (key >> 16) & 255
	var g := (key >> 8) & 255
	var b := key & 255
	match ch:
		1:
			return (g << 16) | (r << 8) | b
		2:
			return (b << 16) | (r << 8) | g
	return key


static func _unpk(pk: int, ch: int) -> int:
	var a := (pk >> 16) & 255
	var b := (pk >> 8) & 255
	var c := pk & 255
	match ch:
		1:
			return (b << 16) | (a << 8) | c
		2:
			return (b << 16) | (c << 8) | a
	return pk


## Median cut over the colour histogram `counts` (packed 0xRRGGBB -> pixel count).
## Returns packed 0xRRGGBB keys, at most `n`.
static func _median_cut(counts: Dictionary, n: int) -> Array:
	var result := []
	if counts.is_empty():
		return result
	var first: Array = counts.keys()
	first.sort()
	var boxes: Array = [first]
	while boxes.size() < n:
		# Pick the splittable box with the widest channel range (ties: lowest index).
		var pick := -1
		var pick_range := -1
		var pick_ch := 0
		for bi in boxes.size():
			var box: Array = boxes[bi]
			if box.size() < 2:
				continue
			var lo := [255, 255, 255]
			var hi := [0, 0, 0]
			for key in box:
				var comps := [(key >> 16) & 255, (key >> 8) & 255, key & 255]
				for c in 3:
					lo[c] = mini(lo[c], comps[c])
					hi[c] = maxi(hi[c], comps[c])
			var best_c := 0
			var best_r: int = hi[0] - lo[0]
			for c in range(1, 3):
				if hi[c] - lo[c] > best_r:
					best_r = hi[c] - lo[c]
					best_c = c
			if best_r > pick_range:
				pick_range = best_r
				pick = bi
				pick_ch = best_c
		if pick < 0:
			break
		var src: Array = boxes[pick]
		var pks := []
		for key in src:
			pks.append(_pk(key, pick_ch))
		pks.sort()
		var ordered := []
		var total := 0
		for pk in pks:
			var key := _unpk(pk, pick_ch)
			ordered.append(key)
			total += int(counts[key])
		var acc := 0
		var cut := ordered.size() - 1
		for i in ordered.size():
			acc += int(counts[ordered[i]])
			if acc * 2 >= total:
				cut = i + 1
				break
		cut = clampi(cut, 1, ordered.size() - 1)
		boxes[pick] = ordered.slice(0, cut)
		boxes.append(ordered.slice(cut))
	for box in boxes:
		var total := 0
		var sr := 0
		var sg := 0
		var sb := 0
		for key in box:
			var c := int(counts[key])
			total += c
			sr += ((key >> 16) & 255) * c
			sg += ((key >> 8) & 255) * c
			sb += (key & 255) * c
		var half := total / 2
		result.append((((sr + half) / total) << 16) | (((sg + half) / total) << 8) | ((sb + half) / total))
	return result
