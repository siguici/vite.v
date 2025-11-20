# Vite.v <span><img src="https://github.com/siguici/art/blob/HEAD/images/v-vite.svg" alt="⚡" width="24" /></span>

**Vite.v** is a [V](https://vlang.io/) module that integrates
your V applications with [Vite.js](https://vitejs.dev/).
It provides a simple and efficient way to manage frontend assets
with minimal configuration while keeping full flexibility.

## 🚀 Features

* 🔌 Seamless integration between **V** and **Vite**
* ⚡ Fast builds with optimized asset handling
* 🎯 Minimal setup for both simple and advanced use cases

## ⚙️ Requirements

Make sure you have:

* [V](https://vlang.io) (latest version)
* [Vite](https://vitejs.dev) (for frontend compilation)
* [v-vite](https://npm.im/v-vite) (a Vite plugin adapted to V)
  or start with the [V Vite Starter template](https://github.com/v-vite/starter)

## 📦 Installation

### Via VPM (Recommended)

```sh
v install siguici.vite
```

### Via Git

```sh
mkdir -p ${VMODULES:-$HOME/.vmodules}/siguici
git clone --depth=1 https://github.com/siguici/vite ${VMODULES:-$HOME/.vmodules}/siguici/vite
```

### As a project dependency

```v
Module {
  dependencies: ['siguici.vite']
}
```

## 🔧 Usage

Vite.v can be used **globally** or **locally** depending on your project needs.

---

### **1. Global usage (recommended for services, middleware, controllers, templates)**

You can simply create a single, global `vite` instance and use it anywhere:

```v
import siguici.vite

const vite := vite.new()

println(vite.url('assets/logo.svg'))
```

This makes the `vite` instance available across your entire project without
having to pass it through your app or context.

---

### **2. Local usage (attached to your app or struct)**

You can store the `Vite` instance as a field inside your app struct:

```v
import siguici.vite { Vite }

struct MyStruct {
    vite: Vite
}

my_struct := MyStruct{
    vite: Vite.new()
}

println(my_struct.vite.url('assets/logo.svg'))
```

Or, using a default value:

```v
struct MyStruct {
    vite Vite = vite.new()
}

my_struct := MyStruct{}

println(my_struct.vite.url('assets/logo.svg'))
```

This pattern is useful when working inside frameworks like **Veb**:

```v
module main

import veb
import siguici.vite { Vite }

pub struct Context {
    veb.Context
}

pub struct App {
pub mut:
    vite Vite
}

fn main() {
    mut app := &App{
        vite: Vite.new()
    }
    veb.run[App, Context](mut app, 8080)
}
```

### **3. Using in templates**

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <!-- Inject assets -->
  @{vite.assets([
    'src/resources/app.css',
    'src/resources/app.ts'
  ])}

  <!-- Or generate individual tags -->
  @{vite.tag('src/resources/app.css')}
  @{vite.tag('src/resources/app.ts')}

  <!-- Preload images -->
  @{vite.preload_tag('src/assets/logo.png')}
</head>
<body>
  <h1>Hello Vite + Veb!</h1>
</body>
</html>
```

---

### Configuration

The configuration is structured as follows:

```v
@[params]
struct ViteConfig {
    manifest_file string = 'manifest.json'
    hot_file      string = 'hot'
    public_dir    string = 'public'
    build_dir     string = 'build'
}
```

---

### 🧩 Injecting Assets in Templates

* **`vite.assets`**
  Manually inject specific CSS/JS assets:

```html
@{vite.assets([
  'src/resources/app.css',
  'src/resources/app.ts'
])}
```

* **`vite.input_assets`** (production only)
  Automatically inject entrypoints (scripts, styles, and dependencies):

```html
@{vite.input_assets()}
```

---

### 🧱 Helpers

* **`tag(path)`**
  Generate the correct HTML tag (`<script>`, `<link>`, `<img>`) for a given path:

```html
@{vite.tag('src/resources/main.ts')}
@{vite.tag('src/resources/global.css')}
@{vite.tag('images/logo.svg')}
```

* **`url(path)`**
  Get the fully resolved asset URL (including `APP_URL` if defined):

```html
<link rel="icon" href="@{vite.url('favicon.ico')}" />
<img src="@{vite.url('images/logo.png')}" alt="Logo" />
<script type="module" src="@{vite.url('src/resources/main.ts')}"></script>
```

These helpers work consistently in both **development** (via the Vite dev server)
and **production** (via the Vite manifest).

---

## 🤝 Contributing

Contributions are welcome!
Feel free to open an issue or submit a PR to improve **Vite.v**.

## 📜 License

This project is licensed under the MIT License.
See the [LICENSE](LICENSE) file for details.
