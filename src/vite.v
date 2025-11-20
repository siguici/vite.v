module vite

import os
import json
import veb
import veb.assets

@[params]
pub struct ViteConfig {
pub:
	manifest_file string = 'manifest.json'
	hot_file      string = 'hot'
	public_dir    string = 'public'
	build_dir     string = 'build'
}

@[params]
pub struct AssetOptions {
pub:
	use_react      bool
	preload_assets bool
}

pub struct Vite {
	assets.AssetManager
mut:
	manifest_file   string @[required]
	hot_file        string @[required]
	public_dir      string @[required]
	build_dir       string @[required]
	manifest        ViteManifest
	manifest_loaded bool
}

pub struct ViteAsset {
	file             string @[required]
	name             string
	src              string
	is_entry         bool
	is_dynamic_entry bool
	css              []string
	imports          []string
	assets           []string
	dynamic_imports  []string
}

pub type ViteManifest = map[string]ViteAsset

pub struct ViteContext {
pub mut:
	vite_config ViteConfig
mut:
	vite &Vite = unsafe { nil }
}

pub fn Vite.new(config ViteConfig) Vite {
	return Vite{
		manifest_file: config.manifest_file
		hot_file:      config.hot_file
		public_dir:    config.public_dir
		build_dir:     config.build_dir
	}
}

pub fn new(config ViteConfig) Vite {
	return Vite.new(config)
}

pub fn (v Vite) manifest_path() string {
	return v.build_file(v.manifest_file)
}

pub fn (v Vite) hot_path() string {
	return if v.public_dir == '' {
		v.hot_file
	} else {
		'${v.public_dir}/${v.hot_file}'
	}
}

pub fn (v Vite) public_file(path string) string {
	return if v.public_dir == '' { path } else { '${v.public_dir}/${path}' }
}

pub fn (v Vite) build_file(path string) string {
	return if v.build_dir == '' {
		v.public_file(path)
	} else {
		v.public_file('${v.build_dir}/${path}')
	}
}

pub fn (mut v Vite) entrypoints() []ViteAsset {
	return v.entrypoints_opt() or {
		eprintln(err)
		[]
	}
}

pub fn (mut v Vite) entrypoints_opt() ![]ViteAsset {
	return v.manifest()!.values().filter(it.is_entry)
}

pub fn (mut v Vite) input_assets(options AssetOptions) veb.RawHtml {
	return v.assets(v.entrypoints().map(it.name), options)
}

pub fn (mut v Vite) input_assets_opt(options AssetOptions) !veb.RawHtml {
	return v.assets_opt(v.entrypoints_opt()!.map(it.name), options)
}

pub fn (mut v Vite) assets(names []string, options AssetOptions) veb.RawHtml {
	return v.assets_opt(names, options) or {
		eprintln(err)
		''
	}
}

pub fn (mut v Vite) assets_or_panic(names []string, options AssetOptions) veb.RawHtml {
	return v.assets_opt(names, options) or { panic(err) }
}

pub fn (mut v Vite) assets_opt(names []string, options AssetOptions) !veb.RawHtml {
	mut render := ''

	if v.is_hot() {
		render = v.hot_scripts(options)
	}

	for name in names {
		render = '${render}${v.asset_opt(name, options)!}'
	}

	return render
}

pub fn (mut v Vite) asset(name string, options AssetOptions) veb.RawHtml {
	return v.asset_opt(name, options) or {
		eprintln(err)
		''
	}
}

pub fn (mut v Vite) asset_opt(name string, options AssetOptions) !veb.RawHtml {
	mut html := ''

	if !v.is_hot() {
		asset := v.chunk_opt(name)!
		css := asset.css
		imports := asset.imports

		for css_file in css {
			html += v.style(v.build_url(css_file))
		}

		for chunk in imports {
			chunk_url := v.build_url(chunk)
			html += if v.is_css(chunk) {
				v.style(chunk_url)
			} else if v.is_js(chunk) {
				v.preload_script(chunk_url)
			} else {
				''
			}
		}

		if options.preload_assets {
			asset_assets := asset.assets
			for asset_file in asset_assets {
				html += v.preload_asset(v.build_url(asset_file))
			}
		}
	}

	html = '${html}${v.tag(name)}'

	return html
}

pub fn (mut v Vite) url(path string) string {
	return v.url_opt(path) or {
		eprintln(err)
		''
	}
}

pub fn (mut v Vite) url_or_panic(path string) string {
	return v.url_opt(path) or { panic(err) }
}

pub fn (mut v Vite) url_opt(path string) !string {
	return if v.is_hot() {
		v.hot_url(path)
	} else {
		asset := v.chunk_opt(path)!
		file := asset.file

		if file == '' {
			error('Unable to locate asset ${path} in Vite manifest.')
		}

		v.build_url(file)
	}
}

