class_name NeonTextures
extends RefCounted

## Helper that generates glow sprites at runtime, so the game needs no
## external image assets. Every sprite is a soft radial gradient: bright
## in the center, fading to transparent at the edges. Combined with
## additive blending this gives the neon look.

static func glow(color: Color, size: int = 128) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size, size) * 0.5
	var radius := size * 0.5
	for y in range(size):
		for x in range(size):
			var d := Vector2(x, y).distance_to(center) / radius
			var a := clampf(1.0 - d, 0.0, 1.0)
			a *= a
			img.set_pixel(x, y, Color(color.r, color.g, color.b, a))
	return ImageTexture.create_from_image(img)


static func additive_material() -> CanvasItemMaterial:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return mat
