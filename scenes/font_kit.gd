class_name FontKit
# 跨平台一致字体：中文用打包的 qiji-fallback，英文/数字用打包的 Times New Roman。
# 全部通过 FontFile 从项目内加载（不依赖系统字体名），保证每台电脑渲染一致、无乱码。

const LATIN := "res://assets/fonts/times-new-roman.ttf"
const LATIN_BOLD := "res://assets/fonts/times-new-roman-bold.ttf"
const CJK := "res://assets/fonts/qiji-fallback.ttf"

static var _latin: FontFile
static var _latin_bold: FontFile
static var _cjk: FontFile
static var _composite: Font
static var _composite_bold: Font

static func _load(p: String) -> FontFile:
	var f := FontFile.new()
	if ResourceLoader.exists(p):
		if f.load_dynamic_font(p) == OK:
			return f
	f.free()
	return FontFile.new()

static func latin() -> FontFile:
	if _latin == null:
		_latin = _load(LATIN)
	return _latin

static func latin_bold() -> FontFile:
	if _latin_bold == null:
		_latin_bold = _load(LATIN_BOLD)
	return _latin_bold

static func cjk() -> FontFile:
	if _cjk == null:
		_cjk = _load(CJK)
	return _cjk

# base=Times(英文/数字)，中文缺字回退 qiji-fallback —— 两个都是打包的 FontFile，全平台一致
static func composite() -> Font:
	if _composite == null:
		_composite = latin()
		_composite.fallbacks = [cjk()]
	return _composite

static func composite_bold() -> Font:
	if _composite_bold == null:
		_composite_bold = latin_bold()
		_composite_bold.fallbacks = [cjk()]
	return _composite_bold