pub fn (mut v Vite) tag(path string) veb.RawHtml {
	return v.tag_opt(path) or {
		eprintln(err)
		''
	}
}

pub fn (mut v Vite) tag_or_panic(path string) veb.RawHtml {
	return v.tag_opt(path) or { panic(err) }
}

pub fn (mut v Vite) tag_opt(path string) !veb.RawHtml {
	url := v.url_opt(path)!

	return if v.is_css(path) {
		v.style(url)
	} else if v.is_js(path) {
		v.defer_script(url, '')
	} else if v.is_img(path) {
		v.img(url, '')
	} else {
		url
	}
}

pub fn (mut v Vite) chunk(name string) ViteAsset {
	return v.chunk_opt(name) or {
		eprintln(err)
		ViteAsset{
			file: ''
			name: name
		}
	}
}

pub fn (mut v Vite) chunk_opt(name string) !ViteAsset {
	manifest := v.manifest()!

	return manifest[name]
}

pub fn (mut v Vite) chunk_or_panic(name string) ViteAsset {
	return v.chunk_opt(name) or { panic(err) }
}

fn (v Vite) is_css(path string) bool {
	return match os.file_ext(path) {
		'.css', '.less', '.sass', '.scss', '.styl', '.stylus', '.pcss', '.postcss' {
			true
		}
		else {
			false
		}
	}
}

fn (v Vite) is_js(path string) bool {
	return match os.file_ext(path) {
		'.js', '.cjs', '.mjs', '.jsx', '.ts', '.tsx', '.cts', '.mts' {
			true
		}
		else {
			false
		}
	}
}

fn (v Vite) is_img(path string) bool {
	return match os.file_ext(path) {
		'.png', '.jpg', '.jpeg', '.svg', '.webp', '.gif' {
			true
		}
		else {
			false
		}
	}
}

pub fn (v Vite) hot_scripts(options AssetOptions) veb.RawHtml {
	mut render := v.script('${v.app_url()}/@vite/client', '')

	if options.use_react {
		render = '${render}${v.react_script()}'
	}

	return render
}

pub fn (v Vite) react_script() veb.RawHtml {
	mut content := ''
	content += 'import RefreshRuntime from "${v.app_url()}/@react-refresh";'
	content += 'RefreshRuntime.injectIntoGlobalHook(window);'
	content += 'window.\$RefreshReg\$ = () => {};'
	content += 'window.\$RefreshSig\$ = () => (type) => type;'
	content += 'window.__v_plugin_react_preamble_installed__ = true;'
	return v.script('', content)
}

pub fn (v Vite) style(href string) string {
	attrs := [
		new_attribute('rel', 'stylesheet'),
		new_attribute('href', href),
	]
	return new_style(attrs, '').str()
}

fn (v Vite) preload_script(href string) string {
	attrs := [
		new_attribute('rel', 'modulepreload'),
		new_attribute('href', href),
	]
	return new_tag('link', attrs, '').str()
}

fn (v Vite) preload_asset(path string) string {
	ext := os.file_ext(path).after('.').to_lower()
	mut use_as := ''
	mut mime := ''
	mut crossorigin := false

	match ext {
		// Fonts
		'woff2' {
			use_as = 'font'
			mime = 'font/woff2'
			crossorigin = true
		}
		'woff' {
			use_as = 'font'
			mime = 'font/woff'
			crossorigin = true
		}
		'ttf' {
			use_as = 'font'
			mime = 'font/ttf'
			crossorigin = true
		}
		'otf' {
			use_as = 'font'
			mime = 'font/otf'
			crossorigin = true
		}
		'eot' {
			use_as = 'font'
			mime = 'application/vnd.ms-fontobject'
			crossorigin = true
		}
		// Images
		'jpg', 'jpeg' {
			use_as = 'image'
			mime = 'image/jpeg'
		}
		'png' {
			use_as = 'image'
			mime = 'image/png'
		}
		'gif' {
			use_as = 'image'
			mime = 'image/gif'
		}
		'webp' {
			use_as = 'image'
			mime = 'image/webp'
		}
		'avif' {
			use_as = 'image'
			mime = 'image/avif'
		}
		'svg' {
			use_as = 'image'
			mime = 'image/svg+xml'
		}
		'ico' {
			use_as = 'image'
			mime = 'image/x-icon'
		}
		// Audios
		'mp3' {
			use_as = 'audio'
			mime = 'audio/mpeg'
		}
		'ogg' {
			use_as = 'audio'
			mime = 'audio/ogg'
		}
		'wav' {
			use_as = 'audio'
			mime = 'audio/wav'
		}
		// Videos
		'mp4' {
			use_as = 'video'
			mime = 'video/mp4'
		}
		'webm' {
			use_as = 'video'
			mime = 'video/webm'
		}
		'ogv' {
			use_as = 'video'
			mime = 'video/ogg'
		}
		// Documents
		'pdf' {
			use_as = 'document'
			mime = 'application/pdf'
		}
		else {
			return ''
		}
	}

	attrs := [
		new_attribute('rel', 'preload'),
		new_attribute('href', path),
		new_attribute('as', use_as),
		new_attribute('type', mime),
		new_attribute('crossorigin', crossorigin),
	]

	return new_tag('link', attrs, '').str()
}

pub fn (v Vite) script(src string, content TagContent) string {
	mut attrs := [
		new_attribute('type', 'module'),
	]

	if src != '' {
		attrs << new_attribute('src', src)
	}

	return new_script(attrs, content).str()
}

pub fn (v Vite) defer_script(src string, content TagContent) string {
	attrs := [
		new_attribute('src', src),
		new_attribute('type', 'module'),
		new_attribute('defer', true),
	]

	return new_script(attrs, content).str()
}

pub fn (v Vite) img(src string, alt string) string {
	attrs := [
		new_attribute('src', src),
		new_attribute('alt', alt),
	]
	return new_image(attrs).str()
}

pub fn (v Vite) is_hot() bool {
	return os.is_file(v.hot_path())
}

pub fn (v Vite) hot_url(path string) string {
	return '${v.app_url()}/${path}'
}

pub fn (v Vite) app_url() string {
	return v.app_url_opt() or {
		eprintln(err)
		''
	}
}

pub fn (v Vite) app_url_opt() !string {
	return if v.is_hot() {
		hot_file := v.hot_path().trim_space()
		os.read_file(hot_file) or { error('Unable to read hot file ${hot_file}: ${err}') }
	} else {
		os.getenv('APP_URL')
	}
}

pub fn (v Vite) build_url(path string) string {
	return if v.build_dir == '' { v.hot_url(path) } else { '${v.app_url()}/${v.build_dir}/${path}' }
}

pub fn (mut v Vite) manifest() !ViteManifest {
	if !v.manifest_loaded {
		v.load_manifest()!

		v.manifest_loaded = true
	}

	return v.manifest
}

fn (mut v Vite) load_manifest() ! {
	manifest_path := v.manifest_path()

	if !os.is_file(manifest_path) {
		error('Vite manifest ${manifest_path} not found.')
	}

	v.manifest = json.decode(ViteManifest, os.read_file(manifest_path)!)!

	v.add_manifest_assets()!
}

fn (mut v Vite) add_manifest_assets() ! {
	for name, asset in v.manifest {
		file := v.build_file(asset.file)
		if v.is_css(name) {
			v.add_css(file, name)!
		} else if v.is_js(name) {
			v.add_js(file, name)!
		}
	}
}

pub fn (mut v Vite) add_css(file string, name string) ! {
	v.add(.css, file, name)!
}

pub fn (mut v Vite) add_js(file string, name string) ! {
	v.add(.js, file, name)!
}

pub fn (mut ctx ViteContext) vite() &Vite {
	if ctx.vite == unsafe { nil } || ctx.vite.manifest_file != ctx.vite_config.manifest_file
		|| ctx.vite.hot_file != ctx.vite_config.hot_file
		|| ctx.vite.public_dir != ctx.vite_config.public_dir
		|| ctx.vite.build_dir != ctx.vite_config.build_dir {
		v := Vite.new(ctx.vite_config)
		ctx.vite = &v
	}
	return ctx.vite
}

pub fn (mut ctx ViteContext) vite_entrypoints() []ViteAsset {
	mut v := ctx.vite()
	return v.entrypoints()
}

pub fn (mut ctx ViteContext) vite_chunk(name string) ViteAsset {
	mut v := ctx.vite()
	return v.chunk(name)
}

pub fn (mut ctx ViteContext) vite_input_assets(options AssetOptions) veb.RawHtml {
	mut v := ctx.vite()
	return v.input_assets(options)
}

pub fn (mut ctx ViteContext) vite_assets(names []string, options AssetOptions) veb.RawHtml {
	mut v := ctx.vite()
	return v.assets(names, options)
}

pub fn (mut ctx ViteContext) vite_asset(name string, options AssetOptions) veb.RawHtml {
	mut v := ctx.vite()
	return v.asset(name, options)
}

pub fn (mut ctx ViteContext) vite_url(path string) string {
	mut v := ctx.vite()
	return v.url(path)
}

pub fn (mut ctx ViteContext) vite_tag(path string) veb.RawHtml {
	mut v := ctx.vite()
	return v.tag(path)
}

pub fn (mut ctx ViteContext) vite_hot_scripts(options AssetOptions) veb.RawHtml {
	mut v := ctx.vite()
	return v.hot_scripts(options)
}

pub fn (mut ctx ViteContext) vite_react_script() veb.RawHtml {
	mut v := ctx.vite()
	return v.react_script()
}
